import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_from_zero.dart';


enum APISnackBarBlockUIType {
  never,
  always,
  whileLoading,
  whileLoadingOrError,
}

class APISnackBar extends SnackBarFromZero {

  final ApiState<String?> state;
  final String? successText;

  APISnackBar({
    Key? key,
    required BuildContext context,
    required this.state,
    this.successText,
    int? behaviour,
    Duration? duration = const Duration(milliseconds: 300),
    double? width,
    bool showProgressIndicatorForRemainingTime = false,
    VoidCallback? onCancel,
    APISnackBarBlockUIType blockUIType = APISnackBarBlockUIType.whileLoading,
  })  : super(
          key: key,
          context: context,
          behaviour: behaviour,
          duration: duration,
          width: width,
          showProgressIndicatorForRemainingTime: showProgressIndicatorForRemainingTime,
          onCancel: onCancel,
          blockUI: blockUIType==APISnackBarBlockUIType.never ? false : true,
        );

  @override
  APISnackBarState createState() => APISnackBarState();

}


class APISnackBarState extends SnackBarFromZeroState {

  @override
  void initState() {
    super.initState();

  }

  // @override
  // Widget build(BuildContext context) {
  //
  // }

}