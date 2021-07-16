
import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/snackbar_from_zero.dart';
import 'package:provider/provider.dart';


class SnackBarHostControllerFromZero extends ChangeNotifier {

  List<SnackBarFromZero> _snackbarQueue = [];

  void show(SnackBarFromZero o) {
    _snackbarQueue.add(o);
    notifyListeners();
  }

  void dismiss(SnackBarFromZero o) {
    _snackbarQueue.remove(o);
    notifyListeners();
  }

  void dismissFirst(){
    _snackbarQueue.removeAt(0);
    notifyListeners();
  }

  void dismissAll() {
    _snackbarQueue.clear();
    notifyListeners();
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
                          child: child,
                        ),
                      );
                    },
                    child: controller._snackbarQueue.isEmpty ? SizedBox.shrink() : controller._snackbarQueue.first,
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
