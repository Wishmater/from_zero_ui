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
    _onScrollListener ();
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
  void _onScrollListener () async {
    await Future.delayed(Duration(milliseconds: 400));
    if (built) return;
    if (widget.controller!=null) {
      if (!widget.controller!.hasClients) {
        _onScrollListener();
        return;
      }
      if (mounted) {
        built = true;
        if (widget.moveBackAndForthToForceTriggerScrollbar) {
          final pixels = widget.controller!.position.pixels;
          widget.controller!.jumpTo(pixels+1);
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
            widget.controller!.jumpTo(pixels);
          });
        }
        setState(() {});
      }
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
    // print (toString() + ' - ' + built.toString());

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
