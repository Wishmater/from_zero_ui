import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


/// extends default scroll controller by notifying listeners in extra cases
/// for example, on attach/detach scroll position. This means it is slightly
/// less porformant, but solves a number of edge case bugs
class ScrollControllerFromZero extends ScrollController {

  ScrollControllerFromZero({
    super.initialScrollOffset = 0.0,
    super.keepScrollOffset = true,
    super.debugLabel,
  });

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  @override
  void detach(ScrollPosition position) {
    super.detach(position);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

}


class ScrollbarFromZero extends StatefulWidget {

  final ScrollController? controller;
  final Widget child;
  final ScrollNotificationPredicate? notificationPredicate;
  final bool? isAlwaysShown;
  final bool? applyOpacityGradientToChildren;
  final int? opacityGradientDirection;
  final double opacityGradientSize;
  final bool ignoreDevicePadding;
  // final bool addPaddingOnDesktop;
  /// is main window scaffold scrollbar
  final bool mainScrollbar;

  const ScrollbarFromZero({
    required this.child,
    this.controller,
    this.applyOpacityGradientToChildren,
    this.opacityGradientDirection,
    this.opacityGradientSize = 16,
    this.notificationPredicate,
    this.isAlwaysShown,
    this.ignoreDevicePadding = true,
    this.mainScrollbar = false,
    // this.addPaddingOnDesktop = false,
    super.key,
  });

  @override
  ScrollbarFromZeroState createState() => ScrollbarFromZeroState();

}

class ScrollbarFromZeroState extends State<ScrollbarFromZero> {

  late AlwaysAttachedScrollController alwaysAttachedScrollController;

  @override
  void initState() {
    super.initState();
    alwaysAttachedScrollController = AlwaysAttachedScrollController(parent: widget.controller, context: context);
  }

  @override
  void didUpdateWidget(covariant ScrollbarFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller!=widget.controller) {
      alwaysAttachedScrollController.parent = widget.controller;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _listenToControllerAttached(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted || widget.controller!=controller) {
        return;
      }
      if (controller.hasClients) {
        setState(() {});
        return;
      }
      _listenToControllerAttached(controller);
    });
  }

  @override
  Widget build(BuildContext context) {

    if (widget.controller==null) {
      return widget.child;
    }

    Widget child = widget.child;
    bool wantsAlwaysShown = Theme.of(context).scrollbarTheme.thumbVisibility?.resolve({}) ?? PlatformExtended.isDesktop;
    bool supportsAlwaysShown = widget.controller!=null && (widget.controller!.hasClients || alwaysAttachedScrollController.lastPosition!=null);
    if (widget.controller!=null && wantsAlwaysShown && !supportsAlwaysShown) {
      // Listen until the controller has clients
      _listenToControllerAttached(widget.controller!);
    }

    if (widget.applyOpacityGradientToChildren ?? widget.controller!=null){
      if (widget.controller!=null) {
        child = ScrollOpacityGradient(
          scrollController: alwaysAttachedScrollController,
          direction: widget.opacityGradientDirection ?? (widget.controller!.hasClients
              ? widget.controller!.position.axis==Axis.vertical
                  ? OpacityGradient.vertical
                  : OpacityGradient.horizontal
              : OpacityGradient.vertical),
          maxSize: widget.opacityGradientSize,
          child: child,
        );
      } else {
        child = OpacityGradient(
          direction: widget.opacityGradientDirection ?? OpacityGradient.vertical,
          size: widget.opacityGradientSize,
          child: child,
        );
      }
    }


    Widget result;
    if (widget.mainScrollbar) {

      final theme = Theme.of(context);
      result = Theme(
        key: ValueKey(PlatformExtended.appWindow?.isMaximized ?? true),
        data: theme.copyWith(
          scrollbarTheme: theme.scrollbarTheme.copyWith(
            crossAxisMargin: PlatformExtended.appWindow?.isMaximized ?? true
                ? theme.scrollbarTheme.crossAxisMargin
                : theme.scrollbarTheme.crossAxisMargin?.clamp(6, double.infinity),
          ),
        ),
        child: buildScrollbar(
          context: context,
          child: Theme(
            data: theme,
            child: child,
          ),
        ),
      );
      if (widget.ignoreDevicePadding) {
        result = MediaQuery.removePadding(
          context: context,
          child: result,
        );
      }

    } else {

      result = buildScrollbar(
        context: context,
        child: child,
      );

    }

    return NotificationListener(
      onNotification: (notification) {
        if (notification is ScrollMetricsNotification) {
          widget.controller?.notifyListeners();
          return true;
        }
        return notification is ScrollNotification;
      },
      child: result,
    );

  }

  Widget buildScrollbar({
    required BuildContext context,
    required Widget child,
    Key? key,
  }) {
    return Scrollbar(
      key: key,
      controller: widget.controller==null ? null : alwaysAttachedScrollController,
      notificationPredicate: widget.notificationPredicate,
      child: child,
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

  @override
  double get devicePixelRatio => 1;

}

class DummyScrollPosition extends ScrollPositionWithSingleContext {

  DummyScrollPosition(BuildContext context) : super(
    context: DummyScrollContext(context),
    physics: const NeverScrollableScrollPhysics(),
  );

}

class AlwaysAttachedScrollController implements ScrollController {

  BuildContext context;
  ScrollController? parent;
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
      lastPosition = parent!.positions.first;
      return parent!.positions.first;
    }
  }

  @override
  Iterable<ScrollPosition> get positions => parent==null ? []
      : parent!.positions.isEmpty ? [] : [parent!.positions.first];

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
    // TODO 1 on attach/detach, a ScrollMetricsNotification.empty should be dispatched to potentially notify the scrollbar that no positions are attached
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
    // TODO 1 on attach/detach, a ScrollMetricsNotification.empty should be dispatched to potentially notify the scrollbar that no positions are attached
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

  @override
  ScrollControllerCallback? get onAttach => parent?.onAttach;

  @override
  ScrollControllerCallback? get onDetach => parent?.onDetach;

}

