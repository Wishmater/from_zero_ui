import 'dart:io';

import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {

  final Future<String> Function() nextPageNameAccessor;
  final Widget child;

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
    widget.nextPageNameAccessor().then((value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, value,  (route) => false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container(color: Platform.isWindows ? Colors.black : Theme.of(context).canvasColor,);
  }

}
