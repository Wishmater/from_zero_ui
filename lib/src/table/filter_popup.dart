import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


typedef ShowFilterPopupCallback = Future<bool> Function({
required BuildContext context,
required dynamic colKey,
required ColModel? col,
required ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters,
required Map<dynamic, List<ConditionFilter>> conditionFilters,
required Map<dynamic, Map<Object?, bool>> valueFilters,
GlobalKey? anchorKey,
});


abstract class TableFromZeroFilterPopup {

  static Future<bool> showDefaultFilterPopup({
    required BuildContext context,
    required dynamic colKey,
    required ColModel? col,
    required ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters,
    required Map<dynamic, List<ConditionFilter>> conditionFilters,
    required Map<dynamic, Map<Object?, bool>> valueFilters,
    GlobalKey? anchorKey,
  }) async {
    ScrollController filtersScrollController = ScrollController();
    TableController filterTableController = TableController();
    final modified = ValueNotifier(false);
    List<ConditionFilter> possibleConditionFilters = col?.getAvailableConditionFilters()
        ?? getDefaultAvailableConditionFilters();
    final filterSearchFocusNode = FocusNode();
    if (PlatformExtended.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        filterSearchFocusNode.requestFocus();
      });
    }
    await showPopupFromZero(
      context: context,
      anchorKey: anchorKey,
      builder: (context) {
        return ValueListenableBuilder<Map<dynamic, List<dynamic>>?>(
          valueListenable: availableFilters,
          builder: (context, availableFilters, child) {
            if (availableFilters==null) {
              return AspectRatio(
                aspectRatio: 1,
                child: ApiProviderBuilder.defaultLoadingBuilder(context, null),
              );
            } else {
              return ScrollbarFromZero(
                controller: filtersScrollController,
                child: Stack (
                  children: [
                    StatefulBuilder(
                      builder: (context, filterPopupSetState) {
                        return CustomScrollView(
                          controller: filtersScrollController,
                          shrinkWrap: true,
                          slivers: [
                            SliverToBoxAdapter(child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Center(
                                child: Text(FromZeroLocalizations.of(context).translate('filters'),
                                  style: Theme.of(context).textTheme.subtitle1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),),
                            SliverToBoxAdapter(child: SizedBox(height: 16,)),
                            if (possibleConditionFilters.isNotEmpty)
                              SliverToBoxAdapter(child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4,),
                                      child: Text(FromZeroLocalizations.of(context).translate('condition_filters'),
                                        style: Theme.of(context).textTheme.subtitle1,
                                      ),
                                    ),
                                    TooltipFromZero(
                                      message: FromZeroLocalizations.of(context).translate('add_condition_filter'),
                                      child: PopupMenuButton<ConditionFilter>(
                                        tooltip: '',
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4,),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add, color: Colors.blue,),
                                              SizedBox(width: 6,),
                                              Text(FromZeroLocalizations.of(context).translate('add'),
                                                style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.blue,),
                                              ),
                                            ],
                                          ),
                                        ),
                                        itemBuilder: (context) {
                                          return possibleConditionFilters.map((e) {
                                            return PopupMenuItem(
                                              value: e,
                                              child: Text(e.getUiName(context)+'...'),
                                            );
                                          }).toList();
                                        },
                                        onSelected: (value) {
                                          filterPopupSetState((){
                                            modified.value = true;
                                            if (conditionFilters[colKey]==null) {
                                              conditionFilters[colKey] = [];
                                            }
                                            conditionFilters[colKey]!.add(value);
                                          });
                                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                                            value.focusNode.requestFocus();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),),
                            if ((conditionFilters[colKey] ?? []).isEmpty)
                              SliverToBoxAdapter(child: Padding(
                                padding: EdgeInsets.only(left: 24, bottom: 8,),
                                child: Text (FromZeroLocalizations.of(context).translate('none'),
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),),
                            SliverList(
                              delegate: SliverChildListDelegate.fixed(
                                (conditionFilters[colKey] ?? []).map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    child: e.buildFormWidget(
                                      context: context,
                                      onValueChanged: () {
                                        modified.value = true;
                                        // filterPopupSetState((){});
                                      },
                                      onDelete: () {
                                        modified.value = true;
                                        filterPopupSetState((){
                                          conditionFilters[colKey]!.remove(e);
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SliverToBoxAdapter(child: SizedBox(height: (conditionFilters[colKey] ?? []).isEmpty ? 6 : 12,)),
                            SliverToBoxAdapter(child: Divider(height: 32,)),
                            TableFromZero(
                              tableController: filterTableController,
                              columns: col==null ? null : {colKey: col},
                              showHeaders: false,
                              emptyWidget: SizedBox.shrink(),
                              initialSortedColumn: colKey,
                              rows: (col ?? SimpleColModel(name: ''))
                                  .buildFilterPopupRowModels(availableFilters[colKey] ?? [], valueFilters, colKey, modified),
                              // override style and text alignment
                              cellBuilder: (context, row, colKey) {
                                var message = ColModel.getRowValueString(row, colKey, col);
                                var textStyle = TextStyle(fontSize: 16);
                                if (message.isBlank) {
                                  message = '< vacío >'; // TODO 3 internacionalize
                                  textStyle = TextStyle(fontSize: 16, color: Theme.of(context).textTheme.caption!.color);
                                }
                                final autoSizeTextMaxLines = 1;
                                Widget result = AutoSizeText(
                                  message,
                                  style: textStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: autoSizeTextMaxLines,
                                  minFontSize: 14,
                                  overflowReplacement: TooltipFromZero(
                                    message: message,
                                    waitDuration: Duration(milliseconds: 0),
                                    verticalOffset: -16,
                                    child: AutoSizeText(
                                      message,
                                      style: textStyle,
                                      textAlign: TextAlign.left,
                                      maxLines: autoSizeTextMaxLines,
                                      softWrap: autoSizeTextMaxLines>1,
                                      overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
                                    ),
                                  ),
                                );
                                return result;
                              },
                              tableHeader: Container(
                                padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: TextFormField(
                                        focusNode: filterSearchFocusNode,
                                        onChanged: (v) {
                                          filterTableController.extraFilters = [
                                                (rows) {
                                              List<RowModel> starts = [];
                                              List<RowModel> contains = [];
                                              final q = v
                                                  .replaceAll('.', '')
                                                  .replaceAll(',', '')
                                                  .trim()
                                                  .toUpperCase();
                                              if (q.isEmpty) {
                                                return rows;
                                              } else {
                                                for (final e in rows) {
                                                  final List<String> values = [
                                                    ColModel.getRowValueString(e, colKey, col),
                                                  ];
                                                  for (int i=0; i<values.length; i++) {
                                                    values[i] = values[i]
                                                        .replaceAll('.', '')
                                                        .replaceAll(',', '')
                                                        .trim()
                                                        .toUpperCase();
                                                  }
                                                  bool doesContain = false, doesStart = false;
                                                  for (final value in values) {
                                                    if (value.contains(q)) {
                                                      doesContain = true;
                                                      if (value.startsWith(q)) {
                                                        doesStart = true;
                                                      }
                                                    }
                                                  }
                                                  if (doesStart) {
                                                    starts.add(e);
                                                  } else if (doesContain) {
                                                    contains.add(e);
                                                  }
                                                }
                                              }
                                              return [...starts, ...contains];
                                            },
                                          ];
                                          filterPopupSetState((){
                                            filterTableController.filter();
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: FromZeroLocalizations.of(context).translate('search...'),
                                          contentPadding: EdgeInsets.only(bottom: 12, top: 6, left: 6,),
                                          labelStyle: TextStyle(height: 0.2),
                                          suffixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.caption!.color!,),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6,),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            child: Text(FromZeroLocalizations.of(context).translate('select_all')),
                                            onPressed: () {
                                              modified.value = true;
                                              filterPopupSetState(() {
                                                filterTableController.filtered.forEach((initialRow) {
                                                  for (final row in [initialRow, ...initialRow.allFilteredChildren]) {
                                                    if (row.onCheckBoxSelected!=null) {
                                                      valueFilters[colKey]![row.id] = true;
                                                      (row as SimpleRowModel).selected = true;
                                                    }
                                                  }
                                                });
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: TextButton(
                                            child: Text(FromZeroLocalizations.of(context).translate('clear_selection')),
                                            onPressed: () {
                                              modified.value = true;
                                              filterPopupSetState(() {
                                                filterTableController.filtered.forEach((initialRow) {
                                                  for (final row in [initialRow, ...initialRow.allFilteredChildren]) {
                                                    if (row.onCheckBoxSelected!=null) {
                                                      valueFilters[colKey]![row.id] = false;
                                                      (row as SimpleRowModel).selected = false;
                                                    }
                                                  }
                                                });
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(child: SizedBox(height: 16+42,),),
                          ],
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).cardColor.withOpacity(0),
                                  Theme.of(context).cardColor,
                                ],
                              ),
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(bottom: 8, right: 16,),
                            color: Theme.of(context).cardColor,
                            child: FlatButton(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(FromZeroLocalizations.of(context).translate('accept_caps'),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              textColor: Colors.blue,
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
    return modified.value;
  }
  static List<ConditionFilter> getDefaultAvailableConditionFilters() => [
    // FilterIsEmpty(),
    // FilterTextExactly(),
    FilterTextContains(),
    FilterTextStartsWith(),
    FilterTextEndsWith(),
    // FilterNumberEqualTo(),
    FilterNumberGreaterThan(),
    FilterNumberLessThan(),
    // FilterDateExactDay(),
    FilterDateAfter(),
    FilterDateBefore(),
  ];

}