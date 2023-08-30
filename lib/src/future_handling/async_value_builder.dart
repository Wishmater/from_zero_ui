import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/animations/animated_switcher_image.dart';
import 'package:humanizer/humanizer.dart';


typedef DataBuilder<T> = Widget Function(BuildContext context, T data);
typedef DataMultiBuilder<T> = Widget Function(BuildContext context, List<T> data);
typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace);
typedef FutureTransitionBuilder = Widget Function (BuildContext context, Widget child, Animation<double> animation);


enum AnimatedSwitcherType {
  none,
  normal,
  image,
  imageWithRebuild,
  imageNoOutgoing,
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
  final bool applyAnimatedContainerFromChildSize;
  final AnimatedSwitcherImageLayoutBuilder layoutBuilder;
  final Alignment? alignment; // used for animated switches
  final Clip? clipBehaviour;
  final AnimatedSwitcherType animatedSwitcherType;
  final bool addLoadingStateAsValueKeys;

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
    this.layoutBuilder = AnimatedSwitcherImage.defaultLayoutBuilder,
    this.alignment,
    this.clipBehaviour,
    this.addLoadingStateAsValueKeys = true,
    this.animatedSwitcherType = AnimatedSwitcherType.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? stateString;
    Widget result = asyncValue.when(
      data: (data) {
        stateString = 'Data-${data.hashCode}';
        return dataBuilder(context, data);
      },
      error: (error, stackTrace) {
        stateString = 'Error-${error.hashCode}';
        return errorBuilder(context, error, stackTrace);
      },
      loading: () {
        stateString = 'loading';
        return loadingBuilder(context);
      },
    );
    return AsyncBuilderAnimationWrapper(
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
      applyAnimatedContainerFromChildSize: applyAnimatedContainerFromChildSize,
      layoutBuilder: layoutBuilder,
      alignment: alignment,
      animatedSwitcherType: animatedSwitcherType,
      loadingState: addLoadingStateAsValueKeys ? stateString : null,
      clipBehaviour: clipBehaviour,
      child: result,
    );
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
    return AnimatedSwitcherImage.defaultTransitionBuilder(child, animation);
  }

}

class SliverAsyncValueBuilder<T> extends AsyncValueBuilder<T> {

  SliverAsyncValueBuilder({
    required super.asyncValue,
    required super.dataBuilder,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    super.errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
    super.transitionBuilder = SliverAsyncValueBuilder.defaultTransitionBuilder,
    super.layoutBuilder = AnimatedSwitcherImage.sliverLayoutBuilder,
  }) : super(
    applyAnimatedContainerFromChildSize: false,
  );

  static Widget defaultLoadingBuilder(BuildContext context){
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 256,
        child: AsyncValueBuilder.defaultLoadingBuilder(context),
      ),
    );
  }

  static Widget defaultErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace){
    return SizedBox(
      height: 256,
      child: SliverToBoxAdapter(
        child: AsyncValueBuilder.defaultErrorBuilder(context, error, stackTrace),
      ),
    );
  }

  static Widget defaultTransitionBuilder(BuildContext context, Widget child, Animation<double> animation){
    return AnimatedSwitcherImage.sliverTransitionBuilder(child, animation);
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
  final AnimatedSwitcherImageLayoutBuilder layoutBuilder;
  final Alignment? alignment; // used for animated switches
  final Clip? clipBehaviour;
  final AnimatedSwitcherType animatedSwitcherType;
  final bool addLoadingStateAsValueKeys;

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
    this.layoutBuilder = AnimatedSwitcherImage.defaultLayoutBuilder,
    this.alignment,
    this.clipBehaviour,
    this.addLoadingStateAsValueKeys = true,
    this.animatedSwitcherType = AnimatedSwitcherType.image,
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
    String stateString;
    if (error!=null) {
      stateString = 'Error-${error.hashCode}';
      result = errorBuilder(context, error!, stackTrace);
    } else if (data.length==asyncValues.length) {
      stateString = asyncValues.isEmpty ? 'empty' : 'Data-${Object.hashAll(asyncValues)}';
      result = dataBuilder(context, data);
    } else {
      stateString = 'loading';
      result = loadingBuilder(context);
    }
    return AsyncBuilderAnimationWrapper(
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
      applyAnimatedContainerFromChildSize: applyAnimatedContainerFromChildSize,
      layoutBuilder: layoutBuilder,
      alignment: alignment,
      animatedSwitcherType: animatedSwitcherType,
      loadingState: addLoadingStateAsValueKeys ? stateString : null,
      clipBehaviour: clipBehaviour,
      child: result,
    );
  }

}

class SliverAsyncValueMultiBuilder<T> extends AsyncValueMultiBuilder<T> {
  SliverAsyncValueMultiBuilder({
    required super.asyncValues,
    required super.dataBuilder,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    super.errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
    super.transitionBuilder = SliverAsyncValueBuilder.defaultTransitionBuilder,
    super.layoutBuilder = AnimatedSwitcherImage.sliverLayoutBuilder,
  }) : super(
    applyAnimatedContainerFromChildSize: false,
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
  final AnimatedSwitcherImageLayoutBuilder layoutBuilder;
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
    this.layoutBuilder = AnimatedSwitcherImage.defaultLayoutBuilder,
    this.alignment,
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
      layoutBuilder: layoutBuilder,
      alignment: alignment,
    );
  }

}

class SliverFutureProviderBuilder<T> extends FutureProviderBuilder<T> {
  SliverFutureProviderBuilder({
    required super.provider,
    required super.dataBuilder,
    super.transitionDuration = const Duration(milliseconds: 300),
    super.loadingBuilder = SliverAsyncValueBuilder.defaultLoadingBuilder,
    super.errorBuilder = SliverAsyncValueBuilder.defaultErrorBuilder,
    super.transitionBuilder = SliverAsyncValueBuilder.defaultTransitionBuilder,
    super.layoutBuilder = AnimatedSwitcherImage.sliverLayoutBuilder,
  }) : super(
    applyAnimatedContainerFromChildSize: false,
  );
}



class AsyncBuilderAnimationWrapper extends StatelessWidget {

  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final AnimatedSwitcherImageLayoutBuilder layoutBuilder;
  final Alignment? alignment; // used for animated switches
  final Clip? clipBehaviour;
  final AnimatedSwitcherType animatedSwitcherType;
  final String? loadingState;
  final Widget child;

  const AsyncBuilderAnimationWrapper({
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
    this.applyAnimatedContainerFromChildSize = false,
    this.layoutBuilder = AnimatedSwitcherImage.defaultLayoutBuilder,
    this.alignment,
    this.clipBehaviour,
    this.animatedSwitcherType = AnimatedSwitcherType.image,
    this.loadingState,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final notifyResize = applyAnimatedContainerFromChildSize ? ChangeNotifier() : null;
    Widget result = child;
    if (animatedSwitcherType!=AnimatedSwitcherType.none && transitionDuration!=Duration.zero) {
      if (loadingState!=null) {
        result = KeyedSubtree(
          child: result,
          key: child.key ?? ValueKey(loadingState),
        );
      }
      if (animatedSwitcherType==AnimatedSwitcherType.normal) {
        result = AnimatedSwitcher(
          child: result,
          duration: transitionDuration,
          switchInCurve: transitionInCurve,
          switchOutCurve: transitionOutCurve,
          transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
          layoutBuilder: (currentChild, previousChildren) {
            return layoutBuilder(currentChild, previousChildren, alignment ?? Alignment.center, clipBehaviour ?? Clip.hardEdge);
          },
        );
      } else {
        result = AnimatedSwitcherImage(
          child: result,
          duration: transitionDuration,
          switchInCurve: transitionInCurve,
          switchOutCurve: transitionOutCurve,
          transitionBuilder: (child, animation) => transitionBuilder(context, child, animation),
          layoutBuilder: layoutBuilder,
          alignment: alignment ?? Alignment.center,
          clipBehaviour: clipBehaviour ?? Clip.hardEdge,
          takeImages: animatedSwitcherType!=AnimatedSwitcherType.imageNoOutgoing,
          rebuildOutgoingChildrenIfNoImageReady: animatedSwitcherType==AnimatedSwitcherType.imageWithRebuild,
        );
      }
    }
    if (applyAnimatedContainerFromChildSize) {
      result = AnimatedContainerFromChildSize(
        duration: transitionDuration,
        alignment: alignment ?? Alignment.topLeft,
        notifyResize: notifyResize,
        child: result,
      );
    }
    return result;
  }

}
