import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class PageSettings extends StatelessWidget {
  final animation;
  final secondaryAnimation;


  PageSettings({this.animation, this.secondaryAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      title: Text("Settings"),
      body: Container(),
    );
  }
}
