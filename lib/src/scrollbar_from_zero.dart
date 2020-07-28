import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'file:///C:/Workspaces/Flutter/from_zero_ui/lib/util/custom_draggable_scrollbar.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';

class ScrollbarFromZero extends StatefulWidget {

  final ScrollController controller;
  final Widget child;
  final double minScrollbarHeight;
  final double scrollbarWidthDesktop;
  final double scrollbarWidthMobile;
  final bool applyPaddingToChildrenOnDesktop;
  final bool applyOpacityGradientToChildren;
//TODO 1 ??? add support for horizontal scroll
//TODO 3 expose options for scrollbarColor and iconColor
//TODO 3 expose an option to consume events (default true)
  ScrollbarFromZero({
    Key key,
    @required this.controller,
    @required this.child,
    this.minScrollbarHeight = 64,
    this.scrollbarWidthDesktop = 16,
    this.scrollbarWidthMobile = 10,
    this.applyPaddingToChildrenOnDesktop = true,
    bool applyOpacityGradientToChildren,
  }) :  assert(child != null),
        this.applyOpacityGradientToChildren = applyOpacityGradientToChildren ?? !applyPaddingToChildrenOnDesktop,
        super(key: key);

  @override
  _ScrollbarFromZeroState createState() =>
      _ScrollbarFromZeroState();

}

class _ScrollbarFromZeroState extends State<ScrollbarFromZero> {

  double height = 0;
  double maxHeight = 0;
  double maxScrollExtent = 0;
  int topFlex = 0;
  bool disposed = false;
  int initialTimestamp;

  @override
  void initState() {
    super.initState();
    if (widget.controller!=null){
//      WidgetsBinding.instance.addPostFrameCallback((_) {
//      _updateMaxScrollExtent();
//    });
      widget.controller.addListener(_onScrollListener);
      if (widget.controller.hasClients)
        widget.controller.position.addListener(_onScrollListener);
      initialTimestamp = DateTime.now().millisecondsSinceEpoch;
    }

  }

  @override
  void dispose() {
    if (widget.controller!=null){
      disposed = true;
      widget.controller.removeListener(_onScrollListener);
    }
    super.dispose();
  }

  void _onScrollListener () {
    _updateMaxScrollExtent();
    if (widget.controller.position.extentAfter>0){
      setState(() {
        topFlex = 100*widget.controller.position.extentBefore ~/ widget.controller.position.maxScrollExtent;
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
      if (widget.controller.position.maxScrollExtent != maxScrollExtent){
        maxScrollExtent = widget.controller.position.maxScrollExtent;
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
      if (doSetState)
        setState(() {
          height = height;
        });
    }
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _updateMaxHeight(constraints, doSetState: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.doWhile(() async{
              _updateMaxScrollExtent(doSetState: true);
              await (Future.delayed(Duration(milliseconds: 100)));
              return !disposed;
            });
          });
          // assumes maxHeight constraint here is the same as inside the scrollable viewport
          // TODO 3 ??? web defaults to desktop mode
          if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)){

            return DraggableScrollbar.rrect(
              alwaysVisibleScrollThumb: false,
              heightScrollThumb: height,
              backgroundColor: Theme.of(context).highlightColor.withOpacity(1.0),
              controller: widget.controller==null||!widget.controller.hasClients ? null : widget.controller,
              child: child,
              scrollbarTimeToFade: Duration(milliseconds: 2500),
              scrollThumbBorderRadius: 0,
              scrollThumbWidth: widget.scrollbarWidthMobile,
              scrollThumbElevation: 4,
            );

          } else{

            return Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: height>0 ? widget.scrollbarWidthDesktop : 0,
                    child: Column(
                      children: [
                        Flexible(
                          flex: topFlex,
                          child: Material(
                            color: Theme.of(context).brightness==Brightness.light ? Colors.grey : Colors.grey.shade900,
                            child: InkWell(
                              child: Container(),
                              onTap: () {
                                double jump = widget.controller.position.pixels - widget.controller.position.extentInside;
                                if (jump < 0) jump = 0;
                                if (kIsWeb){
                                  widget.controller.jumpTo(jump);
                                } else{
                                  widget.controller.animateTo(
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
                                double jump = widget.controller.position.pixels + widget.controller.position.extentInside;
                                if (jump > widget.controller.position.maxScrollExtent) jump = widget.controller.position.maxScrollExtent;
                                if (kIsWeb){
                                  widget.controller.jumpTo(jump);
                                } else{
                                  widget.controller.animateTo(
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
                DraggableScrollbar.rrect(
                  alwaysVisibleScrollThumb: height>0,
                  heightScrollThumb: height,
                  backgroundColor: Theme.of(context).cardColor,
                  controller: widget.controller==null||!widget.controller.hasClients ? null : widget.controller,
                  child: AnimatedPadding(
                    duration: Duration(milliseconds: (DateTime.now().millisecondsSinceEpoch-initialTimestamp-300).clamp(0, 200)),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                        right: widget.applyPaddingToChildrenOnDesktop && height>0
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

          }
        },
      ),
    );
  }

}
