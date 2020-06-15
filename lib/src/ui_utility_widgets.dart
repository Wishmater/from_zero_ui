import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/scaffold_from_zero.dart';

class ResponsiveHorizontalInsets extends StatelessWidget {

  final Widget child;

  ResponsiveHorizontalInsets({this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < ScaffoldFromZero.medium ? 0 : 12),
      child: child,
    );
  }

}