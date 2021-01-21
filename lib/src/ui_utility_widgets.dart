import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/src/scaffold_from_zero.dart';
import 'package:flutter/foundation.dart';
import 'package:from_zero_ui/util/platform_web_impl.dart';


class ResponsiveHorizontalInsetsSliver extends StatelessWidget {

  final Widget sliver;

  ResponsiveHorizontalInsetsSliver({Key? key, required this.sliver}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < ScaffoldFromZero.screenSizeMedium ? 0 : 12),
      sliver: sliver,
    );
  }

}

class ResponsiveHorizontalInsets extends StatelessWidget {

  final Widget child;

  ResponsiveHorizontalInsets({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < ScaffoldFromZero.screenSizeLarge ? 0 : 12),
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
  PageTransitionSwitcherTransitionBuilder? pageTransitionBuilder;
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
        transitionBuilder: pageTransitionBuilder,
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

  AnimatedSwitcherTransitionBuilder _defaultTransitionBuilder
      = (Widget child, Animation<double> animation)
    => ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic), child: child,);


  PageTransitionSwitcherTransitionBuilder _defaultPageTransitionBuilder
      = (child, primaryAnimation, secondaryAnimation) {
    return FadeThroughTransition(
      animation: primaryAnimation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Colors.transparent,
      child: child,
    );
  };

}

class AnimatedEntryWidget extends StatefulWidget {

  Widget child;
  AnimatedSwitcherTransitionBuilder? transitionBuilder;
  Duration duration;
  Curve curve;

  AnimatedEntryWidget({
    Key? key,
    required this.child,
    this.transitionBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
  }): super(key: key) {
    if (transitionBuilder==null) transitionBuilder = (child, animation){
      return FadeTransition(opacity: animation, child: child,);
    };
  }

  @override
  _AnimatedEntryWidgetState createState() => _AnimatedEntryWidgetState();

}

class _AnimatedEntryWidgetState extends State<AnimatedEntryWidget> with SingleTickerProviderStateMixin{

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    controller.forward(from: 0);
    animation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    );
  }

  @override
  void dispose(){
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.transitionBuilder!(widget.child, animation);
  }

}

class MaterialKeyValuePair extends StatelessWidget {

  String? title;
  String? value;
  bool frame;


  MaterialKeyValuePair({required this.title, required this.value, this.frame=false});

  @override
  Widget build(BuildContext context) {
    if (frame){
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title!=null)
                Text(title!, style: Theme.of(context).textTheme.caption,),
              Stack(
                fit: StackFit.passthrough,
                children: [
                  if (value!=null)
                    Padding(
                      padding: const EdgeInsets.only(left: 3, bottom: 1),
                      child: Text(value!,),
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
            style: Theme.of(context).textTheme.caption,
          ),
        if (value!=null)
          Text(
            value!,
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
  //TODO 3 implement all

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

  final double verticalPadding;
  final Widget? child;
  final double horizontalPadding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  TitleTextBackground({this.verticalPadding=8, this.child, this.horizontalPadding=24, this.backgroundColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = this.backgroundColor ?? Theme.of(context).canvasColor;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: Row(
            children: <Widget>[
              Container(
                width: horizontalPadding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      backgroundColor.withOpacity(0),
                      backgroundColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: backgroundColor.withOpacity(0.8),
                ),
              ),
              Container(
                width: horizontalPadding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      backgroundColor.withOpacity(0.8),
                      backgroundColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
              child: child,
            ),
          ),
        ),
      ],
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