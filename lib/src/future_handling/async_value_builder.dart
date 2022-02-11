import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


typedef DataBuilder<T> = Widget Function(BuildContext context, T data);
typedef DataMultiBuilder<T> = Widget Function(BuildContext context, List<T> data);
typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);
typedef FutureTransitionBuilder = Widget Function (BuildContext context, Widget child, Animation<double> animation);


class FutureProviderBuilder<T> extends ConsumerWidget {

  final ProviderBase<AsyncValue<T>> provider;
  final DataBuilder<T> dataBuilder;
  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;

  const FutureProviderBuilder({
    Key? key,
    required this.provider,
    required this.dataBuilder,
    this.loadingBuilder = AsyncValueBuilder.defaultLoadingBuilder,
    this.errorBuilder = AsyncValueBuilder.defaultErrorBuilder,
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder(
      asyncValue: ref.watch(provider),
      dataBuilder: dataBuilder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
    );
  }

}


class AsyncValueBuilder<T> extends StatelessWidget {

  final AsyncValue<T> asyncValue;
  final DataBuilder<T> dataBuilder;
  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;

  const AsyncValueBuilder({
    Key? key,
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingBuilder = AsyncValueBuilder.defaultLoadingBuilder,
    this.errorBuilder = AsyncValueBuilder.defaultErrorBuilder,
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = asyncValue.when(
      data: (data) => Container(
        key: ValueKey(data),
        child: dataBuilder(context, data),
      ),
      error: (error, stackTrace) => Container(
        key: ValueKey(error),
        child: errorBuilder(context, error, stackTrace),
      ),
      loading: () => Container(
        key: const ValueKey('loading'),
        child: loadingBuilder(context),
      ),
    );
    result = AnimatedSwitcher(
      child: result,
      duration: transitionDuration,
      switchInCurve: transitionInCurve,
      switchOutCurve: transitionOutCurve,
      transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
    );
    return result;
  }


  static Widget defaultLoadingBuilder(BuildContext context){
    return const LoadingSign();
  }

  static Widget defaultErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace){
    // print(error);
    // print(stackTrace);
    return ErrorSign(
      icon: const Icon(Icons.error_outline), //size: 64, color: Theme.of(context).errorColor,
      title: FromZeroLocalizations.of(context).translate("error"),
      subtitle: FromZeroLocalizations.of(context).translate("error_details"),
    );
  }

  static Widget defaultTransitionBuilder(BuildContext context, Widget child, Animation<double> animation){
    return ZoomedFadeInFadeOutTransition(
      animation: animation,
      child: child,
    );
  }

}


class AsyncValueMultiBuilder<T> extends StatelessWidget {

  final List<AsyncValue<T>> asyncValues;
  final DataMultiBuilder<T> dataBuilder;
  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;

  const AsyncValueMultiBuilder({
    Key? key,
    required this.asyncValues,
    required this.dataBuilder,
    this.loadingBuilder = AsyncValueBuilder.defaultLoadingBuilder,
    this.errorBuilder = AsyncValueBuilder.defaultErrorBuilder,
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<T> data = [];
    Object? error;
    StackTrace? stackTrace;
    for (final e in asyncValues) {
      e.whenOrNull(
        data: (d) {
          data.add(d);
        },
        error: (e, st) {
          error = e; stackTrace = st;
        },
      );
    }
    Widget result;
    if (error!=null) {
      result = Container(
        key: ValueKey(error),
        child: errorBuilder(context, error!, stackTrace),
      );
    } else if (data.length==asyncValues.length) {
      result = Container(
        key: ValueKey(data),
        child: dataBuilder(context, data),
      );
    } else {
      result = Container(
        key: const ValueKey('loading'),
        child: loadingBuilder(context),
      );
    }
    result = AnimatedSwitcher(
      child: result,
      duration: transitionDuration,
      switchInCurve: transitionInCurve,
      switchOutCurve: transitionOutCurve,
      transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
    );
    return result;
  }


}
