import 'dart:async';
import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/future_handling/async_value_builder.dart';
import 'package:from_zero_ui/src/future_handling/future_handling.dart';
import 'package:riverpod/riverpod.dart';


typedef ApiProvider<T> = AutoDisposeStateNotifierProvider<ApiState<T>, AsyncValue<T>>;
typedef ApiProviderFamily<T, P> = AutoDisposeStateNotifierProviderFamily<ApiState<T>, AsyncValue<T>, P>;

class ApiState<State> extends StateNotifier<AsyncValue<State>> {

  // StateNotifierProviderRef<ApiState<State>, AsyncValue<State>> _ref;
  AutoDisposeRef? _ref;
  Future<State> Function(ApiState<State>) _create;
  late Future<State> future;
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

  ApiState(AutoDisposeRef ref, this._create,)
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
    return _ref!.watch(watchProvider.notifier).future;
  }

  // a new ref needs to be passed to read the watching notifiers. watch() won't be called on it.
  bool retry(WidgetRef? widgetRef, [ProviderBase? providerForInvalidationInsteadOfRefresh]) {
    bool refreshed = false;
    if ((widgetRef??_ref) != null) {
      try {
        final watchingNotifiers = {
          for (final e in _watching)
            e: widgetRef==null
                ? _ref!.read(e.notifier)
                : widgetRef.read(e.notifier)
        };
        for (final e in watchingNotifiers.keys) {
          refreshed = refreshed || watchingNotifiers[e]!.retry(widgetRef, e);
        }
      } catch (_) { }
    }
    if (!refreshed && state is AsyncError) {
      if (widgetRef!=null && providerForInvalidationInsteadOfRefresh!=null) {
        widgetRef.invalidate(providerForInvalidationInsteadOfRefresh);
      } else {
        _runFuture();
      }
      return true;
    }
    return refreshed;
  }

  void refresh(WidgetRef? widgetRef, [ProviderBase? providerForInvalidationInsteadOfRefresh]) {
    bool refreshed = false;
    if ((widgetRef??_ref) != null) {
      final watchingNotifiers = {
        for (final e in _watching)
          e: widgetRef==null
              ? _ref!.read(e.notifier)
              : widgetRef.read(e.notifier)
      };
      for (final e in watchingNotifiers.keys) {
        try {
          watchingNotifiers[e]!.refresh(widgetRef, e);
          refreshed = true;
        } catch (_) { }
      }
    }
    if (!refreshed) {
      if (widgetRef!=null && providerForInvalidationInsteadOfRefresh!=null) {
        widgetRef.invalidate(providerForInvalidationInsteadOfRefresh);
      } else {
        _runFuture();
      }
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
    if (result!=null && _ref!=null) {
      for (final e in _watching) {
        final partial = _ref!.read(e.notifier).wholeTotalNotifier.value
            ?? _ref!.read(e).maybeWhen<double?>(data:(_)=>0, orElse: ()=>null,);
        if (partial!=null) {
          result = (result??0) + partial;
        } else {
          result = null;
          break;
        }
      }
    }
    wholeTotalNotifier.value = result;
  }
  void _computeProgress() {
    double? result = selfProgressNotifier.value;
    if (result!=null && _ref!=null) {
      for (final e in _watching) {
        final partial = _ref!.read(e.notifier).wholeProgressNotifier.value
            ?? _ref!.read(e).maybeWhen<double?>(data:(_)=>0, orElse: ()=>null,);
        if (partial!=null) {
          result = (result??0) + partial;
        } else {
          result = null;
          break;
        }
      }
    }
    wholeProgressNotifier.value = result;
  }
  void _computePercentage() {
    // Percentage calculated only from wholeNotifiers
    double? total = wholeTotalNotifier.value;
    double? progress = wholeProgressNotifier.value;
    double? result = total==null||total==0 ? null
        : (progress??0) / total;
    if (result==null && _ref!=null) {
      // Percentage of all dependencies are used, asuming their totals are equal
      total = selfTotalNotifier.value;
      progress = selfProgressNotifier.value;
      result = total==null ? null
          : progress==null||total==0 ? 0
          : progress/total;
      final allWatching = List<ApiProvider>.from(_watching);
      for (int i=0; i<allWatching.length; i++) {
        for (final e in _ref!.read(allWatching[i].notifier)._watching) {
          if (!allWatching.contains(e)) {
            allWatching.add(e);
          }
        }
      }
      bool allNull = result==null;
      allWatching.forEach((e) {
        final notifier = _ref!.read(e.notifier);
        double? partialProgress = notifier.selfProgressNotifier.value;
        double? partialTotal = notifier.selfTotalNotifier.value;
        double? partial = partialTotal==null ? null
            : partialTotal==0||partialProgress==null ? 0
            : partialProgress/partialTotal;
        allNull = allNull && partial==null;
        partial ??= _ref!.read(e).maybeWhen<double>(data:(_)=>1, orElse: ()=>0,);
        result = (result??0) + partial;
      });
      result = result==null||allNull ? null : (result!/(allWatching.length+1));
    }
    wholePercentageNotifier.value = result;
  }

}








typedef ApiLoadingBuilder = Widget Function(BuildContext context, ValueListenable<double?>? progress);
typedef ApiErrorBuilder = Widget Function(BuildContext context, Object error, StackTrace? stackTrace, VoidCallback? onRetry);

class ApiProviderBuilder<T> extends ConsumerWidget {

  final AutoDisposeStateNotifierProvider<ApiState<T>, AsyncValue<T>> provider;
  final DataBuilder<T> dataBuilder;
  final ApiLoadingBuilder loadingBuilder;
  final ApiErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

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
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final routeBase = context.findAncestorStateOfType<OnlyOnActiveBuilderState>();
    // if (routeBase!=null) {
    //   log ('$routeBase -- ${routeBase.isActiveRoute(context)}'); // should be isActive && !ref.isCalled(provider)
    //   if (!routeBase.isActiveRoute(context)) {
    //     return SizedBox.shrink();
    //   }
    // }
    ApiState<T> stateNotifier = ref.watch(provider.notifier);
    AsyncValue<T> value = ref.watch(provider);
    return AsyncValueBuilder<T>(
      asyncValue: stateNotifier.state, // using stateNotifier.state instead of value because value is kept when realoading, so loading state is never shown
      dataBuilder: dataBuilder,
      alignment: alignment,
      loadingBuilder: (context) {
        return loadingBuilder(context, stateNotifier.wholePercentageNotifier);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorBuilder(context, error, stackTrace, ()=>stateNotifier.retry(ref));
      },
      transitionBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionInCurve: transitionInCurve,
      transitionOutCurve: transitionOutCurve,
      applyAnimatedContainerFromChildSize: applyAnimatedContainerFromChildSize,
    );
  }

  static Widget defaultLoadingBuilder(BuildContext context, ValueListenable<double?>? progress) {
    final color = Theme.of(context).splashColor.withOpacity(1);
    if (progress==null) {
      return LoadingSign(
        color: color,
      );
    } else {
      return ValueListenableBuilder<double?>(
        valueListenable: progress,
        builder: (context, progress, child) {
          return LoadingSign(
            value: progress,
            color: Theme.of(context).splashColor.withOpacity(1),
          );
        },
      );
    }
  }

  static Widget defaultErrorBuilder(BuildContext context, Object? error, StackTrace? stackTrace, VoidCallback? onRetry) {
    final isRetryable = isErrorRetryable(context, error, stackTrace);
    return ErrorSign(
      key: ValueKey(error),
      icon: getErrorIcon(context, error, stackTrace),
      title: getErrorTitle(context, error, stackTrace),
      subtitle: getErrorSubtitle(context, error, stackTrace),
      onRetry: !kReleaseMode || isRetryable ? onRetry : null,
      retryButton: !kReleaseMode || (!isRetryable && shouldShowErrorDetails(context, error, stackTrace))
              ? buildErrorDetailsButton(context, error, stackTrace, onRetry)
              : null,
    );
  }
  static Widget getErrorIcon(BuildContext context, Object? error, StackTrace? stackTrace) {
    if (error is DioError) {
      if (error.type==DioErrorType.response) {
        if (error.response!.statusCode==404) {
          return const Icon(Icons.error_outline);
        } else if (error.response!.statusCode==400) {
          return const Icon(Icons.do_disturb_on_outlined);
        } else if (error.response!.statusCode==403) {
          return const Icon(Icons.do_disturb_on_outlined);
        } else {
          return const Icon(Icons.report_problem_outlined);
        }
      } else {
        return const Icon(MaterialCommunityIcons.wifi_off);
      }
    } else {
      return const Icon(Icons.report_problem_outlined);
    }
  }
  static String getErrorTitle(BuildContext context, Object? error, StackTrace? stackTrace) {
    // TODO 3 internationalize
    if (error is DioError) {
      if (error.type==DioErrorType.response) {
        if (error.response!.statusCode==404) {
          return 'Recurso no Encontrado';
        } else if (error.response!.statusCode==400) {
          return error.response!.data is String
              ? error.response!.data.toString()
              : utf8.decode(error.response!.data);
        } else if (error.response!.statusCode==403) {
          return 'Error de Autorización';
        } else {
          return 'Error Interno del Servidor';
        }
      } else {
        return FromZeroLocalizations.of(context).translate("error_connection");
      }
    } else {
      return "Error Inesperado";
    }
  }
  static String? getErrorSubtitle(BuildContext context, Object? error, StackTrace? stackTrace) {
    // TODO 3 internationalize
    if (error is DioError) {
      if (error.type==DioErrorType.response) {
        if (error.response!.statusCode==404) {
          return 'Por favor, notifique a su administrador de sistema';
        } else if (error.response!.statusCode==400) {
          return null;
        } else if (error.response!.statusCode==403) {
          return 'Usted no tiene permiso para acceder al recurso solicitado';
        } else {
          return 'Por favor, notifique a su administrador de sistema';
        }
      } else {
        return FromZeroLocalizations.of(context).translate("error_connection_details");
      }
    } else {
      return "Por favor, notifique a su administrador de sistema";
    }
  }
  static bool isErrorRetryable(BuildContext context, Object? error, StackTrace? stackTrace) {
    if (error is DioError) {
      if (error.type==DioErrorType.response) {
        if (error.response!.statusCode==404) {
          return false;
        } else if (error.response!.statusCode==400) {
          return false;
        } else if (error.response!.statusCode==403) {
          return false;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } else {
      return false;
    }
  }
  static bool shouldShowErrorDetails(BuildContext context, Object? error, StackTrace? stackTrace) {
    if (error is DioError) {
      if (error.type==DioErrorType.response) {
        if (error.response!.statusCode==404) {
          return false;
        } else if (error.response!.statusCode==400) {
          return false;
        } else if (error.response!.statusCode==403) {
          return false;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } else {
      return true;
    }
  }
  static Widget buildErrorDetailsButton(BuildContext context, Object? error, StackTrace? stackTrace, [VoidCallback? onRetry]) {
    Widget result = TextButton(
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
      onPressed: () => showErrorDetailsDialog(context, error, stackTrace),
    );
    if (!kReleaseMode && onRetry!=null) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          result,
          SizedBox(height: 8,),
          TextButton(
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
          )
        ],
      );
    }
    return result;
  }
  static void showErrorDetailsDialog(BuildContext context, Object? error, StackTrace? stackTrace) {
    showModal(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalles del Error'),
          content: SelectableText("$error\r\n\r\n$stackTrace}"),
          insetPadding: EdgeInsets.all(16),
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
  }

}

class SliverApiProviderBuilder<T> extends ApiProviderBuilder<T> {

  SliverApiProviderBuilder({
    required super.provider,
    required super.dataBuilder,
    ApiLoadingBuilder loadingBuilder = SliverApiProviderBuilder.defaultLoadingBuilder,
    ApiErrorBuilder errorBuilder = SliverApiProviderBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );

  static Widget defaultLoadingBuilder(BuildContext context, ValueListenable<double?>? progress) {
    return SliverToBoxAdapter(
      child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
    );
  }

  static Widget defaultErrorBuilder(BuildContext context, Object? error, StackTrace? stackTrace, VoidCallback? onRetry) {
    return SliverToBoxAdapter(
      child: ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace, onRetry),
    );
  }

}



class ApiProviderMultiBuilder<T> extends ConsumerWidget {

  final List<AutoDisposeStateNotifierProvider<ApiState<T>, AsyncValue<T>>> providers;
  final DataMultiBuilder<T> dataBuilder;
  final ApiLoadingBuilder loadingBuilder;
  final ApiErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

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
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<ApiState<T>> stateNotifiers = [];
    List<AsyncValue<T>> values = [];
    for (final e in providers) {
      final stateNotifier = ref.watch(e.notifier);
      ref.watch(e);
      stateNotifiers.add(stateNotifier);
      values.add(stateNotifier.state); // using stateNotifier.state instead of value because value is kept when realoading, so loading state is never shown
    }
    final listenables = stateNotifiers.map((e) => e.wholePercentageNotifier);
    final unifiedListenable = UnitedValueListenable(listenables, (values) {
      double? percentage;
      try {
        final meaningfulValues = values.whereType<double>().toList();
        percentage = meaningfulValues.isEmpty ? null
            : meaningfulValues.reduce((v, e) => v+e) / meaningfulValues.length;
      } catch (_) {}
      return percentage;
    });
    return AsyncValueMultiBuilder<T>(
      asyncValues: values,
      dataBuilder: dataBuilder,
      alignment: alignment,
      loadingBuilder: (context) {
        return loadingBuilder(context, unifiedListenable);
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
      applyAnimatedContainerFromChildSize: applyAnimatedContainerFromChildSize,
    );
  }

}

class SliverApiProviderMultiBuilder<T> extends ApiProviderMultiBuilder<T> {
  SliverApiProviderMultiBuilder({
    required super.providers,
    required super.dataBuilder,
    ApiLoadingBuilder loadingBuilder = SliverApiProviderBuilder.defaultLoadingBuilder,
    ApiErrorBuilder errorBuilder = SliverApiProviderBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}



class MultiValueListenable<T> extends ChangeNotifier {
  final Iterable<ValueListenable<T>> _listenables;
  MultiValueListenable(this._listenables) {
    for (final e in _listenables) {
      e.addListener(() => notifyListeners());
    }
  }
  List<T> get values => _listenables.map((e) => e.value).toList();
}
class UnitedValueListenable<T> extends ValueListenable<T> {
  final Iterable<ValueListenable<T>> _listenables;
  final T Function(Iterable<T>) _unificator;
  UnitedValueListenable(this._listenables, this._unificator);
  @override
  void addListener(VoidCallback listener) {
    for (final e in _listenables) {
      e.addListener(listener);
    }
  }
  @override
  void removeListener(VoidCallback listener) {
    for (final e in _listenables) {
      e.addListener(listener);
    }
  }
  T get value => _unificator(_listenables.map((e) => e.value));
}



class ApiStateBuilder<T> extends ConsumerStatefulWidget {

  final ApiState<T> stateNotifier;
  final DataBuilder<T> dataBuilder;
  final ApiLoadingBuilder loadingBuilder;
  final ApiErrorBuilder errorBuilder;
  final FutureTransitionBuilder transitionBuilder;
  final Duration transitionDuration;
  final Curve transitionInCurve;
  final Curve transitionOutCurve;
  final bool applyAnimatedContainerFromChildSize;
  final Alignment? alignment; // used for animated switches

  const ApiStateBuilder({
    Key? key,
    required this.stateNotifier,
    required this.dataBuilder,
    this.loadingBuilder = ApiProviderBuilder.defaultLoadingBuilder,
    this.errorBuilder = ApiProviderBuilder.defaultErrorBuilder,
    this.transitionBuilder = AsyncValueBuilder.defaultTransitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionInCurve = Curves.easeOutCubic,
    this.transitionOutCurve = Curves.easeInCubic,
    this.applyAnimatedContainerFromChildSize = false,
    this.alignment,
  }) : super(key: key);

  @override
  _ApiStateBuilderState<T> createState() => _ApiStateBuilderState<T>();

}

class _ApiStateBuilderState<T> extends ConsumerState<ApiStateBuilder<T>> {

  late AsyncValue<T> value;

  @override
  void initState() {
    super.initState();
    value = widget.stateNotifier.state;
    widget.stateNotifier.addListener((state) {
      if (mounted) {
        setState(() {
          value = state;
        });
      }
    }, fireImmediately: false,);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<T>(
      asyncValue: value,
      dataBuilder: widget.dataBuilder,
      alignment: widget.alignment,
      loadingBuilder: (context) {
        return widget.loadingBuilder(context, widget.stateNotifier.wholePercentageNotifier);
      },
      errorBuilder: (context, error, stackTrace) {
        return widget.errorBuilder(context, error, stackTrace, () => widget.stateNotifier.retry(ref));
      },
      transitionBuilder: widget.transitionBuilder,
      transitionDuration: widget.transitionDuration,
      transitionInCurve: widget.transitionInCurve,
      transitionOutCurve: widget.transitionOutCurve,
      applyAnimatedContainerFromChildSize: widget.applyAnimatedContainerFromChildSize,
    );
  }

}

class SliverApiStateBuilder<T> extends ApiStateBuilder<T> {
  SliverApiStateBuilder({
    required super.stateNotifier,
    required super.dataBuilder,
    ApiLoadingBuilder loadingBuilder = SliverApiProviderBuilder.defaultLoadingBuilder,
    ApiErrorBuilder errorBuilder = SliverApiProviderBuilder.defaultErrorBuilder,
  }) : super(
    transitionDuration: Duration.zero,
    applyAnimatedContainerFromChildSize: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}

