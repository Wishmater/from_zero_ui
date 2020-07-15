import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class FlushbarHelperFromZero {

  static const defaultDuration = const Duration(seconds: 5);
  static final infoColor = Colors.blue[300];
  static final successColor = Colors.green[300];
  static final errorColor = Colors.red[300];
  static final recommendedInfoButtonTextStyle = TextStyle(
    fontSize: 15.0,
    color: infoColor,
    fontWeight: FontWeight.bold,
  );
  static final recommendedSuccessButtonTextStyle = TextStyle(
    fontSize: 15.0,
    color: successColor,
    fontWeight: FontWeight.bold,
  );
  static final recommendedErrorButtonTextStyle = TextStyle(
    fontSize: 15.0,
    color: errorColor,
    fontWeight: FontWeight.bold,
  );
  // TODO implement FlushbarButton ?? or pass the actions as String=>(){}

  /// Get a success notification flushbar.
  static Flushbar createSuccess(
      {@required String message,
        String title,
        Duration duration = defaultDuration,
        List<Widget> actions = const []}) {
    var flush;
    flush =  Flushbar(
      titleText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.0,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      messageText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          message,
          style: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
      ),
      icon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          Icons.check_circle,
          color: successColor,
          size: 32,
        ),
      ),
      duration: duration,
      animationDuration: Duration(milliseconds: 300),
      maxWidth: ScaffoldFromZero.screenSizeMedium,
      isDismissible: true,
      margin: EdgeInsets.only(left: 12, right: 12, bottom: 32),
      borderRadius: 999999,
      boxShadows: [BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 3.0,)],
      mainButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: actions,
              ),
              IconButton(
                icon: Icon(Icons.close),
                splashRadius: 16,
                color: Colors.white,
                hoverColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.3),
                splashColor: Colors.white.withOpacity(0.3),
                focusColor: Colors.white.withOpacity(0.3),
                onPressed: () {
                  flush.dismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
    return flush;
  }

  /// Get an information notification flushbar
  static Flushbar createInformation(
      {@required String message,
        String title,
        Duration duration = defaultDuration,
        List<Widget> actions = const []}) {
    var flush;
    flush =  Flushbar(
      titleText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.0,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      messageText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          message,
          style: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
      ),
      icon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          Icons.info_outline,
          color: infoColor,
          size: 32,
        ),
      ),
      duration: duration,
      animationDuration: Duration(milliseconds: 300),
      maxWidth: ScaffoldFromZero.screenSizeMedium,
      isDismissible: true,
      margin: EdgeInsets.only(left: 12, right: 12, bottom: 32),
      borderRadius: 999999,
      boxShadows: [BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 3.0,)],
      mainButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: actions,
              ),
              IconButton(
                icon: Icon(Icons.close),
                splashRadius: 16,
                color: Colors.white,
                hoverColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.3),
                splashColor: Colors.white.withOpacity(0.3),
                focusColor: Colors.white.withOpacity(0.3),
                onPressed: () {
                  flush.dismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
    return flush;
  }

  /// Get a error notification flushbar
  static Flushbar createError(
      {@required String message,
        String title,
        Duration duration = defaultDuration,
        List<Widget> actions = const []}) {
    var flush;
    flush =  Flushbar(
      titleText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.0,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      messageText: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          message,
          style: TextStyle(fontSize: 14.0, color: Colors.white),
        ),
      ),
      icon: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          Icons.warning,
          color: errorColor,
          size: 32,
        ),
      ),
      duration: duration,
      animationDuration: Duration(milliseconds: 300),
      maxWidth: ScaffoldFromZero.screenSizeMedium,
      isDismissible: true,
      margin: EdgeInsets.only(left: 12, right: 12, bottom: 32),
      borderRadius: 999999,
      boxShadows: [BoxShadow(offset: Offset(0.0, 2.0), blurRadius: 3.0,)],
      mainButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: actions,
              ),
              IconButton(
                icon: Icon(Icons.close),
                splashRadius: 16,
                color: Colors.white,
                hoverColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.3),
                splashColor: Colors.white.withOpacity(0.3),
                focusColor: Colors.white.withOpacity(0.3),
                onPressed: () {
                  flush.dismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
    return flush;
  }

  // Get a flushbar that shows the progress of a async computation.
  static Flushbar createLoading(
      {@required String message,
        @required LinearProgressIndicator linearProgressIndicator,
        String title,
        Duration duration = defaultDuration,
        AnimationController progressIndicatorController,
        Color progressIndicatorBackgroundColor}) {
    return Flushbar(
      title: title,
      message: message,
      icon: Icon(
        Icons.cloud_upload,
        color: Colors.blue[300],
      ),
      duration: duration,
      showProgressIndicator: true,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
    );
  }

  /// Get a flushbar that shows an user input form.
  static Flushbar createInputFlushbar({@required Form textForm}) {
    return Flushbar(
      duration: null,
      userInputForm: textForm,
    );
  }
}