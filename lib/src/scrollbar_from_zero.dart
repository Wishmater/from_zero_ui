import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/custom_draggable_scrollbar.dart';

class ScrollbarFromZero extends StatefulWidget {

  final ScrollController controller;
  final Widget child;
  final double minScrollbarHeight;

  ScrollbarFromZero({
    Key key,
    @required this.controller,
    @required this.child,
    this.minScrollbarHeight = 64,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      _updateMaxScrollExtent();
//    });
    widget.controller.addListener(_onScrollListener);
    if (widget.controller.hasClients)
      widget.controller.position.addListener(_onScrollListener);
  }

  @override
  void dispose() {
    disposed = true;
    widget.controller.removeListener(_onScrollListener);
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
    return LayoutBuilder(
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
        if (height <= 0){

          if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)){
            return DraggableScrollbar.rrect(
              alwaysVisibleScrollThumb: false,
              heightScrollThumb: height,
              backgroundColor: Theme.of(context).accentColor,
              controller: widget.controller,
              child: widget.child,
              scrollbarTimeToFade: Duration(seconds: 1),
              scrollThumbBorderRadius: 0,
              scrollThumbWidth: 6,
              scrollThumbElevation: 2,
            );
          } else{
            return(Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(),
                ),
                DraggableScrollbar.rrect(
                  alwaysVisibleScrollThumb: false,
                  heightScrollThumb: height,
                  backgroundColor: Theme.of(context).cardColor,
                  controller: widget.controller,
                  child: AnimatedPadding(
                    duration: Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.only(right: 0),
                    child: widget.child,
                  ),
                  scrollbarTimeToFade: Duration(seconds: 1),
                  scrollThumbBorderRadius: 4,
                  scrollThumbWidth: 12,
                  scrollThumbElevation: 2,
                  showIcons: true,
                ),
              ],
            ));
          }

        } else{

          // TODO 3 ??? web defaults to desktop mode
          if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)){

            return DraggableScrollbar.rrect(
              alwaysVisibleScrollThumb: false,
              heightScrollThumb: height,
              backgroundColor: Theme.of(context).accentColor,
              controller: widget.controller,
              child: widget.child,
              scrollbarTimeToFade: Duration(seconds: 1),
              scrollThumbBorderRadius: 0,
              scrollThumbWidth: 6,
              scrollThumbElevation: 2,
            );

          } else{

            return Stack( //TODO 2 add padding right to children only on dektop mode
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 14,
                    child: Column(
                      children: [
                        Flexible(
                          flex: topFlex,
                          child: Material(
                            color: Colors.grey,
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
                            color: Colors.grey, //TODO 1 support dark mode
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
                  alwaysVisibleScrollThumb: true,
                  heightScrollThumb: height,
                  backgroundColor: Theme.of(context).cardColor,
                  controller: widget.controller,
                  child: AnimatedPadding(
                    duration: Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.only(right: 13),
                    child: widget.child,
                  ),
                  scrollbarTimeToFade: Duration(seconds: 1),
                  scrollThumbBorderRadius: 4,
                  scrollThumbWidth: 12,
                  scrollThumbElevation: 2,
                  showIcons: true,
                ),
              ],
            );

          }

        }
      },
    );
  }

}
