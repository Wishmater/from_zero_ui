import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';
import 'package:from_zero_ui/src/export.dart';


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

  bool built = false;
  bool canBeScrolled = false;
  bool isAlwaysShown = false;
  double maxScrollExtent = 0;
  bool anotherScrollHappened = false;

  @override
  void didUpdateWidget(covariant ScrollbarFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    removeListeners(oldWidget.controller);
    addListeners(widget.controller);
    // built = false;
    _onChildSizeChangeListener();
  }

  @override
  void initState() {
    super.initState();
    addListeners(widget.controller);
    built = false;
    // _onScrollListener();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      listenPeriodically();
    });
  }

  // TODO if a notification could be received on change position.maxScrollExtent, there would be no need to listen periodically
  void listenPeriodically() async {
    while (mounted) {
      _onChildSizeChangeListener();
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

  void _onScrollListener () {
    try { maxScrollExtent = widget.controller!.position.maxScrollExtent; } catch(_){}
  }

  void _onChildSizeChangeListener () async {
    try {
      if (mounted && widget.controller!=null) {
        if (!widget.controller!.hasClients) {
          // await Future.delayed(Duration(milliseconds: 400));
          // _onChildSizeChangeListener();
          return;
        }
        double maxScrollExtent = widget.controller!.position.maxScrollExtent;
        bool canBeScrolled = maxScrollExtent > 0;
        if (!built || canBeScrolled!=this.canBeScrolled) {
          setState(() {
            this.canBeScrolled = canBeScrolled;
          });
        }
        if (!built || canBeScrolled!=this.canBeScrolled || (isAlwaysShown && maxScrollExtent!=this.maxScrollExtent)) {
          widget.controller!.position.didUpdateScrollPositionBy(0);
          anotherScrollHappened = false;
          Future.delayed(Duration(milliseconds: 500)).then((value) {
            if (!isAlwaysShown && !anotherScrollHappened) {
              try { widget.controller!.position.didEndScroll(); } catch(_) {}
            }
          });
        }
        if (!built && widget.moveBackAndForthToForceTriggerScrollbar) {
          final pixels = widget.controller!.position.pixels;
          widget.controller!.jumpTo(pixels+0.1);
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
            try { widget.controller!.jumpTo(pixels); } catch (_) {}
          });
        }
        built = true;
        this.maxScrollExtent = maxScrollExtent;
      }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {

    Widget child = widget.child;

    if (context.findAncestorWidgetOfExactType<Export>()!=null) {
      return child;
    }

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
            width: canBeScrolled ? 12 : 0,
          ),
        ],
      );
    }

    isAlwaysShown = (canBeScrolled && (widget.controller?.hasClients??false))
        ? (widget.isAlwaysShown ?? Theme.of(context).scrollbarTheme.isAlwaysShown ?? PlatformExtended.isDesktop)
        : false;
    // print ("$hashCode $isAlwaysShown");
    return Scrollbar(
      controller: widget.controller,
      isAlwaysShown: isAlwaysShown,
      notificationPredicate: widget.notificationPredicate ?? (notification) => true,
      radius: widget.radius,
      thickness: widget.thickness,
      hoverThickness: widget.hoverThickness,
      showTrackOnHover: widget.showTrackOnHover,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          anotherScrollHappened = true;
          return widget.controller==null;
        },
        child: child,
      ),
    );

  }

}
