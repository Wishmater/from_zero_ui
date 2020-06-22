import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';

class PageSettings extends PageFromZero {

  @override
  int get pageScaffoldDepth => -1;
  @override
  String get pageScaffoldId => "Settings";

  PageSettings(PageFromZero previousPage, Animation<double> animation, Animation<double> secondaryAnimation)
      : super(previousPage, animation, secondaryAnimation);

  @override
  _PageSettingsState createState() => _PageSettingsState();

}

class _PageSettingsState extends State<PageSettings> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Settings"),
      body: Container(),
    );
  }

}
