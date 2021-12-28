import 'dart:io';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:from_zero_ui/src/table/table_from_zero_filters.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:from_zero_ui/util/my_sticky_header.dart';
import 'package:from_zero_ui/util/no_ensure_visible_traversal_policy.dart';
import 'package:from_zero_ui/util/small_splash_popup_menu_button.dart' as small_popup;
import 'dart:async';
import 'package:dartx/dartx.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:keframe/frame_separate_widget.dart';

typedef OnRowHoverCallback = void Function(RowModel row, bool selected);
typedef OnCheckBoxSelectedCallback = bool? Function(RowModel row, bool? selected);
typedef OnHeaderHoverCallback = void Function(int i, bool selected);
typedef OnCellTapCallback = ValueChanged<RowModel>? Function(int index,);
typedef OnCellHoverCallback = OnRowHoverCallback? Function(int index,);


class TableFromZero<T> extends StatefulWidget {

  @deprecated static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;
  static const int animatedListViewBuilder = 4;
  static const int sliverAnimatedListViewBuilder = 5;

  static const double _checkmarkWidth = 48;

  final bool enabled;
  final List<RowModel<T>> rows;
  final List<ColModel>? columns;
  final bool rowTakesPriorityOverColumn;
  final int layoutWidgetType;
  final EdgeInsets itemPadding;
  final bool showHeaders;
  final ScrollController? scrollController;
  /// Only used if layoutWidgetType==listViewBuilder
  final double verticalPadding;
  final double horizontalPadding;
  final bool? Function(bool? value, List<RowModel<T>> filtered)? onAllSelected;
  final int? initialSortedColumnIndex;
  final bool showFirstHorizontalDivider;
  @deprecated final Widget? horizontalDivider;
  @deprecated final Widget? verticalDivider;
  final int autoSizeTextMaxLines;
  final double? headerHeight;
  final Widget Function(BuildContext context, RowModel<T> row, ColModel? col, int j)? cellBuilder;
  final Widget Function(BuildContext context, RowModel<T> row)? rowBuilder;
  final Widget Function(BuildContext context, RowModel<String> row)? headerRowBuilder;
  final bool applyStickyHeaders;
  final Widget? headerAddon;
  final bool applyRowAlternativeColors;
  final bool useSmartRowAlternativeColors;
  final double? minWidth;
  final double? maxWidth;
  final bool applyMinWidthToHeaderAddon;
  final bool applyMaxWidthToHeaderAddon;
  final bool applyTooltipToCells;
  final Color? headerRowColor;
  final bool applyHalfOpacityToHeaderColor;
  final TextStyle? defaultTextStyle;
  final double stickyOffset;
  final List<RowModel<T>> Function(List<RowModel<T>>)? onFilter;
  final TableController? tableController;
  final Alignment? alignmentWhenOverMaxWidth;
  final FutureOr<String>? exportPath;
  final bool applyScrollToRowAddon;
  final bool rowGestureDetectorCoversRowAddon;
  final bool applyStickyHeadersToRowAddon;
  final bool applyRowBackgroundToRowAddon;
  final bool useFixedHeightForListRows;
  final bool hideIfNoRows;
  final Widget? errorWidget;
  final double? rowHeightForScrollingCalculation;
  final List<RowAction<T>> rowActions;

  TableFromZero({
    required List<RowModel<T>> rows,
    this.enabled = true,
    this.columns,
    this.layoutWidgetType = listViewBuilder,
    this.scrollController,
    this.verticalPadding = 0,
    this.horizontalPadding = 0,
    this.showHeaders = true,
    this.rowTakesPriorityOverColumn = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.initialSortedColumnIndex,
    this.onAllSelected,
    @deprecated this.horizontalDivider, //const Divider(height: 1, color: const Color(0xFF757575),),
    @deprecated this.verticalDivider,   //const VerticalDivider(width: 1, color: const Color(0xFF757575),),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
    this.cellBuilder,
    this.rowBuilder,
    this.headerRowBuilder,
    this.headerHeight,
    this.applyStickyHeaders = true,
    this.headerAddon,
    this.applyRowAlternativeColors = true,
    this.minWidth,
    this.maxWidth,
    this.applyMinWidthToHeaderAddon = true,
    this.applyMaxWidthToHeaderAddon = true,
    this.applyTooltipToCells = false,
    this.headerRowColor,
    this.applyHalfOpacityToHeaderColor = true,
    this.defaultTextStyle,
    this.stickyOffset = 0,
    this.onFilter,
    this.tableController,
    this.alignmentWhenOverMaxWidth,
    this.exportPath,
    this.applyScrollToRowAddon = true,
    this.rowGestureDetectorCoversRowAddon = true,
    this.errorWidget,
    this.rowHeightForScrollingCalculation,
    this.useSmartRowAlternativeColors = true,
    this.useFixedHeightForListRows = true,
    this.hideIfNoRows = false,
    this.rowActions = const [],
    bool? applyStickyHeadersToRowAddon,
    bool? applyRowBackgroundToRowAddon,
    Key? key,
  }) :  this.rows = List.from(rows),
        this.applyStickyHeadersToRowAddon = applyStickyHeadersToRowAddon??applyStickyHeaders,
        this.applyRowBackgroundToRowAddon = applyRowBackgroundToRowAddon??applyScrollToRowAddon,
        super(key: key,);

  @override
  TableFromZeroState<T> createState() => TableFromZeroState<T>();

}



class TrackingScrollControllerFixedPosition extends TrackingScrollController {

  ScrollPosition get position {
    assert(positions.isNotEmpty, 'ScrollController not attached to any scroll views.');
    return positions.first;
  }

}

class TableFromZeroState<T> extends State<TableFromZero<T>> {

  late List<RowModel<T>> sorted;
  late List<RowModel<T>> filtered;
  late Map<int, FocusNode> headerFocusNodes = {};

  late Map<int, List<ConditionFilter>> _conditionFilters;
  Map<int, List<ConditionFilter>> get conditionFilters => widget.tableController?.conditionFilters ?? _conditionFilters;
  set conditionFilters(Map<int, List<ConditionFilter>> value) {
    if (widget.tableController == null) {
      _conditionFilters = value;
    } else {
      widget.tableController!.conditionFilters = value;
    }
  }
  late List<Map<Object, bool>> _valueFilters;
  List<Map<Object, bool>> get valueFilters => widget.tableController?.valueFilters ?? _valueFilters;
  set valueFilters(List<Map<Object, bool>> value) {
    if (widget.tableController==null) {
      _valueFilters = value;
    } else {
      widget.tableController!.valueFilters = value;
    }
  }
  late List<bool> filtersApplied;
  List<List<dynamic>> availableFilters = [];
  late List<GlobalKey> filterGlobalKeys = [];

  int? _sortedColumnIndex;
  int? get sortedColumnIndex => widget.tableController==null ? _sortedColumnIndex : widget.tableController!.sortedColumnIndex;
  set sortedColumnIndex (int? value) {
    if (widget.tableController==null) {
      _sortedColumnIndex = value;
    } else {
      widget.tableController!.sortedColumnIndex = value;
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

  late TrackingScrollControllerFixedPosition sharedController;
  RowModel<String>? headerRowModel;

  TableFromZeroState();

  double lastPosition = 0;
  bool lockScrollUpdates = false;
  @override
  void initState() {
    super.initState();
    sharedController = TrackingScrollControllerFixedPosition();
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
    // WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
    //   if (sharedController.hasClients) {
    //     // old hack to show scrollbar at start, no longer needed, i think
    //     final pixels = sharedController.position.pixels;
    //     sharedController.jumpTo(pixels+1);
    //     sharedController.jumpTo(pixels);
    //   }
    // });
    if (sortedColumnIndex==null || sortedColumnIndex==-1) {
      sortedColumnIndex = widget.initialSortedColumnIndex;
    }
    if (sortedColumnIndex!=null && sortedColumnIndex!>=0) {
      sortedAscending = widget.columns?[sortedColumnIndex!].defaultSortAscending ?? true;
    }
    init(notifyListeners: false,);
  }

  @override
  void didUpdateWidget(TableFromZero<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // init();  // This causes major issues with performance and some bugs as well,
                // disabling it might make it necessary to manually trigger an initState when necessary
  }

  void init({bool notifyListeners=true}) {
    sorted = List.from(widget.rows);
    if (widget.columns!=null) {
      headerRowModel = SimpleRowModel(
        id: "header_row",
        values: List.generate(widget.columns!.length, (index) => widget.columns![index].name),
        onCheckBoxSelected:  widget.onAllSelected!=null||widget.rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null,
        selected: true,
        height: widget.headerHeight ?? widget.rowHeightForScrollingCalculation ?? (widget.rows.isEmpty ? 38 : widget.rows.first.height),
      );
      availableFilters = [];
      for (int i=0; i<widget.columns!.length; i++) {
        List<dynamic> available = [];
        if (widget.columns![i].filterEnabled ?? true) {
          widget.rows.forEach((element) {
            if (!available.contains(element.values[i]))
              available.add(element.values[i]);
          });
        }
        bool sortAscending = widget.columns?[i].defaultSortAscending ?? true;
        available.sort((a, b) {
          int? result;
          try {
            result = a.compareTo(b);
          } catch (_) {
            result = a.toString().compareTo(b.toString());
          }
          return sortAscending ? result! : result! * -1;
        });
        availableFilters.add(available);
      }
    }
    if (widget.tableController!=null) {
      widget.tableController!._filter = () {
        if (mounted){
          setState(() {
            filter();
          });
        }
      };
      widget.tableController!._init = () {
        if (mounted){
          setState(() {
            init();
          });
        }
      };
      widget.tableController!._getFiltered = ()=>filtered;
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
        valueFilters = List.generate(widget.columns?.length ?? 0, (index) => {});
      } else{
        if (widget.tableController!.initialValueFiltersExcludeAllElse) {
          valueFilters = [];
          for (var i = 0; i < availableFilters.length; ++i) {
            valueFilters.add({});
            if (widget.tableController!.initialValueFilters![i]!=null) {
              availableFilters[i].forEach((e) {
                valueFilters[i][e] = false;
              });
              widget.tableController!.initialValueFilters![i]!.forEach((key, value) {
                valueFilters[i][key] = value;
              });
            }
          }
        } else {
          valueFilters = List.generate(widget.columns?.length ?? 0, (index) => widget.tableController!.initialValueFilters![index] ?? {});
        }
      }
    }
    valueFilters.forEachIndexed((element, index) {
      element.removeWhere((key, value) => !availableFilters[index].contains(key));
    });
    _updateFiltersApplied();
    sort(notifyListeners: notifyListeners);
  }

  @override
  Widget build(BuildContext context) {

    if (widget.hideIfNoRows && filtered.isEmpty) {
      if (widget.layoutWidgetType==TableFromZero.sliverListViewBuilder || widget.layoutWidgetType==TableFromZero.sliverAnimatedListViewBuilder) {
        return SliverToBoxAdapter(child: SizedBox.shrink(),);
      } else {
        return SizedBox.shrink();
      }
    }

    int childCount = filtered.length.coerceIn(1);
    Widget result;

    // Hack to be able to apply widget.stickyOffset
    if (widget.layoutWidgetType==TableFromZero.column || (widget.stickyOffset!=0 &&
        (widget.layoutWidgetType==TableFromZero.listViewBuilder
        || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder))){

      if (widget.layoutWidgetType==TableFromZero.column){
        result = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(childCount, (i) => _getRow(context, filtered.isEmpty ? null : filtered[i])),
        );
      } else if (widget.layoutWidgetType==TableFromZero.listViewBuilder) {
        result = ListView.builder(
          itemBuilder: (context, i) => _getRow(context, filtered.isEmpty ? null : filtered[i]),
          itemCount: childCount,
          controller: widget.scrollController,
          itemExtent: widget.useFixedHeightForListRows && filtered.isNotEmpty
              ? (widget.rowHeightForScrollingCalculation ?? filtered.first.height)
              : null,
        );
      } else if (widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = ImplicitlyAnimatedList<RowModel<T>>(
          items: filtered,
          areItemsTheSame: (a, b) => a==b,
          shrinkWrap: true,
          controller: widget.scrollController,
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
          insertDuration: Duration(milliseconds: 400),
//        updateItemBuilder: (context, animation, item) {
//          return ZoomedFadeInTransition(
//            animation: animation,
//            child: _getRow(context, 1, item),
//          );
//        },
          updateItemBuilder: (context, animation, item) {
            return SlideTransition(
              position: Tween<Offset>(begin: Offset(-0.10, 0), end: Offset(0, 0)).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: _getRow(context, item),
              ),
            );
          },
          updateDuration: Duration(milliseconds: 400),
        );
      } else{
        result = SizedBox.shrink();
      }
      bool showHeaders = widget.showHeaders && widget.columns!=null && headerRowModel!=null;
      Widget? header;
      if (showHeaders) {
        header = _getRow(context, headerRowModel!);
      } else if (widget.headerAddon!=null) {
        header = _getHeaderAddonWidget(context);
        if (widget.maxWidth!=null) {
          header = Center(
            child: SizedBox(
              width: widget.maxWidth,
              child: header,
            ),
          );
        }
      }
      if (header!=null) {
        result = StickyHeaderBuilder(
          content: result,
          controller: widget.scrollController,
          stickOffset: widget.stickyOffset,
          builder: (context, state) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                header!,
                if (state<0)
                  Positioned(
                    left: 0, right: 0, bottom: -2,
                    child: InitiallyAnimatedWidget(
                      duration: Duration(milliseconds: 300,),
                      builder: (animationController, child) {
                        return Opacity(
                          opacity: CurveTween(curve: Curves.easeOutCubic).evaluate(animationController),
                          child: Center(
                            child: SizedBox(
                              width: widget.maxWidth ?? double.infinity, height: 2,
                              child: const CustomPaint(
                                painter: const SimpleShadowPainter(
                                  direction: SimpleShadowPainter.down,
                                  shadowOpacity: 0.2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      }

      result = Padding(
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding,),
        child: result,
      );

    } else{

      if (widget.layoutWidgetType==TableFromZero.listViewBuilder
          || widget.layoutWidgetType==TableFromZero.sliverListViewBuilder){

        if (widget.useFixedHeightForListRows && filtered.isNotEmpty) {
          result = SliverFixedExtentList(
            itemExtent: widget.rowHeightForScrollingCalculation ?? filtered.first.height,
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
      } else if (widget.layoutWidgetType==TableFromZero.sliverAnimatedListViewBuilder
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = SliverImplicitlyAnimatedList<RowModel<T>>(
          items: filtered,
          areItemsTheSame: (a, b) => a==b,
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
          insertDuration: Duration(milliseconds: 400),
//        updateItemBuilder: (context, animation, item) {
//          return ZoomedFadeInTransition(
//            animation: animation,
//            child: _getRow(context, 1, item),
//          );
//        },
          updateItemBuilder: (context, animation, item) {
            return SlideTransition(
              position: Tween<Offset>(begin: Offset(-0.10, 0), end: Offset(0, 0)).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: _getRow(context, item),
              ),
            );
          },
          updateDuration: Duration(milliseconds: 400),
        );
      } else{
        result = SizedBox.shrink();
      }
      bool showHeaders = widget.showHeaders && widget.columns!=null && headerRowModel!=null;
      Widget? header;
      if (showHeaders) {
        header = _getRow(context, headerRowModel!);
      } else if (widget.headerAddon!=null) {
        header = _getHeaderAddonWidget(context);
        if (widget.maxWidth!=null) {
          header = Center(
            child: SizedBox(
              width: widget.maxWidth,
              child: header,
            ),
          );
        }
      }
      if (header!=null){
        result = SliverStickyHeader.builder(
          sliver: result,
          sticky: widget.applyStickyHeaders,
          builder: (context, state) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                header!,
                Positioned(
                  left: 0, right: 0, bottom: -2,
                  child: !state.isPinned ? SizedBox.shrink() : InitiallyAnimatedWidget(
                    duration: Duration(milliseconds: 300,),
                    builder: (animationController, child) {
                      return Opacity(
                        opacity: CurveTween(curve: Curves.easeOutCubic).evaluate(animationController),
                        child: Center(
                          child: SizedBox(
                            width: widget.maxWidth ?? double.infinity, height: 2,
                            child: const CustomPaint(
                              painter: const SimpleShadowPainter(
                                direction: SimpleShadowPainter.down,
                                shadowOpacity: 0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      }
      result = SliverPadding(
        padding: EdgeInsets.only(top: widget.verticalPadding, bottom: widget.verticalPadding,),
        sliver: result,
      );
      if (widget.layoutWidgetType==TableFromZero.listViewBuilder
          || widget.layoutWidgetType==TableFromZero.column
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = CustomScrollView(
          controller: widget.scrollController,
          shrinkWrap: true,
          slivers: [result],
        );
      }

    }
    result = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: result,
    );
    return result;
  }


  Widget _getHeaderAddonWidget(BuildContext context, [BoxConstraints? constraints]) {
    Widget addon = widget.headerAddon!;
    if (widget.applyMinWidthToHeaderAddon && constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
      addon = NotificationListener(
        onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
        child: SingleChildScrollView(
          controller: sharedController,
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: SizedBox(
              width: widget.minWidth!,
              child: addon,
            ),
          ),
        ),
      );
    }
    return addon;
  }

  Widget _getRow(BuildContext context, RowModel? row){
    if (row==headerRowModel){
      return (widget.headerRowBuilder??_defaultGetRow).call(context, headerRowModel!);
    } else{
      return (widget.rowBuilder??_defaultGetRow).call(context, row as RowModel<T>);
    }
  }
  Widget _defaultGetRow(BuildContext context, RowModel? row){

    if (row==null){
      return InitiallyAnimatedWidget(
        duration: Duration(milliseconds: 500,),
        builder: (animation, child) {
          return SizeFadeTransition(animation: animation, child: child, sizeFraction: 0.7, curve: Curves.easeOutCubic,);
        },
        child: Center(
          child: Container(
            color: Material.of(context)?.color,
            width: widget.maxWidth,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: widget.errorWidget ?? ErrorSign(
              icon: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 64, color: Theme.of(context).disabledColor,),
              title: FromZeroLocalizations.of(context).translate('no_data'),
              subtitle: filtersApplied.where((e) => e).isNotEmpty ? FromZeroLocalizations.of(context).translate('no_data_filters')
                                                                  : FromZeroLocalizations.of(context).translate('no_data_desc'),
            ),
          ),
        ),
      );
    }

    int maxFlex = 0;
    for (var j = 0; j < row.values.length; ++j) {
      maxFlex += _getFlex(j);
    }
    int cols = ((row.values.length) + (row.onCheckBoxSelected==null ? 0 : 1)) * (widget.verticalDivider==null ? 1 : 2) + (widget.verticalDivider==null ? 0 : 1);
    final rowActions = row==headerRowModel
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
                    decoration: _getDecoration(row, -1),
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
        if (result==null && row.onCheckBoxSelected!=null){
          if (j==0){
            addSizing = false;
            result = SizedBox(width: TableFromZero._checkmarkWidth, height: double.infinity,);
          } else{
            j--;
          }
        }
        if (result==null && widget.columns!=null && widget.columns![j].flex==0){
          return SizedBox.shrink();
        }
        if (!kIsWeb && Platform.isWindows){
          result = Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: row==headerRowModel ? 0 : -1,
                bottom: -1, // bottom: i==filtered.length-1 ? 0 : -1,
                left: j==0 ? 0 : -1,
                right: j==cols-1 ? 0 : -1,
                child: Container(
                  decoration: _getDecoration(row, j),
                ),
              ),
              if (result!=null)
                result,
            ],
          );
        } else{
          result = Container(
            decoration: _getDecoration(row, j),
            child: result,
          );
        }
        if (addSizing){
          if (widget.columns!=null && widget.columns![j].width!=null){
            result = SizedBox(width: widget.columns![j].width, child: result,);
          } else{
            if (constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
              return SizedBox(width: widget.minWidth! * (_getFlex(j)/maxFlex), child: result,);
            } else {
              return Expanded(flex: _getFlex(j), child: result,);
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
        if (row.onCheckBoxSelected!=null){
          if (j==0){
            return SizedBox(
              width: TableFromZero._checkmarkWidth,
              child: StatefulBuilder(
                builder: (context, checkboxSetState) {
                  return LoadingCheckbox(
                    value: row==headerRowModel ? filtered.every((element) => element.selected==true) : row.selected,
                    onChanged: (value) {
                      if (row==headerRowModel) {
                        if (widget.onAllSelected!(value, filtered) ?? false) {
                          setState(() {});
                        }
                      } else {
                        if (row.onCheckBoxSelected!(row, value) ?? false) {
                          setState(() {});
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
        if (widget.columns!=null && widget.columns![j].flex==0){
          return SizedBox.shrink();
        }
        Widget result = Container(
          height: widget.rowHeightForScrollingCalculation ?? row.height,
          alignment: Alignment.center,
          padding: row==headerRowModel ? null : widget.itemPadding,
          child: Container(
              width: double.infinity,
              child: row==headerRowModel
                  ? defaultHeaderCellBuilder(context, headerRowModel!, widget.columns==null?null:widget.columns![j], j)
                  : (widget.cellBuilder??defaultCellBuilder).call(context, row as RowModel<T>, widget.columns==null?null:widget.columns![j], j),
          ),
        );
        if (row.onCellTap!=null || row.onCellDoubleTap!=null || row.onCellLongPress!=null || row.onCellHover!=null){
          result = Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.enabled&&row.onCellTap!=null&&row.onCellTap!(j)!=null ? () {
                row.onCellTap!(j)!.call(row);
              } : null,
              onDoubleTap: widget.enabled&&row.onCellDoubleTap!=null&&row.onCellDoubleTap!(j)!=null ? () => row.onCellDoubleTap!(j)!.call(row) : null,
              onLongPress: widget.enabled&&row.onCellLongPress!=null&&row.onCellLongPress!(j)!=null ? () => row.onCellLongPress!(j)!.call(row) : null,
              onHover: widget.enabled&&row.onCellHover!=null&&row.onCellHover!(j)!=null ? (value) => row.onCellHover!(j)!.call(row, value) : null,
              child: result,
            ),
          );
        }
        if (widget.columns!=null && widget.columns![j].width!=null){
          return SizedBox(width: widget.columns![j].width, child: result,);
        } else {
          if (constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
            return SizedBox(width: (widget.minWidth! * (_getFlex(j)/maxFlex)), child: result,);
          } else {
            return Flexible(flex: _getFlex(j), child: result,);
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
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          ),
        );
        result = SizedBox(
          height: widget.rowHeightForScrollingCalculation ?? row.height,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: sharedController,
            itemBuilder: cellBuilder,
            itemCount: cols,
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            cacheExtent: 99999999,
          ),
        );
        if (row==headerRowModel) {
          result = ScrollbarFromZero(
            controller: sharedController,
            opacityGradientDirection: OpacityGradient.horizontal,
            child: result,
          );
        } else {
          result = ScrollOpacityGradient(
            scrollController: sharedController,
            direction: OpacityGradient.horizontal,
            child: NotificationListener(
              onNotification: (n) => n is ScrollNotification || n is ScrollMetricsNotification,
              child: result,
            ),
          );
        }
      } else {
        background = Row(
          children: List.generate(cols, (j) => decorationBuilder(context, j)),
        );
        result = Row(
          children: List.generate(cols, (j) => cellBuilder(context, j)),
        );
        if (widget.horizontalPadding>0){
          background = Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: background,
          );
          result = Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: result,
          );
        }
      }
      if (!widget.rowGestureDetectorCoversRowAddon){
        result = _buildRowGestureDetector(
          context: context,
          row: row,
          child: result,
        );
      }
      if (!widget.applyRowBackgroundToRowAddon || rowActions.isNotEmpty) {
        result = Stack(
          key: row.rowKey ?? ValueKey(row.id),
          children: [
            Positioned.fill(child: background,),
            result,
          ],
        );
      }
      if (rowActions.isNotEmpty) {
        result = AppbarFromZero(
          title: result,
          actions: rowActions,
          useFlutterAppbar: false,
          toolbarHeight: widget.rowHeightForScrollingCalculation ?? row.height,
          addContextMenu: row!=headerRowModel,
          onShowContextMenu: () => row.focusNode.requestFocus(),
          skipTraversalForActions: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          paddingRight: 0,
          titleSpacing: 0,
        );
      }
      if (row==headerRowModel && widget.headerAddon!=null) {
        Widget addon = _getHeaderAddonWidget(context, constraints);
        result = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            addon,
            result,
          ],
        );
      }
      if (row.rowAddon!=null) {
        Widget addon = row.rowAddon!;
        if (widget.applyScrollToRowAddon && constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
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
        if (row!=headerRowModel && widget.applyStickyHeadersToRowAddon){
          result = StickyHeader(
            controller: widget.scrollController,
            header: result,
            content: addon,
            stickOffset: row is! RowModel<T> ? 0
                : filtered.indexOf(row)==0 ? 0
                : widget.stickyOffset + (widget.rowHeightForScrollingCalculation??row.height),
          );
        } else{
          result = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              result,
              addon,
            ],
          );
        }
      }
      if (widget.rowGestureDetectorCoversRowAddon){
        result = _buildRowGestureDetector(
          context: context,
          row: row,
          child: result,
        );
      }
      if (widget.applyRowBackgroundToRowAddon && rowActions.isEmpty) {
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
      if (constraints!=null) {
        if(widget.maxWidth!=null && constraints.maxWidth>widget.maxWidth!) {
          result = Center(child: SizedBox(width: widget.maxWidth!, child: result,),);
        }
      }
      result = FocusTraversalGroup(
        policy: NoEnsureVisibleWidgetTraversalPolicy(),
        child: Container(
          decoration: _getDecoration(row, -1),
          child: result,
        ),
      );
      return result;
    };

    Widget result;
    // bool intrinsicDimensions = context.findAncestorWidgetOfExactType<IntrinsicHeight>()!=null
    //     || context.findAncestorWidgetOfExactType<IntrinsicWidth>()!=null;
    // if (!intrinsicDimensions && (widget.minWidth!=null || widget.maxWidth!=null)){
    if (widget.minWidth!=null || widget.maxWidth!=null){
      result = LayoutBuilder(builder: builder,);
    } else {
      result = builder(context, null);
    }
    return result;
    // return FrameSeparateWidget( // TODO 2 experiment with frameSeparateWidget, just waiting for 100ms or less before buiding should be enough to counteract scroll jank
    //   placeHolder: Container(height: row.height, ),
    //   child: result,
    // );

  }
  Widget _buildRowGestureDetector({required BuildContext context, required RowModel row, required Widget child}) {
    Widget result = child;
    if (row.onRowTap!=null) {
      result = InkWell(
        onTap: widget.enabled ? () => row.onRowTap!(row)
            : row.onCheckBoxSelected!=null && row!=headerRowModel ? () {
          if (row.onCheckBoxSelected!(row, !(row.selected??false)) ?? false) {
            setState(() {});
          }
        } : null,
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

  Widget defaultHeaderCellBuilder(BuildContext context, RowModel<String> row, ColModel? col, int j) {
    // String message = row.values[j]!=null ? row.values[j].toString() : "";
    bool export = context.findAncestorWidgetOfExactType<Export>()!=null;
    while (filterGlobalKeys.length<=j) {
      filterGlobalKeys.add(GlobalKey());
    }
    Widget result = Align(
      alignment: _getAlignment(j)==TextAlign.center ? Alignment.center
          : _getAlignment(j)==TextAlign.left||_getAlignment(j)==TextAlign.start ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPadding(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: widget.itemPadding.left + (!export && sortedColumnIndex==j ? 15 : 4),
              right: widget.itemPadding.right + (!export && (widget.columns![j].filterEnabled??true) ? 10 : 4),
              top: widget.itemPadding.top,
              bottom: widget.itemPadding.bottom,
            ),
            child: AutoSizeText(
              widget.columns![j].name,
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: _getAlignment(j),
              maxLines: widget.autoSizeTextMaxLines,
              minFontSize: 14,
              overflowReplacement: TooltipFromZero(
                message: widget.columns![j].name,
                waitDuration: Duration(milliseconds: 0),
                verticalOffset: -16,
                child: AutoSizeText(
                  widget.columns![j].name,
                  style: Theme.of(context).textTheme.subtitle2,
                  textAlign: _getAlignment(j),
                  maxLines: widget.autoSizeTextMaxLines,
                  softWrap: widget.autoSizeTextMaxLines>1,
                  overflow: widget.autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
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
                child: (widget.enabled && !export && sortedColumnIndex==j) ? Icon(
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
          if (widget.enabled && !export && (widget.columns![j].filterEnabled??true))
            Positioned(
                right: -16, width: 48, top: 0, bottom: 0,
                child: OverflowBox(
                  maxHeight: row.height, maxWidth: 48,
                  alignment: Alignment.center,
                  child: IconButton(
                    key: filterGlobalKeys[j],
                    icon: Icon(filtersApplied[j] ? MaterialCommunityIcons.filter : MaterialCommunityIcons.filter_outline,
                      color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
                    ),
                    splashRadius: 20,
                    tooltip: FromZeroLocalizations.of(context).translate('filters'),
                    onPressed: () => showFilterDialog(j),
                  ),
                )
            ),
        ],
      ),
    );
    headerFocusNodes[j] ??= FocusNode();
    result = Material(
      type: MaterialType.transparency,
      child: EnsureVisibleWhenFocused(
        focusNode: headerFocusNodes[j]!,
        child: InkWell(
          focusNode: headerFocusNodes[j],
          onTap: widget.columns![j].onHeaderTap!=null
              || widget.columns![j].sortEnabled==true ? () {
            headerFocusNodes[j]!.requestFocus();
            if (widget.columns![j].sortEnabled==true){
              if (sortedColumnIndex==j) {
                setState(() {
                  sortedAscending = !sortedAscending;
                  sort();
                });
              } else {
                setState(() {
                  sortedColumnIndex = j;
                  sortedAscending = widget.columns![j].defaultSortAscending ?? true;
                  sort();
                });
              }
            }
            if (widget.columns![j].onHeaderTap!=null){
              widget.columns![j].onHeaderTap!(j);
            }
          } : null,
          child: result,
        ),
      ),
    );
    result = ContextMenuFromZero(
      child: result,
      onShowMenu: () => headerFocusNodes[j]!.requestFocus(),
      actions: [
        if (col?.sortEnabled ?? true)
          ActionFromZero(
            title: 'Ordenar Ascendente', // TODO 1 internationalize
            icon: Icon(MaterialCommunityIcons.sort_ascending),
            onTap: (context) {
              if (sortedColumnIndex!=j || !sortedAscending) {
                setState(() {
                  sortedColumnIndex = j;
                  sortedAscending = true;
                  sort();
                });
              }
            },
          ),
        if (col?.sortEnabled ?? true)
          ActionFromZero(
            title: 'Ordenar Descendente', // TODO 1 internationalize
            icon: Icon(MaterialCommunityIcons.sort_descending),
            onTap: (context) {
              if (sortedColumnIndex!=j || sortedAscending) {
                setState(() {
                  sortedColumnIndex = j;
                  sortedAscending = false;
                  sort();
                });
              }
            },
          ),
        if (col?.filterEnabled ?? true)
          ActionFromZero(
            title: 'Filtros...', // TODO 1 internationalize
            icon: Icon(MaterialCommunityIcons.filter),
            onTap: (context) => showFilterDialog(j),
          ),
      ],
    );
    return result;
  }

  void showFilterDialog(int j) async{
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
    if (widget.columns![j].textConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterTextExactly(),
        FilterTextContains(),
        FilterTextStartsWith(),
        FilterTextEndsWith(),
      ]);
    }
    if (widget.columns![j].numberConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterNumberEqualTo(),
        FilterNumberGreaterThan(),
        FilterNumberLessThan(),
      ]);
    }
    if (widget.columns![j].dateConditionFiltersEnabled ?? true) {
      possibleConditionFilters.addAll([
        // FilterDateExactDay(),
        FilterDateAfter(),
        FilterDateBefore(),
      ]);
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
                              PopupMenuButton<ConditionFilter>(
                                tooltip: FromZeroLocalizations.of(context).translate('add_condition_filter'),
                                offset: Offset(128, 32),
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
                                  WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                                    value.focusNode.requestFocus();
                                  });
                                },
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
                        layoutWidgetType: TableFromZero.sliverListViewBuilder,
                        columns: [
                          SimpleColModel(
                            name: '',
                            sortEnabled: false,
                          ),
                        ],
                        rows: availableFilters[j].map((e) {
                          return SimpleRowModel<T>(
                            id: e,
                            values: [e.toString()],
                            selected: valueFilters[j][e] ?? false,
                            onCheckBoxSelected: (row, selected) {
                              modified = true;
                              valueFilters[j][row.id] = selected!;
                              (row as SimpleRowModel<T>).selected = selected;
                              return true;
                            },
                          );
                        }).toList(),
                        errorWidget: SizedBox.shrink(),
                        headerRowBuilder: (context, row) {
                          return Container(
                            padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: TextFormField(
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
                                            filterTableController.filtered!.forEach((row) {
                                              valueFilters[j][row.id] = true;
                                              (row as SimpleRowModel<T>).selected = true;
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
                                            filterTableController.filtered!.forEach((row) {
                                              valueFilters[j][row.id] = false;
                                              (row as SimpleRowModel<T>).selected = false;
                                            });
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
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

  Widget defaultCellBuilder(BuildContext context, RowModel<T> row, ColModel? col, int j) {
    String message = row.values[j]!=null ? row.values[j].toString() : "";
    Widget result = AutoSizeText(
      message,
      style: _getStyle(context, row, j),
      textAlign: _getAlignment(j),
      maxLines: widget.autoSizeTextMaxLines,
      minFontSize: 14,
      overflowReplacement: TooltipFromZero(
        message: message,
        waitDuration: Duration(milliseconds: 0),
        verticalOffset: -16,
        child: AutoSizeText(
          message,
          style: _getStyle(context, row, j),
          textAlign: _getAlignment(j),
          maxLines: widget.autoSizeTextMaxLines,
          softWrap: widget.autoSizeTextMaxLines>1,
          overflow: widget.autoSizeTextMaxLines>1 ? TextOverflow.clip : TextOverflow.fade,
        ),
      ),
    );
    return result;
  }

  BoxDecoration? _getDecoration(RowModel row, int j,){
    bool header = row==headerRowModel;
    Color? backgroundColor = _getBackgroundColor(row, j, header);
    if (header){
      backgroundColor = backgroundColor ?? widget.headerRowColor ?? _getMaterialColor();
      if (widget.applyHalfOpacityToHeaderColor){
        backgroundColor = backgroundColor.withOpacity(backgroundColor.opacity*(0.5));
      }
    }
    if (backgroundColor!=null) {
      bool applyDarker = widget.applyRowAlternativeColors==true
          && _shouldApplyDarkerBackground(backgroundColor, row, j, header);
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
  Color? _getBackgroundColor(RowModel row, int j, bool header){
    Color? backgroundColor;
    if (header){
      backgroundColor = (j<0 ? null : widget.columns?.elementAtOrNull(j)?.backgroundColor);
    } else if (j<0) {
      backgroundColor = row.backgroundColor ?? Material.of(context)!.color;
    } else{
      if (widget.rowTakesPriorityOverColumn){
        backgroundColor = row.backgroundColor ?? (j<0 ? null : widget.columns?.elementAtOrNull(j)?.backgroundColor);
      } else{
        backgroundColor = (j<0 ? null : widget.columns?.elementAtOrNull(j)?.backgroundColor) ?? row.backgroundColor;
      }
    }
    return backgroundColor;
  }
  bool _shouldApplyDarkerBackground(Color? current, RowModel row, int j, bool header){
//    if (filtered[i]!=row) return false;
    int i = row is! RowModel<T> ? 0 : filtered.indexOf(row);
    if (i<=0) {
      return false;
    } else if (!widget.useSmartRowAlternativeColors || i > filtered.length) {
      return i.isOdd;
    } else {
      Color? previous = _getBackgroundColor(filtered[i-1], j, header);
      if (previous!=current) return false;
      return !_shouldApplyDarkerBackground(previous, filtered[i-1], j, header);
    }
  }

  TextAlign _getAlignment(int j){
    return widget.columns!=null && j<widget.columns!.length ? widget.columns![j].alignment??TextAlign.left : TextAlign.left;
  }

  TextStyle _getStyle(BuildContext context, RowModel<T> row, int j){
    TextStyle? style;
    if (widget.rowTakesPriorityOverColumn){
      style = row.textStyle;
      if (style==null)
        style = widget.columns!=null && j<widget.columns!.length ? widget.columns![j].textStyle : null;
    } else{
      style = widget.columns!=null && j<widget.columns!.length ? widget.columns![j].textStyle : null;
      if (style==null)
        style = row.textStyle;
    }
    return style ?? (widget.defaultTextStyle ?? Theme.of(context).textTheme.bodyText1!);
  }

  int _getFlex(j){
    return widget.columns?[j].flex ?? 1;
  }

  int get disabledColumnCount => widget.columns==null ? 0 : widget.columns!.where((element) => element.flex==0).length;
  void sort({bool notifyListeners=true}) {
    if (sortedColumnIndex!=null && sortedColumnIndex!>=0)
      mergeSort(sorted, compare: ((RowModel<T> a, RowModel<T> b){
        if (a.alwaysOnTop!=null || b.alwaysOnTop!=null) {
          if (a.alwaysOnTop==true || b.alwaysOnTop==false) return -1;
          if (a.alwaysOnTop==false || b.alwaysOnTop==true) return 1;
        }
        final aVal = a.values[sortedColumnIndex!];
        final bVal = b.values[sortedColumnIndex!];
        return sortedAscending
            ? aVal==null ? 1 : bVal==null ? -1 : aVal.compareTo(bVal)
            : aVal==null ? -1 : bVal==null ? 1 : bVal.compareTo(aVal);
      }));
    filter(notifyListeners: notifyListeners);
  }
  void filter({bool notifyListeners=true}){
    filtered = sorted.where((element) {
      bool pass = true;
      for (var i = 0; i<valueFilters.length && pass; ++i) {
        if (filtersApplied[i]) {
          pass = valueFilters[i][element.values[i]] ?? false;
        }
      }
      conditionFilters.forEach((i, filters) {
        for (var j = 0; j < filters.length && pass; ++j) {
          pass = filters[j].isAllowed(element.values[i], element.values, i);
        }
      });
      return pass;
    }).toList();
    if (widget.onFilter!=null) {
      filtered = widget.onFilter!(filtered);
    }
    if (notifyListeners) {
      widget.tableController?.notifyListeners();
    }
  }
  void _updateFiltersApplied(){
    filtersApplied = List.generate(widget.columns?.length ?? 0, (index) {
      if ((conditionFilters[index] ?? []).isNotEmpty) {
        return true;
      }
      bool? previous;
      for (var i = 0; i < availableFilters[index].length; ++i) {
        final availableFilter = availableFilters[index][i];
        final value = valueFilters[index][availableFilter] ?? false;
        if (i==0) {
          previous = value;
        } else if (previous!=value){
          return true;
        }
      }
      return false;
    });
  }

}


class TableController<T> extends ChangeNotifier {

  Map<int, List<ConditionFilter>>? initialConditionFilters;
  Map<int, List<ConditionFilter>>? conditionFilters;
  Map<int, Map<Object, bool>>? initialValueFilters;
  bool initialValueFiltersExcludeAllElse;
  List<Map<Object, bool>>? valueFilters;
  Map<int, bool> columnVisibilities;
  bool sortedAscending;
  int? sortedColumnIndex;

  TableController({
    this.initialConditionFilters,
    this.initialValueFilters,
    this.sortedAscending = true,
    this.sortedColumnIndex,
    this.initialValueFiltersExcludeAllElse = false,
    Map<int, bool>? columnVisibilities,
  })  : this.columnVisibilities = columnVisibilities ?? {};

  TableController copyWith({
    Map<int, List<ConditionFilter>>? initialConditionFilters,
    Map<int, List<ConditionFilter>>? conditionFilters,
    Map<int, Map<Object, bool>>? initialValueFilters,
    bool? initialValueFiltersExcludeAllElse,
    List<Map<Object, bool>>? valueFilters,
    Map<int, bool>? columnVisibilities,
    bool? sortedAscending,
    int? sortedColumnIndex,
  }) {
    return TableController()
      ..initialConditionFilters = initialConditionFilters ?? this.initialConditionFilters
      ..conditionFilters = conditionFilters ?? this.conditionFilters
      ..initialValueFilters = initialValueFilters ?? this.initialValueFilters
      ..initialValueFiltersExcludeAllElse = initialValueFiltersExcludeAllElse ?? this.initialValueFiltersExcludeAllElse
      ..valueFilters = valueFilters ?? this.valueFilters
      ..columnVisibilities = columnVisibilities ?? this.columnVisibilities
      ..sortedAscending = sortedAscending ?? this.sortedAscending
      ..sortedColumnIndex = sortedColumnIndex ?? this.sortedColumnIndex
      .._filter = this._filter;
  }

  VoidCallback? _filter;
  void filter(){
    _filter?.call();
  }

  VoidCallback? _init;
  /// Call this if the rows change, to re-initialize rows
  void init(){
    _init?.call();
  }

  List<RowModel<T>> Function()? _getFiltered;
  List<RowModel<T>>? get filtered => _getFiltered?.call();

}



class RowAction<T> extends ActionFromZero {

  final Function(BuildContext context, RowModel<T> row)? onRowTap;

  RowAction({
    required this.onRowTap,
    required String title,
    Widget? icon,
    bool enabled = true,
    Map<double, ActionState>? breakpoints,
    OverflowActionBuilder overflowBuilder = ActionFromZero.defaultOverflowBuilder,
    ActionBuilder iconBuilder = ActionFromZero.defaultIconBuilder,
    ActionBuilder buttonBuilder = ActionFromZero.defaultButtonBuilder,
  }) : super(
    onTap: (context) {},
    title: title,
    icon: icon,
    enabled: enabled,
    breakpoints: breakpoints ?? {
      0: ActionState.icon,
    },
    overflowBuilder: overflowBuilder,
    iconBuilder: iconBuilder,
    buttonBuilder: buttonBuilder,
  );

  RowAction.divider({
    Map<double, ActionState>? breakpoints,
    OverflowActionBuilder overflowBuilder = ActionFromZero.dividerOverflowBuilder,
    ActionBuilder iconBuilder = ActionFromZero.dividerIconBuilder,
    ActionBuilder buttonBuilder = ActionFromZero.dividerIconBuilder,
  })  : this.onRowTap = null,
        super(
          onTap: null,
          title: '',
          overflowBuilder: overflowBuilder,
          iconBuilder: iconBuilder,
          buttonBuilder: buttonBuilder,
          breakpoints: breakpoints ?? {
            0: ActionState.popup,
          },
        );


}
