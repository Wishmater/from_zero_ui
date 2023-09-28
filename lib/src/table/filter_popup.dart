import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


typedef ShowFilterPopupCallback = Future<bool> Function({
  required BuildContext context,
  required TableController controller,
  required dynamic colKey,
  GlobalKey? anchorKey,
});


abstract class TableFromZeroFilterPopup {

  static Future<bool> showDefaultFilterPopup({
    required BuildContext context,
    required TableController controller,
    required dynamic colKey,
    GlobalKey? anchorKey,
  }) async {
    final ColModel? col = controller.currentState!.widget.columns?[colKey];
    final Map<dynamic, List<ConditionFilter>> conditionFilters = controller.conditionFilters!;
    final Map<dynamic, Map<Object?, bool>> valueFilters = controller.valueFilters!;
    final newConditionFilters = {
      for (final e in conditionFilters.keys)
        e: List<ConditionFilter>.from(conditionFilters[e]!),
    };
    final newValueFilters = {
      for (final e in valueFilters.keys)
        e: Map<Object?, bool>.from(valueFilters[e]!),
    };
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
    final ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters = ValueNotifier(null); // controller.currentState.availableFilters
    final relevantRows = controller.currentState!.getFilterResults(
      controller.currentState!.sorted,
      skipColKey: colKey, // skip filters on this column, filter out everything in other columns
    ); // TODO 3 performance make getFilterResults async (either with an isolate or an artifitial throttle)
    TableFromZeroState.getAvailableFiltersForColumn(
      rowValues: relevantRows.allFiltered.map((e) => e.values),
      key: colKey,
      operationCounter: ValueNotifier(0),
      sort: true,
      sortAscending: col?.defaultSortAscending ?? true,
      // TODO 3 performance pass a state into that is unmounted when the filterView pops, so it can cancel calculations
    ).then((result) {
      availableFilters.value = {
        colKey: result,
      };
    });
    final confirm = await showPopupFromZero(
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
                                  style: Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),),
                            const SliverToBoxAdapter(child: SizedBox(height: 16,)),
                            if (possibleConditionFilters.isNotEmpty)
                              SliverToBoxAdapter(child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4,),
                                      child: Text(FromZeroLocalizations.of(context).translate('condition_filters'),
                                        style: Theme.of(context).textTheme.titleMedium,
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
                                              Icon(Icons.add, color: Theme.of(context).colorScheme.secondary,),
                                              const SizedBox(width: 6,),
                                              Text(FromZeroLocalizations.of(context).translate('add'),
                                                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.secondary,),
                                              ),
                                            ],
                                          ),
                                        ),
                                        itemBuilder: (context) {
                                          return possibleConditionFilters.map((e) {
                                            return PopupMenuItem(
                                              value: e,
                                              child: Text('${e.getUiName(context)}...'),
                                            );
                                          }).toList();
                                        },
                                        onSelected: (value) {
                                          filterPopupSetState((){
                                            modified.value = true;
                                            if (newConditionFilters[colKey]==null) {
                                              newConditionFilters[colKey] = [];
                                            }
                                            newConditionFilters[colKey]!.add(value);
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
                            if (possibleConditionFilters.isNotEmpty && (newConditionFilters[colKey] ?? []).isEmpty)
                              SliverToBoxAdapter(child: Padding(
                                padding: const EdgeInsets.only(left: 24, bottom: 8,),
                                child: Text (FromZeroLocalizations.of(context).translate('none'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),),
                            SliverList(
                              delegate: SliverChildListDelegate.fixed(
                                (newConditionFilters[colKey] ?? []).map((e) {
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
                                          newConditionFilters[colKey]!.remove(e);
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (possibleConditionFilters.isNotEmpty)
                              SliverToBoxAdapter(child: SizedBox(height: (newConditionFilters[colKey] ?? []).isEmpty ? 6 : 12,)),
                            if (possibleConditionFilters.isNotEmpty)
                              const SliverToBoxAdapter(child: Divider(height: 32,)),
                            TableFromZero(
                              tableController: filterTableController,
                              columns: col==null ? null : {colKey: col},
                              showHeaders: false,
                              emptyWidget: const SizedBox.shrink(),
                              initialSortedColumn: colKey,
                              rows: (col ?? SimpleColModel(name: ''))
                                  .buildFilterPopupRowModels(availableFilters[colKey] ?? [], newValueFilters, colKey, modified),
                              // override style and text alignment
                              cellBuilder: (context, row, colKey) {
                                var message = ColModel.getRowValueString(row, colKey, col);
                                var textStyle = const TextStyle(fontSize: 16);
                                if (message.isBlank) {
                                  message = '< vacío >'; // TODO 3 internacionalize
                                  textStyle = TextStyle(fontSize: 16, color: Theme.of(context).disabledColor);
                                }
                                const autoSizeTextMaxLines = 1;
                                Widget result = AutoSizeText(
                                  message,
                                  style: textStyle,
                                  textAlign: TextAlign.left,
                                  maxLines: autoSizeTextMaxLines,
                                  minFontSize: 15,
                                  overflowReplacement: TooltipFromZero(
                                    message: message,
                                    waitDuration: Duration.zero,
                                    verticalOffset: -16,
                                    child: Text(
                                      message,
                                      style: textStyle.copyWith(
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.left,
                                      maxLines: autoSizeTextMaxLines,
                                      softWrap: autoSizeTextMaxLines>1,
                                      overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
                                    ),
                                  ),
                                );
                                return result;
                              },
                              headerWidgetAddon: Container(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                                          contentPadding: const EdgeInsets.only(bottom: 12, top: 6, left: 6,),
                                          labelStyle: const TextStyle(height: 0.2),
                                          suffixIcon: Icon(Icons.search, color: Theme.of(context).disabledColor,),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6,),
                                    if (filterTableController.currentState==null || filterTableController.filtered.isNotEmpty)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              child: Text(FromZeroLocalizations.of(context).translate('select_all')),
                                              onPressed: () {
                                                modified.value = true;
                                                filterPopupSetState(() {
                                                  for (final initialRow in filterTableController.filtered) {
                                                    for (final row in [initialRow, ...initialRow.allFilteredChildren]) {
                                                      if (row.onCheckBoxSelected!=null) {
                                                        newValueFilters[colKey]![row.id] = true;
                                                        (row as SimpleRowModel).selected = true;
                                                      }
                                                    }
                                                  }
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
                                                  for (final initialRow in filterTableController.filtered) {
                                                    for (final row in [initialRow, ...initialRow.allFilteredChildren]) {
                                                      if (row.onCheckBoxSelected!=null) {
                                                        newValueFilters[colKey]![row.id] = false;
                                                        (row as SimpleRowModel).selected = false;
                                                      }
                                                    }
                                                  }
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
                            const SliverToBoxAdapter(child: SizedBox(height: 16+42,),),
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
                            padding: const EdgeInsets.only(bottom: 8,),
                            color: Theme.of(context).cardColor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 128,
                                  child: DialogButton.cancel(
                                    child: AutoSizeText('CANCELAR', maxLines: 1, softWrap: false, wrapWords: false,),
                                  ),
                                ),
                                SizedBox(
                                  width: 128,
                                  child: DialogButton.accept(
                                    child: const AutoSizeText('ACEPTAR', maxLines: 1, softWrap: false, wrapWords: false,),
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
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
    if ((confirm ?? false) && modified.value) {
      conditionFilters.clear();
      conditionFilters.addAll(newConditionFilters);
      valueFilters.clear();
      valueFilters.addAll(newValueFilters);
      return true;
    }
    return false;
  }
  static List<ConditionFilter> getDefaultAvailableConditionFilters() => [
    // FilterIsEmpty(),
    // FilterTextExactly(),
    FilterTextContains(),
    FilterTextStartsWith(),
    FilterTextEndsWith(),
    FilterNumberEqualTo(),
    FilterNumberGreaterThan(),
    FilterNumberLessThan(),
    // FilterDateExactDay(),
    FilterDateAfter(),
    FilterDateBefore(),
  ];

}