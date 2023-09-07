import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:value_layout_builder/value_layout_builder.dart';


/// Signature used by [SliverStickyHeader.builder] to build the header
/// when the sticky header state has changed.
typedef SliverStickyHeaderWidgetBuilder = Widget Function(
    BuildContext context,
    SliverStickyHeaderState state,
    );

/// A
class StickyHeaderController with ChangeNotifier {
  /// The offset to use in order to jump to the first item
  /// of current the sticky header.
  ///
  /// If there is no sticky headers, this is 0.
  double get stickyHeaderScrollOffset => _stickyHeaderScrollOffset;
  double _stickyHeaderScrollOffset = 0;

  /// This setter should only be used by flutter_sticky_header package.
  set stickyHeaderScrollOffset(double value) {
    if (_stickyHeaderScrollOffset != value) {
      _stickyHeaderScrollOffset = value;
      notifyListeners();
    }
  }
}

/// The [StickyHeaderController] for descendant widgets that don't specify one
/// explicitly.
///
/// [DefaultStickyHeaderController] is an inherited widget that is used to share a
/// [StickyHeaderController] with [SliverStickyHeader]s. It's used when sharing an
/// explicitly created [StickyHeaderController] isn't convenient because the sticky
/// headers are created by a stateless parent widget or by different parent
/// widgets.
class DefaultStickyHeaderController extends StatefulWidget {
  const DefaultStickyHeaderController({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Scaffold] whose [AppBar] includes a [TabBar].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage:
  ///
  /// ```dart
  /// StickyHeaderController controller = DefaultStickyHeaderController.of(context);
  /// ```
  static StickyHeaderController? of(BuildContext context) {
    final _StickyHeaderControllerScope? scope = context
        .dependOnInheritedWidgetOfExactType<_StickyHeaderControllerScope>();
    return scope?.controller;
  }

  @override
  DefaultStickyHeaderControllerState createState() => DefaultStickyHeaderControllerState();

}

class DefaultStickyHeaderControllerState extends State<DefaultStickyHeaderController> {

  StickyHeaderController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = StickyHeaderController();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StickyHeaderControllerScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _StickyHeaderControllerScope extends InheritedWidget {
  const _StickyHeaderControllerScope({
    Key? key,
    this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final StickyHeaderController? controller;

  @override
  bool updateShouldNotify(_StickyHeaderControllerScope old) {
    return controller != old.controller;
  }
}

/// State describing how a sticky header is rendered.
@immutable
class SliverStickyHeaderState {
  const SliverStickyHeaderState(
      this.scrollPercentage,
      this.isPinned,
      );

  final double scrollPercentage;

  final bool isPinned;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! SliverStickyHeaderState) return false;
    final SliverStickyHeaderState typedOther = other;
    return scrollPercentage == typedOther.scrollPercentage &&
        isPinned == typedOther.isPinned;
  }

  @override
  int get hashCode {
    return Object.hashAll([scrollPercentage, isPinned]);
  }
}

/// A sliver that displays a header before its sliver.
/// The header scrolls off the viewport only when the sliver does.
///
/// Place this widget inside a [CustomScrollView] or similar.
class SliverStickyHeader extends RenderObjectWidget {
  /// Creates a sliver that displays the [header] before its [sliver], unless
  /// [overlapsContent] it's true.
  /// The [header] stays pinned when it hits the start of the viewport until
  /// the [sliver] scrolls off the viewport.
  ///
  /// The [overlapsContent] and [sticky] arguments must not be null.
  ///
  /// If a [StickyHeaderController] is not provided, then the value of
  /// [DefaultStickyHeaderController.of] will be used.
  const SliverStickyHeader({
    Key? key,
    this.header,
    this.sliver,
    this.overlapsContent = false,
    this.sticky = true,
    this.controller,
    this.scrollController,
    this.stickOffset = 0,
    this.footer = false,
  }) : super(key: key);

  /// Creates a widget that builds the header of a [SliverStickyHeader]
  /// each time its scroll percentage changes.
  ///
  /// The [builder], [overlapsContent] and [sticky] arguments must not be null.
  ///
  /// If a [StickyHeaderController] is not provided, then the value of
  /// [DefaultStickyHeaderController.of] will be used.
  SliverStickyHeader.builder({
    Key? key,
    required SliverStickyHeaderWidgetBuilder builder,
    Widget? sliver,
    bool overlapsContent = false,
    bool sticky = true,
    StickyHeaderController? controller,
    ScrollController? scrollController,
    double stickOffset = 0,
    bool footer = false,
  }) : this(
    key: key,
    header: ValueLayoutBuilder<SliverStickyHeaderState>(
      builder: (context, constraints) =>
          builder(context, constraints.value),
    ),
    sliver: sliver,
    overlapsContent: overlapsContent,
    sticky: sticky,
    controller: controller,
    scrollController: scrollController,
    stickOffset: stickOffset,
    footer: footer,
  );

  /// The header to display before the sliver.
  final Widget? header;

  /// The sliver to display after the header.
  final Widget? sliver;

  /// Whether the header should be drawn on top of the sliver
  /// instead of before.
  final bool overlapsContent;

  /// Whether to stick the header.
  /// Defaults to true.
  final bool sticky;

  /// The controller used to interact with this sliver.
  ///
  /// If a [StickyHeaderController] is not provided, then the value of [DefaultStickyHeaderController.of]
  /// will be used.
  final StickyHeaderController? controller;

  final ScrollController? scrollController;
  final double stickOffset;
  final bool footer;

  @override
  RenderSliverStickyHeader createRenderObject(BuildContext context) {
    return RenderSliverStickyHeader(
      overlapsContent: overlapsContent,
      sticky: sticky,
      controller: controller ?? DefaultStickyHeaderController.of(context),
      scrollController: scrollController,
      stickOffset: stickOffset,
      footer: footer,
    );
  }

  @override
  SliverStickyHeaderRenderObjectElement createElement() =>
      SliverStickyHeaderRenderObjectElement(this);

  @override
  void updateRenderObject(
      BuildContext context,
      RenderSliverStickyHeader renderObject,
      ) {
    renderObject
      ..overlapsContent = overlapsContent
      ..sticky = sticky
      ..controller = controller ?? DefaultStickyHeaderController.of(context)
      ..scrollController = scrollController
      ..stickOffset = stickOffset
      ..footer = footer;
  }
}


class SliverStickyHeaderRenderObjectElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  SliverStickyHeaderRenderObjectElement(SliverStickyHeader widget)
      : super(widget);

  @override
  SliverStickyHeader get widget => super.widget as SliverStickyHeader;

  Element? _header;

  Element? _sliver;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_sliver != null) visitor(_sliver!);
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);
    if (child == _header) _header = null;
    if (child == _sliver) _sliver = null;
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _header = updateChild(_header, widget.header, 0);
    _sliver = updateChild(_sliver, widget.sliver, 1);
  }

  @override
  void update(SliverStickyHeader newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _header = updateChild(_header, widget.header, 0);
    _sliver = updateChild(_sliver, widget.sliver, 1);
  }

  @override
  void insertRenderObjectChild(RenderObject child, int? slot) {
    final RenderSliverStickyHeader renderObject =
    this.renderObject as RenderSliverStickyHeader;
    if (slot==0) {
      renderObject.header = child as RenderBox?;
    }
    if (slot==1) {
      renderObject.child = child as RenderSliver?;
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, slot, newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, slot) {
    final RenderSliverStickyHeader renderObject =
    this.renderObject as RenderSliverStickyHeader;
    if (renderObject.header == child) renderObject.header = null;
    if (renderObject.child == child) renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}



/// A sliver with a [RenderBox] as header and a [RenderSliver] as child.
///
/// The [header] stays pinned when it hits the start of the viewport until
/// the [child] scrolls off the viewport.
class RenderSliverStickyHeader extends RenderSliver with RenderSliverHelpers {
  RenderSliverStickyHeader({
    RenderObject? header,
    RenderSliver? child,
    bool overlapsContent = false,
    bool sticky = true,
    StickyHeaderController? controller,
    ScrollController? scrollController,
    double stickOffset = 0,
    bool footer = false,
  })  : _overlapsContent = overlapsContent,
        _sticky = sticky,
        _scrollController = scrollController,
        _stickOffset = stickOffset,
        _footer = footer,
        _controller = controller {
          this.header = header as RenderBox?;
          this.child = child;
        }

  SliverStickyHeaderState? _oldState;
  double? _headerExtent;
  late bool _isPinned;

  bool get overlapsContent => _overlapsContent;
  bool _overlapsContent;

  set overlapsContent(bool value) {
    if (_overlapsContent == value) return;
    _overlapsContent = value;
    markNeedsLayout();
  }

  bool get sticky => _sticky;
  bool _sticky;
  set sticky(bool value) {
    if (_sticky == value) return;
    _sticky = value;
    markNeedsLayout();
  }

  ScrollController? _scrollController;
  ScrollController? get scrollController => _scrollController;
  set scrollController(ScrollController? value) {
    if (_scrollController == value) return;
    _scrollController = value;
    scrollController?.addListener(markNeedsLayoutFromScrollController);
    markNeedsLayout();
  }

  double _stickOffset;
  double get stickOffset => _stickOffset;
  set stickOffset(double value) {
    if (_stickOffset == value) return;
    _stickOffset = value;
    markNeedsLayout();
  }

  bool _footer;
  bool get footer => _footer;
  set footer(bool value) {
    if (_footer == value) return;
    _footer = value;
    markNeedsLayout();
  }

  StickyHeaderController? get controller => _controller;
  StickyHeaderController? _controller;

  set controller(StickyHeaderController? value) {
    if (_controller == value) return;
    if (_controller != null && value != null) {
      // We copy the state of the old controller.
      value.stickyHeaderScrollOffset = _controller!.stickyHeaderScrollOffset;
    }
    _controller = value;
  }

  /// The render object's header
  RenderBox? get header => _header;
  RenderBox? _header;

  set header(RenderBox? value) {
    if (_header != null) dropChild(_header!);
    _header = value;
    if (_header != null) adoptChild(_header!);
  }

  /// The render object's unique child
  RenderSliver? get child => _child;
  RenderSliver? _child;

  set child(RenderSliver? value) {
    if (_child != null) dropChild(_child!);
    _child = value;
    if (_child != null) adoptChild(_child!);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_header != null) _header!.attach(owner);
    if (_child != null) _child!.attach(owner);
    scrollController?.addListener(markNeedsLayoutFromScrollController);
  }

  @override
  void detach() {
    super.detach();
    if (_header != null) _header!.detach();
    if (_child != null) _child!.detach();
    scrollController?.removeListener(markNeedsLayoutFromScrollController);
  }

  @override
  void redepthChildren() {
    if (_header != null) redepthChild(_header!);
    if (_child != null) redepthChild(_child!);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    List<DiagnosticsNode> result = <DiagnosticsNode>[];
    if (header != null) {
      result.add(header!.toDiagnosticsNode(name: 'header'));
    }
    if (child != null) {
      result.add(child!.toDiagnosticsNode(name: 'child'));
    }
    return result;
  }

  void markNeedsLayoutFromScrollController() {
    if (sticky && header!=null) {
      final SliverPhysicalParentData? headerParentData =
          header!.parentData as SliverPhysicalParentData?;
      if (headerParentData!=null) {
        externalStuckOffset = determineStuckOffsetFromExternalController();
        switch (constraints.axisDirection) {
          case AxisDirection.up:
          case AxisDirection.down:
            headerParentData.paintOffset = Offset(0, headerParentData.paintOffset.dy - (previousExternalStuckOffset??0) + externalStuckOffset);
            break;
          case AxisDirection.left:
          case AxisDirection.right:
            headerParentData.paintOffset = Offset(headerParentData.paintOffset.dx - (previousExternalStuckOffset??0) + externalStuckOffset, 0);
            break;
        }
        previousExternalStuckOffset = externalStuckOffset;
        markNeedsPaint();
      }
    }
  }



  double computeHeaderExtent() {
    if (header == null) return 0.0;
    assert(header!.hasSize);
    switch (constraints.axis) {
      case Axis.vertical:
        return header!.size.height;
      case Axis.horizontal:
        return header!.size.width;
    }
  }

  double? get headerLogicalExtent => overlapsContent ? 0.0 : _headerExtent;

  @override
  void performLayout() {
    if (header == null && child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    // One of them is not null.
    AxisDirection axisDirection = applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection,);

    if (header != null) {
      header!.layout(
        BoxValueConstraints<SliverStickyHeaderState>(
          value: _oldState ?? const SliverStickyHeaderState(0.0, false),
          constraints: constraints.asBoxConstraints(),
        ),
        parentUsesSize: true,
      );
      _headerExtent = computeHeaderExtent();
    }

    // Compute the header extent only one time.
    double headerExtent = headerLogicalExtent!;
    final double headerPaintExtent =
    calculatePaintOffset(constraints, from: 0.0, to: headerExtent);
    final double headerCacheExtent =
    calculateCacheOffset(constraints, from: 0.0, to: headerExtent);

    if (child == null) {
      geometry = SliverGeometry(
          scrollExtent: headerExtent,
          maxPaintExtent: headerExtent,
          paintExtent: headerPaintExtent,
          cacheExtent: headerCacheExtent,
          hitTestExtent: headerPaintExtent,
          hasVisualOverflow: headerExtent > constraints.remainingPaintExtent ||
              constraints.scrollOffset > 0.0,);
    } else {
      child!.layout(
        constraints.copyWith(
          scrollOffset: math.max(0.0, constraints.scrollOffset - headerExtent),
          cacheOrigin: math.min(0.0, constraints.cacheOrigin + headerExtent),
          overlap: 0.0,
          remainingPaintExtent:
          constraints.remainingPaintExtent - headerPaintExtent,
          remainingCacheExtent:
          constraints.remainingCacheExtent - headerCacheExtent,
        ),
        parentUsesSize: true,
      );
      final SliverGeometry childLayoutGeometry = child!.geometry!;
      if (childLayoutGeometry.scrollOffsetCorrection != null) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
        );
        return;
      }

      final double paintExtent = math.min(
        headerPaintExtent +
            math.max(childLayoutGeometry.paintExtent,
                childLayoutGeometry.layoutExtent,),
        constraints.remainingPaintExtent,
      );

      geometry = SliverGeometry(
        scrollExtent: headerExtent + childLayoutGeometry.scrollExtent,
        paintExtent: paintExtent,
        layoutExtent: math.min(
            headerPaintExtent + childLayoutGeometry.layoutExtent, paintExtent,),
        cacheExtent: math.min(
            headerCacheExtent + childLayoutGeometry.cacheExtent,
            constraints.remainingCacheExtent,),
        maxPaintExtent: headerExtent + childLayoutGeometry.maxPaintExtent,
        hitTestExtent: math.max(
            headerPaintExtent + childLayoutGeometry.paintExtent,
            headerPaintExtent + childLayoutGeometry.hitTestExtent,),
        hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
      );

      final SliverPhysicalParentData? childParentData =
      child!.parentData as SliverPhysicalParentData?;
      if (footer) {
        switch (axisDirection) {
          case AxisDirection.up:
            childParentData!.paintOffset = Offset(0.0,
                calculatePaintOffset(constraints, from: 0.0, to: headerExtent),);
            break;
          case AxisDirection.right:
            childParentData!.paintOffset = Offset.zero;
            break;
          case AxisDirection.down:
            childParentData!.paintOffset = Offset.zero;
            break;
          case AxisDirection.left:
            childParentData!.paintOffset = Offset(
                calculatePaintOffset(constraints, from: 0.0, to: headerExtent),
                0.0,);
            break;
        }
      } else {
        switch (axisDirection) {
          case AxisDirection.up:
            childParentData!.paintOffset = Offset.zero;
            break;
          case AxisDirection.right:
            childParentData!.paintOffset = Offset(
                calculatePaintOffset(constraints, from: 0.0, to: headerExtent),
                0.0,);
            break;
          case AxisDirection.down:
            childParentData!.paintOffset = Offset(0.0,
                calculatePaintOffset(constraints, from: 0.0, to: headerExtent),);
            break;
          case AxisDirection.left:
            childParentData!.paintOffset = Offset.zero;
            break;
        }
      }
    }

    if (header != null) {
      final SliverPhysicalParentData? headerParentData =
          header!.parentData as SliverPhysicalParentData?;
      final double childScrollExtent = child?.geometry?.scrollExtent ?? 0.0;
      final double headerPosition = sticky
          ? math.min(
          constraints.overlap,
          childScrollExtent -
              constraints.scrollOffset -
              (overlapsContent ? _headerExtent! : 0.0),)
          : -constraints.scrollOffset;

      externalStuckOffset = sticky ? determineStuckOffsetFromExternalController() : 0;
      previousExternalStuckOffset = externalStuckOffset;

      _isPinned = sticky &&
          ((constraints.scrollOffset + constraints.overlap) > 0.0 ||
              externalStuckOffset > 0 ); // || constraints.remainingPaintExtent==constraints.viewportMainAxisExtent

      final double headerScrollRatio =
      ((headerPosition - constraints.overlap).abs() / _headerExtent!);
      if (_isPinned && headerScrollRatio <= 1) {
        controller?.stickyHeaderScrollOffset =
            constraints.precedingScrollExtent;
      }

      // second layout if scroll percentage changed and header is a
      // RenderStickyHeaderLayoutBuilder.
      if (header is RenderConstrainedLayoutBuilder<
          BoxValueConstraints<SliverStickyHeaderState>, RenderBox>) {
        // TODO 2 the state headerScrollRatioClamped won't be correctly updated if the pin is due to external scrollController
        // TODO 2 the state won't be correctly if footer==true
        double headerScrollRatioClamped = headerScrollRatio.clamp(0.0, 1.0);

        SliverStickyHeaderState state =
        SliverStickyHeaderState(headerScrollRatioClamped, _isPinned);
        if (_oldState != state) {
          _oldState = state;
          header!.layout(
            BoxValueConstraints<SliverStickyHeaderState>(
              value: state,
              constraints: constraints.asBoxConstraints(),
            ),
            parentUsesSize: true,
          );
        }
      }
      if (sticky) {
        if (footer) {
          stickAddedOffset = -1.0 * (geometry!.paintExtent + stickOffset - constraints.remainingPaintExtent).clamp(0, stickOffset);
        } else {
          stickAddedOffset = (constraints.scrollOffset + constraints.overlap).clamp(0, stickOffset);
        }
      }
      if (footer) {
        switch (axisDirection) {
          case AxisDirection.up:
            headerParentData!.paintOffset = Offset(0.0, headerPosition + externalStuckOffset + stickAddedOffset);
            break;
          case AxisDirection.down:
            headerParentData!.paintOffset = Offset(
                0.0, geometry!.paintExtent - headerPosition - _headerExtent! + externalStuckOffset + stickAddedOffset,);
            break;
          case AxisDirection.left:
            headerParentData!.paintOffset = Offset(headerPosition + externalStuckOffset + stickAddedOffset, 0.0);
            break;
          case AxisDirection.right:
            headerParentData!.paintOffset = Offset(
                geometry!.paintExtent - headerPosition - _headerExtent! + externalStuckOffset + stickAddedOffset, 0.0,);
            break;
        }
      } else {
        switch (axisDirection) {
          case AxisDirection.up:
            headerParentData!.paintOffset = Offset(
                0.0, geometry!.paintExtent - headerPosition - _headerExtent! + externalStuckOffset + stickAddedOffset,);
            break;
          case AxisDirection.down:
            headerParentData!.paintOffset = Offset(0.0, headerPosition + externalStuckOffset + stickAddedOffset);
            break;
          case AxisDirection.left:
            headerParentData!.paintOffset = Offset(
                geometry!.paintExtent - headerPosition - _headerExtent! + externalStuckOffset + stickAddedOffset, 0.0,);
            break;
          case AxisDirection.right:
            headerParentData!.paintOffset = Offset(headerPosition + externalStuckOffset + stickAddedOffset, 0.0);
            break;
        }
      }
    }
  }
  double get childScrollExtent => child?.geometry?.scrollExtent ?? 0.0;
  double get fullScrollExtent => childScrollExtent + (headerLogicalExtent??0);
  double? previousExternalStuckOffset;
  double externalStuckOffset = 0;
  double stickAddedOffset = 0;
  double determineStuckOffsetFromExternalController() {
    try {
      final scrollPosition = scrollController!.position;

      var previousViewport = RenderAbstractViewport.of(_header);
      RenderObject temp = previousViewport;
      do {
        temp = temp.parent!;
      }  while (temp is! RenderAbstractViewport);
      var targetViewport = temp;
      // TODO 2 this will only work if the external scrollable is the second wrapping the item, need to validate other cases, such as: the scrollController is the first scrollable (do nothing), the scrollController is third or more (continue iterating until finding it)

      final offsetToReveal = targetViewport
          .getOffsetToReveal(previousViewport.parent! as RenderObject, footer ? 1 : 0)
          .offset.clamp(scrollPosition.minScrollExtent, scrollPosition.maxScrollExtent).toDouble();

      double stuckOffset;
      if (footer) {
        stuckOffset = (-(offsetToReveal - scrollPosition.pixels + math.min(stickOffset, scrollPosition.maxScrollExtent)))
            .clamp(-(fullScrollExtent - (_headerExtent??0.0)), 0);
      } else {
        stuckOffset = (scrollPosition.pixels - offsetToReveal + stickOffset)
            .clamp(0.0, fullScrollExtent - (_headerExtent??0.0));
      }
      return stuckOffset;
    } catch(_) {}
    return 0;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition,}) {
    assert(geometry!.hitTestExtent > 0.0);
    final overlap = - constraints.overlap - externalStuckOffset - stickAddedOffset;
    final onHeader = footer
        ? mainAxisPosition + overlap >= (geometry!.paintExtent-_headerExtent!)
        : mainAxisPosition + overlap <= _headerExtent!;
    if (header != null && onHeader) {
      return hitTestBoxChild(
        BoxHitTestResult.wrap(SliverHitTestResult.wrap(result)),
        header!,
        mainAxisPosition: footer
            ? (mainAxisPosition + overlap) - (geometry!.paintExtent-_headerExtent!)
            : mainAxisPosition + overlap,
        crossAxisPosition: crossAxisPosition,
      ) ||
          (_overlapsContent &&
              child != null &&
              child!.geometry!.hitTestExtent > 0.0 &&
              child!.hitTest(result,
                  mainAxisPosition:
                  mainAxisPosition - childMainAxisPosition(child),
                  crossAxisPosition: crossAxisPosition,));
    } else if (child != null && child!.geometry!.hitTestExtent > 0.0) {
      return child!.hitTest(result,
          mainAxisPosition: mainAxisPosition - childMainAxisPosition(child),
          crossAxisPosition: crossAxisPosition,);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderObject? child) {
    if (child == header) {
      return _isPinned
          ? 0.0
          : -(constraints.scrollOffset + constraints.overlap);
    }
    if (child == this.child) {
      return calculatePaintOffset(constraints,
          from: 0.0, to: headerLogicalExtent!,);
    }
    return 0;
  }

  @override
  double? childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    if (child == this.child) {
      return _headerExtent;
    } else {
      return super.childScrollOffset(child);
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final SliverPhysicalParentData childParentData =
    child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (geometry!.visible) {
      if (child != null && child!.geometry!.visible) {
        final SliverPhysicalParentData childParentData =
        child!.parentData! as SliverPhysicalParentData;
        context.paintChild(child!, offset + childParentData.paintOffset);
      }

      // The header must be drawn over the sliver.
      if (header != null) {
        final SliverPhysicalParentData headerParentData =
        header!.parentData! as SliverPhysicalParentData;
        context.paintChild(header!, offset + headerParentData.paintOffset);
      }
    }
  }
}
