import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:humanizer/humanizer.dart';


typedef DataBuilder<T> = Widget Function(BuildContext context, T data);
typedef DataMultiBuilder<T> = Widget Function(BuildContext context, List<T> data);
typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);
typedef FutureTransitionBuilder = Widget Function (BuildContext context, Widget child, Animation<double> animation);


class AsyncValueBuilder<T> extends StatelessWidget {

  final AsyncValue<T> asyncValue;
  final DataBuilder<T> dataBuilder;
  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

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
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = asyncValue.when(
      data: (data) {
        final result = dataBuilder(context, data);
        return Container(
          key: result.key ?? ValueKey(data.hashCode),
          child: result,
        );
      },
      error: (error, stackTrace) {
        final result = errorBuilder(context, error, stackTrace);
        return Container(
        key: result.key ?? ValueKey(error.hashCode),
          child: result,
        );
      },
      loading: () {
        final result = loadingBuilder(context);
        return Container(
          key: result.key ?? const ValueKey('loading'),
          child: result,
        );
      },
    );
    if (transitionDuration!=Duration.zero) {
      result = AnimatedSwitcher(
        child: result,
        duration: transitionDuration,
        switchInCurve: transitionInCurve,
        switchOutCurve: transitionOutCurve,
        transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
        layoutBuilder: (currentChild, previousChildren) {
          final knownKeys = <Key>[if (currentChild?.key!=null) currentChild!.key!];
          final cleanPreviousChildren = [];
          for (final e in previousChildren) {
            if (e.key==null || !knownKeys.contains(e.key!)) {
              cleanPreviousChildren.add(e);
              if (e.key!=null) {
                knownKeys.add(e.key!);
              }
            }
          }
          return Stack(
            alignment: alignment ?? Alignment.center,
            children: <Widget>[
              // ...cleanPreviousChildren, // TODO 1 implement a transition switcher that uses images for widgets fading out, to avoid conflicts with scrollControllers, etc.
              if (cleanPreviousChildren.isNotEmpty) cleanPreviousChildren.last,
              if (currentChild != null) currentChild,
            ],
          );
        },
      );
    }
    if (applyAnimatedContainerFromChildSize) {
      result = AnimatedContainerFromChildSize(
        duration: transitionDuration,
        alignment: alignment ?? Alignment.topLeft,
        child: result,
      );
    }
    return result;
  }

  static Widget defaultLoadingBuilder(BuildContext context){
    return const LoadingSign();
  }

  static Widget defaultErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace){
    // log(error, stackTrace: stackTrace);
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

class SliverAsyncValueBuilder<T> extends AsyncValueBuilder<T> {

  SliverAsyncValueBuilder({
    required super.asyncValue,
    required super.dataBuilder,
    LoadingBuilder loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    ErrorBuilder errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );

  static Widget defaultLoadingBuilder(BuildContext context){
    return SliverToBoxAdapter(
      child: AsyncValueBuilder.defaultLoadingBuilder(context),
    );
  }

  static Widget defaultErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace){
    return SliverToBoxAdapter(
      child: AsyncValueBuilder.defaultErrorBuilder(context, error, stackTrace),
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
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

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
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment,
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
      result = errorBuilder(context, error!, stackTrace);
      result = Container(
        key: result.key ?? ValueKey(error.hashCode),
        child: result,
      );
    } else if (data.length==asyncValues.length) {
      result = dataBuilder(context, data);
      result = Container(
        key: result.key ?? ValueKey(asyncValues.isEmpty ? 'empty' : asyncValues.map((e) => e.hashCode).reduce((v, e) => v+e)),
        child: result,
      );
    } else {
      result = loadingBuilder(context);
      result = Container(
        key: result.key ?? const ValueKey('loading'),
        child: result,
      );
    }
    if (transitionDuration!=Duration.zero) {
      result = AnimatedSwitcher(
        child: result,
        duration: transitionDuration,
        switchInCurve: transitionInCurve,
        switchOutCurve: transitionOutCurve,
        transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
        layoutBuilder: (currentChild, previousChildren) {
          final knownKeys = <Key>[if (currentChild?.key!=null) currentChild!.key!];
          final cleanPreviousChildren = [];
          for (final e in previousChildren) {
            if (e.key==null || !knownKeys.contains(e.key!)) {
              cleanPreviousChildren.add(e);
              if (e.key!=null) {
                knownKeys.add(e.key!);
              }
            }
          }
          return Stack(
            alignment: alignment ?? Alignment.center,
            children: <Widget>[
              // ...cleanPreviousChildren, // TODO 1 implement a transition switcher that uses images for widgets fading out, to avoid conflicts with scrollControllers, etc.
              if (cleanPreviousChildren.isNotEmpty) cleanPreviousChildren.last,
              if (currentChild != null) currentChild,
            ],
          );
        },
      );
    }
    if (applyAnimatedContainerFromChildSize) {
      result = AnimatedContainerFromChildSize(
        duration: transitionDuration,
        alignment: alignment ?? Alignment.topLeft,
        child: result,
      );
    }
    return result;
  }

}

class SliverAsyncValueMultiBuilder<T> extends AsyncValueMultiBuilder<T> {
  SliverAsyncValueMultiBuilder({
    required super.asyncValues,
    required super.dataBuilder,
    LoadingBuilder loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    ErrorBuilder errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}



class FutureProviderBuilder<T> extends ConsumerWidget {

  final ProviderBase<AsyncValue<T>> provider;
  final DataBuilder<T> dataBuilder;
  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

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
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment
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
      applyAnimatedContainerFromChildSize: applyAnimatedContainerFromChildSize,
      alignment: alignment,
    );
  }

}

class SliverFutureProviderBuilder<T> extends FutureProviderBuilder<T> {
  SliverFutureProviderBuilder({
    required super.provider,
    required super.dataBuilder,
    LoadingBuilder loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    ErrorBuilder errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}


