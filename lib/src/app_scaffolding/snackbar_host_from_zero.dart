
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/api_snackbar.dart';



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
  void Function(VoidCallback)? setState;
  int? type;

  final Completer<void> _closedCompleter = Completer();
  Future<void> get closed => _closedCompleter.future;

  void dismiss() {
    host.dismiss(snackBar);
  }

}


class SnackBarHostControllerFromZero extends ChangeNotifier {

  final List<SnackBarFromZero> _snackBarQueue = [];

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
    super.key,
  });

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
    if (currentSnackBar!=null && !isSameSnackBar && currentSnackBar is APISnackBar) {
      currentSnackBar.updateBlockUI(currentSnackBar.stateNotifier.state);
    }
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    Widget result = Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Stack(
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
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.ease,
                            color: blockUI
                                ? Colors.black54
                                : Colors.black.withOpacity(0),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainerFromChildSize(
              child: controller._snackBarQueue.isEmpty || !controller._snackBarQueue.first.pushScreen
                  ? const SizedBox.shrink()
                  : Container(
                    key: ValueKey(controller._snackBarQueue.first.hashCode),
                    child: controller._snackBarQueue.first,
                  ),
            ),
          ],
        ),
        Positioned(
          bottom: max(viewPadding.bottom, viewInsets.bottom),
          left: max(viewPadding.left, viewInsets.left),
          right: max(viewPadding.right, viewInsets.right),
          child: AnimatedSwitcher(
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            duration: const Duration(milliseconds: 500,),
            reverseDuration: const Duration(milliseconds: 300,),
            transitionBuilder: (child, animation) {
              if (isSameSnackBar) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              } else {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero,).animate(animation),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5,),),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.66, end: 1,).animate(animation),
                      child: child,
                    ),
                  ),
                );
              }
            },
            child: controller._snackBarQueue.isEmpty || controller._snackBarQueue.first.pushScreen
                ? const SizedBox.shrink()
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
