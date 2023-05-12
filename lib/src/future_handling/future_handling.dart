import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/animations/exposed_transitions.dart';
import 'package:intl/intl.dart';


class LoadingCard extends StatelessWidget {

  final double? value;
  final Color? color;

  const LoadingCard({
    this.value,
    this.color,
    Key? key,
  }) :  super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LoadingSign(
        value: value,
        color: color,
      ),
    );
  }

}

class LoadingSign extends ImplicitlyAnimatedWidget {

  final double? value;
  final Color? color;
  final EdgeInsets padding;
  final double size;

  const LoadingSign({
    Key? key,
    this.value,
    this.color,
    /// for animating value
    Duration duration = const Duration(milliseconds: 250),
    /// for animating value
    Curve curve = Curves.easeOutCubic,
    this.padding = const EdgeInsets.all(12),
    this.size = 48,
  }) :  super(
    key: key,
    duration: duration,
    curve: curve,
  );

  @override
  ImplicitlyAnimatedWidgetState<LoadingSign> createState() => _LoadingSignState();

}

class _LoadingSignState extends ImplicitlyAnimatedWidgetState<LoadingSign> {

  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    // Update the tween using the provided visitor function.
    _valueTween = visitor(
      // The latest tween value. Can be `null`.
      _valueTween,
      // The color value toward which we are animating.
      widget.value ?? 0.0,
      // A function that takes a color value and returns a tween
      // beginning at that value.
          (dynamic value) => Tween<double>(begin: value as double?),
    ) as Tween<double>?;
    // We could have more tweens than one by using the visitor
    // multiple times.
  }

  @override
  Widget build(BuildContext context) {
    Color color = this.widget.color ?? Theme.of(context).primaryColor;
    Color colorMedium = color.withOpacity(0.8);
    Color colorMild = color.withOpacity(0.2);
    Color colorTransparent = color.withOpacity(0);
    double fontSize = widget.size*0.3;
    double strokeWidth = widget.size*0.1;
    if (widget.size < 36) {
      fontSize = 0;
      strokeWidth = (strokeWidth*2).clamp(0, 3.6);
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double? value = _valueTween?.evaluate(animation);
        if (value==0) value = null;
        return Padding(
          padding: widget.padding,
          child: LimitedBox(
            maxWidth: 128,
            maxHeight: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: InitiallyAnimatedWidget(
                    duration: Duration(seconds: 1),
                    curve: Curves.easeOut,
                    repeat: true,
                    builder: (loopingAnimation, child) {
                      Color backgroundColor = ColorTween(begin: colorTransparent, end: colorMild).evaluate(loopingAnimation)!;
                      return Stack(
                        // fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.all(strokeWidth/2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [colorTransparent, colorTransparent, backgroundColor,],
                                    stops: [0, 0.25 + (0.75 * loopingAnimation.value), 1],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: widget.size, height: widget.size,
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: strokeWidth,
                                backgroundColor: backgroundColor,
                                valueColor: ColorTween(begin: colorMedium, end: color).animate(loopingAnimation),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (value!=null && fontSize>0)
                  Center(
                    child: OpacityGradient(
                      direction: OpacityGradient.vertical,
                      size: 5,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1, bottom: 1,),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text((value*100).round().toString(),
                              style: TextStyle(
                                fontSize: fontSize,
                                color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                              ),
                            ),
                            Text('%', style: TextStyle(
                              fontSize: fontSize,
                              color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                            ),),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class ErrorCard extends StatelessWidget {

  final String title;
  final String? subtitle;
  final Widget? icon;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  ErrorCard({
    required this.title,
    this.subtitle,
    this.onRetry,
    this.icon,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: ErrorSign(
          title: title,
          subtitle: subtitle,
          onRetry: onRetry,
          icon: icon,
        ),
      ),
    );
  }

}

class ErrorSign extends StatelessWidget {

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final Widget? icon;
  final Widget? retryButton;

  const ErrorSign({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onRetry,
    this.retryButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon!=null)
          IconTheme(
            data: Theme.of(context).iconTheme.copyWith(size: 64, color: Theme.of(context).disabledColor,),
            child: icon!,
          ),
        if (icon!=null)
          SizedBox(height: 4,),
        Text(
          title,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        if (subtitle!=null)
          SizedBox(height: 8,),
        if (subtitle!=null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyText1,
            textAlign: TextAlign.center,
          ),
        if (retryButton!=null || onRetry!=null)
          SizedBox(height: 16,),
        if (retryButton!=null || onRetry!=null)
          retryButton ?? TextButton(
            style: TextButton.styleFrom(
              primary: Theme.of(context).brightness==Brightness.light
                  ? Colors.blue.shade500
                  : Colors.blue.shade400
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 8,),
                Icon(Icons.refresh),
                SizedBox(width: 4,),
                Text(FromZeroLocalizations.of(context).translate("retry"),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.1),
                ),
                SizedBox(width: 8,),
              ],
            ),
            onPressed: onRetry,
          ),
      ],
    );
    final scrollController = ScrollController();
    result = Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: ScrollbarFromZero(
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: result,
          ),
        ),
      ),
    );
    return result;
  }

}

@deprecated
typedef SuccessBuilder<T> = Widget Function(BuildContext context, T data);
@deprecated
typedef FutureErrorBuilder = Widget Function(BuildContext context, Object? error, Object? stackTrace);
@deprecated
typedef FutureLoadingBuilder = Widget Function(BuildContext context);
@deprecated
Widget _defaultLoadingBuilder(context){
  return ApiProviderBuilder.defaultLoadingBuilder(context, null);
}

@deprecated
Widget defaultErrorBuilder(context, error, stackTrace){
  log(error, stackTrace: stackTrace);
  return ErrorSign(
    icon: Icon(Icons.error_outline), //size: 64, color: Theme.of(context).errorColor,
    title: FromZeroLocalizations.of(context).translate("error"),
    subtitle: FromZeroLocalizations.of(context).translate("error_details"),
  );
}

@deprecated
Widget _defaultTransitionBuilder(Widget child, Animation<double> animation){
  return ZoomedFadeInFadeOutTransition(
    animation: animation,
    child: child,
  );
}

@deprecated
Widget _noneTransitionBuilder(Widget child, Animation<double> animation){
  return child;
}


@deprecated
class FutureBuilderFromZero<T> extends StatefulWidget {

  final initialData;
  final Future future;
  final SuccessBuilder<T> successBuilder;
  final Duration duration;
  final bool applyAnimatedContainerFromChildSize;
  final bool keepPreviousDataWhileLoading;
  final FutureErrorBuilder errorBuilder;
  final FutureLoadingBuilder loadingBuilder;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  FutureBuilderFromZero({
    Key? key,
    required this.future,
    required this.successBuilder,
    this.errorBuilder: defaultErrorBuilder,
    this.loadingBuilder: _defaultLoadingBuilder,
    this.initialData,
    AnimatedSwitcherTransitionBuilder? transitionBuilder,
    this.keepPreviousDataWhileLoading = false,
    bool applyDefaultTransition = true,
    Duration? duration,
    this.applyAnimatedContainerFromChildSize = false,
  }) :  transitionBuilder = transitionBuilder ?? (applyDefaultTransition ? _defaultTransitionBuilder : _noneTransitionBuilder),
        duration = duration ?? (applyDefaultTransition ? const Duration(milliseconds: 300) : Duration.zero),
        super(key: key);

  @override
  _FutureBuilderFromZeroState<T> createState() => _FutureBuilderFromZeroState<T>();

}

class _FutureBuilderFromZeroState<T> extends State<FutureBuilderFromZero<T>> {

  bool skipFrame = false;
  late int initialTimestamp;

  @override
  void initState() {
    super.initState();
    initialTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void didUpdateWidget(FutureBuilderFromZero<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.future,
      initialData: widget.initialData,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        Widget result;
        int state = 0;
        if (snapshot.connectionState == ConnectionState.done || (widget.keepPreviousDataWhileLoading&&snapshot.hasData)){
          skipFrame = true;
          if (snapshot.hasData){
            state = 1;
            result = widget.successBuilder(context, snapshot.data);
          } else {
            state = -1;
            result = widget.errorBuilder(context, snapshot.hasError ? snapshot.error : "Forever Loading", snapshot.hasError ? snapshot.stackTrace : '',);
          }
        } else{
          if (skipFrame && (snapshot.hasData || snapshot.hasError)){
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              try{setState(() {
                skipFrame = false;
              });}catch(_){}
            });
            if (snapshot.hasData){
              state = 1;
              result = widget.successBuilder(context, snapshot.data);
            } else {
              state = -1;
              result = widget.errorBuilder(context, snapshot.error, snapshot.stackTrace);
            }
          } else{
            state = 0;
            result = widget.loadingBuilder(context);
          }
        }
        int milliseconds = (DateTime.now().millisecondsSinceEpoch-initialTimestamp).clamp(0, widget.duration.inMilliseconds).toInt();
        result = AnimatedSwitcher(
          transitionBuilder: widget.transitionBuilder,
          child: Container(
            key: ValueKey(state),
            child: result,
          ),
          duration: Duration(milliseconds: milliseconds),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: OverflowBox(
                    child: Stack(
                      children: previousChildren,
                    ),
                  ),
                ),
                if (currentChild!=null)
                  currentChild,
              ],
            );
          },
        );
        if (widget.applyAnimatedContainerFromChildSize){
          result = AnimatedContainerFromChildSize(
            duration: widget.duration,
            child: result,
          );
        }
        return result;
      },
    );
  }

}



class AnimatedContainerFromChildSize extends StatefulWidget {

  final Duration duration;
  final Curve curve;
  final Widget child;
  final Alignment alignment;
  final Clip clipBehavior;
  final ValueNotifier<Size?>? sizeNotifier;

  AnimatedContainerFromChildSize({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.topLeft,
    this.curve = Curves.easeOutCubic,
    this.clipBehavior = Clip.none,
    this.sizeNotifier,
    Key? key,
  })  : super(key: key);

  @override
  _AnimatedContainerFromChildSizeState createState() => _AnimatedContainerFromChildSizeState();

}


class _AnimatedContainerFromChildSizeState extends State<AnimatedContainerFromChildSize> {

  GlobalKey globalKey = GlobalKey();
  Size? previousSize;
  Size? _size;
  Size? get size => _size;
  set size(Size? value) {
    _size = value;
    widget.sizeNotifier?.value = value;
  }

  bool skipNextCalculation = false;
  late int initialTimestamp;

  late bool export;
  @override
  void initState() {
    initialTimestamp = DateTime.now().millisecondsSinceEpoch;
    export = context.findAncestorWidgetOfExactType<Export>()!=null;
    _addCallback(null);
    super.initState();
  }
  @override
  void didUpdateWidget(AnimatedContainerFromChildSize oldWidget) {
    _addCallback(oldWidget);
    super.didUpdateWidget(oldWidget);
  }

  void _addCallback(AnimatedContainerFromChildSize? oldWidget) {
    if (widget.child != oldWidget?.child){
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        try {
          RenderBox renderBox = globalKey.currentContext!.findRenderObject() as RenderBox;
          previousSize = size;
          size = renderBox.size;
          if (size!=previousSize) {
            setState(() {
              skipNextCalculation = true;
            });
          }
        } catch (_, __) { }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (export) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        _addCallback(null);
        Widget child = NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            setState((){});
            return false;
          },
          child: Container(key: globalKey, child: widget.child,),
        );
        if (size == null){
          return AnimatedContainer(
            duration: widget.duration,
            curve: widget.curve,
            child: child,
          );
        } else{
          double height = max(size!.height, constraints.minHeight);
          double width = max(size!.width, constraints.minWidth);
          double durationMult = 1;
          if (previousSize != null){
            double previousHeight = max(previousSize!.height, constraints.minHeight);
            double previousWidth = max(previousSize!.width, constraints.minWidth);
//            durationMult = ((max((previousHeight-height).abs(), (previousWidth-width).abs()))/64).clamp(0.0, 1.0); TODO 3 make this work right when called multiple times in succesion by LayoutBuilder
          }
          int milliseconds = (DateTime.now().millisecondsSinceEpoch-initialTimestamp).clamp(0, widget.duration.inMilliseconds*durationMult).toInt();

          Widget result = OverflowBox(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            minWidth: constraints.minWidth,
            minHeight: constraints.minHeight,
            alignment: widget.alignment,
            child: child,
          );
          if (widget.clipBehavior != Clip.none) {
            result = ClipRect(
              clipBehavior: widget.clipBehavior,
              child: result,
            );
          }
          return AnimatedContainer(
            height: height,
            width: width,
            duration: Duration(milliseconds: milliseconds),
            curve: widget.curve,
            child: result,
          );
        }
      },
    );
  }
}
