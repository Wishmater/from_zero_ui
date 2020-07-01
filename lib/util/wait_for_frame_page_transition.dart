
import 'package:flutter/material.dart';

class PageRouteBuilderWaitForFrame<T> extends PageRouteBuilder<T>{

  PageRouteBuilderWaitForFrame({
    settings,
    @required pageBuilder,
    transitionDuration = const Duration(milliseconds: 300),
    opaque = true,
    barrierDismissible = false,
    barrierColor,
    barrierLabel,
    maintainState = true,
    fullscreenDialog = false,
  }) : super(
    settings: settings,
    pageBuilder: pageBuilder,
    transitionDuration: transitionDuration,
    opaque: opaque,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );

  @override
  AnimationController createAnimationController() {
//    assert(!_transitionCompleter.isCompleted, 'Cannot reuse a $runtimeType after disposing it.');
    final Duration duration = transitionDuration;
    final Duration reverseDuration = reverseTransitionDuration;
    assert(duration != null && duration >= Duration.zero);
    return AnimationControllerWaitForFrame(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      vsync: navigator,
    );
  }

}


class AnimationControllerWaitForFrame extends AnimationController{

  AnimationControllerWaitForFrame({
    value,
    duration,
    reverseDuration,
    debugLabel,
    lowerBound = 0.0,
    upperBound = 1.0,
    animationBehavior = AnimationBehavior.normal,
    @required vsync,
  }) : super(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    lowerBound: lowerBound,
    upperBound: upperBound,
    animationBehavior: animationBehavior,
    vsync: vsync,
  );

  @override
  TickerFuture forward({ double from }) {
    FutureTickerFuture ft = FutureTickerFuture();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ft.tickerFuture = super.forward(from: from);
    });
    return ft;
  }

  @override
  TickerFuture reverse({ double from }) {
    FutureTickerFuture ft = FutureTickerFuture();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ft.tickerFuture = super.reverse(from: from);
    });
    return ft;
  }

}


class FutureTickerFuture implements TickerFuture{

  FutureTickerFuture();

  TickerFuture _tickerFuture;
  TickerFuture get tickerFuture => _tickerFuture;
  set tickerFuture(TickerFuture value) {
    _tickerFuture = value;
    callbacks.forEach((element) {
      tickerFuture.whenCompleteOrCancel(element);
    });
  }

  List<VoidCallback> callbacks = [];
  @override
  void whenCompleteOrCancel(VoidCallback callback) {
    if (tickerFuture!=null)
      tickerFuture.whenCompleteOrCancel(callback);
    else
      callbacks.add(callback);
  }

  Future<void> get orCancel {
    return tickerFuture.orCancel;
  }

  @override
  Stream<void> asStream() {
    return tickerFuture.asStream();
  }

  @override
  Future<void> catchError(Function onError, { bool test(dynamic error) }) {
    return tickerFuture.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(onValue, { Function onError }) {
    return tickerFuture.then(onValue, onError: onError,);
  }

  @override
  Future<void> timeout(Duration timeLimit, { dynamic onTimeout() }) {
    return tickerFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<void> whenComplete(dynamic action()) {
    return tickerFuture.whenComplete(action);
  }

  @override
  String toString() => tickerFuture.toString();

}