import 'package:flutter/material.dart';

class ThemeParameters extends ChangeNotifier {

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  double _textScaleFactor = -1;
  double get textScaleFactor => _textScaleFactor;
  set textScaleFactor(double value) {
    _textScaleFactor = value;
    notifyListeners();
  }


}