import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


enum APISnackBarBlockUIType {
  never,
  always,
  whileLoading,
  whileLoadingOrError,
}

class APISnackBar<T> extends SnackBarFromZero {

  final ApiState<T> stateNotifier;
  final String? successTitle;
  final String? successMessage;
  final bool? cancelable;
  final APISnackBarBlockUIType blockUIType;

  APISnackBar({
    required super.context,
    required this.stateNotifier,
    this.successTitle,
    this.successMessage,
    this.cancelable,
    super.behaviour,
    super.duration = const Duration(milliseconds: 3000),
    super.width,
    super.showProgressIndicatorForRemainingTime,
    super.onCancel,
    this.blockUIType = APISnackBarBlockUIType.whileLoadingOrError,
    super.key,
  })  : super(
          dismissable: cancelable??false,
          blockUI: blockUIType==APISnackBarBlockUIType.never ? false : true,
        );

  @override
  APISnackBarState<T> createState() => APISnackBarState<T>();

  void updateBlockUI(AsyncValue<T> state) {
    state.whenOrNull(
      error: (error, stackTrace) {
        bool blockUI = this.blockUIType==APISnackBarBlockUIType.always
            || this.blockUIType==APISnackBarBlockUIType.whileLoadingOrError;
        if (blockUI != this.blockUI.value) {
          this.blockUI.value = blockUI;
        }
      },
      data: (data) {
        bool blockUI = this.blockUIType==APISnackBarBlockUIType.always;
        if (blockUI != this.blockUI.value) {
          this.blockUI.value = blockUI;
        }
      },
      loading: () {
        bool blockUI = this.blockUIType==APISnackBarBlockUIType.always
            || this.blockUIType==APISnackBarBlockUIType.whileLoading
            || this.blockUIType==APISnackBarBlockUIType.whileLoadingOrError;
        if (blockUI != this.blockUI.value) {
          this.blockUI.value = blockUI;
        }
      },
    );
  }

}


class APISnackBarState<T> extends ConsumerState<APISnackBar<T>> with TickerProviderStateMixin {

  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    widget.stateNotifier.addListener((state) {
      if (mounted) {
        widget.updateBlockUI(state);
        state.whenOrNull(
          data: (data) {
            if (!widget.blockUI.value) {
              initAnimationController();
            } else {
              try { animationController?.dispose(); } catch(_) {}
              animationController = null;
            }
          },
          loading: () {
            if (!widget.blockUI.value) {
              initAnimationController();
            } else {
              try { animationController?.dispose(); } catch(_) {}
              animationController = null;
            }
          },
        );
      }
    });
  }
  void initAnimationController() {
    if (widget.duration!=null) {
      if (widget.duration!=Duration.zero) {
        animationController = AnimationController(
          vsync: this,
          duration: widget.duration,
        );
        animationController!.addStatusListener((status) {
          if (status==AnimationStatus.completed) {
            widget.dismiss();
          }
        });
        animationController?.forward();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          widget.dismiss();
        });
      }
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = ApiStateBuilder<T>(
      stateNotifier: widget.stateNotifier,
      applyAnimatedContainerFromChildSize: true,
      alignment: Alignment.bottomCenter,
      dataBuilder: (context, data) {
        return resultBuilder(context, null, null);
      },
      errorBuilder: (context, error, stackTrace, onRetry) {
        return resultBuilder(context, error, stackTrace);
      },
      loadingBuilder: loadingBuilder,
      transitionBuilder: (context, child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
    return result;
  }

  Widget loadingBuilder(BuildContext context, ValueListenable<double?>? progress) {
    const type = SnackBarFromZero.loading;
    final icon = SnackBarFromZero.icons[type];
    final actionColor = SnackBarFromZero.colors[type];
    final errorColor = SnackBarFromZero.colors[SnackBarFromZero.error];
    Widget result = Row(
      children: [
        const SizedBox(width: 10,),
        icon,
        const SizedBox(width: 8,),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6,),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleMedium!,
                child: const Text('Procesando...'),
              ),
              // if (message!=null)
              //   const SizedBox(height: 2,),
              // if (message!=null)
              //   DefaultTextStyle(
              //     style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
              //     child: Text(message),
              //   ),
              // if (message!=null)
              //   const SizedBox(height: 2,),
              const SizedBox(height: 6,),
            ],
          ),
        ),
        const SizedBox(width: 8,),
        if (widget.cancelable??false)
          ButtonTheme(
            textTheme: ButtonTextTheme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minWidth: 64.0,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6,),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.stateNotifier.cancel();
                        widget.onCancel?.call();
                        widget.dismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: errorColor,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: Text(FromZeroLocalizations.of(context).translate("cancel").toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6,),
                ],
              ),
            ),
          ),
        const SizedBox(width: 16,),
      ],
    );
    Widget progressIndicator = progress==null
        ? LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation(actionColor),
            backgroundColor: SnackBarFromZero.softColors[type],
          )
        : ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (context, progress, child) {
              return LinearProgressIndicator(
                value: progress,
                valueColor: AlwaysStoppedAnimation(actionColor),
                backgroundColor: SnackBarFromZero.softColors[type],
              );
            },
          );
    result = IntrinsicHeight(
      child: Container(
        color: Color.alphaBlend(SnackBarFromZero.colors[type].withOpacity(0.066), Theme.of(context).cardColor),
        constraints: const BoxConstraints(minHeight: 56,),
        child: Column(
          children: [
            progressIndicator,
            Expanded(child: result),
          ],
        ),
      ),
    );
    result = IconTheme(
      data: Theme.of(context).iconTheme.copyWith(
        color: actionColor,
        size: 32,
      ),
      child: result,
    );
    return buildWrapper(context, result: result,);
  }

  Widget resultBuilder(BuildContext context, Object? error, StackTrace? stackTrace) {
    final type = error==null ? SnackBarFromZero.success : SnackBarFromZero.error;
    final actionColor = SnackBarFromZero.colors[type];
    final splashColor = Theme.of(context).colorScheme.secondary;
    bool showRetry = true, showErrorDetails = false;
    Widget? icon;
    String? title, message;
    if (error==null) {
      showRetry = false;
      title = widget.successTitle;
      message = widget.successMessage;
    } else {
      if (error is String) {
        title = error;
      } else {
        final isRetryable = ApiProviderBuilder.isErrorRetryable(context, error, stackTrace);
        showRetry = !kReleaseMode || isRetryable;
        showErrorDetails = !kReleaseMode || (!isRetryable && ApiProviderBuilder.shouldShowErrorDetails(context, error, stackTrace));
        icon = ApiProviderBuilder.getErrorIcon(context, error, stackTrace);
        title = ApiProviderBuilder.getErrorTitle(context, error, stackTrace);
        message = ApiProviderBuilder.getErrorSubtitle(context, error, stackTrace);
      }
    }
    bool showAcceptInsteadOfClose = error!=null && !showRetry;
    final actions = [
      if (showAcceptInsteadOfClose)
        Expanded(
          child: TextButton(
            onPressed: () {
              widget.onCancel?.call();
              widget.dismiss();
            },
            style: TextButton.styleFrom(
              foregroundColor: splashColor,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(FromZeroLocalizations.of(context).translate("accept_caps").toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.1),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (showRetry)
        Expanded(
          child: TextButton(
            onPressed: () {
              widget.stateNotifier.refresh(null);
            },
            style: TextButton.styleFrom(
              foregroundColor: splashColor,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(FromZeroLocalizations.of(context).translate("retry").toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.1),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (showErrorDetails)
        Expanded(
          child: TextButton(
            onPressed: () {
              final navigatorContext = Navigator.of(widget.context).context;
              widget.dismiss();
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                ApiProviderBuilder.showErrorDetailsDialog(navigatorContext, error, stackTrace);
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyLarge!.color,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Text('Detalles del Error',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.1),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ];
    Widget result = Row(
      children: [
        const SizedBox(width: 10,),
        icon ?? SnackBarFromZero.icons[type],
        const SizedBox(width: 8,),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6,),
              if (title!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16),
                  child: Text(title),
                ),
              if (message!=null)
                const SizedBox(height: 2,),
              if (message!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  child: Text(message),
                ),
              if (message!=null)
                const SizedBox(height: 2,),
              const SizedBox(height: 8,),
            ],
          ),
        ),
        const SizedBox(width: 8,),
        ButtonTheme(
          textTheme: ButtonTextTheme.accent,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          minWidth: 64.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 6,),
                  ...actions,
                  const SizedBox(height: 6,),
                ],
              ),
            ),
          ),
        ),
        if (showAcceptInsteadOfClose)
          const SizedBox(width: 16,),
        if (!showAcceptInsteadOfClose && (error==null||(widget.cancelable??true)))
          SizedBox(
            width: 42, height: double.infinity,
            child: TextButton(
              onPressed: () {
                widget.onCancel?.call();
                widget.dismiss();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyLarge!.color,
                padding: const EdgeInsets.only(right: 10),
              ),
              child: const Icon(Icons.close, size: 24,),
            ),
          ),
      ],
    );
    Widget progressIndicator;
    if (!widget.showProgressIndicatorForRemainingTime){
      progressIndicator = const SizedBox.shrink();
    } else {
      if (animationController==null) {
        progressIndicator = LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation(actionColor),
          backgroundColor: SnackBarFromZero.softColors[type],
        );
      } else {
        progressIndicator = AnimatedBuilder(
          animation: animationController!,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: 1 - animationController!.value,
              valueColor: AlwaysStoppedAnimation(actionColor),
              backgroundColor: SnackBarFromZero.softColors[type],
            );
          },
        );
      }
    }
    result = IntrinsicHeight(
      child: Container(
        color: Color.alphaBlend(SnackBarFromZero.colors[type].withOpacity(0.066), Theme.of(context).cardColor),
        constraints: const BoxConstraints(minHeight: 56,),
        child: Column(
          children: [
            progressIndicator,
            Expanded(child: result),
          ],
        ),
      ),
    );
    result = IconTheme(
      data: Theme.of(context).iconTheme.copyWith(
        color: actionColor,
        size: 32,
      ),
      child: result,
    );
    return buildWrapper(context, result: result, hasActions: actions.isNotEmpty);
  }

  Widget buildWrapper(BuildContext context, {
    required Widget result,
    bool hasActions = false,
  }) {
    final fixed = widget.behaviour!=SnackBarFromZero.behaviourFloating
        && (widget.behaviour==SnackBarFromZero.behaviourFixed
            || ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout)));
    if (!fixed) {
      result = Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        shadowColor: Colors.black,
        child: result,
      );
    }
    result = MouseRegion(
      child: result,
      onEnter: (event) {
        animationController?.stop();
      },
      onExit: (event) {
        animationController?.forward();
      },
    );
    result = Container(
      width: fixed ? double.infinity : (widget.width ?? (512 + (hasActions ? 128 : 0))),
      padding: EdgeInsets.only(bottom: fixed ? 0 : 48,),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64,),
        child: result,
      ),
    );
    return result;
  }

}