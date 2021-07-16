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
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _onScrollListener();
    });
  }

  @override
  void initState() {
    super.initState();
   WidgetsBinding.instance?.addPostFrameCallback((_) {
     _onScrollListener ();
   });
    addListeners(widget.controller);
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

  void _onScrollListener () {
    if (widget.controller!=null) {
      if (!widget.controller!.hasClients) {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
          await Future.delayed(Duration(milliseconds: 500));
          _onScrollListener();
        });
        // return;
      }
      WidgetsBinding.instance!.scheduleFrame();
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {

    Widget child = widget.child;

    // if (widget.controller==null)
    //   return child;

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

    return Scrollbar(
      controller: widget.controller,
      isAlwaysShown: (widget.controller?.hasClients??false)
          ? (widget.isAlwaysShown ?? Theme.of(context).scrollbarTheme.isAlwaysShown)
          : false,
      notificationPredicate: widget.notificationPredicate ?? (notification) => true,
      radius: widget.radius,
      thickness: widget.thickness,
      hoverThickness: widget.hoverThickness,
      showTrackOnHover: widget.showTrackOnHover,
      child: child,
    );

  }

}
