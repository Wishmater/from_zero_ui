import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cancelable_compute/cancelable_compute.dart' as cancelable_compute;
import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/table/manage_popup.dart';
import 'package:from_zero_ui/util/comparable_list.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_ensure_visible_when_focused.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_sliver_sticky_header.dart';
import 'package:intl/intl.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef OnRowHoverCallback = void Function(RowModel row, bool selected);
typedef OnCheckBoxSelectedCallback = bool? Function(RowModel row, bool? selected);
typedef OnHeaderHoverCallback = void Function(dynamic key, bool selected);
typedef OnCellTapCallback = ValueChanged<RowModel>? Function(dynamic key,);
typedef OnCellHoverCallback = OnRowHoverCallback? Function(dynamic key,);
typedef WidthGetter = double Function(List<dynamic> currentColumnKeys);


class TableFromZero<T> extends StatefulWidget {

  final List<RowModel<T>> rows;
  final Map<dynamic, ColModel>? columns;
  final bool enabled;
  final WidthGetter? minWidthGetter;
  final WidthGetter? maxWidthGetter;
  final bool ignoreWidthGettersIfEmpty;
  final bool enableFixedHeightForListRows;
  final bool showHeaders;
  final RowModel? headerRowModel;
  final bool enableStickyHeaders;
  final double stickyOffset;
  final double footerStickyOffset;
  final bool alternateRowBackgroundBrightness;
  final bool? alternateRowBackgroundSmartly;
  final bool rowStyleTakesPriorityOverColumn;
  final bool hideIfNoRows;
  final bool? implicitlyAnimated;
  final EdgeInsets cellPadding;
  final ScrollController? scrollController;
  final double tableHorizontalPadding;
  final dynamic initialSortedColumn;
  final Widget? emptyWidget;
  final bool? Function(bool? value, List<RowModel<T>> filtered)? onAllSelected;
  final Widget? horizontalDivider;
  final Widget? verticalDivider;
  final bool showFirstHorizontalDivider;
  final List<RowAction<T>> rowActions;
  final Widget? Function(BuildContext context, RowModel<T> row, dynamic colKey)? cellBuilder;
  final Widget? Function(BuildContext context, RowModel<T> row, int index, double? minWidth,
      Widget Function(BuildContext context, RowModel<T> row, int index, double? minWidth) defaultRowBuilder,)? rowBuilder;
  final Widget? Function(BuildContext context, RowModel row, double? minWidth)? headerRowBuilder;
  final void Function(List<RowModel<T>> rows)? onSort;
  final List<RowModel<T>> Function(List<RowModel<T>>)? onFilter;
  final TableController<T>? tableController;
  final bool? enableSkipFrameWidgetForRows;
  /// if null, excel export option is disabled
  final FutureOr<String>? exportPathForExcel;
  final bool? computeFiltersInIsolate;
  final Color? backgroundColor;
  final Widget? headerWidgetAddon;
  final bool allowCustomization;
  final String? Function(RowModel<T> row)? rowDisabledValidator;
  final String? Function(RowModel<T> row)? rowTooltipGetter;

  const TableFromZero({
    required this.rows,
    this.columns,
    this.enabled = true,
    this.minWidthGetter,
    this.maxWidthGetter,
    this.ignoreWidthGettersIfEmpty = true,
    this.enableFixedHeightForListRows = true,
    this.showHeaders = true,
    this.headerRowModel,
    this.enableStickyHeaders = true,
    this.stickyOffset = 0,
    this.footerStickyOffset = 12,
    this.alternateRowBackgroundBrightness = true,
    this.alternateRowBackgroundSmartly,
    this.rowStyleTakesPriorityOverColumn = true,
    this.hideIfNoRows = false,
    this.implicitlyAnimated,
    this.cellPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    this.scrollController,
    this.tableHorizontalPadding = 8,
    this.initialSortedColumn,
    this.emptyWidget,
    this.onAllSelected,
    this.horizontalDivider, //const Divider(height: 1, color: const Color(0xFF757575),),
    this.verticalDivider,   //const VerticalDivider(width: 1, color: const Color(0xFF757575),),
    this.showFirstHorizontalDivider = true,
    this.rowActions = const [],
    this.cellBuilder,
    this.rowBuilder,
    this.headerRowBuilder,
    this.onSort,
    this.onFilter,
    this.tableController,
    this.exportPathForExcel,
    this.enableSkipFrameWidgetForRows,
    this.computeFiltersInIsolate,
    this.backgroundColor,
    this.headerWidgetAddon,
    this.allowCustomization = true,
    this.rowDisabledValidator,
    this.rowTooltipGetter,
    super.key,
  });

  @override
  TableFromZeroState<T> createState() => TableFromZeroState<T>();

}



class TrackingScrollControllerFomZero extends TrackingScrollController {

  int mainIndex = 0;

  @override
  ScrollPosition get position {
    assert(positions.isNotEmpty, 'ScrollController not attached to any scroll views.');
    return positions.length>mainIndex
        ? positions.elementAt(mainIndex)
        : positions.last;
  }

}


class TableFromZeroState<T> extends State<TableFromZero<T>> with TickerProviderStateMixin {

  static const bool showFiltersLoading = false;
  static const double _checkmarkWidth = 40;
  static const double _dropdownButtonWidth = 28;
  static const double _depthPadding = 16;

  double _leadingControlsWidth = 0;
  bool _showCheckmarks = false;
  bool _showDropdowns = false;
  bool? _expandableRowsExist;
  bool _enableSkipFrameWidgetForRows = false;
  bool get _showLeadingControls => _leadingControlsWidth>0;

  late List<RowModel<T>> sorted;
  late List<RowModel<T>> filtered;
  late List<RowModel<T>> allFiltered;
  late Map<dynamic, FocusNode> headerFocusNodes = {};
  bool isStateInvalidated = false;
  final Map<RowModel<T>, Animation<double>> rowAddonEntranceAnimations = {};
  final Map<RowModel<T>, Animation<double>> nestedRowEntranceAnimations = {};


  List<dynamic>? _columnKeys;
  List<dynamic>? get columnKeys => widget.tableController?.columnKeys ?? _columnKeys;
  set columnKeys(List<dynamic>? value) {
    if (widget.tableController == null) {
      _columnKeys = value;
    } else {
      widget.tableController!.columnKeys = value;
    }
  }
  List<dynamic>? _currentColumnKeys;
  List<dynamic>? get currentColumnKeys => widget.tableController?.currentColumnKeys ?? _currentColumnKeys;
  set currentColumnKeys(List<dynamic>? value) {
    if (widget.tableController == null) {
      _currentColumnKeys = value;
    } else {
      widget.tableController!.currentColumnKeys = value;
    }
  }
  Map<dynamic, List<ConditionFilter>> _conditionFilters = {};
  Map<dynamic, List<ConditionFilter>> get conditionFilters => widget.tableController?.conditionFilters ?? _conditionFilters;
  set conditionFilters(Map<dynamic, List<ConditionFilter>> value) {
    if (widget.tableController == null) {
      _conditionFilters = value;
    } else {
      widget.tableController!.conditionFilters = value;
    }
  }
  Map<dynamic, Map<Object?, bool>> _valueFilters = {};
  Map<dynamic, Map<Object?, bool>> get valueFilters => widget.tableController?.valueFilters ?? _valueFilters;
  set valueFilters(Map<dynamic, Map<Object?, bool>> value) {
    if (widget.tableController==null) {
      _valueFilters = value;
    } else {
      widget.tableController!.valueFilters = value;
    }
  }
  Map<dynamic, bool> _valueFiltersApplied = {};
  Map<dynamic, bool> get valueFiltersApplied => widget.tableController?.valueFiltersApplied ?? _valueFiltersApplied;
  set valueFiltersApplied(Map<dynamic, bool> value) {
    if (widget.tableController==null) {
      _valueFiltersApplied = value;
    } else {
      widget.tableController!.valueFiltersApplied = value;
    }
  }
  Map<dynamic, bool> _filtersApplied = {};
  Map<dynamic, bool> get filtersApplied => widget.tableController?.filtersApplied ?? _filtersApplied;
  set filtersApplied(Map<dynamic, bool> value) {
    if (widget.tableController==null) {
      _filtersApplied = value;
    } else {
      widget.tableController!.filtersApplied = value;
    }
  }
  ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters = ValueNotifier(null);
  Map<dynamic, GlobalKey> filterGlobalKeys = {};

  dynamic _sortedColumn;
  dynamic get sortedColumn => widget.tableController==null ? _sortedColumn : widget.tableController!.sortedColumn;
  set sortedColumn (dynamic value) {
    if (widget.tableController==null) {
      _sortedColumn = value;
    } else {
      widget.tableController!.sortedColumn = value;
    }
  }

  bool _sortedAscending = true;
  bool get sortedAscending => widget.tableController==null ? _sortedAscending : widget.tableController!.sortedAscending;
  set sortedAscending (bool value){
    if (widget.tableController==null) {
      _sortedAscending = value;
    } else {
      widget.tableController!.sortedAscending = value;
    }
  }

  final TrackingScrollControllerFomZero sharedController = TrackingScrollControllerFomZero();
  RowModel? headerRowModel;

  TableFromZeroState();

  @override
  void dispose() {
    super.dispose();
    availableFiltersIsolateController?.cancel();
    validInitialFiltersIsolateController?.cancel();
    if (widget.tableController?.currentState==this) {
      widget.tableController!.currentState = null;
    }
  }

  double lastPosition = 0;
  bool lockScrollUpdates = false;
  @override
  void initState() {
    super.initState();
    sharedController.addListener(() {
      if (!lockScrollUpdates){
        double? newPosition;
        for (final element in sharedController.positions) {
          if (element.pixels!=lastPosition) newPosition = element.pixels;
        }
        lockScrollUpdates = true;
        if (newPosition!=null){
          lastPosition = newPosition;
          for (final element in sharedController.positions) {
            if (element.pixels!=newPosition){
              element.jumpTo(newPosition);
            }
          }
        }
        lockScrollUpdates = false;
      }
    });
    sortedColumn ??= widget.initialSortedColumn;
    sortedAscending = widget.columns?[sortedColumn]?.defaultSortAscending ?? true;
    init(
      notifyListeners: false,
      isFirstInit: true,
    );
  }

  @override
  void didUpdateWidget(TableFromZero<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isStateInvalidated) {
      init(notifyListeners: false);
    } else if (widget.headerRowModel!=null || widget.headerWidgetAddon!=null) {
      initHeaderRowModel();
    }
  }

  late final notificationRelayController = NotificationRelayController(
        (n) => n is ScrollNotification || n is ScrollMetricsNotification,
  );

  void init({
    bool notifyListeners = true,
    bool isFirstInit = false,
  }) {
    availableFilters.value = null;
    bool filtersAltered = false;
    isStateInvalidated = false;
    if (widget.columns==null) {
      columnKeys = null;
      currentColumnKeys = null;
    } else {
      columnKeys ??= [];
      currentColumnKeys ??= [];
      for (int i=0; i<columnKeys!.length; i++) {
        if (!widget.columns!.keys.contains(columnKeys![i])) {
          columnKeys!.removeAt(i);
          i--;
        }
      }
      for (int i=0; i<currentColumnKeys!.length; i++) {
        if (!widget.columns!.keys.contains(currentColumnKeys![i])) {
          currentColumnKeys!.removeAt(i);
          i--;
        }
      }
      final newKeys = widget.columns!.keys.toList();
      for (int i=0; i<newKeys.length; i++) {
        final e = newKeys[i];
        if (!columnKeys!.contains(e)) {
          columnKeys!.insert(min(i, columnKeys!.length), e);
          if (!currentColumnKeys!.contains(e)) {
            currentColumnKeys!.insert(min(i, currentColumnKeys!.length), e);
          }
        }
      }
    }
    sorted = widget.rows;
    for (final e in sorted) {
      e.calculateDepth();
    }
    _showCheckmarks = false;
    _showDropdowns = false;
    final allRows = sorted.map((e) => e.allRows).flatten();
    _enableSkipFrameWidgetForRows = widget.enableSkipFrameWidgetForRows ?? allRows.length>50;
    for (final e in allRows) {
      if (_showCheckmarks && _showDropdowns) {
        break;
      }
      _showCheckmarks = _showCheckmarks || e.onCheckBoxSelected!=null;
      _showDropdowns = _showDropdowns || e.isExpandable;
    }
    _leadingControlsWidth = (_showCheckmarks ? _checkmarkWidth : 0) + (_showDropdowns ? _dropdownButtonWidth : 0);
    if (widget.tableController!=null) {
      widget.tableController!.currentState = this;
    }
    if (widget.tableController?.conditionFilters==null) {
      if (widget.tableController?.initialConditionFilters==null){
        conditionFilters = {};
      } else{
        conditionFilters = Map.from(widget.tableController!.initialConditionFilters ?? {});
        filtersAltered = true;
      }
    } else if (isFirstInit) {
      filtersAltered = true;
    }
    if (widget.tableController?.valueFilters==null) {
      filtersAltered = widget.tableController?.initialValueFilters!=null;
      valueFilters = {
        for (final e in widget.columns?.keys ?? [])
          e: widget.tableController?.initialValueFilters?[e] ?? {},
      };
    } else {
      filtersAltered = isFirstInit;
      for (final e in widget.columns?.keys ?? []) {
        if (!valueFilters.containsKey(e)) {
          valueFilters[e] = widget.tableController?.initialValueFilters?[e] ?? {};
          filtersAltered = true;
        }
      }
    }
    initHeaderRowModel();
    _updateFiltersApplied();
    if (widget.columns!=null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        initFilters(widget.rows.map((e) => e.allRows).flatten().toList(), // passing sorted would count only visible rows
          filterAfter: filtersAltered,
        ).then((value) {
          if (mounted && filtersAltered) {
            setState(() {});
          }
        });
      });
    }
    sort(notifyListeners: notifyListeners);
  }
  void initHeaderRowModel() {
    if (widget.headerRowModel!=null) {
      if (widget.headerRowModel is SimpleRowModel) {
        headerRowModel = (widget.headerRowModel! as SimpleRowModel).copyWith(
          onCheckBoxSelected: widget.headerRowModel!.onCheckBoxSelected,
          values: widget.columns==null || widget.columns!.length==widget.headerRowModel!.values.length
              ? widget.headerRowModel!.values
              : widget.columns!.map((key, value) => MapEntry(key, value.name)),
          rowAddon: widget.headerRowModel?.rowAddon ?? widget.headerWidgetAddon,
          rowAddonIsAboveRow: widget.headerRowModel?.rowAddonIsAboveRow ?? true,
          rowAddonIsCoveredByBackground: widget.headerRowModel?.rowAddonIsCoveredByBackground ?? widget.headerWidgetAddon==null,
          rowAddonIsCoveredByScrollable: widget.headerRowModel?.rowAddonIsCoveredByScrollable ?? widget.headerWidgetAddon==null,
          rowAddonIsCoveredByGestureDetector: widget.headerRowModel?.rowAddonIsCoveredByGestureDetector ?? true,
          rowAddonIsSticky: widget.headerRowModel?.rowAddonIsSticky ?? false,
        );
      } else {
        headerRowModel = widget.headerRowModel;
      }
    } else {
      headerRowModel = SimpleRowModel(
        id: "header_row",
        values: widget.columns?.map((key, value) => MapEntry(key, value.name)) ?? {},
        selected: true,
        height: widget.rows.isEmpty ? 36 : widget.rows.first.height,
        rowAddon: widget.headerWidgetAddon,
        rowAddonIsAboveRow: true,
        rowAddonIsCoveredByScrollable: false,
        rowAddonIsCoveredByBackground: false,
        rowAddonIsCoveredByGestureDetector: true,
        rowAddonIsSticky: false,
      );
    }
  }

  cancelable_compute.ComputeOperation<Map<dynamic, List<dynamic>>>? availableFiltersIsolateController;
  cancelable_compute.ComputeOperation<Map<dynamic, Map<Object?, bool>>?>? validInitialFiltersIsolateController;
  Future<void> initFilters(List<RowModel<T>> rows, {
    bool? filterAfter,
    bool? computeFiltersInIsolate,
  }) async {
    availableFiltersIsolateController?.cancel();
    validInitialFiltersIsolateController?.cancel();
    Map<dynamic, List<dynamic>> computedAvailableFilters;
    Map<dynamic, Map<Object?, bool>>? computedValidInitialFilters;
    if (computeFiltersInIsolate ?? widget.computeFiltersInIsolate ?? rows.length>200) {
      try {
        final Map<dynamic, Map<dynamic, Field>> fieldAliases = {
          for (final key in widget.columns!.keys) key: {},
        };
        final Map<dynamic, Map<dynamic, DAO>> daoAliases = {
          for (final key in widget.columns!.keys) key: {},
        };
        availableFiltersIsolateController = cancelable_compute.compute(getAvailableFilters,
            [
              widget.columns!.map((key, value) => MapEntry(key, [value.filterEnabled, value.defaultSortAscending])),
              rows.map((e) {
                return e.values.map((key, value) {
                  return MapEntry(key, _sanitizeValueForIsolate(key, value, // TODO 2 performance, maybe allow to manually disable sanitization
                    fieldAliases: fieldAliases[key]!,
                    daoAliases: daoAliases[key]!,
                  ),);
                });
              }).toList(),
              fieldAliases.isEmpty && daoAliases.isEmpty,
            ]);
        final computationResult = await availableFiltersIsolateController!.value;
        if (computationResult==null) return; // cancelled
        computedAvailableFilters = computationResult.map((key, value) {
          if (fieldAliases.isEmpty && daoAliases.isEmpty) {
            return MapEntry(key, value);
          } else {
            final result = value.map((e) => fieldAliases[key]![e] ?? daoAliases[key]![e] ?? e).toList();
            final sorted = result.sortedWith((a, b) => defaultComparator(a, b, widget.columns?[key]?.defaultSortAscending ?? true));
            return MapEntry(key, sorted);
          }
        });
        if (valueFiltersApplied.values.where((e) => e==true).isNotEmpty) {
          validInitialFiltersIsolateController = cancelable_compute.compute(_getValidInitialFilters,
              [valueFilters, computedAvailableFilters],);
          computedValidInitialFilters = await validInitialFiltersIsolateController!.value;
        }
      } catch (e, st) {
        log('Isolate creation for computing table filters failed. Computing synchronously...');
        log(e, stackTrace: st, isError: false,);
        initFilters(rows,
          computeFiltersInIsolate: false,
          filterAfter: filterAfter,
        );
        return;
      }
    } else {
      computedAvailableFilters = await getAvailableFilters(
          [
            widget.columns!.map((key, value) => MapEntry(key, [value.filterEnabled, value.defaultSortAscending])),
            rows.map((e) => e.values).toList(),
            true,
          ],
          artifitialThrottle: true,
          state: this,
      );
      computedValidInitialFilters = _getValidInitialFilters(
          [valueFilters, computedAvailableFilters],
      );
    }
    if (mounted) {
      availableFilters.value = computedAvailableFilters;
      if (filterAfter ?? (computedValidInitialFilters!=null)) {
        if (computedValidInitialFilters!=null) valueFilters = computedValidInitialFilters;
        _updateFiltersApplied();
        filter();
      }
    }
  }
  static dynamic _sanitizeValueForIsolate(dynamic key, dynamic value, {
    required Map<dynamic, Field> fieldAliases,
    required Map<dynamic, DAO> daoAliases,
  }) {
    if (value is List) {
      return value.map((e) => _sanitizeValueForIsolate(key, e,
        fieldAliases: fieldAliases,
        daoAliases: daoAliases,
      ),).toList();
    } else if (value is ComparableList) {
      return value.list.map((e) => _sanitizeValueForIsolate(key, e,
        fieldAliases: fieldAliases,
        daoAliases: daoAliases,
      ),).toList();
    } else if (value is Field) {
      final newValue = _sanitizeValueForIsolate(key, value.value,
        fieldAliases: fieldAliases,
        daoAliases: daoAliases,
      );
      if (value is! ListField) {
        fieldAliases[newValue] = value;
      }
      return newValue;
    } else if (value is DAO) {
      final newValue = _sanitizeValueForIsolate(key, value.id ?? value.hashCode,
        fieldAliases: fieldAliases,
        daoAliases: daoAliases,
      );
      daoAliases[newValue] = value;
      return newValue;
    } else {
      return value;
    }
  }
  static Future<Map<dynamic, List<dynamic>>> getAvailableFilters(List<dynamic> params, {
    bool artifitialThrottle = false,
    State? state, // for cancelling if unmounted
  }) async {
    final Map<dynamic, List<bool?>> columnOptions = params[0];
    final List<Map<dynamic, dynamic>> rowValues = params[1];
    final bool sort = params[2];
    Map<dynamic, List<dynamic>> availableFilters = {};
    ValueNotifier<int> operationCounter = ValueNotifier(0);
    for (final e in columnOptions.entries) {
      final key = e.key;
      final options = e.value;
      if (options[0] ?? true) { // filterEnabled
        availableFilters[key] = await getAvailableFiltersForColumn(
          rowValues: rowValues,
          key: key,
          sort: sort,
          sortAscending: options[1] ?? true,
          operationCounter: operationCounter,
          state: state,
        );
      } else {
        availableFilters[key] = [];
      }
      if (state!=null && !state.mounted) {
        return {};
      }
    }
    return availableFilters;
  }
  static Future<List<dynamic>> getAvailableFiltersForColumn({
    required Iterable<Map<dynamic, dynamic>> rowValues,
    required dynamic key,
    bool sort = true,
    bool sortAscending = true,
    ValueNotifier<int>? operationCounter, // if null artifitial throttle is disabled
    State? state, // for cancelling if unmounted
  }) async {
    final artifitialThrottle = operationCounter!=null;
    Set<dynamic> available = {};
    for (final row in rowValues) {
      final element = row[key];
      if (element is List || element is ComparableList || element is ListField) {
        final List list = element is List ? element
            : element is ComparableList ? element.list
            : element is ListField ? element.objects : [];
        for (final e in list) {
          available.add(e);
          if (artifitialThrottle) {
            operationCounter.value+=available.length;
            if (operationCounter.value>5000000) {
              operationCounter.value = 0;
              await Future.delayed(const Duration(milliseconds: 50));
              if (state!=null && !state.mounted) {
                return [];
              }
            }
          }
        }
      } else {
        available.add(element);
      }
      if (artifitialThrottle) {
        operationCounter.value+=available.length;
        if (operationCounter.value>5000000) {
          operationCounter.value = 0;
          await Future.delayed(const Duration(milliseconds: 50));
          if (state!=null && !state.mounted) {
            return [];
          }
        }
      }
    }
    List<dynamic> availableSorted;
    if (sort) {
      if (artifitialThrottle) {
        availableSorted = available.sortedWith((a, b) => defaultComparator(a, b, sortAscending));
      } else {
        availableSorted = available.toList()..sort((a, b) => defaultComparator(a, b, sortAscending));
      }
    } else {
      availableSorted = available.toList();
    }
    return availableSorted;
  }
  static Map<dynamic, Map<Object?, bool>>? _getValidInitialFilters(List<dynamic> params) {
    Map<dynamic, Map<Object?, bool>> initialFilters = params[0];
    Map<dynamic, List<dynamic>> availableFilters = params[1];
    bool removed = false;
    initialFilters.forEach((col, filters) {
      filters.removeWhere((key, value) {
        bool remove = !(availableFilters[col]?.contains(key)??false);
        removed = remove;
        return remove;
      });
    });
    return removed ? initialFilters : null;
  }


  @override
  Widget build(BuildContext context) {

    if (widget.hideIfNoRows && allFiltered.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink(),);
    }
    int childCount = allFiltered.length.coerceIn(1);
    final showHeaders = widget.showHeaders
        && (allFiltered.isNotEmpty || filtersApplied.values.any((e) => e));
    final minWidth = widget.ignoreWidthGettersIfEmpty&&allFiltered.isEmpty&&!showHeaders ? null
        : widget.minWidthGetter?.call(currentColumnKeys??[]);
    final maxWidth = widget.ignoreWidthGettersIfEmpty&&allFiltered.isEmpty&&!showHeaders ? 640.0
        : widget.maxWidthGetter?.call(currentColumnKeys??[]);
    Widget result;

    // if (!(widget.implicitlyAnimated ?? allFiltered.length<10)) {

      if (widget.enableFixedHeightForListRows && allFiltered.isNotEmpty) {
        result = SliverFixedExtentList(
          itemExtent: allFiltered.first.height??36,
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, allFiltered.isEmpty ? null : allFiltered[i], i, minWidth),
            childCount: childCount,
          ),
        );
      } else {
        result = SliverList(
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, allFiltered.isEmpty ? null : allFiltered[i], i, minWidth),
            childCount: childCount,
          ),
        );
      }

    // }  else {
    //
    //   TODO 3 re-implement implicit animation with animated_list_plus
    //   result = SliverImplicitlyAnimatedList<RowModel<T>>(
    //     items: allFiltered.isEmpty ? [] : allFiltered,
    //     areItemsTheSame: (a, b) => a==b,
    //     insertDuration: Duration(milliseconds: 400),
    //     updateDuration: Duration(milliseconds: 400),
    //     itemBuilder: (context, animation, item, index) {
    //       return SlideTransition(
    //         position: Tween<Offset>(begin: Offset(-0.33, 0), end: Offset(0, 0)).animate(animation),
    //         child: SizeFadeTransition(
    //           sizeFraction: 0.7,
    //           curve: Curves.easeOutCubic,
    //           animation: animation,
    //           child: _getRow(context, item, index, minWidth),
    //         ),
    //       );
    //     },
    //     updateItemBuilder: (context, animation, item) {
    //       return SlideTransition(
    //         position: Tween<Offset>(begin: Offset(-0.10, 0), end: Offset(0, 0)).animate(animation),
    //         child: FadeTransition(
    //           opacity: animation,
    //           child: _getRow(context, item, -1, minWidth),
    //         ),
    //       );
    //     },
    //   );
    //
    // }

    Widget? header = showHeaders
        ? headerRowModel!=null
            ? headerRowModel!.values.isEmpty && headerRowModel!.rowAddon!=null
                ? LayoutBuilder(builder: (context, constraints) {
                    return _wrapRowAddon(headerRowModel!, constraints, minWidth)!;
                  },)
                : _getRow(context, headerRowModel, -1, minWidth)
            : null
        : headerRowModel?.rowAddon==null
            ? null
            : minWidth==null
                ? headerRowModel!.rowAddon!
                : LayoutBuilder(builder: (context, constraints) {
                    return _wrapRowAddon(headerRowModel!, constraints, minWidth)!;
                  },);
    if (header!=null) {
      result = SliverStickyHeader.builder(
        sliver: result,
        scrollController: widget.scrollController,
        sticky: widget.enableStickyHeaders,
        stickOffset: widget.stickyOffset,
        builder: (context, state) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              header,
              AnimatedPositioned(
                left: 0, right: 0, bottom: -2,
                height: state.isPinned ? 2 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: const CustomPaint(
                  painter: SimpleShadowPainter(
                    direction: SimpleShadowPainter.down,
                    shadowOpacity: 0.2,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    if (minWidth!=null) {
      final theme = Theme.of(context);
      result = SliverStickyHeader(
        sliver: SliverPadding(
          padding: const EdgeInsets.only(bottom: 8),
          sliver: result,
        ),
        scrollController: widget.scrollController,
        sticky: true,
        footer: true,
        overlapsContent: true,
        stickOffset: widget.footerStickyOffset,
        header: Theme(
          data: theme.copyWith(
            scrollbarTheme: theme.scrollbarTheme.copyWith(
              crossAxisMargin: theme.scrollbarTheme.crossAxisMargin
                  ?.clamp(widget.footerStickyOffset, double.infinity),
            ),
          ),
          child: Transform.translate(
            offset: Offset(0, widget.footerStickyOffset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < minWidth) {
                  return ScrollbarFromZero(
                    controller: sharedController,
                    opacityGradientDirection: OpacityGradient.horizontal,
                    child: SizedBox(
                      height: 12 + 4 + widget.footerStickyOffset,
                      child: NotificationRelayer(
                        controller: notificationRelayController,
                        child: Container(),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      );
    }

    // if (maxWidth!=null) { // this needs to be always added, otherwise it will force rebuild of inner widgets when added/removed
      result = SliverCrossAxisConstrained(
        maxCrossAxisExtent: maxWidth ?? double.infinity,
        child: result,
      );
    // }
    result = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: result,
    );

    return result;

  }


  Widget _getRow(BuildContext context, RowModel? row, int index, double? minWidth){
    if (row==null){

      return Container(
        color: _getMaterialColor(),
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: widget.emptyWidget ?? TableEmptyWidget(
          tableController: widget.tableController ?? TableController()
            ..currentState = this
            ..valueFilters = valueFilters
            ..conditionFilters = conditionFilters,
        ),
      );

    } else {

      if (row==headerRowModel){
        return widget.headerRowBuilder?.call(context, headerRowModel!, minWidth)
            ?? _defaultRowBuilder.call(context, headerRowModel!, index, minWidth);
      } else {
        if (_enableSkipFrameWidgetForRows) {
          return SkipFrameWidget(
            paceholderBuilder: (context) {
              return SizedBox(
                height: row.height,
              );
            },
            childBuilder: (context) {
              return widget.rowBuilder?.call(context, row as RowModel<T>, index, minWidth, _defaultRowBuilder)
                  ?? _defaultRowBuilder.call(context, row as RowModel<T>, index, minWidth);
            },
          );
        } else {
          return widget.rowBuilder?.call(context, row as RowModel<T>, index, minWidth, _defaultRowBuilder)
              ?? _defaultRowBuilder.call(context, row as RowModel<T>, index, minWidth);
        }
      }

    }
  }
  Widget _defaultRowBuilder(BuildContext context, RowModel row, int index, double? minWidth) {

    int maxFlex = 0;
    double flexibleMinWidth = minWidth ?? 0;
    for (final key in currentColumnKeys??row.values.keys) {
      if (widget.columns?[key]?.width!=null) {
        flexibleMinWidth -= widget.columns![key]!.width!;
      } else {
        maxFlex += _getFlex(key);
      }
    }
    flexibleMinWidth = flexibleMinWidth.coerceAtLeast(0);
    int cols = (((currentColumnKeys??row.values.keys).length) + (_showLeadingControls ? 1 : 0))
        * (widget.verticalDivider==null ? 1 : 2)
        + (widget.verticalDivider==null ? 0 : 1);


    final String? rowDisabledReason = row==headerRowModel ? null
        : widget.rowDisabledValidator?.call(row as RowModel<T>);
    final String? tooltip = row==headerRowModel ? null
        : rowDisabledReason??widget.rowTooltipGetter?.call(row as RowModel<T>);
    Widget builder(BuildContext context, BoxConstraints? constraints) {
      final Map<Widget, ActionState> rowActionStates = {
        for (final e in widget.rowActions)
          e: e.getStateForMaxWidth(constraints?.maxWidth??double.infinity),
      };
      List<Widget> rowActions = row==headerRowModel ? []
          : widget.rowActions.map((e) => e.copyWith(
              onTap: (context) {
                e.onRowTap?.call(context, row as RowModel<T>);
              },
              disablingError: e.disablingErrorGetter?.call(context, row as RowModel<T>),
              breakpoints: e.breakpointsGetter?.call(context, row as RowModel<T>) ?? e.breakpoints,
            ),).toList();
      for (final e in rowActions) {
        if (!rowActionStates.containsKey(e)) {
          rowActionStates[e] = e is ActionFromZero
              ? e.getStateForMaxWidth(constraints?.maxWidth??double.infinity)
              : ActionState.none;
        }
      }
      final expandActions = [
        if (row.hasExpandableRows!=null && row!=headerRowModel)
          ActionFromZero(
            icon: Icon(row.hasExpandableRows! ? MaterialCommunityIcons.arrow_collapse_up : MaterialCommunityIcons.arrow_expand_down,),
            title: row.hasExpandableRows! ? 'Colapsar fila' : 'Expandir fila',
            breakpoints: {0: ActionState.popup},
            onTap: (context) {
              for (int i=index; i<allFiltered.length && (i==index || allFiltered[i].depth>row.depth); i++) {
                toggleRowExpanded(allFiltered[i], i,
                  expanded: !row.hasExpandableRows!,
                  forceChildrenAsSame: true,
                  updateHasExpandableRows: false,
                );
              }
              int i = index;
              while (allFiltered[i].depth>0) {
                i--;
              }
              _recalculateHasExpandableRows(allFiltered[i]);
              _recalculateExpandableRowsExist();
            },
          ),
        if (_expandableRowsExist!=null)
          ActionFromZero(
            icon: Icon(_expandableRowsExist! ? MaterialCommunityIcons.arrow_collapse_up : MaterialCommunityIcons.arrow_expand_down,),
            title: _expandableRowsExist! ? 'Colapsar todas las filas' : 'Expandir todas las filas',
            breakpoints: {0: ActionState.popup},
            onTap: (context) {
              for (int i=0; i<allFiltered.length; i++) {
                toggleRowExpanded(allFiltered[i], i,
                  expanded: !_expandableRowsExist!,
                  forceChildrenAsSame: true,
                  updateHasExpandableRows: false,
                );
              }
              for (final e in filtered) {
                _setAllChildrenHasExpandableRows(e, !_expandableRowsExist!);
              }
              _recalculateExpandableRowsExist();
            },
          ),
      ];
      if (expandActions.isNotEmpty) {
        if (rowActions.isNotEmpty) rowActions.add(ActionFromZero.divider());
        rowActions.addAll(expandActions);
      }
      if (widget.allowCustomization) {
        rowActions = addManageActions(context,
          actions: rowActions,
          controller: widget.tableController ?? (TableController()
            ..currentState = this
            ..columnKeys = columnKeys
            ..currentColumnKeys = currentColumnKeys
          ),
        );
      }
      if (widget.exportPathForExcel != null) {
        rowActions = addExportExcelAction(context,
          actions: rowActions,
          exportPathForExcel: widget.exportPathForExcel!,
          tableController: widget.tableController ?? (TableController()..currentState=this),
        );
      }
      // This assumes standard icon size, custom action iconBuilders will probably break the table,
      // this is very prone to breaking, but there is no other efficient way of doing it
      final actionsWidth = widget.rowActions.where((e) => rowActionStates[e]!.shownOnPrimaryToolbar).length * 48.0;
      Widget decorationBuilder(BuildContext context, int j) {
        bool addSizing = true;
        if (widget.verticalDivider!=null){
          if (j%2==0) {
            return Padding(
            padding: EdgeInsets.only(left: j==0 ? 0 : 1, right: j==cols-1 ? 0 : 1,),
            child: widget.verticalDivider,
          );
          }
          j = (j-1)~/2;
        }
        Widget? result;
        if (_showLeadingControls){
          if (j==0){
            addSizing = false;
            result = SizedBox(width: _leadingControlsWidth, height: double.infinity,);
          } else{
            j--;
          }
        }
        final colKey = (currentColumnKeys??row.values.keys.toList())[j];
        final col = widget.columns?[colKey];
        if (result==null && col?.flex==0){
          return const SizedBox.shrink();
        }
        result = Container( // ignore: use_decorated_box
                            // decoration is nullable, so it can't be passed to a DecoratedBox, and this ensures result!=null
          decoration: _getDecoration(row, index, colKey, rowDisabledReason!=null),
          child: result,
        );
        if (addSizing){
          if (col?.width!=null) {
            result = SizedBox(width: col!.width, child: result,);
          } else {
            if (constraints!=null && minWidth!=null && constraints.maxWidth<minWidth) {
              return SizedBox(width: flexibleMinWidth * (_getFlex(colKey)/maxFlex), child: result,);
            } else {
              return Expanded(flex: _getFlex(colKey), child: result,);
            }
          }
        }
        return result;
      }
      Widget cellBuilder(BuildContext context, int j) {
        if (widget.verticalDivider!=null) {
          if (j%2==0) {
            return Padding(
            padding: EdgeInsets.only(left: j==0 ? 0 : 1, right: j==cols-1 ? 0 : 1,),
            child: widget.verticalDivider,
          );
          }
          j = (j-1)~/2;
        }
        if (_showLeadingControls) {
          if (j==0) {
            // return SizedBox(width: _leadingControlsWidth,);
            final theme = Theme.of(context);
            return Transform.translate(
              offset: Offset(row.depth*_depthPadding, 0),
              child: SizedBox(
                width: _leadingControlsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (row.isExpandable)
                      SizedBox(
                        width: _dropdownButtonWidth,
                        child: IconButton(
                          splashRadius: 24,
                          onPressed: row.isFilteredInBecauseOfChildren ? null : () {
                            toggleRowExpanded(row as RowModel<T>, index);
                          },
                          icon: OverflowBox(
                            alignment: Alignment.center,
                            maxHeight: double.infinity, maxWidth: double.infinity,
                            child: SelectableIcon(
                              selected: row.expanded || row.isFilteredInBecauseOfChildren,
                              icon: Icons.expand_less,
                              selectedColor: row.isFilteredInBecauseOfChildren
                                  ? theme.disabledColor
                                  : theme.colorScheme.secondary,
                              unselectedOffset: 0.25,
                              selectedOffset: 0.5,
                            ),
                          ),
                        ),
                      ),
                    if (row==headerRowModel
                        ? row.onCheckBoxSelected!=null || widget.onAllSelected!=null
                        : row.onCheckBoxSelected!=null || (row.children.isNotEmpty && _showCheckmarks))
                      SizedBox(
                        width: _checkmarkWidth,
                        child: StatefulBuilder(
                          builder: (context, checkboxSetState) {
                            return Checkbox(
                              tristate: true,
                              value: row==headerRowModel
                                  ? allFiltered.some((e) => e.selected)
                                  : row.onCheckBoxSelected!=null
                                      ? row.selected
                                      : row.allChildren.some((e) => e.selected),
                              onChanged: (row==headerRowModel ? allFiltered.isEmpty : rowDisabledReason!=null) ? null : (value) {
                                value = value ?? false;
                                if (row==headerRowModel) {
                                  if (row.onCheckBoxSelected!=null) {
                                    if (row.onCheckBoxSelected!(row, value) ?? false) {
                                      checkboxSetState(() {});
                                    }
                                  } else if (widget.onAllSelected!(value, allFiltered) ?? false) {
                                    setState(() {});
                                  }
                                } else {
                                  if (row.onCheckBoxSelected!=null) {
                                    if (row.onCheckBoxSelected!(row, value) ?? false) {
                                      if (row.depth==0) {
                                        checkboxSetState(() {});
                                      } else {
                                        setState(() {}); // nested rows need to set state for whole table, so parents can react to potential changes
                                      }
                                    }
                                  } else {
                                    bool result = false;
                                    for (final e in row.allFilteredChildren) {
                                      if (e.onCheckBoxSelected!=null) {
                                        final evaluation = e.onCheckBoxSelected!(e, value) ?? false;
                                        result = result || evaluation;
                                      }
                                    }
                                    if (result) {
                                      setState(() {});
                                    }
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else{
            j--;
          }
        }
        final colKey = (currentColumnKeys??row.values.keys.toList())[j];
        final col = widget.columns?[colKey];
        if (col?.flex==0){
          return const SizedBox.shrink();
        }
        Widget result = Container(
          height: row.height, // widget.enableFixedHeightForListRows ? row.height : null,
          alignment: Alignment.center,
          padding: row==headerRowModel
              ? null
              : row.depth>0 && j==0
                  ? widget.cellPadding.copyWith(left: widget.cellPadding.left + row.depth*_depthPadding)
                  : widget.cellPadding,
          child: SizedBox(
              width: double.infinity,
              child: row==headerRowModel
                  ? defaultHeaderCellBuilder(context, headerRowModel!, colKey)
                  : widget.cellBuilder?.call(context, row as RowModel<T>, colKey)
                      ?? TableFromZeroState.defaultCellBuilder<T>(context, row as RowModel<T>, colKey, col, _getStyle(context, row, colKey, rowDisabledReason!=null), _getAlignment(colKey)),
          ),
        );
        if (row.onCellTap!=null || row.onCellDoubleTap!=null || row.onCellLongPress!=null || row.onCellHover!=null){
          result = Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.enabled&&row.onCellTap!=null&&row.onCellTap!(colKey)!=null ? () {
                row.onCellTap!(colKey)!.call(row);
              } : null,
              onDoubleTap: widget.enabled&&row.onCellDoubleTap!=null&&row.onCellDoubleTap!(colKey)!=null
                  ? () => row.onCellDoubleTap!(colKey)!.call(row) : null,
              onLongPress: widget.enabled&&row.onCellLongPress!=null&&row.onCellLongPress!(colKey)!=null
                  ? () => row.onCellLongPress!(colKey)!.call(row) : null,
              onHover: widget.enabled&&row.onCellHover!=null&&row.onCellHover!(colKey)!=null
                  ? (value) => row.onCellHover!(colKey)!.call(row, value) : null,
              child: result,
            ),
          );
        }
        if (col?.width!=null){
          return SizedBox(width: col!.width, child: result,);
        } else {
          if (constraints!=null && minWidth!=null && constraints.maxWidth<minWidth) {
            return SizedBox(width: (flexibleMinWidth * (_getFlex(colKey)/maxFlex)), child: result,);
          } else {
            return Flexible(flex: _getFlex(colKey), child: result,);
          }
        }
      }
      Widget background;
      Widget result;
      if (constraints!=null && minWidth!=null && constraints.maxWidth<minWidth) {
        background = NotificationListener(
          onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: sharedController,
            itemBuilder: decorationBuilder,
            itemCount: cols,
            padding: EdgeInsets.symmetric(horizontal: widget.tableHorizontalPadding),
          ),
        );
        if (row.height!=null) {
          result = SizedBox(
            height: row.height,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: sharedController,
              itemBuilder: cellBuilder,
              itemCount: cols,
              padding: EdgeInsets.symmetric(horizontal: widget.tableHorizontalPadding),
              cacheExtent: 99999999,
            ),
          );
        } else {
          result = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: sharedController,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  SizedBox(width: widget.tableHorizontalPadding,),
                  for (int index=0; index<cols; index++)
                    cellBuilder(context, index),
                  SizedBox(width: widget.tableHorizontalPadding,),
                ],
              ),
            ),
          );
        }
        result = ScrollOpacityGradient(
          scrollController: sharedController,
          direction: OpacityGradient.horizontal,
          child: (widget.columns!=null && widget.showHeaders ? row==headerRowModel : index==0)
              ? NotificationRelayListener(
                controller: notificationRelayController,
                consumeRelayedNotifications: true,
                child: result,
              )
              : NotificationListener(
                onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
                child: result,
              ),
        );
      } else {
        background = Row(
          children: List.generate(cols, (j) => decorationBuilder(context, j)),
        );
        result = Row(
          children: List.generate(cols, (j) => cellBuilder(context, j)),
        );
        if (widget.tableHorizontalPadding>0){
          background = Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.tableHorizontalPadding),
            child: background,
          );
          result = Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.tableHorizontalPadding),
            child: result,
          );
        }
      }
      if (row!=headerRowModel && !(row.rowAddonIsCoveredByGestureDetector??false)){
        result = _buildRowGestureDetector(
          context: context,
          row: row as RowModel<T>,
          index: index,
          child: result,
          enabled: rowDisabledReason==null,
          tooltip: tooltip,
        );
      }
      if (row==headerRowModel) {
        result = Padding(
          padding: EdgeInsets.only(right: actionsWidth),
          child: result,
        );
      } else if (rowActions.isNotEmpty) {
        result = AppbarFromZero(
          title: result,
          actions: rowActions,
          useFlutterAppbar: false,
          toolbarHeight: row.height,
          addContextMenu: false,
          skipTraversalForActions: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          paddingRight: 0,
          titleSpacing: 0,
          transitionsDuration: 0.milliseconds,
        );
        if (row.height!=null) {
          result = SizedBox(
            height: row.height,
            child: OverflowBox( // hack to fix Appbar actions overflowing when rowHeight<40
              maxHeight: max(40, row.height??0),
              child: result,
            ),
          );
        }
        result = Material(
          type: MaterialType.transparency,
          child: result,
        );
      }
      if (row.rowAddon!=null) {
        Widget addon;
        if (row.expanded || !row.rowAddonIsExpandable) {
          addon = _wrapRowAddon(row, constraints, minWidth)!;
          if (row.rowAddonIsExpandable && rowAddonEntranceAnimations[row]!=null) {
            addon = _buildEntranceAnimation(
              child: addon,
              row: row,
              animation: rowAddonEntranceAnimations[row]!,
            );
          }
        } else {
          addon = const SizedBox.shrink();
        }
        Widget top, bottom;
        if (row.rowAddonIsAboveRow ?? false) {
          top = addon;
          bottom = result;
        } else {
          top = result;
          bottom = addon;
        }
        if (row.rowAddonIsSticky ?? widget.enableStickyHeaders){
          result = CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverStickyHeader(
                scrollController: widget.scrollController,
                header: top,
                sliver: SliverToBoxAdapter(child: bottom),
                stickOffset: row is! RowModel<T> ? 0
                    : index==0 ? 0
                    : widget.stickyOffset + (row.height??0),
              ),
            ],
          );
        } else{
          result = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              top,
              bottom,
            ],
          );
        }
      }
      if (row!=headerRowModel && (row.rowAddonIsCoveredByGestureDetector??false)){
        result = _buildRowGestureDetector(
          context: context,
          row: row as RowModel<T>,
          index: index,
          child: result,
          enabled: rowDisabledReason==null,
          tooltip: tooltip,
        );
      }
      result = Stack(
        key: row.rowKey ?? ValueKey(row.id),
        children: [
          Positioned.fill(
            child: Align(
              alignment: (row.rowAddonIsAboveRow??false)
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: SizedBox(
                height: (row.rowAddonIsCoveredByBackground??true)
                    ? double.infinity
                    : row.height,
                child: Stack(
                  children: [
                    Container(
                      decoration: _getDecoration(row, index, null, rowDisabledReason!=null),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: actionsWidth),
                      child: background,
                    ),
                  ],
                ),
              ),
            ),
          ),
          result,
        ],
      );
      if (row!=headerRowModel) {
        result = ContextMenuFromZero(
          onShowMenu: () => row.focusNode.requestFocus(),
          actions: rowActions.where((e) => (rowActionStates[e]??ActionState.popup) != ActionState.none).toList().cast(),
          child: result,
        );
      }
      if (widget.horizontalDivider!=null) {
        result = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            result,
            widget.horizontalDivider!,
          ],
        );
      }
      result = FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: result,
      );
      return result;
    }

    Widget result;
    // bool intrinsicDimensions = context.findAncestorWidgetOfExactType<IntrinsicHeight>()!=null
    //     || context.findAncestorWidgetOfExactType<IntrinsicWidth>()!=null;
    // if (!intrinsicDimensions && (minWidth!=null || widget.maxWidth!=null)){
    if (minWidth!=null){
      result = LayoutBuilder(builder: builder,);
    } else {
      result = builder(context, null);
    }
    if (nestedRowEntranceAnimations[row]!=null) {
      result = _buildEntranceAnimation(
        child: result,
        row: row,
        animation: nestedRowEntranceAnimations[row]!,
      );
    }
    result = ClipRect(
      clipBehavior: Clip.hardEdge,
      child: result,
    );
    return result;

  }
  Widget _buildRowGestureDetector({
    required BuildContext context,
    required RowModel<T> row,
    required int index,
    required Widget child,
    bool enabled = true,
    String? tooltip,
  }) {
    Widget result = child;
    if (enabled && (row.onRowTap!=null || row.onCheckBoxSelected!=null || row.isExpandable)) {
      result = InkWell(
        onTap: !widget.enabled ? null
            : row.onRowTap!=null
                ? () => row.onRowTap!(row)
            : row.onCheckBoxSelected!=null
                ? () {
                    if (row.onCheckBoxSelected!(row, !(row.selected??false)) ?? false) {
                      setState(() {});
                    }
                  }
            : row.isExpandable && !row.isFilteredInBecauseOfChildren
                ? () {
                    toggleRowExpanded(row, index);
                  }
            : null,
        onDoubleTap: widget.enabled&&row.onRowDoubleTap!=null ? () => row.onRowDoubleTap!(row) : null,
        onLongPress: widget.enabled&&row.onRowLongPress!=null ? () => row.onRowLongPress!(row) : null,
        onHover: widget.enabled&&row.onRowHover!=null ? (value) => row.onRowHover!(row, value) : null,
        child: child,
      );
    }
    if (tooltip!=null) {
      result = TooltipFromZero(
        message: tooltip,
        child: result,
      );
    }
    result = Material(
      type: MaterialType.transparency,
      child: EnsureVisibleWhenFocused(
        focusNode: row.focusNode,
        child: Focus(
          focusNode: row.focusNode,
          skipTraversal: true,
          child: result,
        ),
      ),
    );
    return result;
  }
  Widget _buildEntranceAnimation({
    required Widget child,
    required RowModel row,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value;
        return Transform.translate(
          offset: Offset(-128*(1-value), -(row.height??36)*(1-value)*0.5),
          transformHitTests: false,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }
  Widget? _wrapRowAddon(RowModel row, BoxConstraints? constraints, double? minWidth) {
    if (row.rowAddon==null) return null;
    if ((row.rowAddonIsCoveredByScrollable??true) && constraints!=null && minWidth!=null && constraints.maxWidth<minWidth) {
      return NotificationListener(
        onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
        child: SingleChildScrollView(
          controller: sharedController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth,
            child: row.rowAddon,
          ),
        ),
      );
    }
    return row.rowAddon;
  }

  Widget defaultHeaderCellBuilder(BuildContext context, RowModel row, dynamic colKey, {
    int autoSizeTextMaxLines = 1,
  }) {
    if (showFiltersLoading) {
      return ValueListenableBuilder<Map<dynamic, List<dynamic>>?>(
        valueListenable: availableFilters,
        builder: (context, availableFilters, child) {
          return _defaultHeaderCellBuilder(context, row, colKey,
            availableFilters: availableFilters,
            autoSizeTextMaxLines: autoSizeTextMaxLines,
          );
        },
      );
    } else {
      return _defaultHeaderCellBuilder(context, row, colKey,
        availableFilters: null, // doesn't matter
        autoSizeTextMaxLines: autoSizeTextMaxLines,
      );
    }
  }
  Widget _defaultHeaderCellBuilder(BuildContext context, RowModel row, dynamic colKey, {
    required Map<dynamic, List<dynamic>>? availableFilters,
    int autoSizeTextMaxLines = 1,
  }) {
    final col = widget.columns?[colKey];
    final compactName = col?.compactName ?? col?.name ?? ColModel.getRowValueString(row, colKey, col);
    final name = col?.name ?? ColModel.getRowValueString(row, colKey, col);
    bool export = context.findAncestorWidgetOfExactType<Export>()!=null;
    if (!filterGlobalKeys.containsKey(colKey)) {
      filterGlobalKeys[colKey] = GlobalKey();
    }
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleSmall!.copyWith(
      color: theme.textTheme.bodyLarge!.color!
          .withOpacity(theme.brightness==Brightness.light ? 0.7 : 0.8),
    );
    final alignment = _getAlignment(colKey);
    Widget result = Align(
      alignment: alignment==TextAlign.center ? Alignment.center
          : alignment==TextAlign.left||alignment==TextAlign.start ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: widget.cellPadding.left + (!export && sortedColumn==colKey ? 15 : 4),
              right: widget.cellPadding.right + (!export && (col?.filterEnabled??true) ? 10 : 4),
              top: widget.cellPadding.top,
              bottom: widget.cellPadding.bottom,
            ),
            child: AutoSizeText(
              compactName,
              style: textStyle,
              textAlign: alignment,
              maxLines: autoSizeTextMaxLines,
              softWrap: autoSizeTextMaxLines>1,
              minFontSize: 15,
              overflowReplacement: name!=compactName ? null : TooltipFromZero(
                message: name,
                waitDuration: Duration.zero,
                verticalOffset: -16,
                child: Text(
                  compactName,
                  textAlign: alignment,
                  style: textStyle.copyWith(
                    fontSize: 15,
                  ),
                  maxLines: autoSizeTextMaxLines,
                  softWrap: autoSizeTextMaxLines>1,
                  overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
                ),
              ),
            ),
          ),
          Positioned(
            left: -6, width: 32, top: 0, bottom: 0,
            child: OverflowBox(
              maxHeight: row.height, maxWidth: 32,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                child: (widget.enabled && !export && sortedColumn==colKey)
                    ? col?.buildSortedIcon(context, sortedAscending)
                        ?? Icon(
                            sortedAscending
                                ? MaterialCommunityIcons.sort_ascending
                                : MaterialCommunityIcons.sort_descending,
                            size: 20,
                            key: ValueKey(sortedAscending),
                            color: theme.colorScheme.secondary,
                          )
                    : const SizedBox(height: 24,),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child,),
                ),
              ),
            ),
          ),
          if (widget.enabled && !export && (col?.filterEnabled??true))
            Positioned(
              right: showFiltersLoading&&availableFilters==null ? -20 : -16,
              width: 48, top: 0, bottom: 0,
              child: OverflowBox(
                maxHeight: row.height, maxWidth: 48,
                alignment: Alignment.center,
                child: showFiltersLoading&&availableFilters==null
                    ? const Center(
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : TooltipFromZero(
                      message: FromZeroLocalizations.of(context).translate('filters'),
                      child: IconButton(
                        key: filterGlobalKeys[colKey],
                        icon: SelectableIcon(
                          selected: filtersApplied[colKey]??false,
                          icon: MaterialCommunityIcons.filter_outline,
                          selectedIcon: MaterialCommunityIcons.filter,
                          selectedColor: theme.colorScheme.secondary,
                          unselectedColor: theme.textTheme.bodyLarge!.color!
                            .withOpacity(theme.brightness==Brightness.light ? 0.7 : 0.8),
                          unselectedOffset: 0,
                          selectedOffset: 0,
                        ),
                        splashRadius: 20,
                        onPressed: () => _showFilterPopup(colKey),
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
    headerFocusNodes[colKey] ??= FocusNode();
    if (compactName!=name) {
      result = TooltipFromZero(
        message: name,
        preferBelow: false,
        child: result,
      );
    }
    result = Material(
      type: MaterialType.transparency,
      child: EnsureVisibleWhenFocused(
        focusNode: headerFocusNodes[colKey]!,
        child: InkWell(
          focusNode: headerFocusNodes[colKey],
          onTap: col?.onHeaderTap!=null
              || col?.sortEnabled==true ? () {
            headerFocusNodes[colKey]!.requestFocus();
            if (col?.sortEnabled==true){
              if (sortedColumn==colKey) {
                setState(() {
                  sortedAscending = !sortedAscending;
                  sort();
                });
              } else {
                setState(() {
                  sortedColumn = colKey;
                  sortedAscending = col?.defaultSortAscending ?? true;
                  sort();
                });
              }
            }
            if (col?.onHeaderTap!=null){
              col?.onHeaderTap!(colKey);
            }
          } : null,
          child: result,
        ),
      ),
    );
    List<Widget> colActions = [
      if (col?.sortEnabled ?? true)
        ActionFromZero(
          title: 'Ordenar Ascendente', // TODO 3 internationalize
          icon: const Icon(MaterialCommunityIcons.sort_ascending),
          onTap: (context) {
            if (sortedColumn!=colKey || !sortedAscending) {
              setState(() {
                sortedColumn = colKey;
                sortedAscending = true;
                sort();
              });
            }
          },
        ),
      if (col?.sortEnabled ?? true)
        ActionFromZero(
          title: 'Ordenar Descendente', // TODO 3 internationalize
          icon: const Icon(MaterialCommunityIcons.sort_descending),
          onTap: (context) {
            if (sortedColumn!=colKey || sortedAscending) {
              setState(() {
                sortedColumn = colKey;
                sortedAscending = false;
                sort();
              });
            }
          },
        ),
      if (currentColumnKeys!=null && widget.allowCustomization)
        ActionFromZero(
          title: 'Esconder Columna', // TODO 3 internationalize
          icon: const Icon(Icons.visibility_off),
          onTap: (context) {
            setState(() {
              currentColumnKeys?.remove(colKey);
            });
          },
        ),
    ];
    if (widget.allowCustomization) {
      colActions = addManageActions(context,
        actions: colActions,
        controller: widget.tableController ?? (TableController()
          ..currentState = this
          ..columnKeys = columnKeys
          ..currentColumnKeys = currentColumnKeys
        ),
        availableFilters: availableFilters,
        colKey: colKey,
        col: col,
      );
    }
    if (widget.exportPathForExcel != null) {
      colActions = addExportExcelAction(context,
        actions: colActions,
        exportPathForExcel: widget.exportPathForExcel!,
        tableController: widget.tableController ?? (TableController()..currentState=this),
      );
    }
    result = ContextMenuFromZero(
      onShowMenu: () => headerFocusNodes[colKey]!.requestFocus(),
      actions: colActions.cast<ActionFromZero>(),
      child: result,
    );
    return result;
  }

  Future<bool> _showFilterPopup(dynamic colKey, {
    bool updateStateIfModified = true,
    GlobalKey? anchorKey,
  }) async {
    final col = widget.columns?[colKey];
    final callback = col?.showFilterPopupCallback ?? TableFromZeroFilterPopup.showDefaultFilterPopup;
    bool modified = await callback(
      context: context,
      controller: widget.tableController
          ?? TableController()
              ..currentState = this
              ..valueFilters = valueFilters
              ..conditionFilters = conditionFilters,
      colKey: colKey,
      anchorKey: anchorKey ?? filterGlobalKeys[colKey],
    );
    if (modified && mounted) {
      _updateFiltersApplied();
      if (updateStateIfModified) {
        setState(() {
          widget.tableController?.notifyListeners();
          filter();
        });
      }
    }
    return modified;
  }
  Future<void> _showManageTablePopup(TableController controller) async {
    if (currentColumnKeys!=null && widget.columns!=null ) {
      final result = await TableFromZeroManagePopup.showDefaultManagePopup(
        context: context,
        controller: controller,
      );
      if ((result.modified || result.filtersModified) && mounted) {
        setState(() {
          widget.tableController?.notifyListeners();
          if (result.filtersModified) {
            _updateFiltersApplied();
            filter();
          }
        });
      }
    }
  }

  static Widget defaultCellBuilder<T>(BuildContext context, RowModel<T> row, dynamic colKey, ColModel? col, TextStyle? style, TextAlign alignment) {
    final message = ColModel.getRowValueString(row, colKey, col);
    const autoSizeTextMaxLines = 1;
    Widget result = AutoSizeText(
      message,
      style: style,
      textAlign: alignment,
      maxLines: autoSizeTextMaxLines,
      softWrap: autoSizeTextMaxLines>1,
      minFontSize: 15,
      overflowReplacement: TooltipFromZero(
        message: message,
        waitDuration: Duration.zero,
        verticalOffset: -16,
        child: Text(
          message,
          style: (style ?? const TextStyle()).copyWith(
            fontSize: 15,
          ),
          textAlign: alignment,
          maxLines: autoSizeTextMaxLines,
          softWrap: autoSizeTextMaxLines>1,
          overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
        ),
      ),
    );
    return result;
  }

  BoxDecoration? _getDecoration(RowModel row, int index, dynamic colKey, bool isDisabled,){
    bool isHeader = row==headerRowModel;
    Color? backgroundColor = _getBackgroundColor(row, colKey, isHeader);
    if (backgroundColor!=null) {
      bool applyDarker = widget.alternateRowBackgroundBrightness
          && _shouldApplyDarkerBackground(backgroundColor, row, index, colKey, isHeader);
      if (backgroundColor.opacity<1 && widget.alternateRowBackgroundBrightness) {
        backgroundColor = backgroundColor.opacity==0
            ? _getMaterialColor()
            : Color.alphaBlend(backgroundColor, _getMaterialColor());
      }
      if (applyDarker) {
        backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.965), Colors.black);
      }
    }
    if (isDisabled) {
      backgroundColor ??= _getMaterialColor();
      backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.66), Theme.of(context).disabledColor);
      if (backgroundColor.opacity<1) {
        backgroundColor = Color.alphaBlend(backgroundColor, _getMaterialColor());
      }
    }
    return backgroundColor==null ? null : BoxDecoration(color: backgroundColor);
  }
  Color _getMaterialColor() => widget.backgroundColor ?? Material.of(context).color ?? Theme.of(context).cardColor;
  // Color _getBrightnessColor() => Theme.of(context).brightness==Brightness.light ? Colors.white : Color.fromRGBO(0, 0, 0, 1);
  Color? _getBackgroundColor(RowModel row, dynamic colKey, bool isHeader){
    Color? backgroundColor;
    if (isHeader){
      backgroundColor = widget.columns?[colKey]?.backgroundColor;
    } else {
      backgroundColor = widget.rowStyleTakesPriorityOverColumn
          ? (row.backgroundColor ?? widget.columns?[colKey]?.backgroundColor)
          : (widget.columns?[colKey]?.backgroundColor ?? row.backgroundColor);
    }
    return backgroundColor ?? _getMaterialColor();
  }
  bool _shouldApplyDarkerBackground(Color? current, RowModel row, int index, dynamic colKey, bool isHeader) {
    if (widget.alternateRowBackgroundSmartly??allFiltered.length<50) {
      if (index<0 || index>allFiltered.length) {
        return false;
      } else if (index==0) {
        return true;
      } else {
        Color? previous = _getBackgroundColor(allFiltered[index-1], colKey, isHeader);
        if (previous!=current) return false;
        return !_shouldApplyDarkerBackground(previous, allFiltered[index-1], index-1, colKey, isHeader);
      }
    } else {
      return index.isEven;
    }
  }

  TextAlign _getAlignment(dynamic colKey){
    return widget.columns?[colKey]?.alignment ?? TextAlign.left;
  }

  TextStyle? _getStyle(BuildContext context, RowModel<T> row, dynamic key, bool isDisabled){
    TextStyle? style;
    if (widget.rowStyleTakesPriorityOverColumn) {
      style = row.textStyle ?? widget.columns?[key]?.textStyle;
    } else {
      style = widget.columns?[key]?.textStyle ?? row.textStyle;
    }
    if (isDisabled) {
      style ??= Theme.of(context).textTheme.bodyLarge;
      style = style!.copyWith(
        color: Color.alphaBlend(style.color!.withOpacity(0.66), Theme.of(context).disabledColor),
      );
    }
    return style;
  }

  int _getFlex(dynamic key) {
    return widget.columns?[key]?.flex ?? 1;
  }

  static List<Widget> addManageActions(BuildContext context, {
    required List<Widget> actions,
    required TableController controller,
    Map<dynamic, List<dynamic>>? availableFilters,
    dynamic colKey,
    ColModel? col,
  }) {
    final clearFiltersAction = getClearAllFiltersAction(controller: controller);
    final manageActions = [
      if (colKey!=null && (col?.filterEnabled ?? true) && (!showFiltersLoading||availableFilters!=null))
        getOpenFilterPopupAction(context, controller: controller, col: col, colKey: colKey),
      if (clearFiltersAction!=null)
        clearFiltersAction,
      if (controller.currentColumnKeys!=null && controller.columns!=null)
        ActionFromZero(
          title: 'Personalizar Tabla...', // TODO 3 internationalize
          icon: const Icon(Icons.settings),
          breakpoints: {0: ActionState.popup},
          onTap: (context) => controller.currentState!._showManageTablePopup(controller),
        ),
    ];
    return [
      ...actions,
      if (actions.isNotEmpty && manageActions.isNotEmpty)
        ActionFromZero.divider(
          breakpoints: {0: ActionState.popup},
        ),
      ...manageActions,
    ];
  }
  static ActionFromZero getOpenFilterPopupAction(BuildContext context, {
    required TableController controller,
    ColModel? col,
    dynamic colKey,
    GlobalKey? globalKey,
    ValueChanged<bool>? onPopupResult,
    bool updateStateIfModified = true,
  }) {
    final theme = Theme.of(context);
    return ActionFromZero(
      title: 'Filtros...', // TODO 3 internationalize
      icon: SelectableIcon(
        selected: controller.currentState?.filtersApplied[colKey]??false,
        icon: MaterialCommunityIcons.filter_outline,
        selectedIcon: MaterialCommunityIcons.filter,
        selectedColor: theme.brightness==Brightness.light ? theme.primaryColor : theme.colorScheme.secondary,
        unselectedColor: theme.textTheme.bodyLarge!.color,
        unselectedOffset: 0,
        selectedOffset: 0,
      ),
      disablingError: (col?.filterEnabled ?? true) ? null : '',
      breakpoints: {0: ActionState.popup},
      onTap: (context) async {
        final result = await controller.currentState!._showFilterPopup(colKey,
          anchorKey: globalKey,
          updateStateIfModified: updateStateIfModified,
        );
        onPopupResult?.call(result);
      },
    );
  }
  static ActionFromZero? getClearAllFiltersAction({
    required TableController controller,
    bool skipConditions = false,
    bool updateStateIfModified = true,
    VoidCallback? onDidTap,
  }) {
    if (skipConditions || (controller.columns!=null && controller.columns!.any((key, value) => (value.filterEnabled??true)))) {
      return ActionFromZero(
        title: 'Limpiar todos los Filtros', // TODO 3 internationalize
        icon: const Icon(MaterialCommunityIcons.filter_remove),
        breakpoints: {0: ActionState.popup},
        onTap: !controller.currentState!.filtersApplied.any((k, v) => v) ? null : (context) {
          controller.currentState!.clearAllFilters(
            updateStateIfModified: updateStateIfModified,
          );
          onDidTap?.call();
        },
      );
    }
    return null;
  }
  void clearAllFilters({
    bool updateStateIfModified = true,
  }) {
    for (final key in valueFilters.keys) {
      for (final val in valueFilters[key]!.keys) {
        valueFilters[key]![val] = false;
      }
    }
    for (final key in conditionFilters.keys) {
      conditionFilters[key] = [];
    }
    _updateFiltersApplied();
    if (updateStateIfModified) {
      setState(filter);
    }
  }
  static List<Widget> addExportExcelAction(BuildContext context, {
    required List<Widget> actions,
    required TableController tableController,
    required FutureOr<String> exportPathForExcel,
  }) {
    return [
      ...actions,
      if (actions.isNotEmpty)
        ActionFromZero.divider(
          breakpoints: {0: ActionState.popup},
        ),
      ActionFromZero(
        title: 'Exportar Excel',
        icon: const Icon(MaterialCommunityIcons.file_excel),
        breakpoints: {0: ActionState.popup},
        onTap: (appbarContext) {
          String routeTitle = 'Excel';
          try {
            final route = GoRouteFromZero.of(context);
            routeTitle = route.title ?? route.path;
          } catch (_) {}
          showModalFromZero(
            context: appbarContext,
            builder: (context) => Export.excelOnly(
              scaffoldContext: appbarContext,
              title: "${DateFormat("yyyy-MM-dd hh.mm.ss aaa").format(DateTime.now())} - $routeTitle",
              path: exportPathForExcel,
              excelSheets: () => {
                routeTitle: tableController,
              },
            ),
          );
        },
      ),
    ];
  }

  bool toggleRowExpanded(RowModel<T> row, int index, {
    bool? expanded,
    bool forceChildrenAsSame = false,
    bool updateHasExpandableRows = true,
  }) {
    expanded ??= !row.expanded;
    if (row.isExpandable && expanded!=row.expanded && !row.isFilteredInBecauseOfChildren) {
      setState(() {
        if (expanded!) {
          row.expanded = true;
          if (forceChildrenAsSame) {
            _setAllChildrenExpanded(row, true);
          }
          final toAdd = _getVisibleFilteredRowsSorted(row.filteredChildren);
          allFiltered.insertAll(index+1, toAdd);
          final animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
          final curvedAnimation = CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic);
          animationController.forward();
          rowAddonEntranceAnimations[row] = curvedAnimation;
          for (final e in toAdd) {
            nestedRowEntranceAnimations[e] = curvedAnimation;
          }
        } else {
          allFiltered.removeRange(index+1, index+row.filteredLength);
          row.expanded = false;
          if (forceChildrenAsSame) {
            _setAllChildrenExpanded(row, false);
          }
        }
        if (updateHasExpandableRows) {
          // if (forceChildrenAsSame) { // TODO 3 PERFORMANCE, deep iteration could be avoided since we know all children are the same, by _setAllChildrenHasExpandableRows on them reccursively and then trusting the parent when recalculating
          // }
          int i = index;
          while (allFiltered[i].depth>0) {
            i--;
          }
          _recalculateHasExpandableRows(allFiltered[i]);
          _recalculateExpandableRowsExist();
        }
      });
      return true;
    }
    return false;
  }
  List<RowModel<T>> _getVisibleFilteredRowsSorted(List<RowModel<T>> rows) {
    final List<RowModel<T>> result = [];
    for (final e in rows) {
      result.add(e);
      if (e.expanded && e.filteredChildren.isNotEmpty) {
        result.addAll(_getVisibleFilteredRowsSorted(e.filteredChildren));
      }
    }
    return result;
  }
  void _setAllChildrenExpanded(RowModel<T> row, bool expanded) {
    row.expanded = expanded;
    for (final e in row.filteredChildren) {
      _setAllChildrenExpanded(e, expanded);
    }
  }
  void _setAllChildrenHasExpandableRows(RowModel<T> row, bool hasExpandableRows) {
    if (row.hasExpandableRows!=null) {
      row.hasExpandableRows = hasExpandableRows;
    }
    for (final e in row.filteredChildren) {
      _setAllChildrenHasExpandableRows(e, hasExpandableRows);
    }
  }
  bool? _recalculateHasExpandableRows(RowModel<T> row) {
    bool? hasExpandableRows = row.isExpandable ? row.expanded : null;
    for (final e in row.filteredChildren) {
      final subResult = _recalculateHasExpandableRows(e);
      if (subResult!=null) {
        hasExpandableRows = hasExpandableRows! && subResult;
      }
    }
    row.hasExpandableRows = hasExpandableRows;
    return hasExpandableRows;
  }
  void _recalculateExpandableRowsExist() {
    bool? hasExpandableRows;
    for (final e in filtered) {
      if (e.hasExpandableRows!=null) {
        hasExpandableRows = (hasExpandableRows??true) && e.hasExpandableRows!;
      }
    }
    _expandableRowsExist = hasExpandableRows;
  }

  void sort({bool notifyListeners=true}) {
    smartSort<T>(sorted,
      sortedColumnKey: sortedColumn,
      sortedAscending: sortedAscending,
    );
    widget.onSort?.call(sorted);
    filter(notifyListeners: notifyListeners);
  }
  static void smartSort<T>(List<RowModel<T>> list, {
    bool sortedAscending = true,
    Object? sortedColumnKey,
    ColModel? col,
  }) {
    if (list.isEmpty) return;
    mergeSort<RowModel<T>>(list.cast<RowModel<T>>(), compare: ((RowModel<T> a, RowModel<T> b) {
      if ((a.alwaysOnTop!=null || b.alwaysOnTop!=null) && a.alwaysOnTop!=b.alwaysOnTop) {
        if (a.alwaysOnTop==true || b.alwaysOnTop==false) return -1;
        if (a.alwaysOnTop==false || b.alwaysOnTop==true) return 1;
      }
      if (sortedColumnKey==null) {
        return 0;
      }
      dynamic aVal = ColModel.getRowValue(a, sortedColumnKey, col);
      dynamic bVal = ColModel.getRowValue(b, sortedColumnKey, col);
      if (aVal!=null && aVal is! Comparable) aVal = ColModel.getRowValueString(a, sortedColumnKey, col);
      if (bVal!=null && bVal is! Comparable) bVal = ColModel.getRowValueString(b, sortedColumnKey, col);
      final sortedAscendingMultiplier = sortedAscending ? 1 : -1;
      if (aVal==null) {
        if (bVal==null) {
          return 0;
        }
        return 1;
      }
      if (bVal==null) {
        return -1;
      }
      if (aVal is ContainsValue) {
        return (aVal as dynamic).compareTo(bVal) * sortedAscendingMultiplier;
      }
      return bVal.compareTo(aVal) * -sortedAscendingMultiplier;
    }),);
    for (final e in list) {
      smartSort<T>(e.children,
        sortedColumnKey: sortedColumnKey,
        sortedAscending: sortedAscending,
      );
    }
  }

  void filter({bool notifyListeners=true}) {
    final result = getFilterResults(sorted);
    filtered = result.filtered;
    allFiltered = result.allFiltered;
    _expandableRowsExist = result.expandableRowsExist;
    if (mounted && notifyListeners) {
      widget.tableController?.notifyListeners();
    }
  }
  FilterResults<T> getFilterResults(List<RowModel<T>> rows, {
    dynamic skipColKey,
  }) {
    List<RowModel<T>> filtered = rows.where((e) => _passesFilters(e, skipColKey: skipColKey)).toList();
    for (final e in (widget.tableController?.extraFilters ?? [])) {
      filtered = e(filtered);
    }
    if (widget.onFilter!=null) {
      filtered = widget.onFilter!(filtered);
    }
    final result = FilterResults(
      filtered: filtered,
    );
    for (final e in result.filtered) {
      bool? hasExpandableRows = _setAllChildrenAsFiltered(e);
      result.allFiltered.addAll(e.visibleRows);
      if (hasExpandableRows!=null) {
        result.expandableRowsExist = (result.expandableRowsExist??true) && hasExpandableRows;
      }
    }
    final filteredSet = Set.from(result.filtered);
    for (final e in rows) {
      if (e.children.isNotEmpty && !filteredSet.contains(e)) {
        final subResult = getFilterResults(e.children);
        e.filteredChildren = subResult.filtered;
        e.hasExpandableRows = subResult.expandableRowsExist;
        if (subResult.expandableRowsExist!=null) {
          result.expandableRowsExist = (result.expandableRowsExist??true) && subResult.expandableRowsExist!;
        }
        if (subResult.filtered.isNotEmpty) {
          e.isFilteredInBecauseOfChildren = true;
          result.filtered.add(e);
          result.allFiltered.add(e);
          result.allFiltered.addAll(subResult.allFiltered);
          // if (e.expanded) { // subResult added always because rows where isFilteredInBecauseOfChildren are always forced expanded
          //   allResults.addAll(subResult[1]);
          // }
        }
      }
    }
    return result;
  }
  bool _passesFilters(RowModel<T> row, {
    dynamic skipColKey,
  }) {
    bool pass = true;
    for (final key in valueFilters.keys) {
      if (key!=skipColKey) {
        final col = widget.columns?[key];
        if (valueFiltersApplied[key] ?? false) {
          final value = ColModel.getRowValue(row, key, col);
          if (value is List || value is ComparableList || value is ListField) {
            final List list = value is List ? value
                : value is ComparableList ? value.list
                : value is ListField ? value.objects : [];
            pass = false;
            for (final e in list) {
              pass = valueFilters[key]![e] ?? false;
              if (pass) {
                break; // make it pass true if at least 1 element is accepted
              }
            }
          } else {
            pass = valueFilters[key]![value] ?? false;
          }
        }
        if (!pass) {
          break;
        }
      }
    }
    conditionFilters.forEach((key, filters) {
      if (key!=skipColKey) {
        final col = widget.columns?[key];
        for (var j = 0; j < filters.length && pass; ++j) {
          pass = filters[j].isAllowed(row, key, col);
        }
      }
    });
    return pass;
  }
  /// returns row.hasExpandableRows
  bool? _setAllChildrenAsFiltered(RowModel<T> row) {
    bool? hasExpandableRows = row.isExpandable ? row.expanded : null;
    for (final e in row.children) {
      final childHasExpandableRows = _setAllChildrenAsFiltered(e);
      hasExpandableRows = hasExpandableRows! && (childHasExpandableRows??true);
    }
    row.hasExpandableRows = hasExpandableRows;
    row.isFilteredInBecauseOfChildren = false;
    row.filteredChildren = List<RowModel<T>>.from(row.children);
    return hasExpandableRows;
  }

  void _updateFiltersApplied(){
    valueFiltersApplied = {
      for (final key in widget.columns?.keys ?? [])
        key: _isValueFilterApplied(key),
    };
    filtersApplied = {
      for (final key in widget.columns?.keys ?? [])
        key: (valueFiltersApplied[key]??false)
            || (conditionFilters[key] ?? []).isNotEmpty,
    };
  }
  bool _isValueFilterApplied(dynamic key) {
    bool? previous;
    for (var i = 0; i < (availableFilters.value?[key]?.length ?? 0); ++i) {
      final availableFilter = availableFilters.value![key]![i];
      final value = valueFilters[key]?[availableFilter] ?? false;
      if (i==0) {
        previous = value;
      } else if (previous!=value){
        return true;
      }
    }
    return false;
  }

  static int defaultComparator(dynamic a, dynamic b, bool sortAscending) {
    int result;
    if (a==null || b==null) {
      if (a==null && b==null) {
        return 0;
      } else if (a==null) {
        return -1;
      } else {
        return 1;
      }
    } if (a is Comparable) {
      try {
        result = a.compareTo(b);
      } catch (_) {
        result = a.toString().compareTo(b.toString());
      }
    } else {
      result = a.toString().compareTo(b.toString());
    }
    return sortAscending ? result : result * -1;
  }

}





class TableController<T> extends ChangeNotifier {

  TableFromZeroState<T>? currentState;
  List<List<RowModel<T>> Function(List<RowModel<T>>)> extraFilters;
  Map<dynamic, List<ConditionFilter>>? initialConditionFilters;
  Map<dynamic, Map<Object?, bool>>? initialValueFilters;
  bool initialValueFiltersExcludeAllElse;

  List<dynamic>? columnKeys;
  List<dynamic>? currentColumnKeys;
  Map<dynamic, List<ConditionFilter>>? conditionFilters;
  Map<dynamic, Map<Object?, bool>>? valueFilters;
  Map<dynamic, bool>? valueFiltersApplied;
  Map<dynamic, bool>? filtersApplied;
  dynamic sortedColumn;
  bool sortedAscending;

  TableController({
    List<List<RowModel<T>> Function(List<RowModel<T>>)>? extraFilters,
    this.initialConditionFilters,
    this.initialValueFilters,
    this.sortedAscending = true,
    this.sortedColumn,
    this.initialValueFiltersExcludeAllElse = false,
  })  : extraFilters = extraFilters ?? [];

  TableController<T> copyWith({
    List<List<RowModel<T>> Function(List<RowModel<T>>)>? extraFilters,
    Map<dynamic, List<ConditionFilter>>? initialConditionFilters,
    Map<dynamic, List<ConditionFilter>>? conditionFilters,
    Map<dynamic, Map<Object?, bool>>? initialValueFilters,
    bool? initialValueFiltersExcludeAllElse,
    Map<dynamic, Map<Object?, bool>>? valueFilters,
    Map<dynamic, bool>? columnVisibilities,
    bool? sortedAscending,
    int? sortedColumnIndex,
    TableFromZeroState<T>? currentState,
  }) {
    return TableController<T>()
      ..extraFilters = extraFilters ?? this.extraFilters
      ..initialConditionFilters = initialConditionFilters ?? this.initialConditionFilters
      ..conditionFilters = conditionFilters ?? this.conditionFilters
      ..initialValueFilters = initialValueFilters ?? this.initialValueFilters
      ..initialValueFiltersExcludeAllElse = initialValueFiltersExcludeAllElse ?? this.initialValueFiltersExcludeAllElse
      ..valueFilters = valueFilters ?? this.valueFilters
      ..sortedAscending = sortedAscending ?? this.sortedAscending
      ..sortedColumn = sortedColumnIndex ?? this.sortedColumn
      ..currentState = currentState ?? this.currentState;
  }

  List<RowModel<T>> get filtered => currentState!.filtered;
  List<RowModel<T>> get allFiltered => currentState!.allFiltered;
  Map<dynamic, ColModel>? get columns => currentState?.widget.columns;

  /// Call this if the rows change, to re-initialize rows
  void reInit() => currentState?.isStateInvalidated = true;
  void sort () {
    if (currentState?.mounted ?? false){
      currentState!.setState(() {
        currentState!.sort();
      });
    }
  }
  void filter(){
    if (currentState?.mounted ?? false){
      currentState!.setState(() {
        currentState!.filter();
      });
    }
  }

}


extension Some<T> on List<T> {
  bool? some(bool? Function(T element) evaluate) {
    if (isEmpty) return false;
    bool any = false; bool every = true;
    for (final element in this) {
      final evaluation = evaluate(element);
      if (evaluation!=null) {
        any = any || evaluation;
        every = every && evaluation;
      }
    }
    return every ? true
        : any ? null
        : false;
  }
}


class FilterResults<T> {
  final List<RowModel<T>> filtered;
  final List<RowModel<T>> allFiltered;
  bool? expandableRowsExist;
  FilterResults({
    List<RowModel<T>>? filtered,
    List<RowModel<T>>? allFiltered,
    this.expandableRowsExist,
  })  : filtered = filtered ?? [],
        allFiltered = allFiltered ?? [];
}