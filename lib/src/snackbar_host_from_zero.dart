
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
  Function(VoidCallback)? setState;
  int? type;

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
    if (o.controller?._closedCompleter.isCompleted==false) {
      o.controller?._closedCompleter.complete();
      notifyListeners();
    }
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

  SnackBarFromZero? lastShownSnackbar;

  @override
  Widget build(BuildContext context) {
    Widget result = ChangeNotifierProvider(
      create: (context) => SnackBarHostControllerFromZero(),
      child: widget.child,
      builder: (context, child) {
        return Consumer<SnackBarHostControllerFromZero>(
          child: child,
          builder: (context, controller, child) {
            SnackBarFromZero? currentSnackbar = controller._snackBarQueue.isEmpty
                ? null : controller._snackBarQueue.first;
            bool isSameSnackbar = currentSnackbar?.key!=null && lastShownSnackbar?.key!=null
                && currentSnackbar?.key==lastShownSnackbar?.key;
            Widget result = Stack(
              children: [
                child!,
                Positioned(
                  bottom: 0, left: 0, right: 0, // TODO 3 snackbar doesnt respond to bottom keyboard inset
                  child: AnimatedSwitcher(
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    duration: Duration(milliseconds: 500,),
                    reverseDuration: Duration(milliseconds: 300,),
                    transitionBuilder: (child, animation) {
                      if (isSameSnackbar) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      } else {
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
                      }
                    },
                    child: controller._snackBarQueue.isEmpty
                        ? SizedBox.shrink()
                        : Container(
                            key: ValueKey(controller._snackBarQueue.first.hashCode),
                            child: controller._snackBarQueue.first,
                          ),
                  ),
                ),
              ],
            );
            lastShownSnackbar = currentSnackbar;
            return result;
          },
        );
      },
    );
    return result;
  }

}
