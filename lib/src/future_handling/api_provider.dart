import 'dart:async';
import 'package:animations/animations.dart';
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
    return _ref!.watch(watchProvider.future);
  }

  // a new ref needs to be passed to read the watching notifiers. watch() won'y be called on it.
  bool retry(WidgetRef? widgetRef) {
    bool refreshed = false;
    if ((widgetRef??_ref) != null) {
      try {
        final watchingNotifiers = _watching.map((e) => widgetRef==null
            ? _ref!.read(e.notifier)
            : widgetRef.read(e.notifier));
        for (final e in watchingNotifiers) {
          refreshed = refreshed || e.retry(widgetRef);
        }
      } catch (e, st) {
        // print (e); print (st);
      }
    }
    if (!refreshed && state is AsyncError) {
      _runFuture();
      return true;
    }
    return refreshed;
  }

  void refresh(WidgetRef? widgetRef) {
    bool refreshed = false;
    if ((widgetRef??_ref) != null) {
      final watchingNotifiers = _watching.map((e) => widgetRef==null
          ? _ref!.read(e.notifier)
          : widgetRef.read(e.notifier));
      for (final e in watchingNotifiers) {
        try {
          e.refresh(widgetRef);
          refreshed = true;
        } catch (e, st) {
          // print (e); print (st);
        }
      }
    }
    if (!refreshed) {
      _runFuture();
    }
  }


  @override
  void dispose() {
    _running = false;
    cancel();
    super.dispose();
  }

  void _runFuture() async {
    cancel();
    selfTotalNotifier.value = null;
    selfProgressNotifier.value = null;
    wholePercentageNotifier.value = null;
    state = AsyncValue.loading();
    try {
      future = _create(this);
      if (future is Future<State>) {
        try {
          final event = await future;
          if (_running) {
            state = AsyncValue<State>.data(event);
          }
        } catch (err, stack) {
          if (_running) {
            state = AsyncValue<State>.error(err, stackTrace: stack);
          }
          cancel();
        }
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

  final StateNotifierProviderOverrideMixin<ApiState<T>, AsyncValue<T>> provider;
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
        return errorBuilder(context, error, stackTrace, ()=>stateNotifier.retry(ref));
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
      color: Theme.of(context).indicatorColor,
    );
  }

  static Widget defaultErrorBuilder(BuildContext context, Object? error, StackTrace? stackTrace, VoidCallback? onRetry) {
    // print(error);
    // print(stackTrace);
    if (error is DioError) {
      if (error.type==DioErrorType.RESPONSE) {
        if (error.response.statusCode==404) {
          return ErrorSign(
            key: ValueKey(error),
            icon: const Icon(Icons.error_outline),
            title: 'Recurso no Encontrado', // TODO 3 internationalize
            subtitle: 'Por favor, notifique a su administrador de sistema', // TODO 3 internationalize
            onRetry: onRetry,
          );
        } else if (error.response.statusCode==400) {
          return ErrorSign(
            key: ValueKey(error),
            icon: const Icon(Icons.do_disturb_on_outlined),
            title: 'Error de Autenticación', // TODO 3 internationalize
            subtitle: 'Intente cerrar la aplicación y autenticarse de nuevo.', // TODO 3 internationalize
          );
        } else if (error.response.statusCode==403) {
          return ErrorSign(
            key: ValueKey(error),
            icon: const Icon(Icons.do_disturb_on_outlined),
            title: 'Error de Autorización', // TODO 3 internationalize
            subtitle: 'Usted no tiene permiso para acceder al recurso solicitado.', // TODO 3 internationalize
          );
        } else {
          return ErrorSign(
            key: ValueKey(error),
            icon: const Icon(Icons.report_problem_outlined),
            title: 'Error Interno del Servidor', // TODO 3 internationalize
            subtitle: 'Por favor, notifique a su administrador de sistema', // TODO 3 internationalize
            retryButton: _buildErrorDetailsButton(context, error, stackTrace),
          );
        }
      } else {
        return ErrorSign(
          key: ValueKey(error),
          icon: const Icon(MaterialCommunityIcons.wifi_off),
          title: FromZeroLocalizations.of(context).translate("error_connection"),
          subtitle: FromZeroLocalizations.of(context).translate("error_connection_details"),
          onRetry: onRetry,
        );
      }
    } else {
      return ErrorSign(
        key: ValueKey(error),
        icon: const Icon(Icons.report_problem_outlined),
        title: "Error Inesperado", // TODO 3 internationalize
        subtitle: "Por favor, notifique a su administrador de sistema", // TODO 3 internationalize
        retryButton: _buildErrorDetailsButton(context, error, stackTrace),
      );
    }
  }
  static Widget _buildErrorDetailsButton(BuildContext context, Object? error, StackTrace? stackTrace) {
    return TextButton(
      style: TextButton.styleFrom(
          primary: Theme.of(context).textTheme.bodyText1!.color!,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 8,),
          Icon(Icons.info_outlined),
          SizedBox(width: 4,),
          Text('Detalles del Error', // TODO 3 internationalize
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.1),
          ),
          SizedBox(width: 8,),
        ],
      ),
      onPressed: () {
        showModal(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Detalles del Error'),
              content: SelectableText("$error\r\n\r\n$stackTrace}"),
              actions: [
                TextButton(
                  child: Text('Cerrar'), // TODO 3 internationalize
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

}


class ApiProviderMultiBuilder<T> extends ConsumerWidget {

  final List<StateNotifierProviderOverrideMixin<ApiState<T>, AsyncValue<T>>> providers;
  final DataMultiBuilder<T> dataBuilder;
  final ApiLoadingBuilder loadingBuilder;
  final ApiErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;

  const ApiProviderMultiBuilder({
    Key? key,
    required this.providers,
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
    List<ApiState<T>> stateNotifiers = [];
    List<AsyncValue<T>> values = [];
    for (final e in providers) {
      stateNotifiers.add(ref.watch(e.notifier));
      values.add(ref.watch(e));
    }
    return AsyncValueMultiBuilder<T>(
      asyncValues: values,
      dataBuilder: dataBuilder,
      loadingBuilder: (context) {
        final listenable = MultiValueListenable(stateNotifiers.map((e) => e.wholePercentageNotifier).toList());
        return AnimatedBuilder(
          animation: listenable,
          builder: (context, child) {
            double? percentage;
            try {
              final meaningfulValues = listenable.values.whereType<double>().toList();
              percentage = meaningfulValues.reduce((v, e) => v+e) / meaningfulValues.length;
            } catch (_) {}
            return loadingBuilder(context, percentage);
          },
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorBuilder(context, error, stackTrace, () {
          for (final e in stateNotifiers) {
            e.retry(ref);
          }
        });
      },
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
    );
  }

}


class MultiValueListenable<T> extends ChangeNotifier {
  List<ValueNotifier<T>> _notifiers;
  MultiValueListenable(this._notifiers) {
    for (final e in _notifiers) {
      e.addListener(() => notifyListeners());
    }
  }
  List<T> get values => _notifiers.map((e) => e.value).toList();
}