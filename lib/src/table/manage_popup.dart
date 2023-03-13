import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';


abstract class TableFromZeroManagePopup {

  static Future<bool> showDefaultManagePopup({
    required BuildContext context,
    required final Map<dynamic, ColModel> columns,
    required List<dynamic> currentColumnKeys,
  }) async {
    bool result = false;
    await showModal(
      context: context,
      builder: (context) {
        return Dialog(
          child: Text('TEST'),
        );
      },
    );
    return result;
  }

}