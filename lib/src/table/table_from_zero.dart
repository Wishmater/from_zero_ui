import 'dart:io';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
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
  final Widget? Function(BuildContext context, RowModel<T> row,
      Widget Function(BuildContext context, RowModel<T> row) defaultRowBuilder)? rowBuilder;
  final Widget? Function(BuildContext context, RowModel row)? headerRowBuilder;
  final List<RowModel<T>> Function(List<RowModel<T>>)? onFilter;
  final TableController<T>? tableController;
  final bool? enableSkipFrameWidgetForRows;
  /// if null, excel export option disabled
  final FutureOr<String>? exportPathForExcel;
  final bool? computeFiltersInIsolate;

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


class TableFromZeroState<T> extends State<TableFromZero<T>> {

  static const double _checkmarkWidth = 48;

  late List<RowModel<T>> sorted;
  late List<RowModel<T>> filtered;
  late Map<dynamic, FocusNode> headerFocusNodes = {};
  List<dynamic>? currentColumnKeys;
  bool isStateInvalidated = false;
  void _invalidateState() {
    isStateInvalidated = true;
  }

  late Map<dynamic, List<ConditionFilter>> _conditionFilters;
  Map<dynamic, List<ConditionFilter>> get conditionFilters => widget.tableController?.conditionFilters ?? _conditionFilters;
  set conditionFilters(Map<dynamic, List<ConditionFilter>> value) {
    if (widget.tableController == null) {
      _conditionFilters = value;
    } else {
      widget.tableController!.conditionFilters = value;
    }
  }
  late Map<dynamic, Map<Object, bool>> _valueFilters;
  Map<dynamic, Map<Object, bool>> get valueFilters => widget.tableController?.valueFilters ?? _valueFilters;
  set valueFilters(Map<dynamic, Map<Object, bool>> value) {
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
      if (widget.tableController!._getFiltered==_getFiltered) {
        widget.tableController!.currentState = null;
      }
      if (widget.tableController!._sort==_controllerSort) {
        widget.tableController!.currentState = null;
      }
      if (widget.tableController!._reInit==_invalidateState) {
        widget.tableController!.currentState = null;
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
    init(notifyListeners: false);
  }

  @override
  void didUpdateWidget(TableFromZero<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isStateInvalidated) {
      init();
    }
  }

  late final notificationRelayController = NotificationRelayController(
        (n) => n is ScrollNotification || n is ScrollMetricsNotification,
  );

  void init({bool notifyListeners=true}) {
    isStateInvalidated = false;
    currentColumnKeys = widget.columns?.keys.toList();
    sorted = List.from(widget.rows);
    if (widget.tableController!=null) {
      widget.tableController!.currentState = this;
      widget.tableController!._filter = _controllerFilter;
      widget.tableController!._sort = _controllerSort;
      widget.tableController!._reInit = _invalidateState;
      widget.tableController!._getFiltered = _getFiltered;
    }
    if (widget.tableController?.conditionFilters==null) {
      if (widget.tableController?.initialConditionFilters==null){
        conditionFilters = {};
      } else{
        conditionFilters = Map.from(widget.tableController!.initialConditionFilters ?? {});
      }
    }
    if (widget.tableController?.valueFilters==null) {
      if (widget.tableController?.initialValueFilters==null){
        valueFilters = {
          for (final e in widget.columns?.keys ?? [])
            e: {},
        };
      } else{
        valueFilters = {
          for (final e in widget.columns?.keys ?? [])
            e: widget.tableController!.initialValueFilters![e] ?? {},
        };
      }
    }
    if (widget.columns==null && widget.showHeaders) {
      headerRowModel = widget.headerRowModel;
    } else {
      if (widget.headerRowModel!=null) {
        if (widget.headerRowModel is SimpleRowModel) {
          headerRowModel = (widget.headerRowModel as SimpleRowModel).copyWith(
            onCheckBoxSelected: widget.headerRowModel!.onCheckBoxSelected
                ?? (widget.onAllSelected!=null||widget.rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null),
            values: widget.columns==null || widget.columns!.length==widget.headerRowModel!.values.length
                ? widget.headerRowModel!.values
                : widget.columns!.map((key, value) => MapEntry(key, value.name)),
            rowAddonIsAboveRow: widget.headerRowModel?.rowAddonIsAboveRow ?? true,
            rowAddonIsCoveredByBackground: widget.headerRowModel?.rowAddonIsCoveredByBackground ?? true,
            rowAddonIsCoveredByScrollable: widget.headerRowModel?.rowAddonIsCoveredByScrollable ?? true,
            rowAddonIsSticky: widget.headerRowModel?.rowAddonIsSticky ?? false,
          );
        } else {
          headerRowModel = widget.headerRowModel;
        }
      } else {
        headerRowModel = SimpleRowModel(
          id: "header_row",
          values: widget.columns!.map((key, value) => MapEntry(key, value.name)),
          onCheckBoxSelected: widget.onAllSelected!=null||widget.rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null,
          selected: true,
          height: widget.rows.isEmpty ? 36 : widget.rows.first.height,
        );
      }
      availableFilters.value = null;
    }
    if (widget.columns!=null) {
      initFilters();
    }
    _updateFiltersApplied();
    sort(notifyListeners: notifyListeners);
  }

  cancelable_compute.ComputeOperation<Map<dynamic, List<dynamic>>>? availableFiltersIsolateController;
  cancelable_compute.ComputeOperation<Map<dynamic, Map<Object, bool>>?>? validInitialFiltersIsolateController;
  void initFilters([bool? computeFiltersInIsolate]) async {
    availableFiltersIsolateController?.cancel();
    validInitialFiltersIsolateController?.cancel();
    Map<dynamic, List<dynamic>> computedAvailableFilters;
    Map<dynamic, Map<Object, bool>>? computedValidInitialFilters;
    if (computeFiltersInIsolate ?? widget.computeFiltersInIsolate ?? widget.rows.length>50) {
      try {
        final Map<dynamic, Map<dynamic, Field>> fieldAliases = {
          for (final key in widget.columns!.keys) key: {},
        };
        final Map<dynamic, Map<dynamic, DAO>> daoAliases = {
          for (final key in widget.columns!.keys) key: {},
        };
        // TODO 2 cancel isolate computations if widget is disposed or initFilters is called again
        availableFiltersIsolateController = cancelable_compute.compute(_getAvailableFilters,
            [
              widget.columns!.map((key, value) => MapEntry(key, [value.filterEnabled, value.defaultSortAscending])),
              widget.rows.map((e) {
                return e.values.map((key, value) {
                  return MapEntry(key, _sanitizeValueForIsolate(key, value, // TODO 2 performance, maybe allow to manually disable sanitization
                    fieldAliases: fieldAliases[key]!,
                    daoAliases: daoAliases[key]!,
                  ));
                });
              }).toList(),
            ]);
        final computationResult = await availableFiltersIsolateController!.value;
        if (computationResult==null) return; // cancelled
        computedAvailableFilters = computationResult;
        computedAvailableFilters = computedAvailableFilters.map((key, value) {
          if (fieldAliases.isEmpty && daoAliases.isEmpty) {
            return MapEntry(key, value);
          } else {
            final result = value.map((e) => fieldAliases[key]![e] ?? daoAliases[key]![e] ?? e).toList();
            result.sort((a, b) => defaultComparator(a, b, sortedAscending));
            return MapEntry(key, result);
          }
        });
        if (valueFiltersApplied.values.where((e) => e==true).isNotEmpty) {
          validInitialFiltersIsolateController = cancelable_compute.compute(_getValidInitialFilters,
              [valueFilters, computedAvailableFilters]);
          computedValidInitialFilters = await validInitialFiltersIsolateController!.value;
        }
      } catch (e, st) {
        print('Isolate creation for computing table filters failed. Computing synchronously...');
        print(e);
        print(st);
        initFilters(false);
        return;
      }
    } else {
      computedAvailableFilters = _getAvailableFilters(
          [
            widget.columns!.map((key, value) => MapEntry(key, [value.filterEnabled, value.defaultSortAscending])),
            widget.rows.map((e) => e.values).toList(),
          ]);
      computedValidInitialFilters = _getValidInitialFilters(
          [valueFilters, computedAvailableFilters]);
    }
    if (mounted) {
      availableFilters.value = computedAvailableFilters;
      if (computedValidInitialFilters != null) {
        valueFilters = computedValidInitialFilters;
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
  static Map<dynamic, List<dynamic>> _getAvailableFilters(List<dynamic> params) {
    final Map<dynamic, List<bool?>> columnOptions = params[0];
    final List<Map<dynamic, dynamic>> rowValues = params[1];
    Map<dynamic, List<dynamic>> availableFilters = {};
    columnOptions.forEach((key, options) {
      List<dynamic> available = [];
      if (options[0] ?? true) { // filterEnabled
        rowValues.forEach((row) {
          final element = row[key];
          if (element is List || element is ComparableList || element is ListField) {
            final List list = element is List ? element
                : element is ComparableList ? element.list
                : element is ListField ? element.objects : [];
            for (final e in list) {
              if (!available.contains(e)) {
                available.add(e);
              }
            }
          } else {
            if (!available.contains(element)) {
              available.add(element);
            }
          }
        });
      }
      bool sortAscending = options[1] ?? true; // defaultSortAscending
      available.sort((a, b) => defaultComparator(a, b, sortAscending));
      availableFilters[key] = available;
    });
    return availableFilters;
  }
  static Map<dynamic, Map<Object, bool>>? _getValidInitialFilters(List<dynamic> params) {
    Map<dynamic, Map<Object, bool>> initialFilters = params[0];
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

    if (widget.hideIfNoRows && filtered.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink(),);
    }
    int childCount = filtered.length.coerceIn(1);
    Widget result;

    if (true) {
    // if (!(widget.implicitlyAnimated ?? filtered.length<10)) {

      if (widget.enableFixedHeightForListRows && filtered.isNotEmpty) {
        result = SliverFixedExtentList(
          itemExtent: filtered.first.height,
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, filtered.isEmpty ? null : filtered[i]),
            childCount: childCount,
          ),
        );
      } else {
        result = SliverList(
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int i) => _getRow(context, filtered.isEmpty ? null : filtered[i]),
            childCount: childCount,
          ),
        );
      }

      // TODO 2 fix fatal error in animated list, seems to be a problem with row id equality
    } else {

      result = SliverImplicitlyAnimatedList<RowModel<T>>(
        items: filtered.isEmpty ? [] : filtered,
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
              child: _getRow(context, item),
            ),
          );
        },
        updateItemBuilder: (context, animation, item) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-0.10, 0), end: Offset(0, 0)).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: _getRow(context, item),
            ),
          );
        },
      );

    }

    Widget? header = widget.showHeaders
        ? headerRowModel!=null
            ? headerRowModel!.values.isEmpty && headerRowModel!.rowAddon!=null
                ? headerRowModel!.rowAddon!
                : _getRow(context, headerRowModel!)
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
                  painter: const SimpleShadowPainter(
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


  Widget _getRow(BuildContext context, RowModel? row){
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
            ?? _defaultGetRow.call(context, headerRowModel!);
      } else {
        if (widget.enableSkipFrameWidgetForRows ?? filtered.length>50) {
          return SkipFrameWidget(
            paceholderBuilder: (context) {
              return SizedBox(
                height: row.height,
              );
            },
            childBuilder: (context) {
              return widget.rowBuilder?.call(context, row as RowModel<T>, _defaultGetRow)
                  ?? _defaultGetRow.call(context, row as RowModel<T>);
            },
          );
        } else {
          return widget.rowBuilder?.call(context, row as RowModel<T>, _defaultGetRow)
              ?? _defaultGetRow.call(context, row as RowModel<T>);
        }
      }

    }
  }
  Widget _defaultGetRow(BuildContext context, RowModel row){

    int maxFlex = 0;
    for (final key in currentColumnKeys??row.values.keys) {
      maxFlex += _getFlex(key);
    }
    int cols = (((currentColumnKeys??row.values.keys).length) + (_showCheckboxes ? 1 : 0))
        * (widget.verticalDivider==null ? 1 : 2)
        + (widget.verticalDivider==null ? 0 : 1);
    List<Widget> rowActions = row==headerRowModel
        ? widget.rowActions.map((e) => e.copyWith(
            iconBuilder: ({
              required BuildContext context,
              required String title,
              Widget? icon,
              ContextCallback? onTap,
              bool enabled = true,
            }) {
              return FocusScope( // TODO 2 huge performance: find a way to pre-measure the width of actions, so we don't have to paint them
                canRequestFocus: false,
                child: IgnorePointer(
                  child: Container(
                    decoration: _getDecoration(row, null),
                    child: Opacity(
                      opacity: 0,
                      child: e.iconBuilder(
                        context: context,
                        title: title,
                        icon: icon,
                        onTap: onTap,
                        enabled: enabled,
                      ),
                    ),
                  ),
                ),
              );
            },
          )).toList()
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

    final builder = (BuildContext context, BoxConstraints? constraints) {
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
        if (result==null && _showCheckboxes){
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
          decoration: _getDecoration(row, colKey),
          child: result,
        );
        if (addSizing){
          if (col?.width!=null){
            result = SizedBox(width: col!.width, child: result,);
          } else{
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
        if (widget.verticalDivider!=null){
          if (j%2==0) return Padding(
            padding: EdgeInsets.only(left: j==0 ? 0 : 1, right: j==cols-1 ? 0 : 1,),
            child: widget.verticalDivider,
          );
          j = (j-1)~/2;
        }
        if (_showCheckboxes) {
          if (j==0){
            return SizedBox(
              width: _checkmarkWidth,
              child: row.onCheckBoxSelected==null ? SizedBox.shrink() :  StatefulBuilder(
                builder: (context, checkboxSetState) {
                  return LoadingCheckbox(
                    value: row==headerRowModel
                        ? filtered.isNotEmpty && filtered.every((element) => element.selected==true)
                        : row.selected,
                    onChanged: row==headerRowModel&&filtered.isEmpty ? null : (value) {
                      if (row==headerRowModel) {
                        if (widget.onAllSelected!(value, filtered) ?? false) {
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
              ),
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
          height: row.height,
          alignment: Alignment.center,
          padding: row==headerRowModel ? null : widget.cellPadding,
          child: Container(
              width: double.infinity,
              child: row==headerRowModel
                  ? defaultHeaderCellBuilder(context, headerRowModel!, colKey)
                  : widget.cellBuilder?.call(context, row as RowModel<T>, colKey)
                      ?? defaultCellBuilder.call(context, row as RowModel<T>, colKey),
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
          child: result,
        );
      }
      if (!(row.rowAddonIsCoveredByBackground??false) || rowActions.isNotEmpty) {
        result = Stack(
          key: row.rowKey ?? ValueKey(row.id),
          children: [
            Positioned.fill(child: background,),
            result,
          ],
        );
      }
      if (rowActions.isNotEmpty) {
        result = Material(
          type: MaterialType.transparency,
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
        );
      }
      if (row.rowAddon!=null) {
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
        Widget top, bottom;
        if (row.rowAddonIsAboveRow ?? false) {
          top = addon;
          bottom = result;
        } else {
          top = result;
          bottom = addon;
        }
        if (row.rowAddonIsSticky ?? widget.enableStickyHeaders){
          result = StickyHeader( // TODO 2 this is probably broken, use SliverStickyHeader instead
            controller: widget.scrollController,
            header: top,
            content: bottom,
            stickOffset: row is! RowModel<T> ? 0
                : filtered.indexOf(row)==0 ? 0
                : widget.stickyOffset + row.height,
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
          child: result,
        );
      }
      if (row!=headerRowModel) {
        result = ContextMenuFromZero(
          child: result,
          onShowMenu: () => row.focusNode.requestFocus(),
          actions: rowActions.where((e) => e is ActionFromZero
              && e.getStateForMaxWidth(constraints?.maxWidth??double.infinity)!=ActionState.none).toList().cast(),
        );
      }
      if ((row.rowAddonIsCoveredByBackground??false) && rowActions.isEmpty) {
        result = Stack(
          key: row.rowKey ?? ValueKey(row.id),
          children: [
            Positioned.fill(child: background,),
            result,
          ],
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
        child: Container(
          decoration: _getDecoration(row, null),
          child: result,
        ),
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
    result = ClipRect(
      clipBehavior: Clip.hardEdge,
      child: result,
    );
    return result;

  }
  Widget _buildRowGestureDetector({required BuildContext context, required RowModel<T> row, required Widget child}) {
    Widget result = child;
    if (row.onRowTap!=null || row.onCheckBoxSelected!=null) {
      result = InkWell(
        onTap: !widget.enabled ? null
            : row.onRowTap!=null ? () => row.onRowTap!(row)
            : row.onCheckBoxSelected!=null
                ? () {
                    if (row.onCheckBoxSelected!(row, !(row.selected??false)) ?? false) {
                      setState(() {});
                    }
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

  Widget defaultHeaderCellBuilder(BuildContext context, RowModel row, dynamic colKey, {
    int autoSizeTextMaxLines = 1,
  }) {
    return ValueListenableBuilder(
      valueListenable: availableFilters,
      builder: (context, availableFilters, child) {
        final col = widget.columns?[colKey];
        final name = col?.name ?? (row.values[colKey]!=null ? row.values[colKey].toString() : "");
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
                left: -4, width: 32, top: 0, bottom: 0,
                child: OverflowBox(
                  maxHeight: row.height, maxWidth: 32,
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    child: (widget.enabled && !export && sortedColumn==colKey) ? Icon(
                      sortedAscending ? MaterialCommunityIcons.sort_ascending : MaterialCommunityIcons.sort_descending,
                      key: ValueKey(sortedAscending),
//                                color: Theme.of(context).brightness==Brightness.light ? Colors.blue.shade700 : Colors.blue.shade400,
                      color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
                    ) : SizedBox(height: 24,),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child,),
                    ),
                  ),
                ),
              ),
              if (widget.enabled && !export && (col?.filterEnabled??true))
                Positioned(
                  right: availableFilters==null ? -20 : -16, width: 48, top: 0, bottom: 0,
                  child: OverflowBox(
                    maxHeight: row.height, maxWidth: 48,
                    alignment: Alignment.center,
                    child: availableFilters==null
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
                            onPressed: () => showFilterDialog(colKey),
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
              title: 'Ordenar Ascendente', // TODO 2 internationalize
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
              title: 'Ordenar Descendente', // TODO 2 internationalize
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
          if (availableFilters!=null && (col?.filterEnabled ?? true))
            ActionFromZero(
              title: 'Filtros...', // TODO 2 internationalize
              icon: Icon(MaterialCommunityIcons.filter),
              onTap: (context) => showFilterDialog(colKey),
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
      },
    );
  }

  void showFilterDialog(dynamic j) async{
    if (availableFilters.value==null) return;
    final col = widget.columns?[j];
    ScrollController filtersScrollController = ScrollController();
    TableController filterTableController = TableController();
    bool modified = false;
    List<ConditionFilter> possibleConditionFilters = [];
    // if (widget.columns![j].neutralConditionFiltersEnabled ?? true) {
    //   possibleConditionFilters.addAll([
    //     FilterIsEmpty(),
    //   ]);
    // }
    // TODO 2 when selecting available filters, automatically enable only possible filters (if null in the column)
    if (col?.textConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterTextExactly(),
        FilterTextContains(),
        FilterTextStartsWith(),
        FilterTextEndsWith(),
      ]);
    }
    if (col?.numberConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterNumberEqualTo(),
        FilterNumberGreaterThan(),
        FilterNumberLessThan(),
      ]);
    }
    if (col?.dateConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterDateExactDay(),
        FilterDateAfter(),
        FilterDateBefore(),
      ]);
    }
    final filterSearchFocusNode = FocusNode();
    if (PlatformExtended.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        filterSearchFocusNode.requestFocus();
      });
    }
    await showPopupFromZero(
      context: context,
      anchorKey: filterGlobalKeys[j],
      builder: (context) {
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
                                      if (conditionFilters[j]==null) {
                                        conditionFilters[j] = [];
                                      }
                                      conditionFilters[j]!.add(value);
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
                      if ((conditionFilters[j] ?? []).isEmpty)
                        SliverToBoxAdapter(child: Padding(
                          padding: EdgeInsets.only(left: 24, bottom: 8,),
                          child: Text (FromZeroLocalizations.of(context).translate('none'),
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),),
                      SliverList(
                        delegate: SliverChildListDelegate.fixed(
                          (conditionFilters[j] ?? []).map((e) {
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
                                    conditionFilters[j]!.remove(e);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: (conditionFilters[j] ?? []).isEmpty ? 6 : 12,)),
                      SliverToBoxAdapter(child: Divider(height: 32,)),
                      TableFromZero(
                        tableController: filterTableController,
                        rows: (availableFilters.value?[j] ?? []).map((e) {
                          return SimpleRowModel(
                            id: e,
                            values: {0: e},
                            selected: valueFilters[j]![e] ?? false,
                            onCheckBoxSelected: (row, selected) {
                              modified = true;
                              valueFilters[j]![row.id] = selected!;
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
                                              valueFilters[j]![row.id] = true;
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
                                              valueFilters[j]![row.id] = false;
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
      },
    );
    if (modified && mounted) {
      setState(() {
        _updateFiltersApplied();
        filter();
      });
    }
    // if (accepted!=true) {
    //   widget.onCanceled?.call();
    // }
  }

  Widget defaultCellBuilder(BuildContext context, RowModel<T> row, dynamic colKey) {
    // final col = widget.columns?[colKey];
    final value = row.values[colKey];
    String message;
    if (value is List || value is ComparableList) {
      final List list = value is List ? value
          : value is ComparableList ? value.list : [];
      message = ListField.listToStringAll(list);
    } else {
      message = value!=null ? value.toString() : "";
    }
    final autoSizeTextMaxLines = 1;
    Widget result = AutoSizeText(
      message,
      style: _getStyle(context, row, colKey),
      textAlign: _getAlignment(colKey),
      maxLines: autoSizeTextMaxLines,
      minFontSize: 14,
      overflowReplacement: TooltipFromZero(
        message: message,
        waitDuration: Duration(milliseconds: 0),
        verticalOffset: -16,
        child: AutoSizeText(
          message,
          style: _getStyle(context, row, colKey),
          textAlign: _getAlignment(colKey),
          maxLines: autoSizeTextMaxLines,
          softWrap: autoSizeTextMaxLines>1,
          overflow: autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
        ),
      ),
    );
    return result;
  }

  BoxDecoration? _getDecoration(RowModel row, dynamic colKey,){
    bool header = row==headerRowModel;
    Color? backgroundColor = _getBackgroundColor(row, colKey, header);
    if (header && backgroundColor==null){
      backgroundColor = _getMaterialColor();
    }
    if (backgroundColor!=null) {
      bool applyDarker = widget.alternateRowBackgroundBrightness==true
          && _shouldApplyDarkerBackground(backgroundColor, row, colKey, header);
      if (backgroundColor.opacity<1) {
        backgroundColor = Color.alphaBlend(backgroundColor, _getMaterialColor());
      }
      if(applyDarker){
        backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.965), Colors.black);
      }
    }
    return backgroundColor==null ? null : BoxDecoration(color: backgroundColor);
  }
  Color _getMaterialColor() => Material.of(context)!.color ?? Theme.of(context).cardColor;
  Color? _getBackgroundColor(RowModel row, dynamic colKey, bool header){
    Color? backgroundColor;
    if (header){
      backgroundColor = widget.columns?[colKey]?.backgroundColor;
    } else if (colKey==null) {
      backgroundColor = row.backgroundColor ?? _getMaterialColor();
    } else{
      if (widget.rowStyleTakesPriorityOverColumn){
        backgroundColor = row.backgroundColor ?? widget.columns?[colKey]?.backgroundColor;
      } else{
        backgroundColor = widget.columns?[colKey]?.backgroundColor ?? row.backgroundColor;
      }
    }
    return backgroundColor;
  }
  bool _shouldApplyDarkerBackground(Color? current, RowModel row, dynamic colKey, bool header){
//    if (filtered[i]!=row) return false;
    int i = row is! RowModel<T> ? -1 : filtered.indexOf(row);
    if (i<0) {
      return false;
    } else if (i==0) {
      return true;
    } else if (!(widget.alternateRowBackgroundSmartly??filtered.length<50) || i > filtered.length) {
      return i.isEven;
    } else {
      Color? previous = _getBackgroundColor(filtered[i-1], colKey, header);
      if (previous!=current) return false;
      return !_shouldApplyDarkerBackground(previous, filtered[i-1], colKey, header);
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

  int get disabledColumnCount => widget.columns==null ? 0
      : widget.columns!.values.where((element) => element.flex==0).length;
  List<RowModel<T>> _controllerSort ({bool filterAfter=true}) {
    List<RowModel<T>> result = [];
    if (mounted){
      result = sort(filterAfter: filterAfter);
      setState(() {});
    }
    return result;
  }
  List<RowModel<T>> sort({bool notifyListeners=true, bool filterAfter=true}) {
    if (filterAfter) {
      _sort(sorted);
      filter(notifyListeners: notifyListeners);
      return sorted;
    } else {
      _sort(filtered);
      if (notifyListeners) {
        widget.tableController?.notifyListeners();
      }
      return filtered;
    }
  }
  _sort(List<RowModel<T>> list) {
    mergeSort(list, compare: ((RowModel<T> a, RowModel<T> b){
      if (a.alwaysOnTop!=null || b.alwaysOnTop!=null && a.alwaysOnTop!=b.alwaysOnTop) {
        if (a.alwaysOnTop==true || b.alwaysOnTop==false) return -1;
        if (a.alwaysOnTop==false || b.alwaysOnTop==true) return 1;
      }
      if (sortedColumn==null) {
        return 0;
      }
      var aVal = a.values[sortedColumn!];
      var bVal = b.values[sortedColumn!];
      if (aVal!=null && aVal is! Comparable) aVal = aVal.toString();
      if (bVal!=null && bVal is! Comparable) bVal = bVal.toString();
      return sortedAscending
          ? aVal==null ? 1 : bVal==null ? -1 : aVal.compareTo(bVal)
          : aVal==null ? -1 : bVal==null ? 1 : bVal.compareTo(aVal);
    }));
  }
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
    filtered = sorted.where((element) {
      bool pass = true;
      for (final key in valueFilters.keys) {
        if (valueFiltersApplied[key]!) {
          final value = element.values[key];
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
        for (var j = 0; j < filters.length && pass; ++j) {
          pass = filters[j].isAllowed(element.values[key], element.values, key);
        }
      });
      return pass;
    }).toList();
    if (widget.onFilter!=null) {
      filtered = widget.onFilter!(filtered);
    }
    for (final e in (widget.tableController?.extraFilters ?? [])) {
      filtered = e(filtered);
    }
    _showCheckboxes = false;
    for (int i=0; i<filtered.length; i++) {
      if (filtered[i].onCheckBoxSelected!=null) {
        _showCheckboxes = true;
        break;
      }
    }
    if (notifyListeners) {
      widget.tableController?.notifyListeners();
    }
    return filtered;
  }
  bool _showCheckboxes = false;
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
      final value = valueFilters[key]![availableFilter] ?? false;
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
    } else if (a is Comparable) {
      result = a.compareTo(b);
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
  Map<dynamic, Map<Object, bool>>? initialValueFilters;
  bool initialValueFiltersExcludeAllElse;
  Map<dynamic, Map<Object, bool>>? valueFilters;
  Map<dynamic, bool>? valueFiltersApplied;
  Map<dynamic, bool>? filtersApplied;
  Map<dynamic, bool> columnVisibilities;
  bool sortedAscending;
  dynamic sortedColumn;

  TableController({
    List<List<RowModel<T>> Function(List<RowModel<T>>)>? extraFilters,
    this.initialConditionFilters,
    this.initialValueFilters,
    this.sortedAscending = true,
    this.sortedColumn,
    this.initialValueFiltersExcludeAllElse = false,
    Map<int, bool>? columnVisibilities,
  })  : this.extraFilters = extraFilters ?? [],
        this.columnVisibilities = columnVisibilities ?? {};

  TableController<T> copyWith({
    List<List<RowModel<T>> Function(List<RowModel<T>>)>? extraFilters,
    Map<dynamic, List<ConditionFilter>>? initialConditionFilters,
    Map<dynamic, List<ConditionFilter>>? conditionFilters,
    Map<dynamic, Map<Object, bool>>? initialValueFilters,
    bool? initialValueFiltersExcludeAllElse,
    Map<dynamic, Map<Object, bool>>? valueFilters,
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
      ..columnVisibilities = columnVisibilities ?? this.columnVisibilities
      ..sortedAscending = sortedAscending ?? this.sortedAscending
      ..sortedColumn = sortedColumnIndex ?? this.sortedColumn
      .._filter = this._filter
      ..currentState = currentState ?? this.currentState;
  }

  List<RowModel<T>> Function()? _filter;
  List<RowModel<T>> filter(){
    return _filter?.call() ?? [];
  }

  List<RowModel<T>> Function({bool filterAfter})? _sort;
  List<RowModel<T>> sort({bool filterAfter=true}){
    return _sort?.call(filterAfter: filterAfter) ?? [];
  }

  VoidCallback? _reInit;
  /// Call this if the rows change, to re-initialize rows
  void reInit(){
    _reInit?.call();
  }

  late List<RowModel<T>> Function() _getFiltered;
  List<RowModel<T>> get filtered => _getFiltered();

}