import 'dart:io';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/table_from_zero_filters.dart';
import 'package:from_zero_ui/src/table_from_zero_models.dart';
import 'package:from_zero_ui/util/my_sticky_header.dart';
import 'package:from_zero_ui/util/small_splash_popup_menu_button.dart' as small_popup;
import 'dart:async';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

typedef OnRowHoverCallback = void Function(RowModel row, bool focused);
typedef OnCheckBoxSelectedCallback = bool? Function(RowModel row, bool? focused);
typedef OnHeaderHoverCallback = void Function(int i, bool focused);
typedef OnCellTapCallback = ValueChanged<RowModel>? Function(int index,);
typedef OnCellHoverCallback = OnRowHoverCallback? Function(int index,);


class TableFromZero extends StatefulWidget {

  static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;
  static const int animatedColumn = 3;
  static const int animatedListViewBuilder = 4;
  static const int sliverAnimatedListViewBuilder = 5;

  static const double _checkmarkWidth = 48;

  final List<RowModel> rows;
  final List<ColModel>? columns;
  final bool rowTakesPriorityOverColumn;
  final int layoutWidgetType;
  final EdgeInsets itemPadding;
  final bool showHeaders;
  /// Only used if layoutWidgetType==listViewBuilder
  final ScrollController? scrollController;
  /// Only used if layoutWidgetType==listViewBuilder
  final double verticalPadding;
  final double horizontalPadding;
  final bool? Function(bool? value, List<RowModel> filtered)? onAllSelected;
  final int? initialSortedColumnIndex;
  final bool showFirstHorizontalDivider;
  @deprecated final Widget? horizontalDivider;
  @deprecated final Widget? verticalDivider;
  final int autoSizeTextMaxLines;
  final double? headerHeight;
  final Widget Function(BuildContext context, RowModel row, ColModel? col, int j)? cellBuilder;
  final Widget Function(BuildContext context, RowModel row)? rowBuilder;
  final Widget Function(BuildContext context, RowModel row)? headerRowBuilder;
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
  final ScrollController? mainScrollController;
  final double stickyOffset;
  final bool forceColumnToLayoutAllChildren;
  final List<RowModel> Function(List<RowModel>)? onFilter;
  final TableController? tableController;
  final Alignment? alignmentWhenOverMaxWidth;
  final FutureOr<String>? exportPath;
  final bool applyScrollToRowAddon;
  final bool rowGestureDetectorCoversRowAddon;
  final bool applyStickyHeadersToRowAddon;
  final bool applyRowBackgroundToRowAddon;
  final Widget? errorWidget;
  final double? rowHeightForScrollingCalculation;

  TableFromZero({
    required List<RowModel> rows,
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
    this.mainScrollController,
    this.stickyOffset = 0,
    this.onFilter,
    this.forceColumnToLayoutAllChildren = false,
    this.tableController,
    this.alignmentWhenOverMaxWidth,
    this.exportPath,
    this.applyScrollToRowAddon = true,
    this.rowGestureDetectorCoversRowAddon = true,
    this.errorWidget,
    this.rowHeightForScrollingCalculation,
    this.useSmartRowAlternativeColors = true,
    bool? applyStickyHeadersToRowAddon,
    bool? applyRowBackgroundToRowAddon,
    Key? key,
  }) :  this.rows = List.from(rows),
        this.applyStickyHeadersToRowAddon = applyStickyHeadersToRowAddon??applyStickyHeaders,
        this.applyRowBackgroundToRowAddon = applyRowBackgroundToRowAddon??applyScrollToRowAddon,
        super(key: key,);

  @override
  TableFromZeroState createState() => TableFromZeroState();

}



class TrackingScrollControllerFixedPosition extends TrackingScrollController {

  ScrollPosition get position {
    assert(positions.isNotEmpty, 'ScrollController not attached to any scroll views.');
    return positions.first;
  }

}

class TableFromZeroState extends State<TableFromZero> {

  late List<RowModel> sorted;
  late List<RowModel> filtered;



  late List<List<ConditionFilter>> _conditionFilters;
  List<List<ConditionFilter>> get conditionFilters => widget.tableController?.conditionFilters ?? _conditionFilters;
  set conditionFilters(List<List<ConditionFilter>> value) {
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
  RowModel? headerRowModel;

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
    init();
  }

  @override
  void didUpdateWidget(TableFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    init();
  }

  void init() {
    sorted = List.from(widget.rows);
    if (widget.initialSortedColumnIndex!=null && widget.initialSortedColumnIndex!>=0 && widget.tableController?.sortedColumnIndex==null) sortedAscending = widget.columns![widget.initialSortedColumnIndex!].defaultSortAscending ?? true;
    if (sortedColumnIndex==null) sortedColumnIndex = widget.initialSortedColumnIndex;
    if (widget.showHeaders && widget.columns!=null){
      int actionsIndex = widget.rows.indexWhere((element) => element.actions!=null);
      headerRowModel = SimpleRowModel(
        id: "header_row",
        values: List.generate(widget.columns!.length, (index) => widget.columns![index].name),
        onCheckBoxSelected:  widget.onAllSelected!=null||widget.rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null,
        actions: actionsIndex!=-1 ? List.generate(widget.rows[actionsIndex].actions!.length, (index) => SizedBox.shrink()) : null,
        selected: true,
        height: widget.headerHeight ?? 38,
        onCellTap: (j) {
          return widget.columns![j].onHeaderTap!=null
              ||widget.columns![j].sortEnabled==true ? (row,) {
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
          } : null;
        },
      );
      availableFilters = [];
      for (int i=0; i<widget.columns!.length; i++){
        List<dynamic> available = [];
        if (widget.columns![i].filterEnabled==true){
          widget.rows.forEach((element) {
            if (!available.contains(element.values[i]))
              available.add(element.values[i]);
          });
        }
        availableFilters.add(available);
      }
    }
    if (widget.tableController!=null){
      widget.tableController!._filter = (){
        if (mounted){
          setState(() {
            filter();
          });
        }
      };
      widget.tableController!._getFiltered = ()=>filtered;
    }
    if (widget.tableController?.conditionFilters==null) {
      if (widget.tableController?.initialConditionFilters==null){
        conditionFilters = List.generate(widget.columns?.length ?? 0, (index) => []);
      } else{
        conditionFilters = List.generate(widget.columns?.length ?? 0, (index) => widget.tableController!.initialConditionFilters![index] ?? []);
      }
    }
    if (widget.tableController?.valueFilters==null) {
      if (widget.tableController?.initialValueFilters==null){
        valueFilters = List.generate(widget.columns?.length ?? 0, (index) => {});
      } else{
        valueFilters = List.generate(widget.columns?.length ?? 0, (index) => widget.tableController!.initialValueFilters![index] ?? {});
      }
    }
    _updateFiltersApplied();
    sort();
  }

  @override
  Widget build(BuildContext context) {
    int childCount = filtered.length;
    Widget result;

    // Hack to be able to apply widget.stickyOffset
    if (widget.stickyOffset!=0 && (widget.layoutWidgetType==TableFromZero.listViewBuilder
        || widget.layoutWidgetType==TableFromZero.column
        || widget.layoutWidgetType==TableFromZero.animatedColumn
        || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder)){

      if (widget.layoutWidgetType==TableFromZero.listViewBuilder
          || widget.layoutWidgetType==TableFromZero.column){
        if (widget.layoutWidgetType==TableFromZero.column && (widget.forceColumnToLayoutAllChildren)){
          result = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(childCount, (i) => _getRow(context, filtered[i])),
          );
        } else {
          result = ListView.builder(
            itemBuilder: (context, i) => _getRow(context, filtered[i]),
            itemCount: childCount,
            shrinkWrap: widget.layoutWidgetType == TableFromZero.column,
            controller: widget.scrollController,
            itemExtent: widget.rowHeightForScrollingCalculation ?? (filtered.isEmpty ? null : filtered.first.height),
          );
        }
      } else if (widget.layoutWidgetType==TableFromZero.animatedColumn
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = ImplicitlyAnimatedList<RowModel>(
          items: filtered,
          areItemsTheSame: (a, b) => a==b,
          shrinkWrap: widget.layoutWidgetType==TableFromZero.animatedColumn,
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
      if (widget.applyStickyHeaders && widget.showHeaders && widget.columns!=null && headerRowModel!=null){
        final header = _getRow(context, headerRowModel!,);
        result = StickyHeaderBuilder(
          content: result,
          controller: widget.mainScrollController,
          stickOffset: widget.stickyOffset,
          builder: (context, state) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                header,
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
          || widget.layoutWidgetType==TableFromZero.column
          || widget.layoutWidgetType==TableFromZero.sliverListViewBuilder){
        result = SliverFixedExtentList(
          itemExtent: widget.rowHeightForScrollingCalculation ?? (filtered.isEmpty ? 0 : filtered.first.height),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int i) => _getRow(context, filtered[i]),
            childCount: childCount,
          ),
        );
      } else if (widget.layoutWidgetType==TableFromZero.sliverAnimatedListViewBuilder
          || widget.layoutWidgetType==TableFromZero.animatedColumn
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = SliverImplicitlyAnimatedList<RowModel>(
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
      if (widget.showHeaders && widget.columns!=null && headerRowModel!=null){
        final header = _getRow(context, headerRowModel!);
        result = SliverStickyHeader.builder(
          sliver: result,
          sticky: widget.applyStickyHeaders,
          builder: (context, state) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                header,
                if (state.isPinned)
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
      // bool showingHeaders = widget.showHeaders && widget.columns!=null && headerRowModel!=null;
      // result = SliverStickyHeader(
      //   header: ScrollbarFromZero(
      //     controller: sharedController,
      //     child: Align(
      //       alignment: ,
      //       child: showingHeaders ? _getRow(context, -1, headerRowModel!)
      //           : SingleChildScrollView(
      //             controller: sharedController,
      //             scrollDirection: Axis.horizontal,
      //             child: Container(),
      //           ),
      //     ),
      //   ),
      //   sliver: SliverPadding(
      //     padding: EdgeInsets.only(top: (showingHeaders?headerRowModel!.height:0), bottom: 12,),
      //     sliver: result,
      //   ),
      //   overlapsContent: true,
      //   sticky: widget.applyStickyHeaders,
      // );
      result = SliverPadding(
        padding: EdgeInsets.only(top: widget.verticalPadding, bottom: widget.verticalPadding,),
        sliver: result,
      );
      if (widget.layoutWidgetType==TableFromZero.listViewBuilder
          || widget.layoutWidgetType==TableFromZero.column
          || widget.layoutWidgetType==TableFromZero.animatedColumn
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = CustomScrollView(
          controller: widget.scrollController,
          shrinkWrap: widget.layoutWidgetType==TableFromZero.column||widget.layoutWidgetType==TableFromZero.animatedColumn,
          slivers: [result],
        );
      }

    }
    return result;
  }


  Widget _getRow(BuildContext context, RowModel row){
    if (row==headerRowModel){
      return (widget.headerRowBuilder??_defaultGetRow).call(context, row);
    } else{
      return (widget.rowBuilder??_defaultGetRow).call(context, row);
    }
  }
  Widget _defaultGetRow(BuildContext context, RowModel row){

    if (row is ErrorRow){
      return AnimatedEntryWidget(
        child: Center(
          child: Container(
            color: Material.of(context)?.color,
            width: widget.maxWidth,
            padding: EdgeInsets.symmetric(vertical: 16),
            child: widget.errorWidget ?? ErrorSign(
              icon: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 64, color: Theme.of(context).disabledColor,),
              title: "No hay datos que mostrar...",
              subtitle: filtersApplied.where((e) => e).isNotEmpty ? "Intente desactivar algunos filtros." : "No existen datos correspondientes a esta consulta.",
            ),
          ),
        ),
        transitionBuilder: (child, animation) => SizeFadeTransition(animation: animation, child: child, sizeFraction: 0.7, curve: Curves.easeOutCubic,),
      );
    }

    int maxFlex = 0;
    for (var j = 0; j < row.values.length; ++j) {
      maxFlex += _getFlex(j);
    }
    int cols = ((row.values.length-disabledColumnCount) + (row.onCheckBoxSelected==null ? 0 : 1)) * (widget.verticalDivider==null ? 1 : 2) + (widget.verticalDivider==null ? 0 : 1) + (row.actions==null ? 0 : 1);

    final builder = (BuildContext context, BoxConstraints? constraints) {
      final decorationBuilder = (BuildContext context, int j) {
        Widget? result;
        bool addSizing = true;
        if (row.actions!=null && j==cols-1){
          addSizing = false;
          result = SizedBox(width: TableFromZero._checkmarkWidth*row.actions!.length, height: double.infinity,);
        }
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
        if (row.actions!=null && j==cols-1){
          return SizedBox(
            width: TableFromZero._checkmarkWidth*row.actions!.length,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.actions!,
            ),
          );
        }
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
          height: row.height,
          alignment: Alignment.center,
          padding: row==headerRowModel ? null : widget.itemPadding,
          child: Container(
              width: double.infinity,
              child: (row==headerRowModel ? defaultHeaderCellBuilder : widget.cellBuilder??defaultCellBuilder)
                  .call(context, row, widget.columns==null?null:widget.columns![j], j)
          ),
        );
        if (row.onCellTap!=null || row.onCellDoubleTap!=null || row.onCellLongPress!=null || row.onCellHover!=null){
          result = InkWell(
            onTap: row.onCellTap!=null&&row.onCellTap!(j)!=null ? () => row.onCellTap!(j)!.call(row) : null,
            onDoubleTap: row.onCellDoubleTap!=null&&row.onCellDoubleTap!(j)!=null ? () => row.onCellDoubleTap!(j)!.call(row) : null,
            onLongPress: row.onCellLongPress!=null&&row.onCellLongPress!(j)!=null ? () => row.onCellLongPress!(j)!.call(row) : null,
            onHover: row.onCellHover!=null&&row.onCellHover!(j)!=null ? (value) => row.onCellHover!(j)!.call(row, value) : null,
            child: result,
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
        background = SizedBox(
          height: row.height + widget.itemPadding.vertical,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => row!=headerRowModel,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: sharedController,
              itemBuilder: decorationBuilder,
              itemCount: cols,
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            ),
          ),
        );
        result = SizedBox(
          height: row.height + widget.itemPadding.vertical,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => row!=headerRowModel,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: sharedController,
              itemBuilder: cellBuilder,
              itemCount: cols,
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            ),
          ),
        );
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
      if (!widget.applyRowBackgroundToRowAddon) {
        result = Stack(
          key: row.rowKey ?? ValueKey(row.id),
          children: [
            Positioned.fill(child: background,),
            result,
          ],
        );
      }
      if (row==headerRowModel && widget.headerAddon!=null) {
        Widget addon = widget.headerAddon!;
        if (widget.applyMinWidthToHeaderAddon && constraints!=null && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!) {
          addon = NotificationListener<ScrollNotification>(
            onNotification: (notification) => row!=headerRowModel,
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
          addon = NotificationListener<ScrollNotification>(
            onNotification: (notification) => row!=headerRowModel,
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
        if (widget.applyStickyHeadersToRowAddon){
          result = StickyHeader(
            controller: widget.mainScrollController,
            header: result,
            content: addon,
            stickOffset: filtered.indexOf(row)==0 ? 0 : widget.stickyOffset+headerRowModel!.height,
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
      if (widget.applyRowBackgroundToRowAddon) {
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
        if (row!=headerRowModel && widget.minWidth!=null && constraints.maxWidth<widget.minWidth!){
          result = ScrollOpacityGradient(
            scrollController: sharedController,
            direction: OpacityGradient.horizontal,
            child: result,
          );
        } else if(widget.maxWidth!=null && constraints.maxWidth>widget.maxWidth!) {
          result = Center(child: SizedBox(width: widget.maxWidth!, child: result,),);
        }
      }
      return result;
    };

    if (widget.minWidth!=null || widget.maxWidth!=null){
      return LayoutBuilder(builder: builder,);
    } else {
      return builder(context, null);
    }

  }
  _buildRowGestureDetector({required BuildContext context, required RowModel row, required Widget child}) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: row.onRowTap!=null ? () => row.onRowTap!(row)
            : row.onCheckBoxSelected!=null && row!=headerRowModel ? () {
                if (row.onCheckBoxSelected!(row, !(row.selected??false)) ?? false) {
                  setState(() {});
                }
              } : null,
        onDoubleTap: row.onRowDoubleTap!=null ? () => row.onRowDoubleTap!(row) : null,
        onLongPress: row.onRowLongPress!=null ? () => row.onRowLongPress!(row) : null,
        onHover: row.onRowHover!=null ? (value) => row.onRowHover!(row, value) : null,
        child: child,
      ),
    );
  }

  Widget defaultHeaderCellBuilder(BuildContext context, RowModel row, ColModel? col, int j) {
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
              right: widget.itemPadding.right + (!export && widget.columns![j].filterEnabled==true ? 10 : 4),
              top: widget.itemPadding.top,
              bottom: widget.itemPadding.bottom,
            ),
            child: AutoSizeText(
              widget.columns![j].name,
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: _getAlignment(j),
              maxLines: widget.autoSizeTextMaxLines,
              minFontSize: 14,
              overflowReplacement: Tooltip(
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
                child: (!export && sortedColumnIndex==j) ? Icon(
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
          if (!export && widget.columns![j].filterEnabled==true)
            Positioned(
                right: -16, width: 48, top: 0, bottom: 0,
                child: OverflowBox(
                  maxHeight: row.height, maxWidth: 48,
                  alignment: Alignment.center,
                  child: Material(
                    type: MaterialType.transparency,
                    child: IconButton(
                      key: filterGlobalKeys[j],
                      icon: Icon(filtersApplied[j] ? MaterialCommunityIcons.filter : MaterialCommunityIcons.filter_outline,
                        color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
                      ),
                      splashRadius: 20,
                      tooltip: "Filtros",
                      onPressed: () async {
                        ScrollController filtersScrollController = ScrollController();
                        TableController filterTableController = TableController();
                        bool modified = false;
                        List<ConditionFilter> possibleConditionFilters = [];
                        // if (widget.columns![j].neutralConditionFiltersEnabled ?? true) {
                        //   possibleConditionFilters.addAll([
                        //     FilterIsEmpty(),
                        //   ]);
                        // }
                        // TODO, when selecting available filters, automatically enable only possible filters (if null in the column)
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
                        await showDialog<bool>(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.2),
                          builder: (context) {
                            final animation = CurvedAnimation(
                              parent: ModalRoute.of(context)!.animation!,
                              curve: Curves.easeInOutCubic,
                            );
                            Offset? referencePosition;
                            Size? referenceSize;
                            try {
                              RenderBox box = filterGlobalKeys[j].currentContext!.findRenderObject()! as RenderBox;
                              referencePosition = box.localToGlobal(Offset.zero); //this is global position
                              referenceSize = box.size;
                            } catch(_) {}
                            return CustomSingleChildLayout(
                              delegate: DropdownChildLayoutDelegate(
                                referencePosition: referencePosition,
                                referenceSize: referenceSize,
                                align: DropdownChildLayoutDelegateAlign.topLeft,
                              ),
                              child: AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: 312, //referenceSize==null ? widget.popupWidth : (referenceSize.width+8).clamp(312, double.infinity),
                                    child: ClipRect(
                                      clipper: RectPercentageClipper(
                                        widthPercent: (animation.value*2.0).clamp(0.0, 1),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axis: Axis.vertical,
                                  axisAlignment: 0,
                                  child: Card(
                                    clipBehavior: Clip.hardEdge,
                                    child: ScrollbarFromZero(
                                      controller: filtersScrollController,
                                      child: StatefulBuilder(
                                        builder: (context, filterPopupSetState) {
                                          return CustomScrollView(
                                            controller: filtersScrollController,
                                            shrinkWrap: true,
                                            slivers: [
                                              SliverToBoxAdapter(child: Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Center(
                                                  child: Text('Filtros',
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
                                                        child: Text('Filtros de Condición',
                                                          style: Theme.of(context).textTheme.subtitle1,
                                                        ),
                                                      ),
                                                      PopupMenuButton<ConditionFilter>(
                                                        tooltip: 'Añadir Filtro de Condición',
                                                        offset: Offset(128, 32),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4,),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.add, color: Colors.blue,),
                                                              SizedBox(width: 6,),
                                                              Text('Añadir',
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
                                                            conditionFilters[j].add(value);
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),),
                                              if (conditionFilters[j].isEmpty)
                                                SliverToBoxAdapter(child: Padding(
                                                  padding: EdgeInsets.only(left: 24, bottom: 8,),
                                                  child: Text ('-ninguno-', style: Theme.of(context).textTheme.caption,),
                                                ),),
                                              SliverList(
                                                delegate: SliverChildListDelegate.fixed(
                                                  conditionFilters[j].map((e) {
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
                                                            conditionFilters[j].remove(e);
                                                          });
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              SliverToBoxAdapter(child: SizedBox(height: conditionFilters[j].isEmpty ? 6 : 12,)),
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
                                                  return SimpleRowModel(
                                                    id: e,
                                                    values: [e.toString()],
                                                    selected: valueFilters[j][e] ?? true,
                                                    onCheckBoxSelected: (row, focused) {
                                                      modified = true;
                                                      valueFilters[j][row.id] = focused!;
                                                      (row as SimpleRowModel).selected = focused;
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
                                                              filterTableController.conditionFilters![0].clear();
                                                              filterTableController.conditionFilters![0].add(
                                                                FilterTextContains(query: v,),
                                                              );
                                                              filterPopupSetState((){
                                                                filterTableController.filter();
                                                              });
                                                            },
                                                            decoration: InputDecoration(
                                                              labelText: 'Buscar',
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
                                                                child: Text('Seleccionar Todos'),
                                                                onPressed: () {
                                                                  modified = true;
                                                                  filterPopupSetState(() {
                                                                    filterTableController.filtered.forEach((row) {
                                                                      valueFilters[j][row.id] = true;
                                                                      (row as SimpleRowModel).selected = true;
                                                                    });
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: TextButton(
                                                                child: Text('Limpiar Selección'),
                                                                onPressed: () {
                                                                  modified = true;
                                                                  filterPopupSetState(() {
                                                                    filterTableController.filtered.forEach((row) {
                                                                      valueFilters[j][row.id] = false;
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
                                                  );
                                                },
                                              ),
                                              SliverToBoxAdapter(child: SizedBox(height: 16,),),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                        if (modified && mounted) {
                          setState(() {
                            filter();
                            _updateFiltersApplied();
                          });
                        }
                        // if (accepted!=true) {
                        //   widget.onCanceled?.call();
                        // }
                      },
                    ),
                  ),
                )
            ),
        ],
      ),
    );
    return result;
  }

  Widget defaultCellBuilder(BuildContext context, RowModel row, ColModel? col, int j) {
    String message = row.values[j]!=null ? row.values[j].toString() : "";
    Widget result = AutoSizeText(
      message,
      style: _getStyle(context, row, j),
      textAlign: _getAlignment(j),
      maxLines: widget.autoSizeTextMaxLines,
      minFontSize: 14,
      overflowReplacement: Tooltip(
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

  BoxDecoration _getDecoration(RowModel row, int j,){
    bool header = row==headerRowModel;
    Color? backgroundColor = _getBackgroundColor(row, j, header);
    bool applyDarker = widget.applyRowAlternativeColors==true
        && _shouldApplyDarkerBackground(backgroundColor, row, j, header);
    if (header){
      backgroundColor = backgroundColor ?? widget.headerRowColor;
    }
    if (backgroundColor==null){
      backgroundColor = Material.of(context)!.color;
    }
    if (backgroundColor!=null) {
      if (widget.applyHalfOpacityToHeaderColor && header){
        backgroundColor = backgroundColor.withOpacity(backgroundColor.opacity*(0.5));
      }
      if (backgroundColor.opacity<1 && Material.of(context)!.color!=null){
        backgroundColor = Color.alphaBlend(backgroundColor, Material.of(context)!.color!);
      }
      if(applyDarker){
        backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.965), Colors.black);
      }
    }
    return BoxDecoration(color: backgroundColor);
//    List<double> stops = [0, 0.1, 0.55, 1,];
//    if (_getAlignment(j)==TextAlign.right)
//      stops = [0, 0.45, 0.9, 1,];
//    return backgroundColor!=null ? BoxDecoration(
//        gradient: LinearGradient(
//            colors: [
//              backgroundColor.withOpacity(0),
//              backgroundColor.withOpacity(backgroundColor.opacity*(header ? 0.5 : 1)),
//              backgroundColor.withOpacity(backgroundColor.opacity*(header ? 0.5 : 1)),
//              backgroundColor.withOpacity(0),
//            ],
//            stops: stops,
//        )
//    ) : null;
//    if (backgroundColor==null){
//      return null;
//    } else{
//
//    }
  }
  Color? _getBackgroundColor(RowModel row, int j, bool header){
    Color? backgroundColor;
    if (header){
      backgroundColor = widget.columns!=null && j<widget.columns!.length ? widget.columns![j].backgroundColor : null;
    } else{
      if (widget.rowTakesPriorityOverColumn){
        backgroundColor = row.backgroundColor;
        if (backgroundColor==null)
          backgroundColor = widget.columns!=null && j<widget.columns!.length ? widget.columns![j].backgroundColor : null;
      } else{
        backgroundColor = widget.columns!=null && j<widget.columns!.length ? widget.columns![j].backgroundColor : null;
        if (backgroundColor==null)
          backgroundColor = row.backgroundColor;
      }
    }
    return backgroundColor;
  }
  bool _shouldApplyDarkerBackground(Color? current, RowModel row, int j, bool header){
//    if (filtered[i]!=row) return false;
    int i = filtered.indexOf(row);
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

  TextStyle _getStyle(BuildContext context, RowModel row, int j){
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
    if (widget.columns!=null && widget.columns![j].flex!=null)
      return widget.columns![j].flex ?? 1;
    return 1;
  }

  late int disabledColumnCount;
  void sort() {
    disabledColumnCount = widget.columns==null ? 0
        : widget.columns!.where((element) => element.flex==0).length;
    if (sortedColumnIndex!=null && sortedColumnIndex!>=0)
      mergeSort(sorted, compare: ((RowModel a, RowModel b){
        if (a.alwaysOnTop!=null || b.alwaysOnTop!=null){
          if (a.alwaysOnTop==true || b.alwaysOnTop==false) return -1;
          if (a.alwaysOnTop==false || b.alwaysOnTop==true) return 1;
        }
        return sortedAscending
            ? a.values[sortedColumnIndex!]!.compareTo(b.values[sortedColumnIndex!])
            : b.values[sortedColumnIndex!]!.compareTo(a.values[sortedColumnIndex!]);
      }));
    filter();
  }
  void filter(){
    filtered = sorted.where((element) {
      bool pass = true;
      for (var i = 0; i<valueFilters.length && pass; ++i) {
        pass = valueFilters[i][element.values[i]] ?? true;
      }
      for (int i=0; i<conditionFilters.length && pass; i++){
        for (var j = 0; j < conditionFilters[i].length && pass; ++j) {
          pass = conditionFilters[i][j].isAllowed(element.values[i]);
        }
      }
      return pass;
    }).toList();
    if (widget.onFilter!=null) filtered = widget.onFilter!(filtered);
    if (filtered.isEmpty) filtered.add(ErrorRow());
//    if (widget.headerRowModel!=null) filtered.insert(0, widget.headerRowModel);
  }
  void _updateFiltersApplied(){
    filtersApplied = List.generate(widget.columns?.length ?? 0,
            (index) => conditionFilters[index].isNotEmpty
                      || valueFilters[index].values.where((e) => e==false).isNotEmpty);
  }

}


class TableController {

  TableController({
    this.initialConditionFilters,
    this.initialValueFilters,
    this.sortedAscending = true,
    this.sortedColumnIndex,
  });

  VoidCallback? _filter;
  void filter(){
    _filter?.call();
  }

  Map<int, List<ConditionFilter>>? initialConditionFilters;
  List<List<ConditionFilter>>? conditionFilters;

  Map<int, Map<Object, bool>>? initialValueFilters;
  List<Map<Object, bool>>? valueFilters;

  bool sortedAscending;

  int? sortedColumnIndex;

  List<RowModel> Function()? _getFiltered;
  List<RowModel> get filtered => _getFiltered!();

}
