import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/app_content_wrapper.dart';
import 'package:from_zero_ui/src/animations/exposed_transitions.dart';
import 'package:from_zero_ui/src/app_scaffolding/scaffold_from_zero.dart';
import 'package:flutter/foundation.dart';
import 'package:from_zero_ui/util/platform_web_impl.dart';

import 'package:dartx/dartx.dart';


// TODO 2 break this up into individual files

class ResponsiveHorizontalInsetsSliver extends StatelessWidget {

  final Widget sliver;
  final double padding;
  /// Screen width required to add padding
  final double breakpoint;

  ResponsiveHorizontalInsetsSliver({
    Key? key,
    required this.sliver,
    this.padding = 12,
    this.breakpoint = ScaffoldFromZero.screenSizeMedium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < breakpoint ? 0 : padding),
      sliver: sliver,
    );
  }

}


class ResponsiveHorizontalInsets extends StatelessWidget {

  final Widget child;
  final double padding;
  /// Screen width required to add padding
  final double breakpoint;

  ResponsiveHorizontalInsets({
    Key? key,
    required this.child,
    this.padding = 12,
    this.breakpoint = ScaffoldFromZero.screenSizeMedium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < breakpoint ? 0 : padding),
      child: child,
    );
  }

}


class LoadingCheckbox extends StatelessWidget{

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final MouseCursor? mouseCursor;
  final Color? activeColor;
  final Color? checkColor;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final Color? focusColor;
  final Color? hoverColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget loadingWidget;
  final Duration transitionDuration;
  final Key? key;
  final PageTransitionSwitcherTransitionBuilder? pageTransitionBuilder;
  AnimatedSwitcherTransitionBuilder? transitionBuilder;

  LoadingCheckbox({
    required this.value,
    required this.onChanged,
    this.mouseCursor,
    this.activeColor, this.checkColor, this.materialTapTargetSize,
    this.visualDensity, this.focusColor, this.hoverColor, this.focusNode,
    this.autofocus = false,
    this.loadingWidget = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3,),),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionBuilder,
    this.transitionBuilder,
    this.key,
  }) {
    if (transitionBuilder==null && pageTransitionBuilder==null)
      transitionBuilder = _defaultTransitionBuilder;
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    if (value==null){
      result = Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        child: loadingWidget,
      );
    } else{
      result = Checkbox(
        key: key,
        value: value,
        onChanged: onChanged,
        mouseCursor: mouseCursor,
        activeColor: activeColor,
        checkColor: checkColor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        materialTapTargetSize: materialTapTargetSize,
        visualDensity: visualDensity,
        focusNode: focusNode,
        autofocus: autofocus,
      );
    }
    if (pageTransitionBuilder!=null)
      return PageTransitionSwitcher(
        transitionBuilder: pageTransitionBuilder!,
        duration: transitionDuration,
        child: result,
      );
    else
      return AnimatedSwitcher(
        transitionBuilder: transitionBuilder!,
        duration: transitionDuration,
        child: result,
      );
  }

  AnimatedSwitcherTransitionBuilder _defaultTransitionBuilder = (Widget child, Animation<double> animation)
      => ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic), child: child,);

  // PageTransitionSwitcherTransitionBuilder _defaultPageTransitionBuilder = (child, primaryAnimation, secondaryAnimation) {
  //   return FadeThroughTransition(
  //     animation: primaryAnimation,
  //     secondaryAnimation: secondaryAnimation,
  //     fillColor: Colors.transparent,
  //     child: child,
  //   );
  // };

}


class MaterialKeyValuePair extends StatelessWidget {

  final String? title;
  final String? value;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;
  final bool frame;
  final double padding;

  MaterialKeyValuePair({
    required this.title,
    required this.value,
    this.frame=false,
    this.titleStyle,
    this.valueStyle,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (frame) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title!=null)
                Text(title!, style: titleStyle ?? Theme.of(context).textTheme.caption,),
              Stack(
                fit: StackFit.passthrough,
                children: [
                  if (value!=null)
                    Padding(
                      padding: const EdgeInsets.only(left: 3, bottom: 1),
                      child: Text(value!, style: valueStyle,),
                    ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: Divider(
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: VerticalDivider(
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title!=null)
          Text(
            title!,
            style: titleStyle ?? Theme.of(context).textTheme.caption,
          ),
        SizedBox(height: padding,),
        if (value!=null)
          Text(
            value!,
            style: valueStyle,
          ),
      ],
    );
  }

}


class AppbarFiller extends StatelessWidget {

  final child;

  AppbarFiller({this.child});

  @override
  Widget build(BuildContext context) {
    double height = 0;
    ScaffoldFromZero? scaffold = context.findAncestorWidgetOfExactType<ScaffoldFromZero>();
    if (scaffold!=null && scaffold.bodyFloatsBelowAppbar){
      height = scaffold.appbarHeight + MediaQuery.of(context).padding.top;
    }
    return Padding(
      padding: EdgeInsets.only(top: height),
      child: child ?? SizedBox.shrink(),
    );
  }

}


class OpacityGradient extends StatelessWidget {

  static const left = 0;
  static const right = 1;
  static const top = 2;
  static const bottom = 3;
  static const horizontal = 4;
  static const vertical = 5;

  final Widget child;
  final int direction;
  final double? size;
  final double? percentage;

  OpacityGradient({
    required this.child,
    this.direction = vertical,
    double? size,
    this.percentage,
  }) :
    assert(size==null || percentage==null, "Can't set both a hard size and a percentage."),
    size = size==null&&percentage==null ? 16 : size
  ;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: direction==top || direction==bottom || direction==vertical
            ? Alignment.topCenter : Alignment.centerLeft,
        end: direction==top || direction==bottom || direction==vertical
            ? Alignment.bottomCenter : Alignment.centerRight,
        stops: [
          0,
          direction==bottom || direction==right ? 0
              : size==null ? percentage!
              : size!/(direction==top || direction==bottom || direction==vertical ? bounds.height : bounds.width),
          direction==top || direction==left ? 1
              : size==null ? 1-percentage!
              : 1-size!/(direction==top || direction==bottom || direction==vertical ? bounds.height : bounds.width),
          1,
        ],
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}


class ScrollOpacityGradient extends StatefulWidget {

  final ScrollController scrollController;
  final Widget child;
  final double maxSize;
  final int direction;

  ScrollOpacityGradient({
    required this.scrollController,
    required this.child,
    this.maxSize = 16,
    this.direction = OpacityGradient.vertical,
  });

  @override
  _ScrollOpacityGradientState createState() => _ScrollOpacityGradientState();

}
class _ScrollOpacityGradientState extends State<ScrollOpacityGradient> {

  @override
  void initState() {
    _addListener(widget.scrollController);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateScroll();
    });
  }

  @override
  void didUpdateWidget(ScrollOpacityGradient oldWidget) {
    super.didUpdateWidget(oldWidget);
    _removeListener(oldWidget.scrollController);
    _addListener(widget.scrollController);
  }

  @override
  void dispose() {
    super.dispose();
    _removeListener(widget.scrollController);
  }

  void _addListener(ScrollController scrollController) {
    scrollController.addListener(_updateScroll);
  }

  void _removeListener(ScrollController scrollController) {
    scrollController.removeListener(_updateScroll);
  }

  void _updateScroll(){
    if (mounted){
      setState(() {});
    }
  }

  double size1 = 0;
  double size2 = 0;
  @override
  Widget build(BuildContext context) {
    try{
      size1 = widget.scrollController.position.pixels.clamp(0, widget.maxSize);
      size2 = (widget.scrollController.position.maxScrollExtent-widget.scrollController.position.pixels).clamp(0, widget.maxSize);
    } catch(e){ }
    return OpacityGradient(
      size: size1,
      direction: widget.direction==OpacityGradient.horizontal ? OpacityGradient.left : OpacityGradient.top,
      child: OpacityGradient(
        size: size2,
        direction: widget.direction==OpacityGradient.horizontal ? OpacityGradient.right : OpacityGradient.bottom,
        child: widget.child,
      ),
    );
  }

}


class OverflowScroll extends StatefulWidget {

  final ScrollController? scrollController;
  /// Autoscroll speed in pixels per second if null, disable autoscroll
  final double? autoscrollSpeed;
  final double opacityGradientSize;
  final Duration autoscrollWaitTime;
  final Duration initialAutoscrollWaitTime;
  final Axis scrollDirection;
  final Widget child;

  OverflowScroll({
    required this.child,
    this.scrollController,
    this.autoscrollSpeed = 64,
    this.opacityGradientSize = 16,
    this.autoscrollWaitTime = const Duration(seconds: 5),
    this.initialAutoscrollWaitTime = const Duration(seconds: 3),
    this.scrollDirection = Axis.horizontal,
    Key? key,
  }): super(key: key);

  @override
  _OverflowScrollState createState() => _OverflowScrollState();

}
class _OverflowScrollState extends State<OverflowScroll> {

  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = widget.scrollController ?? ScrollController();
    if (widget.autoscrollSpeed!=null && widget.autoscrollSpeed!>0){
      _scroll(true, widget.initialAutoscrollWaitTime);
    }
    super.initState();
  }

  void _scroll([bool forward=true, Duration? waitDuration]) async{
    await Future.delayed(waitDuration ?? widget.autoscrollWaitTime);
    try {
      Duration duration = (1000*scrollController.position.maxScrollExtent/widget.autoscrollSpeed!).milliseconds;
      if (forward){
        await scrollController.animateTo(scrollController.position.maxScrollExtent, duration: duration, curve: Curves.linear);
      } else{
        await scrollController.animateTo(0, duration: duration, curve: Curves.linear);
      }
      _scroll(!forward);
    } catch(_){}
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    result = NotificationListener(
      onNotification: (notification) => true,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: widget.scrollDirection,
        child: widget.child,
      ),
    );
    if (widget.opacityGradientSize>0) {
      result = ScrollOpacityGradient(
        scrollController: scrollController,
        direction: widget.scrollDirection==Axis.horizontal ? OpacityGradient.horizontal : OpacityGradient.vertical,
        maxSize: widget.opacityGradientSize,
        child: result,
      );
    }
    return result;
  }

}


class ReturnToTopButton extends ConsumerStatefulWidget {

  final ScrollController scrollController;
  final Widget child;
  final Widget? icon;
  final Duration? duration;
  final VoidCallback? onTap;

  ReturnToTopButton({
    required this.scrollController,
    required this.child,
    this.onTap,
    this.icon,
    this.duration=const Duration(milliseconds: 300)
  });

  @override
  _ReturnToTopButtonState createState() => _ReturnToTopButtonState();

}
class _ReturnToTopButtonState extends ConsumerState<ReturnToTopButton> {

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(update);
  }

  @override
  void didUpdateWidget(ReturnToTopButton oldWidget) {
    oldWidget.scrollController.removeListener(update);
    widget.scrollController.addListener(update);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(update);
    super.dispose();
  }

  void update(){
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    bool show = false;
    try {
      show = widget.scrollController.position.pixels > 256;
    } catch(_){}
    double space = 16;
    try{
      space = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout)) ? 16 : 32;
    } catch(_){}
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          bottom: space, right: space,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween(begin: Offset(0, 1), end: Offset.zero,).animate(animation),
              child: ZoomedFadeInTransition(animation: animation, child: child,),
            ),
            child: !show ? SizedBox.shrink() : FloatingActionButton(
              child: widget.icon ?? Icon(Icons.arrow_upward,
                color: Theme.of(context).appBarTheme.iconTheme?.color
                    ?? (Theme.of(context).primaryColorBrightness==Brightness.light ? Colors.black : Colors.white),
              ),
              tooltip: FromZeroLocalizations.of(context).translate('return_to_top'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              onPressed: widget.onTap ?? () {
                if (widget.duration==null){
                  widget.scrollController.jumpTo(0);
                } else{
                  widget.scrollController.animateTo(0, duration: widget.duration!, curve: Curves.easeOutCubic);
                }
              },
            ),
          ),
        )
      ],
    );
  }

}


class TextIcon extends StatelessWidget {

  final String text;
  final double width;
  final double height;

  TextIcon(
      this.text,
      {this.width = 24,
      this.height = 24,}
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness==Brightness.light ? Colors.black45 : Colors.white,
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Theme.of(context).cardColor),
          ),
        ),
      ),
    );
  }

}


class TitleTextBackground extends StatelessWidget {

  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final Widget? child;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  TitleTextBackground({
    double paddingVertical = 8,
    double paddingHorizontal = 24,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    this.child,
    this.backgroundColor,
    this.onTap,
  })  : this.paddingTop = paddingTop ?? paddingVertical,
        this.paddingBottom = paddingBottom ?? paddingVertical,
        this.paddingLeft = paddingLeft ?? paddingHorizontal,
        this.paddingRight = paddingRight ?? paddingHorizontal;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor ?? Theme.of(context).canvasColor;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double stopPercentageLeft = (paddingLeft/constraints.maxWidth).clamp(0, 1);
              double stopPercentageRight = 1 - (paddingRight/constraints.maxWidth).clamp(0, 1);
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      backgroundColor.withOpacity(0),
                      backgroundColor.withOpacity(0.8),
                      backgroundColor.withOpacity(0.8),
                      backgroundColor.withOpacity(0),
                    ],
                    stops: [0, stopPercentageLeft, stopPercentageRight, 1,],
                  ),
                ),
              );
            },
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(paddingLeft, paddingTop, paddingRight, paddingBottom),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

}


class IconButtonBackground extends StatelessWidget {

  final Widget child;

  IconButtonBackground({required this.child,});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(666)),
        gradient: RadialGradient(
            colors: [
              (Theme.of(context).brightness==Brightness.light
                  ? Colors.grey.shade100 : Color.fromRGBO(55, 55, 55, 1)).withOpacity(0.8),
              (Theme.of(context).brightness==Brightness.light
                  ? Colors.grey.shade100 : Color.fromRGBO(55, 55, 55, 1)).withOpacity(0),
            ],
            stops: [
              0.5,
              1
            ]
        ),
      ),
      child: child,
    );
  }

}



class SkipFrameWidget extends StatefulWidget {

  final int frameSkipCount;
  final WidgetBuilder paceholderBuilder;
  final WidgetBuilder childBuilder;
  final InitiallyAnimatedWidgetBuilder? transitionBuilder;
  final Duration duration;
  final Curve curve;

  const SkipFrameWidget({
    Key? key,
    required this.paceholderBuilder,
    required this.childBuilder,
    this.frameSkipCount = 1,
    this.transitionBuilder,
    this.duration = const Duration(milliseconds: 250,),
    this.curve = Curves.easeOutCubic,
  }) : super(key: key);

  @override
  _SkipFrameWidgetState createState() => _SkipFrameWidgetState();

}

class _SkipFrameWidgetState extends State<SkipFrameWidget> {

  late int skipFramesLeft;

  @override
  void initState() {
    super.initState();
    skipFramesLeft = widget.frameSkipCount;
    skipNextFrame();
  }

  void skipNextFrame() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      skipFramesLeft--;
      if (skipFramesLeft > 1) {
        skipNextFrame();
      } else {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (skipFramesLeft > 0) {
      return widget.paceholderBuilder(context);
    } else {
      return InitiallyAnimatedWidget(
        builder: widget.transitionBuilder ?? (animation, child) {
          return FadeTransition(opacity: animation, child: child!,);
        },
        child: widget.childBuilder(context),
        duration: widget.duration,
        curve: widget.curve,
      );
    }
  }

}



typedef Widget InitiallyAnimatedWidgetBuilder(Animation<double> animation, Widget? child);
class InitiallyAnimatedWidget extends StatefulWidget {

  final InitiallyAnimatedWidgetBuilder? builder;
  final Duration duration;
  final Curve curve;
  final Widget? child;
  final bool repeat;
  final bool reverse;

  InitiallyAnimatedWidget({
    Key? key,
    this.builder,
    this.duration = const Duration(milliseconds: 300,),
    this.curve = Curves.easeOutCubic,
    this.child,
    this.repeat = false,
    this.reverse = true,
  }) : super(key: key);

  @override
  _InitiallyAnimatedWidgetState createState() => _InitiallyAnimatedWidgetState();

}
class _InitiallyAnimatedWidgetState extends State<InitiallyAnimatedWidget> with SingleTickerProviderStateMixin {

  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    animation = CurvedAnimation(
      parent: animationController,
      curve: widget.curve,
    );
    startAnimation();
  }
  void startAnimation() {
    if (widget.repeat) {
      animationController.repeat(
        reverse: widget.reverse,
      );
    } else {
      animationController.forward();
    }
  }

  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      child: widget.child,
      builder: (context, child) {
        if (widget.builder!=null) {
          return widget.builder!(animation, widget.child);
        } else {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        }
      },
    );
  }

}


class KeepAliveMixinWidget extends StatefulWidget {
  final Widget child;
  const KeepAliveMixinWidget({Key? key, required this.child}) : super(key: key);
  @override
  _KeepAliveMixinWidgetState createState() => _KeepAliveMixinWidgetState();
}

class _KeepAliveMixinWidgetState extends State<KeepAliveMixinWidget> with
                          AutomaticKeepAliveClientMixin<KeepAliveMixinWidget> {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}



class FlexibleLayoutFromZero extends StatelessWidget {

  final Axis axis;
  /// if relevantAxisMaxSize is provided, there is no need for a LayoutBuilder,
  /// min(relevantAxisMaxSize, MediaQuery.maxWidth) will be used instead
  /// if the layout can span the entire screen, set relevantAxisMaxSize=double.infinity
  final double? relevantAxisMaxSize;
  final List<FlexibleLayoutItemFromZero> children;
  final CrossAxisAlignment crossAxisAlignment;

  const FlexibleLayoutFromZero({
    this.axis = Axis.horizontal,
    this.relevantAxisMaxSize,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.children,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (relevantAxisMaxSize!=null) {
      final relevantScreenSize = axis==Axis.horizontal
          ? MediaQuery.of(context).size.width
          : MediaQuery.of(context).size.height;
      return buildInternal(context, min(relevantAxisMaxSize!, relevantScreenSize));
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return buildInternal(context, axis==Axis.horizontal ? constraints.maxWidth : constraints.maxHeight);
        },
      );
    }
  }

  Widget buildInternal(BuildContext context, double relevantAxisSize) {
    double minTotalSize = children.sumBy((e) => e.minSize); // TODO 3 these calculations should probably be done in a render object
    Map<int, FlexibleLayoutItemFromZero> expandableItems = {};
    Map<int, double> itemSizes = {};
    for (int i=0; i<children.length; i++) {
      itemSizes[i] = children[i].minSize;
      if (children[i].maxSize > children[i].minSize) {
        expandableItems[i] = children[i];
      }
    }
    double extraSize = (relevantAxisSize-minTotalSize).clamp(0, double.infinity);
    while (extraSize!=0 && expandableItems.isNotEmpty) {
      double totalFlex = children.sumBy((e) => e.flex);
      for (final key in expandableItems.keys) {
        final percentage = totalFlex==0
            ? 1 / expandableItems.length
            : expandableItems[key]!.flex / totalFlex;
        itemSizes[key] = itemSizes[key]! + (extraSize * percentage);
      }
      extraSize = 0;
      List<int> keysToRemove = [];
      for (final key in expandableItems.keys) {
        final difference = itemSizes[key]! - expandableItems[key]!.maxSize;
        if (difference >= 0) {
          itemSizes[key] = itemSizes[key]! - difference;
          extraSize += difference;
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        expandableItems.remove(key);
      }
    }
    List<Widget> sizedChildren = children.mapIndexed((index, e) {
      return SizedBox(
        height: axis==Axis.vertical ? itemSizes[index] : null,
        width: axis==Axis.horizontal ? itemSizes[index] : null,
        child: e,
      );
    }).toList();
    Widget result;
    if (axis==Axis.horizontal) {
      result = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: sizedChildren,
      );
    } else {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: sizedChildren,
      );
    }
    final scrollController = ScrollController();
    return ScrollbarFromZero(
      controller: scrollController,
      opacityGradientDirection: axis==Axis.horizontal ? OpacityGradient.horizontal
                                                      : OpacityGradient.vertical,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: axis,
        child: result,
      ),
    );
  }

}
class FlexibleLayoutItemFromZero extends StatelessWidget {

  final double minSize;
  final double maxSize;
  /// defines the priority with which space remaining after al minWidth is filled
  /// is distributed among items
  final double flex;
  final Widget child;

  const FlexibleLayoutItemFromZero({
    required this.child,
    required this.maxSize,
    this.minSize = 0,
    this.flex = 0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }

}



class BottomClipper extends CustomClipper<Path> {
  final double infinite = 999999;
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(-infinite, -infinite);
    path.lineTo(-infinite, size.height);
    path.lineTo(infinite, size.height);
    path.lineTo(infinite, -infinite);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}





class PlatformExtended {

  static bool get isWindows{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.windows;
    } else{
      return Platform.isWindows;
    }
  }

  static bool get isAndroid{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.android;
    } else{
      return Platform.isAndroid;
    }
  }

  static bool get isIOS{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.iOS;
    } else{
      return Platform.isIOS;
    }
  }

  static bool get isLinux{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.linux;
    } else{
      return Platform.isLinux;
    }
  }

  static bool get isMacOS{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.macOS;
    } else{
      return Platform.isMacOS;
    }
  }

  static bool get isFuchsia{
    if (kIsWeb){
      return defaultTargetPlatform==TargetPlatform.fuchsia;
    } else{
      return Platform.isFuchsia;
    }
  }

  static bool get isMobile{
    return PlatformExtended.isAndroid||PlatformExtended.isIOS;
  }

  static bool get isDesktop{
    return !PlatformExtended.isMobile;
  }

}


extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true, bool includeAlpha=true}) => '${leadingHashSign ? '#' : ''}'
      '${includeAlpha ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}


extension InverseBrigtenes on Brightness {
  Brightness get inverse => this==Brightness.light
      ? Brightness.dark : Brightness.light;
}