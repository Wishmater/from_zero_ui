import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {

  final Future<String?> Function(BuildContext context) nextPageNameAccessor;
  final Widget? child;

  SplashPage(
    this.nextPageNameAccessor,
    {this.child}
  );

  @override
  _SplashPageState createState() => _SplashPageState();

}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    widget.nextPageNameAccessor(context).then((value) {
      if (value!=null){
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(context, value,  (route) => false);
        });
        WidgetsBinding.instance?.scheduleFrame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container(
      color: kIsWeb ? Theme.of(context).canvasColor
        : Platform.isWindows ? Colors.black
        : Theme.of(context).canvasColor,
    );
  }

}
