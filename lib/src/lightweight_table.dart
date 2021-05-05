import 'dart:io';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/my_sticky_header.dart';
import 'package:from_zero_ui/util/small_splash_popup_menu_button.dart' as small_popup;
import 'dart:async';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

typedef OnRowHoverCallback = void Function(RowModel row, bool focused);
typedef OnCheckBoxSelectedCallback = bool? Function(RowModel row, bool? focused);
typedef OnHeaderHoverCallback = void Function(int i, bool focused);
typedef OnCellTapCallback = ValueChanged<RowModel>? Function(int index,);
typedef OnCellHoverCallback = OnRowHoverCallback? Function(int index,);


class TableFromZero extends StatefulWidget {

  @deprecated static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;
  @deprecated static const int animatedColumn = 3;
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

  late List<dynamic> _filters;
  List<dynamic> get filters => widget.tableController?.filters ?? _filters;
  set filters(List<dynamic> value) {
    if (widget.tableController==null) {
      _filters = value;
    } else {
      widget.tableController!.filters = value;
    }
  }

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

  late ScrollController _scrollController;
  late TrackingScrollControllerFixedPosition sharedController;
  List<List<dynamic>> availableFilters = [];
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
    }
    if (widget.tableController?.filters==null) {
      if (widget.tableController?.initialFilters==null){
        filters = List.generate(widget.columns?.length ?? 0, (index) => EmptyFilter());
      } else{
        filters = List.generate(widget.columns?.length ?? 0, (index) => widget.tableController!.initialFilters![index] ?? EmptyFilter());
      }
    }
    _scrollController = widget.scrollController ?? ScrollController();
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
            controller: _scrollController,
          );
        }
      } else if (widget.layoutWidgetType==TableFromZero.animatedColumn
          || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
        result = ImplicitlyAnimatedList<RowModel>(
          items: filtered,
          areItemsTheSame: (a, b) => a==b,
          shrinkWrap: widget.layoutWidgetType==TableFromZero.animatedColumn,
          controller: _scrollController,
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
        result = SliverList(
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
          controller: _scrollController,
          shrinkWrap: widget.layoutWidgetType==TableFromZero.column||widget.layoutWidgetType==TableFromZero.animatedColumn,
          slivers: [result],
        );
      }

    }
    return result;
  }


  Widget _getRow(BuildContext context, RowModel row){
    if (row==headerRowModel || widget.rowBuilder==null){
      return _defaultGetRow(context, row);
    } else{
      return widget.rowBuilder!(context, row);
    }
  }
  Widget _defaultGetRow(BuildContext context, RowModel row){

    if (row is _ErrorRow){
      return AnimatedEntryWidget(
        child: widget.errorWidget ?? Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: ErrorSign(
            icon: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 64, color: Theme.of(context).disabledColor,),
            title: "No hay datos que mostrar...",
            subtitle: filters.any((element) => element!=EmptyFilter()) ? "Intente desactivar algunos filtros." : "No existen datos correspondientes a esta consulta.",
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
        onTap: row.onRowTap!=null ? () => row.onRowTap!(row) : null,
        onDoubleTap: row.onRowDoubleTap!=null ? () => row.onRowDoubleTap!(row) : null,
        onLongPress: row.onRowLongPress!=null ? () => row.onRowLongPress!(row) : null,
        onHover: row.onRowHover!=null ? (value) => row.onRowHover!(row, value) : null,
        child: child,
      ),
    );
  }

  Widget defaultHeaderCellBuilder(BuildContext context, RowModel row, ColModel? col, int j) {
    String message = row.values[j]!=null ? row.values[j].toString() : "";
    bool export = context.findAncestorWidgetOfExactType<Export>()!=null;
    Widget result = Align(
      alignment: _getAlignment(j)==TextAlign.center ? Alignment.center
          : _getAlignment(j)==TextAlign.left||_getAlignment(j)==TextAlign.start ? Alignment.centerLeft
          : Alignment.centerRight,
      child: Stack(
        overflow: Overflow.visible,
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
                    child: small_popup.PopupMenuButton<dynamic>(
                      icon: Icon(filters[j]==EmptyFilter() ? MaterialCommunityIcons.filter_outline : MaterialCommunityIcons.filter,
//                                    color: Theme.of(context).brightness==Brightness.light ? Colors.blue.shade700 : Colors.blue.shade400,
                        color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).accentColor,
                      ),
                      itemBuilder: (context) => List.generate(
                        availableFilters[j].length+1,
                            (index) => PopupMenuItem(
                          child: Text(index==0 ? "  --sin filtro--" : availableFilters[j][index-1].toString()),
                          value: index==0 ? EmptyFilter() : availableFilters[j][index-1].toString(),
                        ),
                      ),
                      onSelected: (value) {
                        setState(() {
                          filters[j] = value;
                          filter();
                        });
                      },
                      initialValue: filters[j],
                      tooltip: "Filtros",
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
      if (header){
        backgroundColor =  backgroundColor.withOpacity(backgroundColor.opacity*(0.5));
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
      for (int i=0; i<filters.length && pass; i++){
        pass = filters[i]==EmptyFilter()
            || (widget.columns![i].filterUsesContains==true && filters[i].toString().isNotEmpty
                ? element.values[i].toString().contains(filters[i].toString())
                : filters[i]==element.values[i]);
      }
      return pass;
    }).toList();
    if (widget.onFilter!=null) filtered = widget.onFilter!(filtered);
    if (filtered.isEmpty) filtered.add(_ErrorRow());
//    if (widget.headerRowModel!=null) filtered.insert(0, widget.headerRowModel);
  }


}



abstract class RowModel{
  dynamic get id;
  Key? get rowKey => null;
  List<Comparable?> get values;
  Color? get backgroundColor => null;
  TextStyle? get textStyle => null;
  double get height => 36;
  bool? get selected => null;
  ValueChanged<RowModel>? get onRowTap => null;
  ValueChanged<RowModel>? get onRowDoubleTap => null;
  ValueChanged<RowModel>? get onRowLongPress => null;
  OnRowHoverCallback? get onRowHover => null;
  OnCellTapCallback? get onCellTap => null;
  OnCellTapCallback? get onCellDoubleTap => null;
  OnCellTapCallback? get onCellLongPress => null;
  OnCellHoverCallback? get onCellHover => null;
  OnCheckBoxSelectedCallback? get onCheckBoxSelected => null;
  List<Widget>? get actions => null;
  Widget? get rowAddon => null;
  bool? get alwaysOnTop => null;
  @override
  bool operator == (dynamic other) => other is RowModel && !(other is _ErrorRow) && this.id==other.id;
  @override
  int get hashCode => id.hashCode;
}
///The widget assumes columns will be constant, so bugs may arise when changing columns
abstract class ColModel{
  String get name;
  Color? get backgroundColor => null;
  TextStyle? get textStyle => null;
  TextAlign? get alignment => null;
  double? get width => null;
  int? get flex => null;
  ValueChanged<int>? get onHeaderTap => null;
  ValueChanged<int>? get onHeaderDoubleTap => null;
  ValueChanged<int>? get onHeaderLongPress => null;
  OnHeaderHoverCallback? get onHeaderHover => null;
  bool? get defaultSortAscending => null;
  bool? get sortEnabled => true;
  bool? get filterEnabled => null;
  bool? get filterUsesContains => null;
}

class SimpleRowModel extends RowModel{
  dynamic id;
  Key? rowKey;
  List<Comparable?> values;
  Color? backgroundColor;
  TextStyle? textStyle;
  double height;
  bool? selected;
  ValueChanged<RowModel>? onRowTap;
  ValueChanged<RowModel>? onRowDoubleTap;
  ValueChanged<RowModel>? onRowLongPress;
  OnRowHoverCallback? onRowHover;
  OnCellTapCallback? onCellTap;
  OnCellTapCallback? onCellDoubleTap;
  OnCellTapCallback? onCellLongPress;
  OnCellHoverCallback? onCellHover;
  OnCheckBoxSelectedCallback? onCheckBoxSelected;
  List<Widget>? actions;
  Widget? rowAddon;
  bool? alwaysOnTop;
  SimpleRowModel({
    required this.id,
    this.rowKey,
    required this.values,
    this.backgroundColor,
    this.textStyle,
    this.height = 36,
    this.selected,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowHover,
    this.onCheckBoxSelected,
    this.actions,
    this.rowAddon,
    this.alwaysOnTop,
    this.onCellTap,
    this.onCellDoubleTap,
    this.onCellLongPress,
    this.onCellHover,
  });
  SimpleRowModel copywith({
    dynamic? id,
    Key? rowKey,
    List<Comparable?>? values,
    Color? backgroundColor,
    TextStyle? textStyle,
    double? height,
    bool? selected,
    ValueChanged<RowModel>? onRowTap,
    ValueChanged<RowModel>? onRowDoubleTap,
    ValueChanged<RowModel>? onRowLongPress,
    OnRowHoverCallback? onRowHover,
    OnCheckBoxSelectedCallback? onCheckBoxSelected,
    List<Widget>? actions,
    Widget? rowAddon,
    bool? alwaysOnTop,
    OnCellTapCallback? onCellTap,
    OnCellTapCallback? onCellDoubleTap,
    OnCellTapCallback? onCellLongPress,
    OnCellHoverCallback? onCellHover,
  }) {
    return SimpleRowModel(
      id: id ?? this.id,
      rowKey: rowKey ?? this.rowKey,
      values: values ?? this.values,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      selected: selected ?? this.selected,
      onRowTap: onRowTap ?? this.onRowTap,
      onRowDoubleTap: onRowDoubleTap ?? this.onRowDoubleTap,
      onRowLongPress: onRowLongPress ?? this.onRowLongPress,
      onRowHover: onRowHover ?? this.onRowHover,
      onCheckBoxSelected: onCheckBoxSelected ?? this.onCheckBoxSelected,
      actions: actions ?? this.actions,
      rowAddon: rowAddon ?? this.rowAddon,
      onCellTap: onCellTap ?? this.onCellTap,
      onCellDoubleTap: onCellDoubleTap ?? this.onCellDoubleTap,
      onCellLongPress: onCellLongPress ?? this.onCellLongPress,
      onCellHover: onCellHover ?? this.onCellHover,
    );
  }
}
class SimpleColModel extends ColModel{
  String name;
  Color? backgroundColor;
  TextStyle? textStyle;
  TextAlign? alignment;
  int? flex;
  double? width;
  ValueChanged<int>? onHeaderTap;
  ValueChanged<int>? onHeaderDoubleTap;
  ValueChanged<int>? onHeaderLongPress;
  OnHeaderHoverCallback? onHeaderHover;
  bool? defaultSortAscending;
  bool? sortEnabled;
  bool? filterEnabled;
  bool? filterUsesContains;
  SimpleColModel({
    required this.name,
    this.backgroundColor,
    this.textStyle,
    this.alignment,
    this.flex,
    this.width,
    this.onHeaderTap,
    this.onHeaderDoubleTap,
    this.onHeaderLongPress,
    this.onHeaderHover,
    this.defaultSortAscending,
    this.sortEnabled = true,
    this.filterEnabled,
    this.filterUsesContains,
  });
  SimpleColModel copyWith({
    String? name,
    Color? backgroundColor,
    TextStyle? textStyle,
    TextAlign? alignment,
    int? flex,
    double? width,
    ValueChanged<int>? onHeaderTap,
    ValueChanged<int>? onHeaderDoubleTap,
    ValueChanged<int>? onHeaderLongPress,
    OnHeaderHoverCallback? onHeaderHover,
    bool? defaultSortAscending,
    bool? sortEnabled,
    bool? filterEnabled,
    bool? filterUsesContains,
  }){
    return SimpleColModel(
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      flex: flex ?? this.flex,
      width: width ?? this.width,
      onHeaderTap: onHeaderTap ?? this.onHeaderTap,
      onHeaderDoubleTap: onHeaderDoubleTap ?? this.onHeaderDoubleTap,
      onHeaderLongPress: onHeaderLongPress ?? this.onHeaderLongPress,
      onHeaderHover: onHeaderHover ?? this.onHeaderHover,
      defaultSortAscending: defaultSortAscending ?? this.defaultSortAscending,
      sortEnabled: sortEnabled ?? this.sortEnabled,
      filterEnabled: filterEnabled ?? this.filterEnabled,
      filterUsesContains: filterUsesContains ?? this.filterUsesContains,
    );
  }
}

class EmptyFilter{
  @override
  bool operator == (dynamic other) => other is EmptyFilter;
  @override
  int get hashCode => 0;
}
class _ErrorRow extends RowModel{
  @override
  bool operator == (dynamic other) => other is EmptyFilter;
  @override
  int get hashCode => -1;
  @override
  get id => throw UnimplementedError();
  @override
  List<Comparable> get values => throw UnimplementedError();
}


class TableController {

  TableController({
    this.initialFilters,
    this.filters,
    this.sortedAscending = true,
    this.sortedColumnIndex,
  });

  Map<int, dynamic>? initialFilters;

  VoidCallback? _filter;
  void filter(){
    _filter?.call();
  }

  List<dynamic>? filters;

  bool sortedAscending;

  int? sortedColumnIndex;

}