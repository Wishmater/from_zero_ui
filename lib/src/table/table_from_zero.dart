import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/notification_relayer.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:from_zero_ui/src/table/table_from_zero_filters.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';
import 'package:from_zero_ui/util/comparable_list.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:from_zero_ui/util/my_sticky_header.dart';
import 'package:from_zero_ui/util/my_sliver_sticky_header.dart';
import 'package:from_zero_ui/util/no_ensure_visible_traversal_policy.dart';
import 'package:from_zero_ui/util/small_splash_popup_menu_button.dart' as small_popup;
import 'dart:async';
import 'package:dartx/dartx.dart';
import 'package:intl/intl.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:cancelable_compute/cancelable_compute.dart' as cancelable_compute;

typedef OnRowHoverCallback = void Function(RowModel row, bool selected);
typedef OnCheckBoxSelectedCallback = bool? Function(RowModel row, bool? selected);
typedef OnHeaderHoverCallback = void Function(dynamic key, bool selected);
typedef OnCellTapCallback = ValueChanged<RowModel>? Function(dynamic key,);
typedef OnCellHoverCallback = OnRowHoverCallback? Function(dynamic key,);


class TableFromZero<T> extends StatefulWidget {

  final List<RowModel<T>> rows;
  final Map<dynamic, ColModel>? columns;
  final bool enabled;
  final double? minWidth; // TODO 3 maybe be more smart about this, like autommatically sum rows
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
  final Widget? Function(BuildContext context, RowModel<T> row, int index,
      Widget Function(BuildContext context, RowModel<T> row, int index) defaultRowBuilder)? rowBuilder;
  final Widget? Function(BuildContext context, RowModel row)? headerRowBuilder;
  final List<RowModel<T>> Function(List<RowModel<T>>)? onFilter;
  final TableController<T>? tableController;
  final bool? enableSkipFrameWidgetForRows;
  /// if null, excel export option is disabled
  final FutureOr<String>? exportPathForExcel;
  final bool? computeFiltersInIsolate;
  final Color? backgroundColor;
  final Widget? tableHeader;

  TableFromZero({
    Key? key,
    required this.rows,
    this.columns,
    this.enabled = true,
    this.minWidth,
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
    this.onFilter,
    this.tableController,
    this.exportPathForExcel,
    this.enableSkipFrameWidgetForRows,
    this.computeFiltersInIsolate,
    this.backgroundColor,
    this.tableHeader,
  }) :  super(key: key,);

  @override
  TableFromZeroState<T> createState() => TableFromZeroState<T>();

}



class TrackingScrollControllerFomZero extends TrackingScrollController {

  ScrollPosition get position {
    assert(positions.isNotEmpty, 'ScrollController not attached to any scroll views.');
    return positions.first;
  }

}


class TableFromZeroState<T> extends State<TableFromZero<T>> with TickerProviderStateMixin {

  static const double _checkmarkWidth = 48;
  static const bool showFiltersLoading = false;

  late List<RowModel<T>> sorted;
  late List<RowModel<T>> allSorted;
  late List<RowModel<T>> filtered;
  late List<RowModel<T>> allFiltered;
  late Map<dynamic, FocusNode> headerFocusNodes = {};
  List<dynamic>? currentColumnKeys;
  bool isStateInvalidated = false;
  void _invalidateState() {
    isStateInvalidated = true;
  }
  final Map<RowModel<T>, Animation<double>> rowAddonEntranceAnimations = {};
  final Map<RowModel<T>, Animation<double>> nestedRowEntranceAnimations = {};

  late Map<dynamic, List<ConditionFilter>> _conditionFilters;
  Map<dynamic, List<ConditionFilter>> get conditionFilters => widget.tableController?.conditionFilters ?? _conditionFilters;
  set conditionFilters(Map<dynamic, List<ConditionFilter>> value) {
    if (widget.tableController == null) {
      _conditionFilters = value;
    } else {
      widget.tableController!.conditionFilters = value;
    }
  }
  late Map<dynamic, Map<Object?, bool>> _valueFilters;
  Map<dynamic, Map<Object?, bool>> get valueFilters => widget.tableController?.valueFilters ?? _valueFilters;
  set valueFilters(Map<dynamic, Map<Object?, bool>> value) {
    if (widget.tableController==null) {
      _valueFilters = value;
    } else {
      widget.tableController!.valueFilters = value;
    }
  }
  late Map<dynamic, bool> _valueFiltersApplied;
  Map<dynamic, bool> get valueFiltersApplied => widget.tableController?.valueFiltersApplied ?? _valueFiltersApplied;
  set valueFiltersApplied(Map<dynamic, bool> value) {
    if (widget.tableController==null) {
      _valueFiltersApplied = value;
    } else {
      widget.tableController!.valueFiltersApplied = value;
    }
  }
  late Map<dynamic, bool> _filtersApplied;
  Map<dynamic, bool> get filtersApplied => widget.tableController?.filtersApplied ?? _filtersApplied;
  set filtersApplied(Map<dynamic, bool> value) {
    if (widget.tableController==null) {
      _filtersApplied = value;
    } else {
      widget.tableController!.filtersApplied = value;
    }
  }
  ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters = ValueNotifier(null);
  late Map<dynamic, GlobalKey> filterGlobalKeys = {};

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

  late TrackingScrollControllerFomZero sharedController;
  RowModel? headerRowModel;

  TableFromZeroState();

  @override
  void dispose() {
    super.dispose();
    availableFiltersIsolateController?.cancel();
    validInitialFiltersIsolateController?.cancel();
    if (widget.tableController!=null) {
      if (widget.tableController!.currentState==this) {
        widget.tableController!.currentState = null;
      }
      if (widget.tableController!._filter==_controllerFilter) {
        widget.tableController!._filter = null;
      }
      try {
        if (widget.tableController!._getFiltered==_getFiltered) {
          widget.tableController!._getFiltered = ()=>[];
        }
      } catch (_) {}
      try {
        if (widget.tableController!._getColumns==_getColumns) {
          widget.tableController!._getColumns = ()=>{};
        }
      } catch (_) {}
      if (widget.tableController!._sort==_controllerSort) {
        widget.tableController!._sort = null;
      }
      if (widget.tableController!._reInit==_invalidateState) {
        widget.tableController!._reInit = null;
      }
    }
  }

  double lastPosition = 0;
  bool lockScrollUpdates = false;
  @override
  void initState() {
    super.initState();
    sharedController = TrackingScrollControllerFomZero();
    sharedController.addListener(() {
      if (!lockScrollUpdates){
        double? newPosition;
        sharedController.positions.forEach((element) {
          if (element.pixels!=lastPosition) newPosition = element.pixels;
        });
        lockScrollUpdates = true;
        if (newPosition!=null){
          lastPosition = newPosition!;
          sharedController.positions.forEach((element) {
            if (element.pixels!=newPosition){
              element.jumpTo(newPosition!);
            }
          });
        }
        lockScrollUpdates = false;
      }
    });
    if (sortedColumn==null) {
      sortedColumn = widget.initialSortedColumn;
    }
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
    } else if (widget.headerRowModel!=null) {
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
    currentColumnKeys = widget.columns?.keys.toList();
    sorted = widget.rows;
    for (final e in sorted) {
      e.calculateDepth();
    }
    _showLeadingControls = sorted.map((e) => e.allRows).flatten()
        .any((e) => e.onCheckBoxSelected!=null
                    || e.children.isNotEmpty
                    || (e.rowAddon!=null && e.rowAddonIsExpandable));
    if (widget.tableController!=null) {
      widget.tableController!.currentState = this;
      widget.tableController!._filter = _controllerFilter;
      widget.tableController!._sort = _controllerSort;
      widget.tableController!._reInit = _invalidateState;
      widget.tableController!._getFiltered = _getFiltered;
      widget.tableController!._getColumns = _getColumns;
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
      if (widget.tableController?.initialValueFilters==null){
        valueFilters = {
          for (final e in widget.columns?.keys ?? [])
            e: {},
        };
      } else {
        valueFilters = {
          for (final e in widget.columns?.keys ?? [])
            e: widget.tableController!.initialValueFilters![e] ?? {},
        };
        filtersAltered = true;
      }
    } else if (isFirstInit) {
      filtersAltered = true;
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
    if (widget.columns==null && widget.showHeaders) {
      headerRowModel = widget.headerRowModel;
    } else {
      if (widget.headerRowModel!=null) {
        if (widget.headerRowModel is SimpleRowModel) {
          headerRowModel = (widget.headerRowModel as SimpleRowModel).copyWith(
            onCheckBoxSelected: widget.headerRowModel!.onCheckBoxSelected,
            values: widget.columns==null || widget.columns!.length==widget.headerRowModel!.values.length
                ? widget.headerRowModel!.values
                : widget.columns!.map((key, value) => MapEntry(key, value.name)),
            rowAddon: headerRowModel?.rowAddon ?? widget.tableHeader,
            rowAddonIsAboveRow: widget.headerRowModel?.rowAddonIsAboveRow ?? true,
            rowAddonIsCoveredByBackground: widget.headerRowModel?.rowAddonIsCoveredByBackground ?? widget.tableHeader==null,
            rowAddonIsCoveredByScrollable: widget.headerRowModel?.rowAddonIsCoveredByScrollable ?? widget.tableHeader==null,
            rowAddonIsCoveredByGestureDetector: widget.headerRowModel?.rowAddonIsCoveredByGestureDetector ?? true,
            rowAddonIsSticky: widget.headerRowModel?.rowAddonIsSticky ?? false,
          );
        } else {
          headerRowModel = widget.headerRowModel;
        }
      } else {
        headerRowModel = SimpleRowModel(
          id: "header_row",
          values: widget.columns!.map((key, value) => MapEntry(key, value.name)),
          selected: true,
          height: widget.rows.isEmpty ? 36 : widget.rows.first.height,
          rowAddon: widget.tableHeader,
          rowAddonIsAboveRow: true,
          rowAddonIsCoveredByScrollable: false,
          rowAddonIsCoveredByBackground: false,
          rowAddonIsCoveredByGestureDetector: true,
          rowAddonIsSticky: false,
        );
      }
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
        availableFiltersIsolateController = cancelable_compute.compute(_getAvailableFilters,
            [
              widget.columns!.map((key, value) => MapEntry(key, [value.filterEnabled, value.defaultSortAscending])),
              rows.map((e) {
                return e.values.map((key, value) {
                  return MapEntry(key, _sanitizeValueForIsolate(key, value, // TODO 2 performance, maybe allow to manually disable sanitization
                    fieldAliases: fieldAliases[key]!,
                    daoAliases: daoAliases[key]!,
                  ));
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
              [valueFilters, computedAvailableFilters]);
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
      computedAvailableFilters = await _getAvailableFilters(
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
      )).toList();
    } else if (value is ComparableList) {
      return value.list.map((e) => _sanitizeValueForIsolate(key, e,
        fieldAliases: fieldAliases,
        daoAliases: daoAliases,
      )).toList();
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
  static Future<Map<dynamic, List<dynamic>>> _getAvailableFilters(List<dynamic> params, {
    bool artifitialThrottle = false,
    State? state,
  }) async {
    final Map<dynamic, List<bool?>> columnOptions = params[0];
    final List<Map<dynamic, dynamic>> rowValues = params[1];
    final bool sortNeeded = params[2];
    Map<dynamic, List<dynamic>> availableFilters = {};
    int operationCounter = 0;
    for (final e in columnOptions.entries) {
      final key = e.key;
      final options = e.value;
      Set<dynamic> available = {};
      if (options[0] ?? true) { // filterEnabled
        for (final row in rowValues) {
          final element = row[key];
          if (element is List || element is ComparableList || element is ListField) {
            final List list = element is List ? element
                : element is ComparableList ? element.list
                : element is ListField ? element.objects : [];
            for (final e in list) {
              available.add(e);
              if (artifitialThrottle) {
                operationCounter+=available.length;
                if (operationCounter>5000000) {
                  operationCounter = 0;
                  await Future.delayed(Duration(milliseconds: 50));
                  if (state!=null && !state.mounted) {
                    return {};
                  }
                }
              }
            }
          } else {
            available.add(element);
          }
          if (artifitialThrottle) {
            operationCounter+=available.length;
            if (operationCounter>5000000) {
              operationCounter = 0;
              await Future.delayed(Duration(milliseconds: 50));
              if (state!=null && !state.mounted) {
                return {};
              }
            }
          }
        }
      }
      bool sortAscending = options[1] ?? true; // defaultSortAscending
      List<dynamic> availableSorted;
      if (sortNeeded) {
        if (artifitialThrottle) {
          availableSorted = available.sortedWith((a, b) => defaultComparator(a, b, sortAscending));
        } else {
          availableSorted = available.toList()..sort((a, b) => defaultComparator(a, b, sortAscending));
        }
      } else {
        availableSorted = available.toList();
      }
      availableFilters[key] = availableSorted;
    }
    return availableFilters;
  }
  static Map<dynamic, Map<Object?, bool>>? _getValidInitialFilters(List<dynamic> params) {
    Map<dynamic, Map<Object?, bool>> initialFilters = params[0];
    Map<dynamic, List<dynamic>> availableFilters = params[1];
    bool removed = false;
    initialFilters.forEach((col, filters) {
      filters.removeWhere((key, value) {
        bool remove = !availableFilters[col]!.contains(key);
        removed = remove;
        return remove;
      });
    });
    return removed ? initialFilters : null;
  }


  @override
  Widget build(BuildContext context) {

    if (widget.hideIfNoRows && allFiltered.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink(),);
    }
    int childCount = allFiltered.length.coerceIn(1);
    Widget result;

    if (true) {
    // if (!(widget.implicitlyAnimated ?? allFiltered.length<10)) {

      if (widget.enableFixedHeightForListRows && allFiltered.isNotEmpty) {
        result = SliverFixedExtentList(
          itemExtent: allFiltered.first.height??36,
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, allFiltered.isEmpty ? null : allFiltered[i], i),
            childCount: childCount,
          ),
        );
      } else {
        result = SliverList(
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, allFiltered.isEmpty ? null : allFiltered[i], i),
            childCount: childCount,
          ),
        );
      }

      // TODO 2 fix fatal error in animated list, seems to be a problem with row id equality
    } else {

      result = SliverImplicitlyAnimatedList<RowModel<T>>(
        items: allFiltered.isEmpty ? [] : allFiltered,
        areItemsTheSame: (a, b) => a==b,
        insertDuration: Duration(milliseconds: 400),
        updateDuration: Duration(milliseconds: 400),
        itemBuilder: (context, animation, item, index) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-0.33, 0), end: Offset(0, 0)).animate(animation),
            child: SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeOutCubic,
              animation: animation,
              child: _getRow(context, item, index),
            ),
          );
        },
        updateItemBuilder: (context, animation, item) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-0.10, 0), end: Offset(0, 0)).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: _getRow(context, item, -1),
            ),
          );
        },
      );

    }

    Widget? header = widget.showHeaders
        ? headerRowModel!=null
            ? headerRowModel!.values.isEmpty && headerRowModel!.rowAddon!=null
                ? headerRowModel!.rowAddon!
                : _getRow(context, headerRowModel!, -1)
            : null
        : headerRowModel?.rowAddon;
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
                duration: Duration(milliseconds: 300),
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

    if (widget.minWidth!=null) {
      result = SliverStickyHeader(
        sliver: SliverPadding(
          padding: EdgeInsets.only(bottom: 8),
          sliver: result,
        ),
        scrollController: widget.scrollController,
        sticky: true,
        footer: true,
        overlapsContent: true,
        stickOffset: widget.footerStickyOffset,
        header: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < widget.minWidth!) {
              return ScrollbarFromZero(
                controller: sharedController,
                opacityGradientDirection: OpacityGradient.horizontal,
                child: SizedBox(
                  height: 12,
                  child: NotificationRelayer(
                    controller: notificationRelayController,
                    child: Container(),
                  ),
                ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      );
    }

    result = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: result,
    );

    return result;

  }


  Widget _getRow(BuildContext context, RowModel? row, int index){
    if (row==null){

      return InitiallyAnimatedWidget(
        duration: Duration(milliseconds: 500,),
        builder: (animation, child) {
          return SizeFadeTransition(animation: animation, child: child, sizeFraction: 0.7, curve: Curves.easeOutCubic,);
        },
        child: Container(
          color: _getMaterialColor(),
          padding: EdgeInsets.symmetric(vertical: 16),
          child: widget.emptyWidget ?? ErrorSign(
            icon: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 64, color: Theme.of(context).disabledColor,),
            title: FromZeroLocalizations.of(context).translate('no_data'),
            subtitle: filtersApplied.values.firstOrNullWhere((e) => e==true)!=null
                ? FromZeroLocalizations.of(context).translate('no_data_filters')
                : FromZeroLocalizations.of(context).translate('no_data_desc'),
          ),
        ),
      );

    } else {

      if (row==headerRowModel){
        return widget.headerRowBuilder?.call(context, headerRowModel!)
            ?? _defaultRowBuilder.call(context, headerRowModel!, index);
      } else {
        if (widget.enableSkipFrameWidgetForRows ?? allFiltered.length>50) {
          return SkipFrameWidget(
            paceholderBuilder: (context) {
              return SizedBox(
                height: row.height,
              );
            },
            childBuilder: (context) {
              return widget.rowBuilder?.call(context, row as RowModel<T>, index, _defaultRowBuilder)
                  ?? _defaultRowBuilder.call(context, row as RowModel<T>, index);
            },
          );
        } else {
          return widget.rowBuilder?.call(context, row as RowModel<T>, index, _defaultRowBuilder)
              ?? _defaultRowBuilder.call(context, row as RowModel<T>, index);
        }
      }

    }
  }
  Widget _defaultRowBuilder(BuildContext context, RowModel row, int index) {

    int maxFlex = 0;
    for (final key in currentColumnKeys??row.values.keys) {
      maxFlex += _getFlex(key);
    }
    int cols = (((currentColumnKeys??row.values.keys).length) + (_showLeadingControls ? 1 : 0))
        * (widget.verticalDivider==null ? 1 : 2)
        + (widget.verticalDivider==null ? 0 : 1);

    final builder = (BuildContext context, BoxConstraints? constraints) {
      final Map<Widget, ActionState> rowActionStates = {
        for (final e in widget.rowActions)
          e: e.getStateForMaxWidth(constraints?.maxWidth??double.infinity)
      };
      List<Widget> rowActions = row==headerRowModel ? []
          : widget.rowActions.map((e) => e.copyWith(onTap: (context) {
            e.onRowTap?.call(context, row as RowModel<T>);
          },)).toList();
      if (widget.exportPathForExcel != null) {
        rowActions = addExportExcelAction(context,
          actions: rowActions,
          exportPathForExcel: widget.exportPathForExcel!,
          tableController: widget.tableController ?? (TableController()..currentState=this),
        );
      }
      for (final e in rowActions) {
        if (!rowActionStates.containsKey(e)) {
          rowActionStates[e] = e is ActionFromZero
              ? e.getStateForMaxWidth(constraints?.maxWidth??double.infinity)
              : ActionState.none;
        }
      }
      // This assumes standard icon size, custom action iconBuilders will probably break the table,
      // this is very prone to breaking, but there is no other efficient way of doing it
      final actionsWidth = widget.rowActions.where((e) => rowActionStates[e]!.shownOnPrimaryToolbar).length * 48.0;
      final decorationBuilder = (BuildContext context, int j) {
        Widget? result;
        bool addSizing = true;
        if (result==null && widget.verticalDivider!=null){
          if (j%2==0) return Padding(
            padding: EdgeInsets.only(left: j==0 ? 0 : 1, right: j==cols-1 ? 0 : 1,),
            child: widget.verticalDivider,
          );
          j = (j-1)~/2;
        }
        if (result==null && _showLeadingControls){
          if (j==0){
            addSizing = false;
            result = SizedBox(width: _checkmarkWidth, height: double.infinity,);
          } else{
            j--;
          }
        }
        final colKey = (currentColumnKeys??row.values.keys.toList())[j];
        final col = widget.columns?[colKey];
        if (result==null && col?.flex==0){
          return SizedBox.shrink();
        }
        result = Container(
          decoration: _getDecoration(row, index, colKey),
          child: result,
        );
        if (addSizing){
          if (col?.width!=null) {
            result = SizedBox(width: col!.width, child: result,);
          } else {
            if (constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
              return SizedBox(width: widget.minWidth! * (_getFlex(colKey)/maxFlex), child: result,);
            } else {
              return Expanded(flex: _getFlex(colKey), child: result,);
            }
          }
        }
        return result;
      };
      final cellBuilder = (BuildContext context, int j) {
        if (widget.verticalDivider!=null) {
          if (j%2==0) return Padding(
            padding: EdgeInsets.only(left: j==0 ? 0 : 1, right: j==cols-1 ? 0 : 1,),
            child: widget.verticalDivider,
          );
          j = (j-1)~/2;
        }
        if (_showLeadingControls) {
          if (j==0) {
            return SizedBox(
              width: _checkmarkWidth,
              child: (row==headerRowModel ? row.onCheckBoxSelected!=null||widget.onAllSelected!=null : row.onCheckBoxSelected!=null)
                  ? StatefulBuilder(
                      builder: (context, checkboxSetState) {
                        return LoadingCheckbox(
                          value: row==headerRowModel
                              ? allFiltered.isNotEmpty && allFiltered.every((element) => element.selected==true || element.onCheckBoxSelected==null)
                              : row.selected,
                          onChanged: row==headerRowModel&&allFiltered.isEmpty ? null : (value) {
                            if (row==headerRowModel) {
                              if (row.onCheckBoxSelected!=null) {
                                if (row.onCheckBoxSelected!(row, value) ?? false) {
                                  checkboxSetState(() {});
                                }
                              } else if (widget.onAllSelected!(value, allFiltered) ?? false) {
                                setState(() {});
                              }
                            } else {
                              if (row.onCheckBoxSelected!(row, value) ?? false) {
                                checkboxSetState(() {});
                              }
                            }
                          },
                        );
                      },
                    )
                  : row.isExpandable ? IconButton(
                      onPressed: () {
                        toggleRowExpanded(row as RowModel<T>, index);
                      },
                      icon: SelectableIcon(
                        selected: row.expanded,
                        icon: Icons.expand_less,
                        unselectedOffset: 0.25,
                        selectedOffset: 0.5,
                      ),
                    )
                  : SizedBox.shrink(),
            );
          } else{
            j--;
          }
        }
        final colKey = (currentColumnKeys??row.values.keys.toList())[j];
        final col = widget.columns?[colKey];
        if (col?.flex==0){
          return SizedBox.shrink();
        }
        Widget result = Container(
          height: row.height, // widget.enableFixedHeightForListRows ? row.height : null,
          alignment: Alignment.center,
          padding: row==headerRowModel ? null : widget.cellPadding,
          child: Container(
              width: double.infinity,
              child: row==headerRowModel
                  ? defaultHeaderCellBuilder(context, headerRowModel!, colKey)
                  : widget.cellBuilder?.call(context, row as RowModel<T>, colKey)
                      ?? TableFromZeroState.defaultCellBuilder<T>(context, row as RowModel<T>, colKey, col, _getStyle(context, row, colKey), _getAlignment(colKey)),
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
          if (constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
            return SizedBox(width: (widget.minWidth! * (_getFlex(colKey)/maxFlex)), child: result,);
          } else {
            return Flexible(flex: _getFlex(colKey), child: result,);
          }
        }
      };
      Widget background;
      Widget result;
      if (constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
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
        result = ScrollOpacityGradient(
          scrollController: sharedController,
          direction: OpacityGradient.horizontal,
          child: row==headerRowModel // TODO 2 horizontal scrollbar might not work in tables with no header
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
        );
      }
      if (row==headerRowModel) {
        result = Padding(
          padding: EdgeInsets.only(right: actionsWidth),
          child: result,
        );
      } else if (rowActions.isNotEmpty) {
        result = Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: row.height,
            child: OverflowBox( // hack to fix Appbar actions overflowing when rowHeight<40
              maxHeight: max(40, row.height??0),
              child: AppbarFromZero(
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
              ),
            ),
          ),
        );
      }
      if (row.rowAddon!=null && (row.expanded || !row.rowAddonIsExpandable)) {
        Widget addon = row.rowAddon!;
        if ((row.rowAddonIsCoveredByScrollable??true) && constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
          addon = NotificationListener(
            onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
            child: SingleChildScrollView(
              controller: sharedController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.minWidth!,
                child: addon,
              ),
            ),
          );
        }
        if (row.rowAddonIsExpandable && rowAddonEntranceAnimations[row]!=null) {
          addon = _buildEntranceAnimation(
            child: addon,
            row: row,
            animation: rowAddonEntranceAnimations[row]!,
          );
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
          result = StickyHeader( // TODO 1 fix addon stickyHeader, use SliverStickyHeader instead
            controller: widget.scrollController,
            header: top,
            content: bottom,
            stickOffset: row is! RowModel<T> ? 0
                : index==0 ? 0
                : widget.stickyOffset + (row.height??0),
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
                      decoration: _getDecoration(row, index, null),
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
          child: result,
          onShowMenu: () => row.focusNode.requestFocus(),
          actions: rowActions.where((e) => rowActionStates[e]! != ActionState.none).toList().cast(),
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
        policy: NoEnsureVisibleWidgetTraversalPolicy(),
        child: result,
      );
      return result;
    };

    Widget result;
    // bool intrinsicDimensions = context.findAncestorWidgetOfExactType<IntrinsicHeight>()!=null
    //     || context.findAncestorWidgetOfExactType<IntrinsicWidth>()!=null;
    // if (!intrinsicDimensions && (widget.minWidth!=null || widget.maxWidth!=null)){
    if (widget.minWidth!=null){
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
  }) {
    Widget result = child;
    if (row.onRowTap!=null || row.onCheckBoxSelected!=null || row.isExpandable) {
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
            : row.isExpandable
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
    final name = col?.name ?? getRowValueString(row, colKey, col) ?? '';
    bool export = context.findAncestorWidgetOfExactType<Export>()!=null;
    if (!filterGlobalKeys.containsKey(colKey)) {
      filterGlobalKeys[colKey] = GlobalKey();
    }
    Widget result = Align(
      alignment: _getAlignment(colKey)==TextAlign.center ? Alignment.center
          : _getAlignment(colKey)==TextAlign.left||_getAlignment(colKey)==TextAlign.start ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPadding(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: widget.cellPadding.left + (!export && sortedColumn==colKey ? 15 : 4),
              right: widget.cellPadding.right + (!export && (col?.filterEnabled??true) ? 10 : 4),
              top: widget.cellPadding.top,
              bottom: widget.cellPadding.bottom,
            ),
            child: AutoSizeText(
              name,
              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                color: Theme.of(context).textTheme.bodyText1!.color!
                    .withOpacity(Theme.of(context).brightness==Brightness.light ? 0.66 : 0.8),
              ),
              textAlign: _getAlignment(colKey),
              maxLines: autoSizeTextMaxLines,
              minFontSize: 14,
              overflowReplacement: TooltipFromZero(
                message: name,
                waitDuration: Duration(milliseconds: 0),
                verticalOffset: -16,
                child: AutoSizeText(
                  name,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                    color: Theme.of(context).textTheme.bodyText1!.color!
                        .withOpacity(Theme.of(context).brightness==Brightness.light ? 0.66 : 0.8),
                  ),
                  textAlign: _getAlignment(colKey),
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
                duration: Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                child: (widget.enabled && !export && sortedColumn==colKey)
                    ? col?.buildSortedIcon(context, sortedAscending)
                        ?? Icon(
                            sortedAscending
                                ? MaterialCommunityIcons.sort_alphabetical_ascending
                                : MaterialCommunityIcons.sort_alphabetical_descending,
                            key: ValueKey(sortedAscending),
                            // color: Theme.of(context).brightness==Brightness.light ? Colors.blue.shade700 : Colors.blue.shade400,
                            color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
                          )
                    : SizedBox(height: 24,),
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
                    ? Center(
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
                        icon: Icon((filtersApplied[colKey]??false) ? MaterialCommunityIcons.filter : MaterialCommunityIcons.filter_outline,
                          color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
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
          icon: Icon(MaterialCommunityIcons.sort_ascending),
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
          icon: Icon(MaterialCommunityIcons.sort_descending),
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
      if (showFiltersLoading&&availableFilters!=null && (col?.filterEnabled ?? true))
        ActionFromZero(
          title: 'Filtros...', // TODO 3 internationalize
          icon: Icon(MaterialCommunityIcons.filter),
          onTap: (context) => _showFilterPopup(colKey),
        ),
    ];
    if (widget.exportPathForExcel != null) {
      colActions = addExportExcelAction(context,
        actions: colActions,
        exportPathForExcel: widget.exportPathForExcel!,
        tableController: widget.tableController ?? (TableController()..currentState=this),
      );
    }
    result = ContextMenuFromZero(
      child: result,
      onShowMenu: () => headerFocusNodes[colKey]!.requestFocus(),
      actions: colActions.cast<ActionFromZero>(),
    );
    return result;
  }

  void _showFilterPopup(dynamic colKey) async {
    final col = widget.columns?[colKey];
    final callback = col?.showFilterPopupCallback ?? showDefaultFilterPopup;
    bool modified = await callback(
      context: context,
      colKey: colKey,
      col: col,
      availableFilters: availableFilters,
      conditionFilters: conditionFilters,
      valueFilters: valueFilters,
      anchorKey: filterGlobalKeys[colKey],
    );
    if (modified && mounted) {
      setState(() {
        _updateFiltersApplied();
        filter();
      });
    }
  }
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
    bool modified = false;
    List<ConditionFilter> possibleConditionFilters = col?.getAvailableConditionFilters() ?? [
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
                                            modified = true;
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
                                        modified = true;
                                        // filterPopupSetState((){});
                                      },
                                      onDelete: () {
                                        modified = true;
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
                              rows: (availableFilters[colKey] ?? []).map((e) {
                                return SimpleRowModel(
                                  id: e,
                                  values: {0: e},
                                  selected: valueFilters[colKey]![e] ?? false,
                                  onCheckBoxSelected: (row, selected) {
                                    modified = true;
                                    valueFilters[colKey]![row.id] = selected!;
                                    (row as SimpleRowModel).selected = selected;
                                    return true;
                                  },
                                );
                              }).toList(),
                              emptyWidget: SizedBox.shrink(),
                              headerRowModel: SimpleRowModel(
                                id: 'header', values: {},
                                rowAddon: Container(
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
                                            filterTableController.conditionFilters![0] = [];
                                            filterTableController.conditionFilters![0]!.add(
                                              FilterTextContains(query: v,),
                                            );
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
                                                modified = true;
                                                filterPopupSetState(() {
                                                  filterTableController.filtered.forEach((row) {
                                                    valueFilters[colKey]![row.id] = true;
                                                    (row as SimpleRowModel).selected = true;
                                                  });
                                                });
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: TextButton(
                                              child: Text(FromZeroLocalizations.of(context).translate('clear_selection')),
                                              onPressed: () {
                                                modified = true;
                                                filterPopupSetState(() {
                                                  filterTableController.filtered.forEach((row) {
                                                    valueFilters[colKey]![row.id] = false;
                                                    (row as SimpleRowModel).selected = false;
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
    return modified;
  }

  static Widget defaultCellBuilder<T>(BuildContext context, RowModel<T> row, dynamic colKey, ColModel? col, TextStyle? style, TextAlign alignment) {
    // final col = widget.columns?[colKey];
    final message = getRowValueString(row, colKey, col);
    final autoSizeTextMaxLines = 1;
    Widget result = AutoSizeText(
      message,
      style: style,
      textAlign: alignment,
      maxLines: autoSizeTextMaxLines,
      minFontSize: 14,
      overflowReplacement: TooltipFromZero(
        message: message,
        waitDuration: Duration(milliseconds: 0),
        verticalOffset: -16,
        child: AutoSizeText(
          message,
          style: style,
          textAlign: alignment,
          maxLines: autoSizeTextMaxLines,
          softWrap: autoSizeTextMaxLines>1,
          overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
        ),
      ),
    );
    return result;
  }

  static Object? getRowValue(RowModel row, dynamic key, ColModel? col) {
    return col?.getValue(row, key) ?? row.values[key];
  }
  static String getRowValueString(RowModel row, dynamic key, ColModel? col) {
    if (col!=null) {
      col.getValueString(row, key);
    }
    final value = getRowValue(row, key, col);
    if (value is List || value is ComparableList) {
      final List list = value is List ? value
          : value is ComparableList ? value.list : [];
      return ListField.listToStringAll(list);
    } else {
      return value!=null ? value.toString() : "";
    }
  }
  BoxDecoration? _getDecoration(RowModel row, int index, dynamic colKey,){
    bool isHeader = row==headerRowModel;
    Color? backgroundColor = _getBackgroundColor(row, colKey, isHeader);
    if (backgroundColor!=null) {
      bool applyDarker = widget.alternateRowBackgroundBrightness
          && _shouldApplyDarkerBackground(backgroundColor, row, index, colKey, isHeader);
      if (backgroundColor.opacity<1 && widget.alternateRowBackgroundBrightness) {
        backgroundColor = Color.alphaBlend(backgroundColor, _getMaterialColor());
      }
      if (applyDarker) {
        backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.965), Colors.black);
      }
    }
    return backgroundColor==null ? null : BoxDecoration(color: backgroundColor);
  }
  Color _getMaterialColor() => widget.backgroundColor ?? Material.of(context)!.color ?? Theme.of(context).cardColor;
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

  TextStyle? _getStyle(BuildContext context, RowModel<T> row, dynamic j){
    TextStyle? style;
    if (widget.rowStyleTakesPriorityOverColumn){
      style = row.textStyle ?? widget.columns?[j]?.textStyle;
    } else{
      style = widget.columns?[j]?.textStyle ?? row.textStyle;
    }
    return style;
  }

  int _getFlex(j){
    return widget.columns?[j]?.flex ?? 1;
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
        icon: Icon(MaterialCommunityIcons.file_excel),
        breakpoints: {0: ActionState.popup},
        onTap: (appbarContext) {
          String routeTitle = 'Excel';
          try {
            final route = GoRouteFromZero.of(context);
            routeTitle = route.title ?? route.path;
          } catch (_) {}
          showModal(
            context: appbarContext,
            builder: (context) => Export.excelOnly(
              scaffoldContext: appbarContext,
              title: DateFormat("yyyy-MM-dd hh.mm.ss aaa").format(DateTime.now()) + " - $routeTitle",
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

  void toggleRowExpanded(RowModel<T> row, int index) {
    setState(() {
      if (!row.expanded) {
        row.expanded = true;
        final visibleRows = row.visibleRows..removeAt(0);
        final toAdd = visibleRows.where(_passesFilters).toList();
        smartSort<T>(toAdd,
          sortedColumnKey: sortedColumn,
          sortedAscending: sortedAscending,
        );
        allFiltered.insertAll(index+1, toAdd);
        final animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
        final curvedAnimation = CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic);
        animationController.forward();
        rowAddonEntranceAnimations[row] = curvedAnimation;
        for (final e in toAdd) {
          nestedRowEntranceAnimations[e] = curvedAnimation;
        }
      } else {
        allFiltered.removeRange(index+1, index+row.length);
        row.expanded = false;
      }
    });
  }

  int get disabledColumnCount => widget.columns==null ? 0
      : widget.columns!.values.where((element) => element.flex==0).length;
  List<RowModel<T>> _controllerSort () {
    List<RowModel<T>> result = [];
    if (mounted){
      result = sort();
      setState(() {});
    }
    return result;
  }
  List<RowModel<T>> sort({bool notifyListeners=true}) {
    smartSort<T>(sorted,
      sortedColumnKey: sortedColumn,
      sortedAscending: sortedAscending,
    );
    allSorted = sorted.map((e) => e.visibleRows).flatten().toList();
    filter(notifyListeners: notifyListeners);
    return sorted;
  }
  static void smartSort<T>(List<RowModel<T>> list, {
    bool sortedAscending = true,
    Object? sortedColumnKey,
    ColModel? col,
  }) {
    if (list.isEmpty) return;
    mergeSort<RowModel<T>>(list.cast<RowModel<T>>(), compare: ((RowModel<T> a, RowModel<T> b) {
      if (a.alwaysOnTop!=null || b.alwaysOnTop!=null && a.alwaysOnTop!=b.alwaysOnTop) {
        if (a.alwaysOnTop==true || b.alwaysOnTop==false) return -1;
        if (a.alwaysOnTop==false || b.alwaysOnTop==true) return 1;
      }
      if (sortedColumnKey==null) {
        return 0;
      }
      dynamic aVal = getRowValue(a, sortedColumnKey, col);
      dynamic bVal = getRowValue(b, sortedColumnKey, col);
      if (aVal!=null && aVal is! Comparable) aVal = getRowValueString(a, sortedColumnKey, col);
      if (bVal!=null && bVal is! Comparable) bVal = getRowValueString(b, sortedColumnKey, col);
      return sortedAscending
          ? aVal==null ? 1 : bVal==null ? -1 : aVal.compareTo(bVal)
          : aVal==null ? -1 : bVal==null ? 1 : bVal.compareTo(aVal);
    }));
    for (final e in list) {
      smartSort<T>(e.children,
        sortedColumnKey: sortedColumnKey,
        sortedAscending: sortedAscending,
      );
    }
  }
  Map<dynamic, ColModel>? _getColumns() => widget.columns;
  List<RowModel<T>> _getFiltered() => filtered;
  List<RowModel<T>> _controllerFilter() {
    List<RowModel<T>> result = [];
    if (mounted){
      result = filter();
      setState(() {});
    }
    return result;
  }

  List<RowModel<T>> filter({bool notifyListeners=true}){
    filtered = sorted.where(_passesFilters).toList();
    if (widget.onFilter!=null) {
      filtered = widget.onFilter!(filtered);
    }
    for (final e in (widget.tableController?.extraFilters ?? [])) {
      filtered = e(filtered);
    }
    allFiltered = filtered.map((e) => e.visibleRows).flatten()
        .where((e) => e.depth==0 || _passesFilters(e)).toList();
    if (mounted && notifyListeners) {
      widget.tableController?.notifyListeners();
    }
    return filtered;
  }
  bool _passesFilters(RowModel<T> row) {
    bool pass = true;
    for (final key in valueFilters.keys) {
      final col = widget.columns?[key];
      if (valueFiltersApplied[key] ?? false) {
        final value = getRowValue(row, key, col);
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
    conditionFilters.forEach((key, filters) {
      final col = widget.columns?[key];
      for (var j = 0; j < filters.length && pass; ++j) {
        pass = filters[j].isAllowed(row, key, col);
      }
    });
    return pass;
  }

  bool _showLeadingControls = false;
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
  bool _isValueFilterApplied(key) {
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

  static int defaultComparator(a, b, bool sortAscending) {
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

  List<List<RowModel<T>> Function(List<RowModel<T>>)> extraFilters;
  TableFromZeroState<T>? currentState;
  Map<dynamic, List<ConditionFilter>>? initialConditionFilters;
  Map<dynamic, List<ConditionFilter>>? conditionFilters;
  Map<dynamic, Map<Object?, bool>>? initialValueFilters;
  bool initialValueFiltersExcludeAllElse;
  Map<dynamic, Map<Object?, bool>>? valueFilters;
  Map<dynamic, bool>? valueFiltersApplied;
  Map<dynamic, bool>? filtersApplied;
  bool sortedAscending;
  dynamic sortedColumn;

  TableController({
    List<List<RowModel<T>> Function(List<RowModel<T>>)>? extraFilters,
    this.initialConditionFilters,
    this.initialValueFilters,
    this.sortedAscending = true,
    this.sortedColumn,
    this.initialValueFiltersExcludeAllElse = false,
  })  : this.extraFilters = extraFilters ?? [];

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
      .._filter = this._filter
      ..currentState = currentState ?? this.currentState;
  }

  List<RowModel<T>> Function()? _filter;
  List<RowModel<T>> filter(){
    return _filter?.call() ?? [];
  }

  List<RowModel<T>> Function()? _sort;
  List<RowModel<T>> sort(){
    return _sort?.call() ?? [];
  }

  VoidCallback? _reInit;
  /// Call this if the rows change, to re-initialize rows
  void reInit(){
    _reInit?.call();
  }

  late List<RowModel<T>> Function() _getFiltered;
  List<RowModel<T>> get filtered => _getFiltered();

  late Map<dynamic, ColModel>? Function() _getColumns;
  Map<dynamic, ColModel>? get columns => _getColumns();

}