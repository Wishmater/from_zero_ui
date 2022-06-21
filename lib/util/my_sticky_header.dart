// Copyright 2018 Simon Lightfoot. All rights reserved.
// Use of this source code is governed by a the MIT license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' show min, max;

/// Builder called during layout to allow the header's content to be animated or styled based
/// on the amount of stickyness the header has.
///
/// [context] for your build operation.
///
/// [stuckAmount] will have the value of:
/// ```
///   0.0 <= value <= 1.0: about to be stuck
///          0.0 == value: at top
///  -1.0 >= value >= 0.0: past stuck
/// ```
///
typedef Widget StickyHeaderWidgetBuilder(BuildContext context, double stuckAmount);

/// Stick Header Widget
///
/// Will layout the [header] above the [content] unless the [overlapHeaders] boolean is set to true.
/// The [header] will remain stuck to the top of its parent [Scrollable] content.
///
/// Place this widget inside a [ListView], [GridView], [CustomScrollView], [SingleChildScrollView] or similar.
///
class StickyHeader extends MultiChildRenderObjectWidget {
  /// Constructs a new [StickyHeader] widget.
  StickyHeader({
    Key? key,
    required this.header,
    required this.content,
    this.overlapHeaders: false,
    this.controller,
    this.callback,
    this.stickOffset = 0,
    this.footer = false,
  }) : super(
    key: key,
    // Note: The order of the children must be preserved for the RenderObject.
    children: [content, header],
  );

  final double stickOffset;

  /// Header to be shown at the top of the parent [Scrollable] content.
  final Widget header;

  /// Content to be shown below the header.
  final Widget content;

  /// If true, the header will overlap the Content.
  final bool overlapHeaders;

  /// Optional [ScrollController] that will be used by the widget instead of the default inherited one.
  final ScrollController? controller;

  /// Optional callback with stickyness value. If you think you need this, then you might want to
  /// consider using [StickyHeaderBuilder] instead.
  final RenderStickyHeaderCallback? callback;

  final bool footer;

  @override
  RenderStickyHeader createRenderObject(BuildContext context) {
//    final scrollPosition = this.controller?.position ?? Scrollable.of(context).position;
//    assert(scrollPosition != null);
    return RenderStickyHeader(
      scrollController: controller,
      scrollPosition: controller!=null ? null : Scrollable.of(context)?.position,
      callback: this.callback,
      overlapHeaders: this.overlapHeaders,
      stickOffset: stickOffset,
      footer: footer,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStickyHeader renderObject) {
//    final scrollPosition = this.controller?.position ?? Scrollable.of(context).position;
//    assert(scrollPosition != null);
    renderObject
      ..scrollController = controller
      ..scrollPosition = controller!=null ? null : Scrollable.of(context)?.position
      ..callback = this.callback
      ..overlapHeaders = this.overlapHeaders
      ..stickOffset = this.stickOffset;
  }
}

/// Sticky Header Builder Widget.
///
/// The same as [StickyHeader] but instead of supplying a Header view, you supply a [builder] that
/// constructs the header with the appropriate stickyness.
///
/// Place this widget inside a [ListView], [GridView], [CustomScrollView], [SingleChildScrollView] or similar.
///
class StickyHeaderBuilder extends StatefulWidget {
  /// Constructs a new [StickyHeaderBuilder] widget.
  const StickyHeaderBuilder({
    Key? key,
    required this.builder,
    required this.content,
    this.overlapHeaders: false,
    this.controller,
    this.stickOffset = 0,
    this.footer = false,
  }) : super(key: key);

  final double stickOffset;

  /// Called when the sticky amount changes for the header.
  /// This builder must not return null.
  final StickyHeaderWidgetBuilder builder;

  /// Content to be shown below the header.
  final Widget content;

  /// If true, the header will overlap the Content.
  final bool overlapHeaders;

  /// Optional [ScrollController] that will be used by the widget instead of the default inherited one.
  final ScrollController? controller;

  final bool footer;

  @override
  _StickyHeaderBuilderState createState() => _StickyHeaderBuilderState();
}

class _StickyHeaderBuilderState extends State<StickyHeaderBuilder> {
  double? _stuckAmount;

  @override
  Widget build(BuildContext context) {
    return StickyHeader(
      overlapHeaders: widget.overlapHeaders,
      stickOffset: widget.stickOffset,
      header: LayoutBuilder(
        builder: (context, _) => widget.builder(context, _stuckAmount ?? 0.0),
      ),
      content: widget.content,
      controller: widget.controller,
      footer: widget.footer,
      callback: (double stuckAmount) {
        if (_stuckAmount != stuckAmount) {
          _stuckAmount = stuckAmount;
          WidgetsBinding.instance.endOfFrame.then((_) {
            if(mounted){
              setState(() {});
            }
          });
        }
      },
    );
  }
}




/// Called every layout to provide the amount of stickyness a header is in.
/// This lets the widgets animate their content and provide feedback.
///
typedef void RenderStickyHeaderCallback(double stuckAmount);

/// RenderObject for StickyHeader widget.
///
/// Monitors given [Scrollable] and adjusts its layout based on its offset to
/// the scrollable's [RenderObject]. The header will be placed above content
/// unless overlapHeaders is set to true. The supplied callback will be used
/// to report the
///
class RenderStickyHeader extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {

  RenderStickyHeaderCallback? _callback;
  ScrollPosition? _scrollPosition;
  ScrollController? _scrollController;
  bool _overlapHeaders;
  double stickOffset;
  bool footer;

  RenderStickyHeader({
    ScrollPosition? scrollPosition,
    ScrollController? scrollController,
    RenderStickyHeaderCallback? callback,
    bool overlapHeaders: false,
    RenderBox? header,
    RenderBox? content,
    this.stickOffset = 0,
    this.footer = false,
  })  : _scrollPosition = scrollPosition,
        _scrollController = scrollController,
        _callback = callback,
        _overlapHeaders = overlapHeaders {
    if (content != null) add(content);
    if (header != null) add(header);
  }

  ScrollPosition? get scrollPosition => _scrollController?.position ?? _scrollPosition;

  set scrollPosition(ScrollPosition? newValue) {
    if (_scrollPosition == newValue) {
      return;
    }
    final ScrollPosition? oldValue = _scrollPosition;
    _scrollPosition = newValue;
    markNeedsLayout();
    if (attached) {
      oldValue?.removeListener(markNeedsLayout);
      newValue?.addListener(markNeedsLayout);
    }
  }
  set scrollController(ScrollController? newValue){
    if (_scrollController == newValue) {
      return;
    }
    final ScrollController? oldValue = _scrollController;
    _scrollController = newValue;
    markNeedsLayout();
    if (attached) {
      oldValue?.removeListener(markNeedsLayout);
      newValue?.addListener(markNeedsLayout);
    }
  }
  
  set callback(RenderStickyHeaderCallback? newValue) {
    if (_callback == newValue) {
      return;
    }
    _callback = newValue;
    markNeedsLayout();
  }

  set overlapHeaders(bool newValue) {
    if (_overlapHeaders == newValue) {
      return;
    }
    _overlapHeaders = newValue;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_scrollController!=null){
      _scrollController?.addListener(markNeedsLayout);
    } else{
      scrollPosition?.addListener(markNeedsLayout);
    }
  }

  @override
  void detach() {
    if (_scrollController!=null){
      _scrollController?.removeListener(markNeedsLayout);
    } else{
      scrollPosition?.removeListener(markNeedsLayout);
    }
    super.detach();
  }

  // short-hand to access the child RenderObjects
  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  @override
  void performLayout() {
    // ensure we have header and content boxes
    assert(childCount == 2);

    // layout both header and content widget
    final childConstraints = constraints.loosen();
    _headerBox.layout(childConstraints, parentUsesSize: true);
    _contentBox.layout(childConstraints, parentUsesSize: true);

    final headerHeight = _headerBox.size.height;
    final contentHeight = _contentBox.size.height;

    // determine size of ourselves based on content widget
    final width = max(constraints.minWidth, _contentBox.size.width);
    final height = max(constraints.minHeight,
        _overlapHeaders ? contentHeight : headerHeight + contentHeight);
    size = Size(width, height);
    assert(size.width == constraints.constrainWidth(width));
    assert(size.height == constraints.constrainHeight(height));
    assert(size.isFinite);

    // place content underneath header
    final contentParentData = _contentBox.parentData as MultiChildLayoutParentData;
    contentParentData.offset = Offset(0.0, _overlapHeaders ? 0.0 : headerHeight);

    // determine by how much the header should be stuck to the top
    final double stuckOffset = determineStuckOffset();

    // place header over content relative to scroll offset
    final double maxOffset = height - headerHeight;
    final headerParentData = _headerBox.parentData as MultiChildLayoutParentData;
    headerParentData.offset = Offset(0.0, max(0.0, min(-stuckOffset, maxOffset)));

    // report to widget how much the header is stuck.
    if (_callback != null) {
      final stuckAmount = max(min(headerHeight, stuckOffset), -headerHeight) / headerHeight;
      _callback?.call(stuckAmount);
    }
  }

//  bool initial = true;
  double determineStuckOffset() {
//    if (initial){
//      initial = false;
//      return 0;
//    }
    try {
      final scrollBox = scrollPosition!.context.notificationContext?.findRenderObject();
      if (scrollBox?.attached ?? false) {
        final stickOffset = footer ? this.stickOffset : -this.stickOffset;
        double result = localToGlobal(Offset(0, stickOffset,), ancestor: scrollBox).dy;
        if (footer) {
          result -= scrollPosition!.viewportDimension;
          result += _headerBox.size.height;
        }
        return result;
      }
    } catch(e) {
      // ignore and fall-through and return 0.0
    }
    return 0.0;
  }

  @override
  void setupParentData(RenderObject child) {
    super.setupParentData(child);
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _contentBox.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _contentBox.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _overlapHeaders ? _contentBox.getMinIntrinsicHeight(width)
        : (_headerBox.getMinIntrinsicHeight(width) +
        _contentBox.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _overlapHeaders ? _contentBox.getMaxIntrinsicHeight(width)
        : (_headerBox.getMaxIntrinsicHeight(width) +
        _contentBox.getMaxIntrinsicHeight(width));
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline)!;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}