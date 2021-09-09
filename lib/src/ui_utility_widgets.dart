import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_content_wrapper.dart';
import 'package:from_zero_ui/src/exposed_transitions.dart';
import 'package:from_zero_ui/src/scaffold_from_zero.dart';
import 'package:flutter/foundation.dart';
import 'package:from_zero_ui/util/platform_web_impl.dart';
import 'package:provider/provider.dart';
import 'package:dartx/dartx.dart';


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
    super.initState();
    widget.scrollController.addListener(_updateScroll);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _updateScroll();
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.scrollController.removeListener(_updateScroll);
  }

  void _updateScroll(){
    if (mounted){
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double size1 = 0;
    double size2 = 0;
    try{
      size1 = widget.scrollController.positions.first.pixels.clamp(0, widget.maxSize);
      size2 = (widget.scrollController.positions.first.maxScrollExtent-widget.scrollController.positions.first.pixels).clamp(0, widget.maxSize);
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


class ReturnToTopButton extends StatefulWidget {

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
class _ReturnToTopButtonState extends State<ReturnToTopButton> {

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
      space = Provider.of<ScreenFromZero>(context).displayMobileLayout ? 16 : 32;
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
              child: widget.icon ?? Icon(Icons.arrow_upward, color: Theme.of(context).primaryColorBrightness==Brightness.light ? Colors.black : Colors.white,),
              tooltip: FromZeroLocalizations.of(context).translate('return_to_top'),
              backgroundColor: Theme.of(context).primaryColor,
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


class ChangeNotifierBuilder<T extends ChangeNotifier> extends StatelessWidget{

  final T changeNotifier;
  final Widget? child;
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  ChangeNotifierBuilder({
    required this.changeNotifier,
    this.child,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: changeNotifier,
      child: child,
      builder: (context, child) {
        return Consumer<T>(
          builder: builder,
          child: child,
        );
      },
    );
  }

}


class ChangeNotifierSelectorBuilder<A extends ChangeNotifier, S> extends StatelessWidget{

  final A changeNotifier;
  final Widget? child;
  final ValueWidgetBuilder<S> builder;
  final S Function(BuildContext, A) selector;

  ChangeNotifierSelectorBuilder({
    required this.changeNotifier,
    required this.selector,
    this.child,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<A>.value(
      value: changeNotifier,
      child: child,
      builder: (context, child) {
        return Selector<A, S>(
          selector: selector,
          builder: builder,
          child: child,
        );
      },
    );
  }

}


typedef Widget InitiallyAnimatedWidgetBuilder(Animation<double> animation, Widget? child);
class InitiallyAnimatedWidget extends StatefulWidget {

  final InitiallyAnimatedWidgetBuilder? builder;
  final Duration duration;
  final Curve curve;
  final Widget? child;

  InitiallyAnimatedWidget({
    Key? key,
    this.builder,
    this.duration = const Duration(milliseconds: 300,),
    this.curve = Curves.easeOutCubic,
    this.child,
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
    animationController.forward();
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


class PlatformExtended {

  static bool get isWindows{
    if (kIsWeb){
      return false; // ! TODO ! enable this to get platform from web once null-safety compatibility issues are solved
      // return operatingSystem.isWindows;
    } else{
      return Platform.isWindows;
    }
  }

  static bool get isAndroid{
    if (kIsWeb){
      return false; // ! TODO ! enable this to get platform from web once null-safety compatibility issues are solved
      // return operatingSystem.isLinux; //Assuming unix==android
    } else{
      return Platform.isAndroid;
    }
  }

  static bool get isIOS{
    if (kIsWeb){
      return false; // ! TODO ! enable this to get platform from web once null-safety compatibility issues are solved
      // return operatingSystem.isMac; //Assuming mac==ios
    } else{
      return Platform.isIOS;
    }
  }

  static bool get isLinux{
    if (kIsWeb){
      return false;
    } else{
      return Platform.isLinux;
    }
  }

  static bool get isMacOS{
    if (kIsWeb){
      return false;
    } else{
      return Platform.isMacOS;
    }
  }

  static bool get isFuchsia{
    if (kIsWeb){
      return false;
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