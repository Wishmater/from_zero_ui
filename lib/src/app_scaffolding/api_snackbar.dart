import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_from_zero.dart';


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
  final bool cancelable;
  final APISnackBarBlockUIType blockUIType;

  APISnackBar({
    Key? key,
    required BuildContext context,
    required this.stateNotifier,
    this.successTitle,
    this.successMessage,
    this.cancelable = true,
    int? behaviour,
    Duration? duration = const Duration(milliseconds: 3000),
    double? width,
    bool showProgressIndicatorForRemainingTime = false,
    VoidCallback? onCancel,
    this.blockUIType = APISnackBarBlockUIType.whileLoadingOrError,
  })  : super(
          key: key,
          context: context,
          behaviour: behaviour,
          duration: duration,
          width: width,
          dismissable: cancelable,
          showProgressIndicatorForRemainingTime: showProgressIndicatorForRemainingTime,
          onCancel: onCancel,
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
      dataBuilder: (context, data) {
        return resultBuilder(context, null, null);
      },
      errorBuilder: (context, error, stackTrace, onRetry) {
        return resultBuilder(context, error, stackTrace);
      },
      loadingBuilder: (context, progress) {
        return loadingBuilder(context, progress);
      },
      transitionBuilder: (context, child, animation) {
        return FadeTransition(
          child: child,
          opacity: animation,
        );
      },
    );
    final fixed = widget.behaviour!=SnackBarFromZero.behaviourFloating
        && (widget.behaviour==SnackBarFromZero.behaviourFixed
            || ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout)));
    if (!fixed) {
      result = Card(
        shape: RoundedRectangleBorder(
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
      width: fixed ? double.infinity : (widget.width ?? 512),
      padding: EdgeInsets.only(bottom: fixed ? 0 : 48,),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64,),
        child: result,
      ),
    );
    return result;
  }

  Widget loadingBuilder(BuildContext context, double? progress) {
    final type = SnackBarFromZero.loading;
    final icon = SnackBarFromZero.icons[type];
    final actionColor = SnackBarFromZero.colors[type];
    final errorColor = SnackBarFromZero.colors[SnackBarFromZero.error];
    Widget result = Row(
      children: [
        SizedBox(width: 10,),
        icon,
        SizedBox(width: 8,),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6,),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.subtitle1!,
                child: Text('Procesando...'),
              ),
              SizedBox(height: 2,),
              // if (message!=null)
              //   DefaultTextStyle(
              //     style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 12),
              //     child: Text(message),
              //   ),
              SizedBox(height: 8,),
            ],
          ),
        ),
        SizedBox(width: 8,),
        if (widget.cancelable)
          ButtonTheme(
            textTheme: ButtonTextTheme.accent,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minWidth: 64.0,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 6,),
                  Expanded(
                    child: FlatButton(
                      onPressed: () {
                        widget.stateNotifier.cancel();
                        widget.onCancel?.call();
                        widget.dismiss();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(FromZeroLocalizations.of(context).translate("cancel").toUpperCase(),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: errorColor,
                      disabledTextColor: Theme.of(context).disabledColor,
                      hoverColor: errorColor.withOpacity(0.1),
                      highlightColor: errorColor.withOpacity(0.1),
                      splashColor: errorColor.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(height: 6,),
                ],
              ),
            ),
          ),
        SizedBox(width: 16,),
      ],
    );
    Widget progressIndicator = LinearProgressIndicator(
      value: progress,
      valueColor: AlwaysStoppedAnimation(actionColor),
      backgroundColor: SnackBarFromZero.softColors[type],
    );
    result = IntrinsicHeight(
      child: Container(
        color: Color.alphaBlend(SnackBarFromZero.colors[type].withOpacity(0.066), Theme.of(context).cardColor),
        constraints: BoxConstraints(minHeight: 56,),
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
    return result;
  }

  Widget resultBuilder(BuildContext context, Object? error, StackTrace? stackTrace) {
    final type = error==null ? SnackBarFromZero.success : SnackBarFromZero.error;
    final actionColor = SnackBarFromZero.colors[type];
    final splashColor = Theme.of(context).splashColor.withOpacity(1);
    bool showRetry = true;
    Widget? icon;
    String? title, message;
    if (error==null) {
      showRetry = false;
      title = widget.successTitle;
      message = widget.successMessage;
    } else {
      log ('Error caught by API snackbar:');
      log (error, stackTrace: stackTrace, isError: true); // TODO 2 remove this after implementing details button
      if (error is String) {
        title = error;
      } else {
        showRetry = ApiProviderBuilder.isErrorRetryable(context, error, stackTrace);
        icon = ApiProviderBuilder.getErrorIcon(context, error, stackTrace);
        title = ApiProviderBuilder.getErrorTitle(context, error, stackTrace);
        message = ApiProviderBuilder.getErrorSubtitle(context, error, stackTrace);
      }
    }
    bool showAcceptInsteadOfClose = error!=null && !showRetry;
    Widget result = Row(
      children: [
        SizedBox(width: 10,),
        icon ?? SnackBarFromZero.icons[type],
        SizedBox(width: 8,),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6,),
              if (title!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 16),
                  child: Text(title),
                ),
              SizedBox(height: 2,),
              if (message!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 12),
                  child: Text(message),
                ),
              SizedBox(height: 8,),
            ],
          ),
        ),
        SizedBox(width: 8,),
        ButtonTheme(
          textTheme: ButtonTextTheme.accent,
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          minWidth: 64.0,
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 6,),
                if (showAcceptInsteadOfClose)
                  Expanded(
                    child: FlatButton(
                      onPressed: () {
                        widget.onCancel?.call();
                        widget.dismiss();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(FromZeroLocalizations.of(context).translate("accept_caps").toUpperCase(),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: splashColor,
                      disabledTextColor: Theme.of(context).disabledColor,
                      hoverColor: splashColor.withOpacity(0.1),
                      highlightColor: splashColor.withOpacity(0.1),
                      splashColor: splashColor.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (showRetry)
                  Expanded(
                    child: FlatButton(
                      onPressed: () {
                        widget.stateNotifier.refresh(null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(FromZeroLocalizations.of(context).translate("retry").toUpperCase(),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: splashColor,
                      disabledTextColor: Theme.of(context).disabledColor,
                      hoverColor: splashColor.withOpacity(0.1),
                      highlightColor: splashColor.withOpacity(0.1),
                      splashColor: splashColor.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                SizedBox(height: 6,),
              ],
            ),
          ),
        ),
        if (showAcceptInsteadOfClose)
          SizedBox(width: 16,),
        if (!showAcceptInsteadOfClose && (error==null||widget.dismissable))
          SizedBox(
            width: 42, height: double.infinity,
            child: FlatButton(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.close, size: 24,),
              onPressed: () {
                widget.onCancel?.call();
                widget.dismiss();
              },
            ),
          ),
      ],
    );
    Widget progressIndicator;
    if (!widget.showProgressIndicatorForRemainingTime){
      progressIndicator = SizedBox.shrink();
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
        constraints: BoxConstraints(minHeight: 56,),
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
    return result;
  }

}