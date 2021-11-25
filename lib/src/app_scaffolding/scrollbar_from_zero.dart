import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/ui_utility_widgets.dart';
import 'package:from_zero_ui/src/ui_utility/export.dart';


class ScrollbarFromZero extends StatefulWidget {

  final ScrollController? controller;
  final Widget child;
  final ScrollNotificationPredicate? notificationPredicate;
  final Radius? radius;
  final double? thickness;
  final double? hoverThickness;
  final bool? showTrackOnHover;
  final bool? isAlwaysShown;
  final bool? applyOpacityGradientToChildren;
  final int? opacityGradientDirection;
  final double opacityGradientSize;
  final bool ignoreDevicePadding;
  // final bool addPaddingOnDesktop;

  ScrollbarFromZero({
    Key? key,
    this.controller,
    required this.child,
    this.applyOpacityGradientToChildren,
    this.opacityGradientDirection,
    this.opacityGradientSize = 16,
    this.notificationPredicate,
    this.isAlwaysShown,
    this.radius,
    this.thickness,
    this.hoverThickness,
    this.showTrackOnHover,
    this.ignoreDevicePadding = true,
    // this.addPaddingOnDesktop = false,
  }) :  super(key: key);

  @override
  _ScrollbarFromZeroState createState() =>
      _ScrollbarFromZeroState();

}



class _ScrollbarFromZeroState extends State<ScrollbarFromZero> {

  late AlwaysAttachedScrollController alwaysAttachedScrollController;

  @override
  void initState() {
    super.initState();
    alwaysAttachedScrollController = AlwaysAttachedScrollController(parent: widget.controller, context: context);
  }

  @override
  Widget build(BuildContext context) {

    alwaysAttachedScrollController.parent = widget.controller;
    Widget child = widget.child;
    bool wantsAlwaysShown = Theme.of(context).scrollbarTheme.isAlwaysShown ?? PlatformExtended.isDesktop;
    bool supportsAlwaysShown = widget.controller!=null && (widget.controller!.hasClients || alwaysAttachedScrollController.lastPosition!=null);
    if (widget.controller!=null && !supportsAlwaysShown) {
      // Listen until the controller has clients
      final controller = widget.controller!;
      Future.doWhile(() async {
        if (!mounted || widget.controller!=controller) {
          return false;
        }
        if (controller.hasClients) {
          setState(() {});
          return false;
        }
        await Future.delayed(Duration(milliseconds: 200));
        return true;
      });
    }

    if (context.findAncestorWidgetOfExactType<Export>()!=null) {
      return child;
    }

    if (widget.applyOpacityGradientToChildren ?? widget.controller!=null){
      if (widget.controller!=null) {
        child = ScrollOpacityGradient(
          scrollController: alwaysAttachedScrollController,
          child: child,
          direction: widget.opacityGradientDirection ?? (widget.controller!.hasClients
              ? widget.controller!.position.axis==Axis.vertical
                  ? OpacityGradient.vertical
                  : OpacityGradient.horizontal
              : OpacityGradient.vertical),
          maxSize: widget.opacityGradientSize,
        );
      } else {
        child = OpacityGradient(
          child: child,
          direction: widget.opacityGradientDirection ?? OpacityGradient.vertical,
          size: widget.opacityGradientSize,
        );
      }
    }

    Widget result = Scrollbar(
      // controller: supportsAlwaysShown ? widget.controller : null
      controller: widget.controller==null ? null : alwaysAttachedScrollController,
      isAlwaysShown: wantsAlwaysShown && supportsAlwaysShown,
      notificationPredicate: widget.notificationPredicate,
      radius: widget.radius,
      thickness: widget.thickness,
      hoverThickness: widget.hoverThickness,
      showTrackOnHover: widget.showTrackOnHover,
      child: child,
    );
    if (widget.ignoreDevicePadding) {
      result = MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
        child: result,
      );
    }
    return NotificationListener(
      onNotification: (notification) => true,
      child: result,
    );

  }

}








class DummyTickerProvider extends TickerProvider {

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker((time) {});
  }

}

class DummyScrollContext extends ScrollContext {

  BuildContext context;

  DummyScrollContext(this.context);

  @override
  AxisDirection get axisDirection => AxisDirection.down;

  @override
  BuildContext? get notificationContext => null;

  @override
  BuildContext get storageContext => context;

  final _dummyTickerProvider = DummyTickerProvider();
  @override
  TickerProvider get vsync => _dummyTickerProvider;

  @override
  void saveOffset(double offset) {}

  @override
  void setCanDrag(bool value) {}

  @override
  void setIgnorePointer(bool value) {}

  @override
  void setSemanticsActions(Set<SemanticsAction> actions) {}

}

class DummyScrollPosition extends ScrollPositionWithSingleContext {

  DummyScrollPosition(BuildContext context) : super(
    context: DummyScrollContext(context),
    physics: NeverScrollableScrollPhysics(),
  );

}

class AlwaysAttachedScrollController implements ScrollController {

  ScrollController? parent;
  BuildContext context;
  DummyScrollPosition dummyScrollPosition;


  AlwaysAttachedScrollController({
    required this.parent,
    required this.context,
  })  : dummyScrollPosition = DummyScrollPosition(context);

  @override
  bool get hasClients => true;

  ScrollPosition? lastPosition;
  @override
  ScrollPosition get position {
    if (parent==null || parent!.positions.isEmpty) {
      return lastPosition ?? dummyScrollPosition;
    } else {
      lastPosition = parent!.position;
      return parent!.position;
    }
  }

  @override
  Iterable<ScrollPosition> get positions => parent?.positions ?? [];

  @override
  void addListener(VoidCallback listener) {
    parent?.addListener(listener);
  }

  @override
  Future<void> animateTo(double offset, {required Duration duration, required Curve curve}) async {
    return parent?.animateTo(offset, duration: duration, curve: curve);
  }

  @override
  void attach(ScrollPosition position) {
    parent?.attach(position);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    if (parent==null) {
      return DummyScrollPosition(this.context);
    } else {
      return parent!.createScrollPosition(physics, context, oldPosition);
    }
  }

  @override
  void debugFillDescription(List<String> description) {
    parent?.debugFillDescription(description);
  }

  @override
  String? get debugLabel => 'AlwaysAttachedScrollController';

  @override
  void detach(ScrollPosition position) {
    parent?.detach(position);
  }

  @override
  void dispose() {
    parent?.dispose();
  }

  @override
  bool get hasListeners => parent?.hasListeners ?? false;

  @override
  double get initialScrollOffset => parent?.initialScrollOffset ?? 0;

  @override
  void jumpTo(double value) {
    parent?.jumpTo(value);
  }

  @override
  bool get keepScrollOffset => parent?.keepScrollOffset ?? true;

  @override
  void notifyListeners() {
    parent?.notifyListeners();
  }

  @override
  double get offset => parent?.offset ?? 0;


  @override
  void removeListener(VoidCallback listener) {
    parent?.removeListener(listener);
  }

}

