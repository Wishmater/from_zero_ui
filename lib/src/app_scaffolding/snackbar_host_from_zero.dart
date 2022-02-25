
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_from_zero.dart';



var fromZeroSnackBarHostControllerProvider = ChangeNotifierProvider<SnackBarHostControllerFromZero>((ref) {
  return SnackBarHostControllerFromZero();
});




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


class SnackBarHostFromZero extends ConsumerStatefulWidget {

  final Widget child;

  const SnackBarHostFromZero({
    required this.child,
    Key? key,
  }) : super(key: key,);

  @override
  SnackBarHostFromZeroState createState() => SnackBarHostFromZeroState();

}

class SnackBarHostFromZeroState extends ConsumerState<SnackBarHostFromZero> {

  SnackBarFromZero? lastShownSnackBar;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(fromZeroSnackBarHostControllerProvider);
    SnackBarFromZero? currentSnackBar = controller._snackBarQueue.isEmpty
        ? null : controller._snackBarQueue.first;
    bool isSameSnackBar = currentSnackBar?.key!=null && lastShownSnackBar?.key!=null
        && currentSnackBar?.key==lastShownSnackBar?.key;
    Widget result = Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: controller._snackBarQueue.isEmpty
                ? ValueNotifier(false)
                : controller._snackBarQueue.first.blockUI,
            builder: (context, blockUI, child) {
              return IgnorePointer(
                ignoring: !blockUI,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  color: blockUI
                      ? Colors.black54
                      : Colors.black.withOpacity(0),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, // TODO 3 snackbar doesnt respond to bottom keyboard inset
          child: AnimatedSwitcher(
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            duration: Duration(milliseconds: 500,),
            reverseDuration: Duration(milliseconds: 300,),
            transitionBuilder: (child, animation) {
              if (isSameSnackBar) {
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
    lastShownSnackBar = currentSnackBar;
    return result;
  }

}
