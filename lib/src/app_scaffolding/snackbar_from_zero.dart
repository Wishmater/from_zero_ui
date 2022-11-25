
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/src/app_scaffolding/app_content_wrapper.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_host_from_zero.dart';




class SnackBarFromZero extends ConsumerStatefulWidget {

  static const info = 0;
  static const success = 1;
  static const error = 2;
  static const loading = 3;
  static final softColors = <Color>[
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.red.shade300,
    Colors.blue.shade300,
  ];
  static final colors = <Color>[
    Colors.blue.shade500,
    Colors.green.shade500,
    Colors.red.shade500,
    Colors.blue.shade500,
  ];
  static final icons = [
    Icon(Icons.info_outline),
    Icon(Icons.check_circle),
    Icon(Icons.warning),
    SizedBox(
      width: 32, height: 32,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.blue.shade500),
      ),
    ),
  ];
  static const behaviourFixed = 10;
  static const behaviourFloating = 11;

  final BuildContext context;
  final Duration? duration;
  final int? type;
  final int? behaviour;
  final Widget? icon;
  final Widget? title;
  final Widget? message;
  final Widget? content; /// Overrides title and message
  final Widget? progressIndicator;
  final bool showProgressIndicatorForRemainingTime;
  final List<Widget>? actions;
  final double? width;
  final Widget? widget; /// Overrides everything else
  final VoidCallback? onCancel;
  final ValueNotifier<bool> blockUI;
  final bool dismissable;
  final bool pushScreen;
  late final SnackBarControllerFromZero? controller;


  SnackBarFromZero({
    Key? key,
    required this.context,
    this.type,
    this.behaviour,
    this.duration = const Duration(milliseconds: 4000),
    this.width,
    this.icon,
    this.title,
    this.message,
    this.content,
    this.progressIndicator,
    this.showProgressIndicatorForRemainingTime = false,
    this.actions,
    this.widget,
    this.onCancel,
    this.dismissable = true,
    this.pushScreen = false,
    bool blockUI = false,
  })  : this.blockUI = ValueNotifier(blockUI),
        super(key: key,);

  @override
  ConsumerState<SnackBarFromZero> createState() => SnackBarFromZeroState();

  SnackBarControllerFromZero show([BuildContext? context]){
    try {
      if (controller!=null) {
        throw Exception('Already showed this SnackBar');
      }
    } catch (_) {}
    final ref = ((context??this.context).findAncestorStateOfType<SnackBarHostFromZeroState>()?.ref)
                ?? (context??this.context) as WidgetRef;
    final host = ref.read(fromZeroSnackBarHostControllerProvider);
    controller = SnackBarControllerFromZero(
      host: host,
      snackBar: this,
    );
    host.show(this);
    return controller!;
  }

  void dismiss(){
    try {
      controller?.dismiss();
    } catch (_) {}
  }

}

class SnackBarFromZeroState extends ConsumerState<SnackBarFromZero> with TickerProviderStateMixin {

  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    widget.controller?.setState = setState;
    if (widget.duration!=null) {
      animationController = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      animationController!.addStatusListener((status) {
        if (status==AnimationStatus.completed) {
          widget.dismiss();
        }
      });
      animationController!.forward();
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int? type = widget.controller?.type ?? widget.type;
    if (widget.widget!=null) {
      return widget.widget!;
    }
    Color actionColor = type==null
        ? Theme.of(context).brightness==Brightness.light
            ? Theme.of(context).primaryColor
            : Theme.of(context).accentColor
        : SnackBarFromZero.colors[type];
    Widget result = Row(
      children: [
        SizedBox(width: 10,),
        if (widget.icon!=null || type!=null)
          widget.icon ?? SnackBarFromZero.icons[type!],
        SizedBox(width: 8,),
        Expanded(
          child: widget.content ?? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6,),
              if (widget.title!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 16),
                  child: widget.title!,
                ),
              SizedBox(height: 2,),
              if (widget.message!=null)
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(fontSize: 12),
                  child: widget.message!,
                ),
              SizedBox(height: 8,),
            ],
          ),
        ),
        SizedBox(width: 8,),
        if (widget.actions!=null)
          ButtonTheme(
            textTheme: ButtonTextTheme.accent,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minWidth: 64.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 128),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.actions!.length>1)
                      SizedBox(height: 6,),
                    ...widget.actions!.map((e) {
                      if (e is SnackBarAction){
                        SnackBarAction action = e;
                        return Expanded(
                          child: FlatButton(
                            onPressed: () {
                              widget.dismiss();
                              action.onPressed();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(action.label.toUpperCase(),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            textColor: action.textColor ?? actionColor,
                            disabledTextColor: action.disabledTextColor ?? Theme.of(context).disabledColor,
                            hoverColor: (action.textColor ?? actionColor).withOpacity(0.1),
                            highlightColor: (action.textColor ?? actionColor).withOpacity(0.1),
                            splashColor: (action.textColor ?? actionColor).withOpacity(0.3),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }
                      return e;
                    }).toList(),
                    if (widget.actions!.length>1)
                      SizedBox(height: 6,),
                  ],
                ),
              ),
            ),
          ),
        if (widget.dismissable)
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
    if (widget.progressIndicator!=null) {
      progressIndicator = widget.progressIndicator!;
    } else if (!widget.showProgressIndicatorForRemainingTime){
      progressIndicator = SizedBox.shrink();
    } else {
      if (animationController==null) {
        progressIndicator = LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation(actionColor),
          backgroundColor: type==null ? null : SnackBarFromZero.softColors[type],
        );
      } else {
        progressIndicator = AnimatedBuilder(
          animation: animationController!,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: 1 - animationController!.value,
              valueColor: AlwaysStoppedAnimation(actionColor),
              backgroundColor: type==null ? null : SnackBarFromZero.softColors[type],
            );
          },
        );
      }
    }
    result = IntrinsicHeight(
      child: Column(
        children: [
          progressIndicator,
          Expanded(child: result),
        ],
      ),
    );
    final fixed = widget.behaviour!=SnackBarFromZero.behaviourFloating
        && (widget.behaviour==SnackBarFromZero.behaviourFixed
            || ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout)));
    Color backgroundColor = type==null ? Theme.of(context).cardColor
        : Color.alphaBlend(SnackBarFromZero.colors[type].withOpacity(0.066), Theme.of(context).cardColor);
    if (fixed) {
      result = Material(
        color: backgroundColor,
        elevation: 0,
        child: result,
      );
    } else {
      result = Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        color: backgroundColor,
        clipBehavior: Clip.antiAlias,
        elevation: 12,
        shadowColor: Colors.black,
        child: result,
      );
    }
    if (animationController!=null) {
      result = MouseRegion(
        child: result,
        onEnter: (event) {
          animationController?.stop();
        },
        onExit: (event) {
          animationController?.forward();
        },
      );
    }
    result = Container(
      width: fixed ? double.infinity : (widget.width ?? (512 + ((widget.actions?.length??0)==0 ? 0 : 128))),
      padding: EdgeInsets.only(bottom: fixed ? 0 : 48,),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64,),
        child: result,
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