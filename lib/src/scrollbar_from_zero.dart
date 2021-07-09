import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/util/custom_draggable_scrollbar.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';

class ScrollbarFromZero extends StatefulWidget {

  final ScrollController? controller;
  final Widget child;
  final double minScrollbarHeight;
  final double scrollbarWidthDesktop;
  final double scrollbarWidthMobile;
  final bool applyPaddingToChildrenOnDesktop;
  final bool applyOpacityGradientToChildren;
  final bool assumeTheScrollBarWillShowOnDesktop;
  final bool useMobileScrollbarOnDesktop;
//TODO 1 ??? add support for horizontal scroll
//TODO 3 expose options for scrollbarColor and iconColor
//TODO 3 expose an option to consume events (default true)
  ScrollbarFromZero({
    Key? key,
    this.controller,
    required this.child,
    this.useMobileScrollbarOnDesktop = false,
    @deprecated this.minScrollbarHeight = 64,
    @deprecated this.scrollbarWidthDesktop = 16,
    @deprecated this.scrollbarWidthMobile = 10,
    @deprecated this.applyPaddingToChildrenOnDesktop = true,
    @deprecated this.assumeTheScrollBarWillShowOnDesktop = false,
    @deprecated bool? applyOpacityGradientToChildren,
  }) :  this.applyOpacityGradientToChildren = applyOpacityGradientToChildren ?? !applyPaddingToChildrenOnDesktop,
        super(key: key);

  @override
  _ScrollbarFromZeroState createState() =>
      _ScrollbarFromZeroState();

}


// class _ScrollbarFromZeroState extends State<ScrollbarFromZero> {

//   @override
//   void initState() {
//     super.initState();
//     widget.controller?.addListener(() {
//       if (mounted) {
//         setState(() {

//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         if (widget.controller==null) {
//           return widget.child;
//         }
//         return NotificationListener<ScrollNotification>(
//           onNotification: (notification) => true,
//           child: Scrollbar(
//             controller: widget.controller,
//             child: widget.child,
//           ),
//         );
//       },
//     );
//   }

// }



class _ScrollbarFromZeroState extends State<ScrollbarFromZero> {

  double height = 0;
  double maxHeight = 0;
  double maxScrollExtent = 0;
  int topFlex = 0;
  bool disposed = false;
  late int initialTimestamp;

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
//    WidgetsBinding.instance?.addPostFrameCallback((_) {
//      _updateMaxScrollExtent();
//    });
    addListeners(widget.controller);
    initialTimestamp = DateTime.now().millisecondsSinceEpoch;
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
    disposed = true;
    removeListeners(widget.controller);
    super.dispose();
  }

  void _onScrollListener () {
    WidgetsBinding.instance!.scheduleFrame();
    _updateMaxScrollExtent();
    if (widget.controller==null) {
      setState(() {});
      return;
    }
    if (!widget.controller!.hasClients) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        _onScrollListener();
      });
      return;
    }
    if (widget.controller!.position.extentAfter>0){
      setState(() {
        topFlex = 100*widget.controller!.position.extentBefore ~/ widget.controller!.position.maxScrollExtent;
      });
    } else{
      setState(() {
        topFlex = 100;
      });
    }
  }

  void _updateMaxScrollExtent({bool doSetState = true}){
//    print(widget.id + " _updateMaxScrollExtent()");
    try {
      if (widget.controller!.position.maxScrollExtent != maxScrollExtent){
        maxScrollExtent = widget.controller!.position.maxScrollExtent;
//        print("     maxScrollExtent = " + maxScrollExtent.toString());
        _updateHeight(doSetState: doSetState);
      }
    } catch(_, __){
      maxScrollExtent = 0;
      maxHeight = 0;
      height = 0;
//      print(widget.id + "     no scroll positions");
    }
  }
  void _updateMaxHeight(BoxConstraints constraints, {bool doSetState = true}){
//    print(widget.id + " _updateMaxHeight()");
    if (maxHeight != constraints.maxHeight){
      maxHeight = constraints.maxHeight;
//      print("     maxHeight = " + maxHeight.toString());
      _updateHeight(doSetState: doSetState);
    }
  }
  void _updateHeight({bool doSetState = true}){
//    print(widget.id + " _updateHeight()");
    if (maxHeight<=0 || maxScrollExtent<=0){
      height = 0;
    } else{
      height = maxHeight * (maxHeight / (maxHeight+maxScrollExtent));
      if (height<widget.minScrollbarHeight) height = widget.minScrollbarHeight;
    }
    if (doSetState)
      setState(() {
        height = height;
      });
//    print("     height = " + height.toString());
  }


  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.controller==null)
      return child;

    if (widget.applyOpacityGradientToChildren){
      child = OpacityGradient(
        child: child,
      );
    }

    if (widget.useMobileScrollbarOnDesktop || PlatformExtended.isMobile){

      return Scrollbar(
        key: ValueKey(widget.controller?.hasClients),
        controller: widget.controller,
        isAlwaysShown: (widget.controller?.hasClients??false) ? null : false,
        notificationPredicate: (notification) => true,
        child: child,
      );

    } else {

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) => true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _updateMaxHeight(constraints, doSetState: false);
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              Future.doWhile(() async{
                _updateMaxScrollExtent(doSetState: true);
                await (Future.delayed(Duration(milliseconds: 100)));
                return !disposed;
              });
            });
            // TODO also implement desktop scrollbar with default scrollbar, that has WAY less bugs
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      width: height>0 ? widget.scrollbarWidthDesktop : 0,
//                    duration: Duration(milliseconds: 300+((DateTime.now().millisecondsSinceEpoch-initialTimestamp-200)*-1).clamp(0, 200)),
//                    curve: Curves.easeInExpo,
                      duration: Duration(milliseconds: (DateTime.now().millisecondsSinceEpoch-initialTimestamp-300).clamp(0, 200)),
                      curve: Curves.easeInCubic,
                      child: Column(
                        children: [
                          Flexible(
                            flex: topFlex,
                            child: Material(
                              color: Theme.of(context).brightness==Brightness.light ? Colors.grey : Colors.grey.shade900,
                              child: InkWell(
                                child: Container(),
                                onTap: () {
                                  double jump = widget.controller!.position.pixels - widget.controller!.position.extentInside;
                                  if (jump < 0) jump = 0;
                                  if (kIsWeb){
                                    widget.controller!.jumpTo(jump);
                                  } else{
                                    widget.controller!.animateTo(
                                      jump,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          Flexible(
                            flex: 100-topFlex,
                            child: Material(
                              color: Theme.of(context).brightness==Brightness.light ? Colors.grey : Colors.grey.shade900,
                              child: InkWell(
                                child: Container(),
                                onTap: () {
                                  double jump = widget.controller!.position.pixels + widget.controller!.position.extentInside;
                                  if (jump > widget.controller!.position.maxScrollExtent) jump = widget.controller!.position.maxScrollExtent;
                                  if (kIsWeb){
                                    widget.controller!.jumpTo(jump);
                                  } else{
                                    widget.controller!.animateTo(
                                      jump,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DraggableScrollbar.rrect(
                  alwaysVisibleScrollThumb: height>0,
                  heightScrollThumb: height,
                  backgroundColor: Theme.of(context).cardColor,
                  controller: widget.controller==null||!widget.controller!.hasClients ? null : widget.controller,
                  child: AnimatedPadding(
//                    duration: Duration(milliseconds: 300+((DateTime.now().millisecondsSinceEpoch-initialTimestamp-200)*-1).clamp(0, 200)),
//                    curve: Curves.easeInExpo,
                    duration: Duration(milliseconds: (DateTime.now().millisecondsSinceEpoch-initialTimestamp-300).clamp(0, 200)),
                    curve: Curves.easeInCubic,
                    padding: EdgeInsets.only(
                        right: widget.applyPaddingToChildrenOnDesktop && (height>0 || widget.assumeTheScrollBarWillShowOnDesktop)
                            ? widget.scrollbarWidthDesktop : 0),
                    child: child,
                  ),
                  scrollbarTimeToFade: Duration(milliseconds: 1),
                  scrollThumbBorderRadius: 999999,
                  scrollThumbWidth: widget.scrollbarWidthDesktop,
                  scrollThumbElevation: 4,
                  showIcons: true,
                ),
              ],
            );
          },
        ),
      );

    }
  }

}
