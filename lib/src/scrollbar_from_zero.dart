import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';


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
  final bool moveBackAndForthToForceTriggerScrollbar;
  final bool addPaddingOnDesktop;

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
    this.moveBackAndForthToForceTriggerScrollbar = false,
    this.addPaddingOnDesktop = false,
  }) :  super(key: key);

  @override
  _ScrollbarFromZeroState createState() =>
      _ScrollbarFromZeroState();

}



class _ScrollbarFromZeroState extends State<ScrollbarFromZero> {

  @override
  void didUpdateWidget(covariant ScrollbarFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    removeListeners(oldWidget.controller);
    addListeners(widget.controller);
    built = false;
    _onScrollListener();
  }

  @override
  void initState() {
    super.initState();
    addListeners(widget.controller);
    built = false;
    _onScrollListener();
    listenPeriodically();
  }

  // TODO if a notification could be received on change position.maxScrollExtent, there would be no need to listen periodically
  void listenPeriodically() async {
    while (mounted) {
      if (built) {
        _onScrollListener();
      }
      await Future.delayed(Duration(milliseconds: 1000));
    }
  }

  void addListeners(ScrollController? controller){
    controller?.addListener(_onScrollListener);
    if (controller?.hasClients ?? false)
      controller?.position.addListener(_onScrollListener);
  }

  void removeListeners(ScrollController? controller) {
    controller?.removeListener(_onScrollListener);
  }

  @override
  void dispose() {
    removeListeners(widget.controller);
    super.dispose();
  }

  bool built = false;
  bool showing = false;
  double maxScrollExtent = 0;
  void _onScrollListener () async {
    await Future.delayed(Duration(milliseconds: 400));
    if (mounted && widget.controller!=null) {
      if (!widget.controller!.hasClients) {
        _onScrollListener();
        return;
      }
      double maxScrollExtent = widget.controller!.position.maxScrollExtent;
      bool showing = maxScrollExtent > 0;
      if (!built || maxScrollExtent!=this.maxScrollExtent) {
        widget.controller!.position.didUpdateScrollPositionBy(0);
      }
      if (!built || showing!=this.showing) {
        setState(() {});
      }
      if (!built && widget.moveBackAndForthToForceTriggerScrollbar) {
        final pixels = widget.controller!.position.pixels;
        widget.controller!.jumpTo(pixels+0.1);
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          widget.controller!.jumpTo(pixels);
        });
      }
      built = true;
      this.maxScrollExtent = maxScrollExtent;
      this.showing = showing;
    }
  }


  @override
  Widget build(BuildContext context) {

    Widget child = widget.child;

    if (widget.applyOpacityGradientToChildren ?? widget.controller!=null){
      if (widget.controller!=null) {
        child = ScrollOpacityGradient(
          scrollController: widget.controller!,
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

    if (widget.addPaddingOnDesktop) {
      //TODO implement add padding on desktop functionality
      // allow to set background color
      // find a way to reduce the scrollbar gesture detector size
      child = Row(
        children: [
          Expanded(child: child,),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: showing ? 12 : 0,
          ),
        ],
      );
    }

    return Scrollbar(
      controller: widget.controller,
      isAlwaysShown: (showing && (widget.controller?.hasClients??false))
          ? (widget.isAlwaysShown ?? Theme.of(context).scrollbarTheme.isAlwaysShown)
          : false,
      notificationPredicate: widget.notificationPredicate ?? (notification) => true,
      radius: widget.radius,
      thickness: widget.thickness,
      hoverThickness: widget.hoverThickness,
      showTrackOnHover: widget.showTrackOnHover,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => widget.controller==null,
        child: child,
      ),
    );

  }

}
