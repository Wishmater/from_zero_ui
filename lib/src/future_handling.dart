import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';


class LoadingCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LoadingSign(),
      ),
    );
  }

}

class LoadingSign extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

}

class ErrorCard extends StatelessWidget {

  String title;
  String subtitle;
  Widget icon;
  VoidCallback onRetry;

  ErrorCard({this.title, this.subtitle, this.onRetry, this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
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

  String title;
  String subtitle;
  VoidCallback onRetry;
  Widget icon;

  ErrorSign({this.title, this.subtitle, this.onRetry, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon!=null)
            icon,
          if (icon!=null)
            SizedBox(height: 6,),
          Text(
            title,
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 12,),
          Text(
            subtitle,
          ),
          if (onRetry!=null)
          SizedBox(height: 12,),
          if (onRetry!=null)
          RaisedButton(
            child: Text("Reintentar"), //TODO 3 internationalize
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

}

typedef SuccessBuilder<T> = Widget Function(BuildContext context, T result);
typedef ErrorBuilder = Widget Function(BuildContext context, Object error);
typedef LoadingBuilder = Widget Function(BuildContext context);
class FutureBuilderFromZero<T> extends StatelessWidget {

  final key;
  final initialData;
  final Future future;
  final SuccessBuilder<T> successBuilder;
  final Duration duration;
  ErrorBuilder errorBuilder;
  LoadingBuilder loadingBuilder;
  PageTransitionSwitcherTransitionBuilder transitionBuilder;

  FutureBuilderFromZero({
    this.key,
    @required this.future,
    @required this.successBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.initialData,
    this.transitionBuilder,
    this.duration = const Duration(milliseconds: 300),
  }) {
    assert(successBuilder != null);
    if (errorBuilder==null) errorBuilder = _defaultErrorBuilder;
    if (loadingBuilder==null) loadingBuilder = _defaultLoadingBuilder;
    if (transitionBuilder==null) transitionBuilder = _defaultTransitionBuilder;
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      key: key,
      future: future,
      initialData: initialData,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        Widget result;
        int state = 0;
        if (snapshot.connectionState == ConnectionState.done){
          if (snapshot.hasData){
            state = 1;
            result = successBuilder(context, snapshot.data);
          } else if (snapshot.hasError){
            state = -1;
            result = errorBuilder(context, snapshot.error);
          }
        } else{
          state = 0;
          result = loadingBuilder(context);
        }
        return AnimatedContainerFromChildSize(
          duration: duration,
          child: PageTransitionSwitcher(
            key: ValueKey(state),
            transitionBuilder: transitionBuilder,
            child: Container(key: ValueKey(state), child: result),
            duration: duration,
          ),
        );
      },
    );
  }

  Widget _defaultLoadingBuilder(context){
    return LoadingSign();
  }

  Widget _defaultErrorBuilder(context, error){
    return ErrorSign(
      icon: Icon(Icons.error_outline, size: 64, color: Theme.of(context).errorColor,),
      title: "Oops!",
      subtitle: "Something went wrong...",
    );
  }

  Widget _defaultTransitionBuilder(Widget child, Animation<double> primaryAnimation, Animation<double> secondaryAnimation,){
    return FadeThroughTransition(
      animation: primaryAnimation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Colors.transparent,
      child: child,
    );
  }

}


/// Only updates when a different child is given, like AnimatedSwitcher
class AnimatedContainerFromChildSize extends StatefulWidget {

  final Duration duration;
  final Curve curve;
  final Widget child;

  AnimatedContainerFromChildSize({@required this.duration, this.curve = Curves.easeOutCubic, @required this.child});

  @override
  _AnimatedContainerFromChildSizeState createState() => _AnimatedContainerFromChildSizeState();

}

class _AnimatedContainerFromChildSizeState extends State<AnimatedContainerFromChildSize> {

  GlobalKey globalKey = GlobalKey();
  Size previouSize;
  Size size;
  bool skipNextCalculation = false;
  int initialTimestamp;

  @override
  void initState() {
    initialTimestamp = DateTime.now().millisecondsSinceEpoch;
    _addCalback(null);
  }
  @override
  void didUpdateWidget(AnimatedContainerFromChildSize oldWidget) {
    _addCalback(oldWidget);
  }

  void _addCalback(AnimatedContainerFromChildSize oldWidget){
    if (widget?.child != oldWidget?.child){
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        try {
          RenderBox renderBox = globalKey.currentContext.findRenderObject();
          setState(() {
            previouSize = size;
            size = renderBox.size;
            skipNextCalculation = true;
          });
        } catch (_, __) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget child = Container(key: globalKey, child: widget.child,);
        if (size == null){
          return AnimatedContainer(
            duration: widget.duration,
            curve: widget.curve,
            child: child,
          );
        } else{
          double height = max(size.height, constraints.minHeight);
          double width = max(size.width, constraints.minWidth);
          double durationMult = 1;
          if (previouSize != null){
            double previousHeight = max(previouSize.height, constraints.minHeight);
            double previousWidth = max(previouSize.width, constraints.minWidth);
            durationMult = ((max((previousHeight-height).abs(), (previousWidth-width).abs()))/64).clamp(0.0, 1.0);
          }
          int milliseconds = (DateTime.now().millisecondsSinceEpoch-initialTimestamp-300).clamp(0, widget.duration.inMilliseconds*durationMult).toInt();
          return AnimatedContainer(
            height: height,
            width: width,
            duration: Duration(milliseconds: milliseconds),
            curve: widget.curve,
            child: OverflowBox(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              minWidth: constraints.minWidth,
              minHeight: constraints.minHeight,
              alignment: Alignment.topLeft,
              child: child,
            ),
          );
        }
      },
    );
  }
}
