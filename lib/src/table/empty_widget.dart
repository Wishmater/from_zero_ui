import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class TableEmptyWidget<T> extends StatelessWidget {

  final TableController<T> tableController;
  final String? title;
  final String? subtitle;
  final List<ActionFromZero>? actions;
  final FutureOr<String>? exportPathForExcel;
  final VoidCallback? onShowMenu;
  final Widget? retryButton;

  const TableEmptyWidget({
    required this.tableController,
    this.title,
    this.subtitle,
    this.actions,
    this.exportPathForExcel,
    this.onShowMenu,
    this.retryButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final state = tableController.currentState;
    List<ActionFromZero> actions = this.actions ?? [];
    if (tableController.currentState?.widget.allowCustomization??false) {
      actions = TableFromZeroState.addManageActions(context,
        actions: actions,
        controller: tableController,
      );
    }
    final exportPathForExcel = this.exportPathForExcel ?? tableController.currentState?.widget.exportPathForExcel;
    if (exportPathForExcel!=null) {
      actions = TableFromZeroState.addExportExcelAction(context,
        actions: actions,
        tableController: tableController,
        exportPathForExcel: exportPathForExcel,
      );
    }
    final filtersApplied = state!=null && state.filtersApplied.values.firstOrNullWhere((e) => e==true)!=null;
    return ContextMenuFromZero(
      actions: actions.whereType<ActionFromZero>().toList(),
      onShowMenu: onShowMenu,
      child: Stack(
        children: [
          Positioned.fill(
            child: OverflowBox(
              maxHeight: double.infinity,
              child: Center(
                child: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 88, color: Theme.of(context).disabledColor.withOpacity(0.04),),
              ),
            ),
          ),
          ErrorSign(
            title: title ?? FromZeroLocalizations.of(context).translate('no_data'),
            subtitle: state!=null && (filtersApplied || state.widget.rows.isNotEmpty)
                ? FromZeroLocalizations.of(context).translate('no_data_filters')
                : FromZeroLocalizations.of(context).translate('no_data_desc'),
            retryButton: retryButton ?? (state!=null && !filtersApplied ? null
                : TextButton(
                    onPressed: () {
                      state?.clearAllFilters();
                    },
                    child: const IntrinsicWidth(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 8,),
                          Icon(Icons.filter_alt_off),
                          SizedBox(width: 4,),
                          Expanded(
                            child: Text('Limpiar todos los Filtros', // TODO 3 internationalize
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.1),
                            ),
                          ),
                          SizedBox(width: 8,),
                        ],
                      ),
                    ),
                  )),
          ),
        ],
      ),
    );
  }

}
