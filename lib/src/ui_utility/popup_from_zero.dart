import 'dart:math';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/future_handling/future_handling.dart';



Future<T?> showPopupFromZero<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  GlobalKey? anchorKey,
  Offset? referencePosition,
  Size? referenceSize,
  double? width,
  Alignment anchorAlignment = Alignment.topCenter,
  Alignment popupAlignment = Alignment.bottomCenter,
  Color? barrierColor,
  bool barrierDismissible = true,
  // TODO 2 add an option to highlight the anchor (don't paint barrier over it), default true in ContextMenuFromZero
}) async {
  return showDialog<T>(
    context: context,
    barrierColor: barrierColor ?? Colors.black.withOpacity(0.2),
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return PopupFromZero(
        anchorKey: anchorKey,
        referencePosition: referencePosition,
        referenceSize: referenceSize,
        builder: builder,
        width: width,
        anchorAlignment: anchorAlignment,
        popupAlignment: popupAlignment,
      );
    },
  );
}

class PopupFromZero extends StatefulWidget {

  final GlobalKey? anchorKey;
  final Offset? referencePosition;
  final Size? referenceSize;
  final WidgetBuilder builder;
  final double? width;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;

  PopupFromZero({
    Key? key,
    this.anchorKey,
    this.referencePosition,
    this.referenceSize,
    this.width,
    this.anchorAlignment = Alignment.topCenter,
    this.popupAlignment = Alignment.bottomCenter,
    required this.builder,
  }) :  assert(anchorKey!=null || (referencePosition!=null && referenceSize!=null)),
        super(key: key);

  @override
  _PopupFromZeroState createState() => _PopupFromZeroState();
}

class _PopupFromZeroState extends State<PopupFromZero> {

  GlobalKey childGlobalKey = GlobalKey();
  Offset? lastReferencePosition;
  Size? lastReferenceSize;
  Size? lastChildSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback(_checkChildSize);
  }
  void _checkChildSize(timeStamp) { // hack to know when child changes size, since notifications don't work for some reason
    if (!mounted) {
      return;
    }
    try {
      final childSize = (childGlobalKey.currentContext!.findRenderObject()! as RenderBox).size;
      if (childSize != lastChildSize) {
        setState(() {});
      }
    } catch(_) {}
    WidgetsBinding.instance!.addPostFrameCallback(_checkChildSize);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final animation = CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeInOutCubic,
        );
        Offset? referencePosition = lastReferencePosition ?? widget.referencePosition;
        Size? referenceSize = lastReferenceSize ?? widget.referenceSize;
        if (widget.anchorKey != null) {
          try {
            RenderBox box = widget.anchorKey!.currentContext!.findRenderObject()! as RenderBox;
            referencePosition = box.localToGlobal(Offset.zero); //this is global position
            referenceSize = box.size;
          } catch(_) {}
        }
        lastReferencePosition = referencePosition;
        lastReferenceSize = referenceSize;
        double popupWidth = widget.width ?? (referenceSize==null ? 312 : (referenceSize.width+8).clamp(312, double.infinity));
        popupWidth = popupWidth.clamp(0, constraints.maxWidth);
        Size childSize = lastChildSize ?? Size(popupWidth, 0);
        try {
          childSize = (childGlobalKey.currentContext!.findRenderObject()! as RenderBox).size;
          childSize = Size(
            childSize.width.clamp(0, constraints.maxWidth),
            childSize.height.clamp(0, constraints.maxHeight),
          );
          lastChildSize = childSize;
        } catch(_) {
          // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) { // not needed because of hack done every frame, ideally use this + NotificationListener<ScrollMetricsNotification> and remove hack
          //   setState(() {});
          // });
        }
        return AnimatedBuilder(
          animation: animation,
          child: widget.builder(context),
          builder: (context, child) {
            Alignment popupAlignment = widget.popupAlignment;
            double currentChildWidth = popupWidth * animation.value;
            double currentChildHeight = childSize.height * animation.value;
            double x;
            double y;
            if (referencePosition!=null && referenceSize!=null) {
              x = referencePosition.dx
                  + referenceSize.width*((widget.anchorAlignment.x+1)/2)
                  - popupWidth*((widget.popupAlignment.x-1)/-2);
              y = referencePosition.dy
                  + referenceSize.height*((widget.anchorAlignment.y+1)/2)
                  - childSize.height*((widget.popupAlignment.y-1)/-2);
              x = x.clamp(0, constraints.maxWidth);
              y = y.clamp(0, constraints.maxHeight);
              if (constraints.maxWidth-x < popupWidth) {
                x = constraints.maxWidth - popupWidth;
              }
              if (constraints.maxHeight-y < childSize.height) {
                y = constraints.maxHeight - childSize.height;
              }
              double overlappingWidth = Rectangle(referencePosition.dx, 0, referenceSize.width, 1)
                  .intersection(Rectangle(x, 0, popupWidth, 1))?.width.toDouble() ?? 0;
              double overlappingHeight = Rectangle(0, referencePosition.dy, 1, referenceSize.height)
                  .intersection(Rectangle(0, y, 1, childSize.height))?.height.toDouble() ?? 0;
              currentChildWidth = overlappingWidth + ((popupWidth-overlappingWidth) * animation.value);
              currentChildHeight = overlappingHeight + ((childSize.height-overlappingHeight) * animation.value);
              if (overlappingWidth >= referenceSize.width) {
                x = referencePosition.dx - ((currentChildWidth-referenceSize.width) * ((widget.popupAlignment.x-1)/-2));
              } else if (referencePosition.dx < x) {
                x = referencePosition.dx + referenceSize.width - overlappingWidth;
              } else {
                x = referencePosition.dx - ((currentChildWidth-overlappingWidth) * ((popupAlignment.x-1)/-2));
              }
              if (overlappingHeight >= referenceSize.height) {
                y = referencePosition.dy - ((currentChildHeight-overlappingHeight) * ((popupAlignment.y-1)/-2));
              } else if (referencePosition.dy < y) {
                y = referencePosition.dy + referenceSize.height - overlappingHeight;
              } else {
                y = referencePosition.dy - ((currentChildHeight-overlappingHeight) * ((popupAlignment.y-1)/-2));
              }
              x = x.clamp(0, constraints.maxWidth);
              y = y.clamp(0, constraints.maxHeight);
              if (constraints.maxWidth-x < currentChildWidth) {
                x = constraints.maxWidth - currentChildWidth;
              }
              if (constraints.maxHeight-y < currentChildHeight) {
                y = constraints.maxHeight - currentChildHeight;
              }
            } else {
              x = constraints.maxWidth/2-currentChildWidth/2;
              y = constraints.maxHeight/2-currentChildHeight/2;
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPositioned(
                  duration: animation.isCompleted
                      ? Duration(milliseconds: 250)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: x, top: y,
                  width: currentChildWidth,
                  height: currentChildHeight,
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: OverflowBox(
                      alignment: animation.isCompleted
                          ? Alignment.topCenter
                          : popupAlignment,
                      minWidth: popupWidth,
                      maxWidth: popupWidth,
                      minHeight: 0,
                      maxHeight: MediaQuery.of(context).size.height,
                      child: Container(
                        key: childGlobalKey,
                        child: child!,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}











// not used anymore
class RectPercentageClipper extends CustomClipper<Rect> {

  double heightPercent;
  double widthPercent;

  RectPercentageClipper({
    this.heightPercent = 1,
    this.widthPercent = 1,
  });

  @override
  getClip(Size size) {
    return Rect.fromLTWH(0, 0,
      size.width * widthPercent,
      size.height * heightPercent,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }

}