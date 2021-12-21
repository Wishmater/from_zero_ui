import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/future_handling/async_value_builder.dart';
import 'package:from_zero_ui/src/future_handling/future_handling.dart';
import 'package:riverpod/riverpod.dart';


typedef ApiProvider<T> = StateNotifierProvider<ApiState<T>, AsyncValue<T>>;

class ApiState<State> extends StateNotifier<AsyncValue<State>> {

  // StateNotifierProviderRef<ApiState<State>, AsyncValue<State>> _ref;
  Ref? _ref;
  FutureOr<State> Function(ApiState<State>) _create;
  late FutureOr<State> future;
  bool _running = true;
  late final ValueNotifier<double?> selfTotalNotifier;
  late final ValueNotifier<double?> selfProgressNotifier;
  late final ValueNotifier<double?> wholeTotalNotifier;
  late final ValueNotifier<double?> wholeProgressNotifier;
  late final ValueNotifier<double?> wholePercentageNotifier;
  final List<ApiProvider> _watching = [];
  final List<CancelToken> _cancelTokens = [];
  void addCancelToken(CancelToken ct) {
    _cancelTokens.add(ct);
  }

  ApiState(Ref ref, this._create,)
      : this._ref = ref,
        super(AsyncValue.loading()) {
    init();
  }

  ApiState.noProvider(this._create,)
      : super(AsyncValue.loading()) {
    init();
  }

  void init() {
    selfTotalNotifier = ValueNotifier(null);
    selfTotalNotifier.addListener(_computeTotal);
    selfProgressNotifier = ValueNotifier(null);
    selfProgressNotifier.addListener(_computeProgress);
    wholeTotalNotifier = ValueNotifier(null);
    wholeTotalNotifier.addListener(_computePercentage);
    wholeProgressNotifier = ValueNotifier(null);
    wholeProgressNotifier.addListener(_computePercentage);
    wholePercentageNotifier = ValueNotifier(null);
    _runFuture();
  }

  Future<T> watch<T>(ApiProvider<T> watchProvider) async {
    assert(_ref!=null);
    if (!_watching.contains(watchProvider)) {
      _watching.add(watchProvider);
      final newApiState = _ref!.read(watchProvider.notifier);
      _computeTotal();
      _computeProgress();
      _computePercentage();
      newApiState.wholeTotalNotifier.addListener(_computeTotal);
      newApiState.wholeProgressNotifier.addListener(_computeProgress);
      newApiState.wholePercentageNotifier.addListener(_computePercentage);
    }
    // return await _ref.watch(watchProvider.notifier).future;
    return await _ref!.watch(watchProvider.future);
  }

  void retry() {
    bool refreshed = false;
    if (_ref != null) {
      for (final e in List<ApiProvider>.from(_watching)) {
        _ref!.read(e).whenOrNull(
          error: (error, stackTrace) {
            _ref!.read(e.notifier).retry();
            refreshed = true;
          },
        );
      }
    }
    if (!refreshed) {
      _runFuture();
    }
    // try { _ref.refresh(provider); } catch (_) {} // TODO ??? how to refresh THIS provider ??? pretty sure it is not needed
  }

  void refresh() {
    bool refreshed = false;
    if (_ref != null) {
      for (final e in _watching) {
        _ref!.read(e.notifier).refresh();
        refreshed = true;
      }
    }
    if (!refreshed) {
      _runFuture();
    }
    // try { _ref.refresh(provider); } catch (_) {} // TODO ??? how to refresh THIS provider ??? pretty sure it is not needed
  }


  @override
  void dispose() {
    _running = false;
    cancel();
    super.dispose();
  }

  void _runFuture() {
    cancel();
    selfTotalNotifier.value = null;
    selfProgressNotifier.value = null;
    wholePercentageNotifier.value = null;
    try {
      future = _create(this);
      if (future is Future<State>) {
        (future as Future<State>).then(
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
            cancel();
          },
        );
      } else {
        state = AsyncData(future as State);
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stackTrace: stack);
    }
  }

  void cancel() {
    for (final c in _cancelTokens) {
      try { c.cancel(); } catch (_) {}
    }
    _cancelTokens.clear();
  }

  void _computeTotal() {
    double? result = selfTotalNotifier.value;
    if (_ref != null) {
      _watching.forEach((e) {
        final partial = _ref!.read(e.notifier).wholeTotalNotifier.value;
        if (partial!=null) {
          result = (result??0) + partial;
        }
      });
    }
    wholeTotalNotifier.value = result;
  }
  void _computeProgress() {
    double? result = selfProgressNotifier.value;
    if (_ref != null) {
      _watching.forEach((e) {
        final partial = _ref!.read(e.notifier).wholeProgressNotifier.value;
        if (partial!=null) {
          result = (result??0) + partial;
        }
      });
    }
    wholeProgressNotifier.value = result;
  }
  void _computePercentage() {
    // TODO 3 there could be some improvement here, right now wholeNotifiers are ignored
    //    Instead percentage of all dependencies are used, asuming their totals are equal
    //    Percentage could be calculated only from wholeNotifiers,
    //    but this has problems when not all dependencies teport their total/progress
    final total = selfTotalNotifier.value;
    final progress = selfProgressNotifier.value;
    double? result = total==null||progress==null||total==0 ? null : progress/total;
    if (_ref != null) {
      _watching.forEach((e) {
        final partial = _ref!.read(e.notifier).wholePercentageNotifier.value
            ?? _ref!.read(e).maybeWhen<double>(data:(_)=>1, orElse: ()=>0,);
        result = (result??0) + partial;
      });
    }
    wholePercentageNotifier.value = result==null ? null : (result!/(_watching.length+1));
  }

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
    ApiState<T> stateNotifier = ref.watch(provider.notifier);
    AsyncValue<T> value = ref.watch(provider);
    return AsyncValueBuilder<T>(
      asyncValue: value,
      dataBuilder: dataBuilder,
      loadingBuilder: (context) {
        return ValueListenableBuilder<double?>(
          valueListenable: stateNotifier.wholePercentageNotifier,
          builder: (context, percentage, child) {
            return loadingBuilder(context, percentage);
          },
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorBuilder(context, error, stackTrace, stateNotifier.retry);
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