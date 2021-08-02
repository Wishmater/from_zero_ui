
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/snackbar_from_zero.dart';
import 'package:provider/provider.dart';


class SnackBarControllerFromZero {

  SnackBarControllerFromZero({
    required this.host,
    required this.snackBar,
  });

  SnackBarHostControllerFromZero host;
  SnackBarFromZero snackBar;

  Completer<void> _closedCompleter = Completer();
  Future<void> get closed => _closedCompleter.future;

  void dismiss() {
    host.dismiss(snackBar);
  }

}


class SnackBarHostControllerFromZero extends ChangeNotifier {

  List<SnackBarFromZero> _snackBarQueue = [];

  void show(SnackBarFromZero o) {
    _snackBarQueue.add(o);
    notifyListeners();
  }

  void dismiss(SnackBarFromZero o) {
    _snackBarQueue.remove(o);
    o.controller?._closedCompleter.complete();
    notifyListeners();
  }

  void dismissFirst(){
    if (_snackBarQueue.isNotEmpty) {
      dismiss(_snackBarQueue.first);
    }
  }

  void dismissAll() {
    for (var i = 0; i < _snackBarQueue.length; ++i) {
      dismiss(_snackBarQueue[i]);
    }
  }

}


class SnackBarHostFromZero extends StatefulWidget {

  final Widget child;

  const SnackBarHostFromZero({
    required this.child,
    Key? key,
  }) : super(key: key,);

  @override
  _SnackBarHostFromZeroState createState() => _SnackBarHostFromZeroState();

}

class _SnackBarHostFromZeroState extends State<SnackBarHostFromZero> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SnackBarHostControllerFromZero(),
      child: widget.child,
      builder: (context, child) {
        return Consumer<SnackBarHostControllerFromZero>(
          child: child,
          builder: (context, controller, child) {
            return Stack(
              children: [
                child!,
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: AnimatedSwitcher(
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    duration: Duration(milliseconds: 500,),
                    reverseDuration: Duration(milliseconds: 300,),
                    transitionBuilder: (child, animation) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero,).animate(animation),
                        child: FadeTransition(
                          opacity: CurvedAnimation(parent: animation, curve: Interval(0, 0.5,),),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.66, end: 1,).animate(animation),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: controller._snackBarQueue.isEmpty ? SizedBox.shrink() : controller._snackBarQueue.first,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
