import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/future_handling/async_value_builder.dart';
import 'package:from_zero_ui/src/future_handling/future_handling.dart';
import 'package:riverpod/riverpod.dart';

class ApiState<State> extends StateNotifier<AsyncValue<State>> {

  StateNotifierProviderRef<ApiState<State>, AsyncValue<State>> _ref;
  FutureOr<State> Function(ApiState<State>) _create;
  bool _running = true;
  late final ValueNotifier<double?> totalNotifier;
  late final ValueNotifier<double?> progressNotifier;
  late final ValueNotifier<double?> percentageNotifier;
  final List<StateNotifierProvider<ApiState, AsyncValue>> _watching = [];
  final List<CancelToken> _cancelTokens = [];
  void addCancelToken(CancelToken ct) {
    _cancelTokens.add(ct);
  }

  ApiState(this._ref, this._create,)
      : super(AsyncValue.loading()) {
    totalNotifier = ValueNotifier(null);
    totalNotifier.addListener(_computePercentage);
    progressNotifier = ValueNotifier(null);
    progressNotifier.addListener(_computePercentage);
    percentageNotifier = ValueNotifier(null);
    _runFuture();
  }

  // Future<T> watch<T>(StateNotifierProvider<ApiState<T>, AsyncValue<T>> watchProvider) {
  //
  //   if (!_watching.contains(watchProvider)) {
  //     _watching.add(watchProvider);
  //   }
  //   return _ref.watch(watchProvider.notifier);
  // }
  //
  // void retry() {
  //   for (final e in List<ApiProvider>.from(_watching)) {
  //     _ref.read(e.provider).whenOrNull(
  //       error: (error, stackTrace) {
  //         e.retry();
  //       },
  //     );
  //   }
  //   try { _ref.refresh(provider); } catch (_) {}
  // }
  //
  // void refresh() {
  //   for (final e in _watching) {
  //     e.refresh();
  //   }
  //   try { _ref.refresh(provider); } catch (_) {}
  // }
  //
  // void _cleanupCancelTokens() {
  //   for (final c in cancelTokens) {
  //     try { c.cancel(); } catch (_) {}
  //   }
  //   cancelTokens.clear();
  // }
  //
  // @override
  // void dispose() {
  //   _running = false;
  //   super.dispose();
  // }

  void _runFuture() {
    try {
      final value = _create(this);
      if (value is Future<State>) {
        value.then(
              (event) {
            if (_running) {
              state = AsyncValue<State>.data(event);
            }
          },
          // ignore: avoid_types_on_closure_parameters
          onError: (Object err, StackTrace stack) {
            if (_running) {
              state = AsyncValue<State>.error(err, stackTrace: stack);
            }
          },
        );
      } else {
        state = AsyncData(value);
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stackTrace: stack);
    }
  }

  void _computeTotal() {
    //
    // double? result = totalNotifier.value;
    // _watching.forEach((e) {
    //   final partial = ref.watch(e.totalProvider);
    //   if (partial!=null) {
    //     result = (result??0) + partial;
    //   }
    // });
    // return result;
  }
  void _computeProgress() {
    //
    // double? result = progressNotifier.value;
    // _watching.forEach((e) {
    //   final partial = ref.watch(e.progressProvider);
    //   if (partial!=null) {
    //     result = (result??0) + partial;
    //   }
    // });
    // return result;
  }
  void _computePercentage() {
    // final total = totalNotifier.value;
    // final progress = progressNotifier.value;
    // double? result = total==null||progress==null||total==0 ? null : progress/total;
    // _watching.forEach((e) {
    //   final partial = ref.watch(e.percentageProvider)
    //       ?? ref.watch(e.provider).maybeWhen<double>(data:(_)=>1, orElse: ()=>0,);
    //   result = (result??0) + partial;
    // });
    // return result==null ? null : (result!/(_watching.length+1));

  }





}



class ApiProvider<State> {

  final FutureOr<State> Function(FutureProviderRef<State> ref,
      ApiProvider<State> apiProvider,) _create;
  final AlwaysAliveProviderBase<AsyncValue<State>> Function
      (Create<FutureOr<State>, FutureProviderRef<State>>)? providerBuilder;

  ApiProvider(this._create,{
    this.providerBuilder,
  });

  late final ValueNotifier<double?> totalNotifier;
  late final ValueNotifier<double?> progressNotifier;
  late final Provider<double?> totalProvider;
  late final Provider<double?> progressProvider;
  late final Provider<double?> percentageProvider;
  late FutureProviderRef<State> _ref;
  final List<ApiProvider> _watching = [];
  final List<CancelToken> cancelTokens = [];

  AlwaysAliveProviderBase<AsyncValue<State>>? _provider;
  AlwaysAliveProviderBase<AsyncValue<State>> get provider {
    if (_provider==null) {
      _init();
    }
    return _provider!;
  }
  void _init() {
    totalProvider = Provider<double?>((ref) {
      double? result = totalNotifier.value;
      _watching.forEach((e) {
        final partial = ref.watch(e.totalProvider);
        if (partial!=null) {
          result = (result??0) + partial;
        }
      });
      return result;
    });
    progressProvider = Provider<double?>((ref) {
      double? result = progressNotifier.value;
      _watching.forEach((e) {
        final partial = ref.watch(e.progressProvider);
        if (partial!=null) {
          result = (result??0) + partial;
        }
      });
      return result;
    });
    percentageProvider = Provider<double?>((ref) {
      final total = totalNotifier.value;
      final progress = progressNotifier.value;
      double? result = total==null||progress==null||total==0 ? null : progress/total;
      _watching.forEach((e) {
        final partial = ref.watch(e.percentageProvider)
            ?? ref.watch(e.provider).maybeWhen<double>(data:(_)=>1, orElse: ()=>0,);
        result = (result??0) + partial;
      });
      return result==null ? null : (result!/(_watching.length+1));
    });
    totalNotifier = ValueNotifier(null);
    progressNotifier = ValueNotifier(null);
    totalNotifier.addListener(() {
      _ref.refresh(totalProvider);
      _ref.refresh(percentageProvider);
    });
    progressNotifier.addListener(() {
      _ref.refresh(progressProvider);
      _ref.refresh(percentageProvider);
    });
    final create = (ref) async {
      this._ref = ref;
      totalNotifier.value = null;
      progressNotifier.value = null;
      ref.onDispose(() {
        cleanupCancelTokens();
        _watching.clear();
      });
      State result;
      try {
        result = await _create(ref, this);
      } catch(_) {
        cleanupCancelTokens();
        rethrow;
      }
      cleanupCancelTokens();
      return result;
    };
    _provider = (providerBuilder ?? ApiProvider.defaultProviderBuilder)(create);
  }

  Future<T> watch<T>(ApiProvider<T> watchProvider) {
    if (!_watching.contains(watchProvider)) {
      _watching.add(watchProvider);
    }
    return _ref.watch(watchProvider.provider.future);
  }

  void retry() {
    for (final e in List<ApiProvider>.from(_watching)) {
      _ref.read(e.provider).whenOrNull(
        error: (error, stackTrace) {
          e.retry();
        },
      );
    }
    try { _ref.refresh(provider); } catch (_) {}
  }

  void refresh() {
    for (final e in _watching) {
      e.refresh();
    }
    try { _ref.refresh(provider); } catch (_) {}
  }

  void cleanupCancelTokens() {
    for (final c in cancelTokens) {
      try { c.cancel(); } catch (_) {}
    }
    cancelTokens.clear();
  }

  static AlwaysAliveProviderBase<AsyncValue<State>> defaultProviderBuilder<State>
      (Create<FutureOr<State>, FutureProviderRef<State>> create) {
    return FutureProvider<State>(create);
  }

  // TODO !!! implement .autoDispose and .family

}







typedef ApiLoadingBuilder = Widget Function(BuildContext context, double? progress);
typedef ApiErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace, VoidCallback? onRetry);

class ApiProviderBuilder<T> extends ConsumerWidget {

  final ApiProvider<T> provider;
  final DataBuilder<T> dataBuilder;
  final ApiLoadingBuilder loadingBuilder;
  final ApiErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;

  const ApiProviderBuilder({
    Key? key,
    required this.provider,
    required this.dataBuilder,
    this.loadingBuilder = ApiProviderBuilder.defaultLoadingBuilder,
    this.errorBuilder = ApiProviderBuilder.defaultErrorBuilder,
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueBuilder(
      asyncValue: ref.watch(provider.provider),
      dataBuilder: dataBuilder,
      loadingBuilder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return loadingBuilder(context, ref.watch(provider.percentageProvider));
          },
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorBuilder(context, error, stackTrace, provider.retry);
      },
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
    );
  }

  static Widget defaultLoadingBuilder(BuildContext context, double? progress) {
    return LoadingSign(
      value: progress,
    );
  }

  static Widget defaultErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace, VoidCallback? onRetry) {
    print(error);
    print(stackTrace);
    return ErrorSign(
      key: ValueKey(error),
      icon: const Icon(MaterialCommunityIcons.wifi_off),
      title: FromZeroLocalizations.of(context).translate("error_connection"),
      subtitle: FromZeroLocalizations.of(context).translate("error_connection_details"),
      onRetry: onRetry,
    );
  }

}