
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';


class SnackBarFromZero extends SnackBar{

  static const info = 0;
  static const success = 1;
  static const error = 2;
  static final colors = <Color>[
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.red.shade300,
  ];
  static final icons = [
    Icons.info_outline,
    Icons.check_circle,
    Icons.warning,
  ];


  BuildContext context;

  SnackBarFromZero({
    required this.context,
    required int type,
    Duration duration = const Duration(milliseconds: 4000),
    Widget? message,
    Widget? title,
    List<Widget> actions = const [],
  }) : super(
      duration: duration,
      elevation: 0,
      width: Provider.of<ScreenFromZero>(context, listen: false).displayMobileLayout ? null : ScaffoldFromZero.screenSizeMedium,
      behavior: Provider.of<ScreenFromZero>(context, listen: false).displayMobileLayout ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
      padding: EdgeInsets.all(0),
      shape: Provider.of<ScreenFromZero>(context, listen: false).displayMobileLayout ? null
          : RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
      content: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 56,
          ),
          child: Row(
            children: [
              SizedBox(width: 8,),
              Icon(
                icons[type],
                color: colors[type],
                size: 32,
              ),
              SizedBox(width: 8,),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6,),
                    if (title!=null)
                      DefaultTextStyle(
                        style: TextStyle(fontSize: 16.0, color: _inverseColor(context)),
                        child: title,
                      ),
                    SizedBox(height: 2,),
                    if (message!=null)
                      DefaultTextStyle(
                        style: TextStyle(fontSize: 14.0, color: _inverseColor(context)),
                        child: message,
                      ),
                    SizedBox(height: 6,),
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
                      if (actions.length>1)
                        SizedBox(height: 6,),
                      ...actions.map((e) {
                        if (e is SnackBarAction){
                          SnackBarAction action = e;
                          return Expanded(
                            child: FlatButton(
                              onPressed: action.onPressed==null ? null : (){
                                Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                                action.onPressed();
                              },
                              child: Text(action.label.toUpperCase(),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              textColor: action.textColor ?? colors[type],
                              disabledTextColor: action.disabledTextColor ?? _inverseColor(context).withOpacity(0.6),
                              hoverColor: (action.textColor ?? colors[type]).withOpacity(0.1),
                              highlightColor: (action.textColor ?? colors[type]).withOpacity(0.1),
                              splashColor: (action.textColor ?? colors[type]).withOpacity(0.3),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        }
                        return e;
                      }).toList(),
                      if (actions.length>1)
                        SizedBox(height: 6,),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 36, height: double.infinity,
                child: FlatButton(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.close, color: _inverseColor(context),),
                  hoverColor: _inverseColor(context).withOpacity(0.1),
                  highlightColor: _inverseColor(context).withOpacity(0.3),
                  splashColor: _inverseColor(context).withOpacity(0.3),
                  focusColor: _inverseColor(context).withOpacity(0.1),
                  onPressed: () {
                    Scaffold.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
  );

  var controller;
  void show([BuildContext? context]){
    controller = Scaffold.of(context??this.context).showSnackBar(this);
  }
  void dismiss(){
    if (controller!=null) controller.close();
  }


  double passedMilliseconds = 0;


//  // Get a flushbar that shows the progress of a async computation.
//  static Flushbar createLoading(
//      { String message,
//        @required LinearProgressIndicator linearProgressIndicator,
//        String title,
//        Duration duration = defaultDuration,
//        AnimationController progressIndicatorController,
//        Color progressIndicatorBackgroundColor}) {
//    return Flushbar(
//      title: title,
//      message: message,
//      icon: Icon(
//        Icons.cloud_upload,
//        color: Colors.blue[300],
//      ),
//      duration: duration,
//      showProgressIndicator: true,
//      progressIndicatorController: progressIndicatorController,
//      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
//    );
//  }

//  /// Get a flushbar that shows an user input form.
//  static Flushbar createInputFlushbar({@required Form textForm}) {
//    return Flushbar(
//      duration: null,
//      userInputForm: textForm,
//    );
//  }


  static Color _inverseColor(BuildContext context) {
    return Theme.of(context).brightness==Brightness.light ? Colors.white : Colors.black;
  }

}