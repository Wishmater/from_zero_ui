import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';



Future<T?> showPopupFromZero<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  GlobalKey? anchorKey,
  Offset? referencePosition,
  Size? referenceSize,
  EdgeInsets? padding,
  double? width,
  Alignment anchorAlignment = Alignment.topCenter,
  Alignment popupAlignment = Alignment.bottomCenter,
  Offset offsetCorrection = Offset.zero,
  Color? barrierColor,
  bool barrierDismissible = true,
  // TODO 2 add an option to highlight the anchor (don't paint barrier over it), default true in ContextMenuFromZero
}) async {
  return showDialog<T>(
    context: context,
    barrierColor: barrierColor ?? Colors.black.withOpacity(0.2),
    barrierDismissible: barrierDismissible,
    useSafeArea: false,
    builder: (context) {
      return PopupFromZero(
        anchorKey: anchorKey,
        referencePosition: referencePosition,
        referenceSize: referenceSize,
        padding: padding,
        builder: builder,
        width: width,
        anchorAlignment: anchorAlignment,
        popupAlignment: popupAlignment,
        offsetCorrection: offsetCorrection,
      );
    },
  );
}

class PopupFromZero extends StatefulWidget {

  final GlobalKey? anchorKey;
  final Offset? referencePosition;
  final Size? referenceSize;
  final EdgeInsets? padding;
  final WidgetBuilder builder;
  final double? width;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;
  final Offset offsetCorrection;

  const PopupFromZero({
    required this.builder,
    this.anchorKey,
    this.referencePosition,
    this.referenceSize,
    this.padding,
    this.width,
    this.anchorAlignment = Alignment.topCenter,
    this.popupAlignment = Alignment.bottomCenter,
    this.offsetCorrection = Offset.zero,
    super.key,
  }) :  assert(anchorKey!=null || (referencePosition!=null && referenceSize!=null));

  @override
  PopupFromZeroState createState() => PopupFromZeroState();

}

class PopupFromZeroState extends State<PopupFromZero> {

  GlobalKey childGlobalKey = GlobalKey();
  Offset? lastReferencePosition;
  Size? lastReferenceSize;
  Size? lastChildSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_checkChildSize);
  }
  void _checkChildSize(timeStamp) { // TODO 1 performance hack to know when child changes size, since notifications don't work for some reason. Test the same method used in AnimatedFromChildSize, it could also work here
    if (!mounted) {
      return;
    }
    try {
      final childSize = (childGlobalKey.currentContext!.findRenderObject()! as RenderBox).size;
      if (childSize != lastChildSize) {
        setState(() {});
      }
    } catch(_) {}
    WidgetsBinding.instance.addPostFrameCallback(_checkChildSize);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQueryPadding = MediaQuery.viewPaddingOf(context) + MediaQuery.viewInsetsOf(context); // viewPadding has the permanent padding (notch), viewInsets has the keyboard inset
    return LayoutBuilder(
      builder: (context, constraints) {
        final mqMaxWidth = constraints.maxWidth - mediaQueryPadding.horizontal;
        final mqMaxHeight = constraints.maxHeight - mediaQueryPadding.vertical;
        final extraPadding = widget.padding ?? EdgeInsets.symmetric(
          horizontal: mqMaxWidth>ScaffoldFromZero.screenSizeLarge ? 24 : mqMaxWidth>ScaffoldFromZero.screenSizeMedium ? 16 : 0,
          vertical: mqMaxHeight>ScaffoldFromZero.screenSizeLarge ? 24 : mqMaxHeight>ScaffoldFromZero.screenSizeMedium ? 16 : 0,
        );
        final padding = mediaQueryPadding + extraPadding;
        final maxWidth = constraints.maxWidth - padding.horizontal;
        final maxWidthWithPaddingLeft = maxWidth + padding.left;
        final maxHeight = constraints.maxHeight - padding.vertical;
        final maxHeightWithPaddingTop = maxHeight + padding.top;
        final animation = CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeInOutCubic,
        );
        Offset? referencePosition = lastReferencePosition ?? widget.referencePosition;
        Size? referenceSize = lastReferenceSize ?? widget.referenceSize;
        if (widget.anchorKey != null) {
          try {
            RenderBox box = widget.anchorKey!.currentContext!.findRenderObject()! as RenderBox;
            referencePosition = box.localToGlobal(Offset.zero,
              ancestor: widget.anchorKey!.currentContext!.findAncestorStateOfType<SnackBarHostFromZeroState>()?.context.findRenderObject(), // hack to support UI scale
            ); //this is global position
            referenceSize = box.size;
          } catch(_) {}
        }
        lastReferencePosition = referencePosition;
        lastReferenceSize = referenceSize;
        double popupWidth = widget.width ?? (referenceSize==null ? 312 : (referenceSize.width+8).clamp(312, double.infinity));
        popupWidth = popupWidth.clamp(0, maxWidth);
        Size childSize = lastChildSize ?? Size(popupWidth, 0);
        try {
          childSize = (childGlobalKey.currentContext!.findRenderObject()! as RenderBox).size;
          childSize = Size(
            childSize.width.clamp(0, maxWidth),
            childSize.height.clamp(0, maxHeight),
          );
          lastChildSize = childSize;
        } catch(_) {
          // WidgetsBinding.instance.addPostFrameCallback((timeStamp) { // not needed because of hack done every frame, ideally use this + NotificationListener<ScrollMetricsNotification> and remove hack
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
                  - popupWidth*((widget.popupAlignment.x-1)/-2)
                  + widget.offsetCorrection.dx;
              y = referencePosition.dy
                  + referenceSize.height*((widget.anchorAlignment.y+1)/2)
                  - childSize.height*((widget.popupAlignment.y-1)/-2)
                  + widget.offsetCorrection.dy;
              x = x.clamp(padding.left, maxWidthWithPaddingLeft);
              y = y.clamp(padding.top, maxHeightWithPaddingTop);
              if (maxWidth-x < popupWidth) {
                x = maxWidthWithPaddingLeft - popupWidth;
              }
              if (maxHeight-y < childSize.height) {
                y = maxHeightWithPaddingTop - childSize.height;
              }
              final overlappingWidth = Rectangle(referencePosition.dx, 0, referenceSize.width, 1)
                  .intersection(Rectangle(x, 0, popupWidth, 1))?.width.toDouble() ?? 0;
              final overlappingHeight = Rectangle(0, referencePosition.dy, 1, referenceSize.height)
                  .intersection(Rectangle(0, y, 1, childSize.height))?.height.toDouble() ?? 0;
              currentChildWidth = overlappingWidth + ((popupWidth-overlappingWidth) * animation.value);
              currentChildHeight = overlappingHeight + ((childSize.height-overlappingHeight) * animation.value);
              final overlappingCorrectionX = (x < referencePosition.dx  // add offsetCorrection only if not already accounted for in overlappingMeassure
                  ? x - referencePosition.dx
                  : x - (referencePosition.dx + referenceSize.width)).smartClamp(0, widget.offsetCorrection.dx);
              final overlappingCorrectionY = (y < referencePosition.dy  // add offsetCorrection only if not already accounted for in overlappingMeassure
                  ? y - referencePosition.dy
                  : y - (referencePosition.dy + referenceSize.height)).smartClamp(0, widget.offsetCorrection.dy);
              if (overlappingWidth >= referenceSize.width) {
                x = referencePosition.dx - ((currentChildWidth-referenceSize.width) * ((widget.popupAlignment.x-1)/-2));
              } else if (referencePosition.dx < x) {
                x = referencePosition.dx + referenceSize.width - overlappingWidth;
              } else {
                x = referencePosition.dx - ((currentChildWidth-overlappingWidth) * ((popupAlignment.x-1)/-2));
              }
              if (overlappingHeight >= referenceSize.height) {
                y = referencePosition.dy - ((currentChildHeight-referenceSize.height) * ((popupAlignment.y-1)/-2));
              } else if (referencePosition.dy < y) {
                y = referencePosition.dy + referenceSize.height - overlappingHeight;
              } else {
                y = referencePosition.dy - ((currentChildHeight-overlappingHeight) * ((popupAlignment.y-1)/-2));
              }
              x = (x + overlappingCorrectionX).clamp(padding.left, maxWidthWithPaddingLeft);
              y = (y + overlappingCorrectionY).clamp(padding.top, maxHeightWithPaddingTop);
              if (maxWidth-x < currentChildWidth) {
                x = (maxWidthWithPaddingLeft - currentChildWidth).clamp(padding.left, maxWidthWithPaddingLeft);
              }
              if (maxHeight-y < currentChildHeight) {
                y = (maxHeightWithPaddingTop - currentChildHeight).clamp(padding.top, maxHeightWithPaddingTop);
              }
            } else {
              x = maxWidth/2-currentChildWidth/2 + widget.offsetCorrection.dx;
              y = maxHeight/2-currentChildHeight/2 + widget.offsetCorrection.dy;
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPositioned(
                  duration: animation.isCompleted
                      ? const Duration(milliseconds: 250)
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: x,
                  top: y,
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
                      maxHeight: maxHeight,
                      child: Container(
                        key: childGlobalKey,
                        child: child,
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








extension SmartClamp on double {
  num smartClamp(double x, double y) {
    return x<y ? clamp(x, y) : clamp(y, x);
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
  Rect getClip(Size size) {
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