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
typedef OnCheckBoxSelectedCallback = void Function(RowModel row, bool? focused);
typedef OnHeaderHoverCallback = void Function(int i, bool focused);


class TableFromZero extends StatefulWidget { //TODO 2 internationalize

  @deprecated static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;
  @deprecated static const int animatedColumn = 3;
  static const int animatedListViewBuilder = 4;
  static const int sliverAnimatedListViewBuilder = 5;

  static const double _checkmarkWidth = 48;

  List<RowModel> rows;
  List<ColModel>? columns;
  bool rowTakesPriorityOverColumn;
  int layoutWidgetType;
  EdgeInsets itemPadding;
  bool showHeaders;
  /// Only used if layoutWidgetType==listViewBuilder
  ScrollController? scrollController;
  /// Only used if layoutWidgetType==listViewBuilder
  double verticalPadding;
  double horizontalPadding;
  ValueChanged<bool?>? onAllSelected;
  int? initialSortedColumnIndex;
  bool showFirstHorizontalDivider;
  Widget? horizontalDivider;
  Widget? verticalDivider;
  int autoSizeTextMaxLines;
  RowModel? headerRowModel;
  double? headerHeight;
  List<List<dynamic>>? availableFilters;
  Widget Function(BuildContext context, RowModel row, ColModel? col, int j)? cellBuilder;
  Widget Function(BuildContext context, int i, RowModel row)? rowBuilder;
  bool applyStickyHeaders;
  Widget? headerAddon;
  bool applyRowAlternativeColors;
  double? minWidth;
  double? maxWidth;
  bool applyMinWidthToHeaderAddon;
  bool applyMaxWidthToHeaderAddon;
  bool applyTooltipToCells;
  Color? headerRowColor;
  TextStyle? defaultTextStyle;
  ScrollController? mainScrollController;
  double stickyOffset;
  bool forceColumnToLayoutAllChildren;
  List<RowModel> Function(List<RowModel>)? onFilter;
  TableController? tableController;
  Alignment? alignmentWhenOverMaxWidth;
  final FutureOr<String>? exportPath;
  final bool applyScrollToRowAddon;
  final bool rowGestureDetectorCoversRowAddon;

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
    this.horizontalDivider = const Divider(height: 1, color: const Color(0xFF757575),),
    this.verticalDivider = const VerticalDivider(width: 1, color: const Color(0xFF757575),),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
    this.cellBuilder,
    this.rowBuilder,
    this.headerHeight,
    this.applyStickyHeaders = true,
    this.headerAddon,
    this.applyRowAlternativeColors = false,
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
    this.rowGestureDetectorCoversRowAddon = false,
  }) : this.rows = List.from(rows) {
    if (showHeaders && columns!=null){
      int actionsIndex = rows.indexWhere((element) => element.actions!=null);
      headerRowModel = SimpleRowModel(
        id: "header_row",
        values: List.generate(columns!.length, (index) => columns![index].name),
        onCheckBoxSelected: rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null,
        actions: actionsIndex!=-1 ? List.generate(rows[actionsIndex].actions!.length, (index) => SizedBox.shrink()) : null,
        selected: true,
        height: headerHeight ?? 38,
      );
      availableFilters = [];
      for (int i=0; i<columns!.length; i++){
        List<dynamic> available = [];
        if (columns![i].filterEnabled==true){
          rows.forEach((element) {
            if (!available.contains(element.values[i]))
              available.add(element.values[i]);
          });
        }
        availableFilters!.add(available);
      }
    }
  }

  @override
  _TableFromZeroState createState() => _TableFromZeroState(initialSortedColumnIndex);

}


class _TableFromZeroState extends State<TableFromZero> {

  late List<RowModel> sorted;
  late List<RowModel> filtered;
  late List<dynamic> _filters;
  List<dynamic> get filters => widget.tableController?.filters ?? _filters;
  set filters(List<dynamic> value) {
    _filters = value;
  }

  int? sortedColumnIndex;
  bool sortedAscending = true;
  late ScrollController _scrollController;
  late TrackingScrollController sharedController;

  _TableFromZeroState(this.sortedColumnIndex);

  double lastPosition = 0;
  bool lockScrollUpdates = false;
  @override
  void initState() {
    super.initState();
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
        _filters = List.generate(widget.columns?.length ?? 0, (index) => EmptyFilter());
      } else{
        _filters = List.generate(widget.columns?.length ?? 0, (index) => widget.tableController!.initialFilters![index] ?? EmptyFilter());
      }
    }
    if (sortedColumnIndex!=null && sortedColumnIndex!>=0) sortedAscending = widget.columns![sortedColumnIndex!].defaultSortAscending ?? true;
    sorted = List.from(widget.rows);
    _scrollController = widget.scrollController ?? ScrollController();
    sharedController = TrackingScrollController();
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
    sort();
  }

  @override
  void didUpdateWidget(TableFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    sorted = List.from(widget.rows);
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
            children: List.generate(childCount, (i) => _getRow(context, i, filtered[i])),
          );
        } else {
          result = ListView.builder(
            itemBuilder: (context, i) => _getRow(context, i, filtered[i]),
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
                curve: Curves.easeInOut,
                animation: animation,
                child: _getRow(context, index, item),
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
                child: _getRow(context, 1, item),
              ),
            );
          },
          updateDuration: Duration(milliseconds: 400),
        );
      } else{
        result = SizedBox.shrink();
      }
      if (widget.applyStickyHeaders && widget.showHeaders && widget.columns!=null){
        result = StickyHeader(
          header: _getHeaderRow(context),
          content: result,
          stickOffset: widget.stickyOffset,
          controller: widget.mainScrollController,
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
                (BuildContext context, int i) => _getRow(context, i, filtered[i]),
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
                curve: Curves.easeInOut,
                animation: animation,
                child: _getRow(context, index, item),
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
                child: _getRow(context, 1, item),
              ),
            );
          },
          updateDuration: Duration(milliseconds: 400),
        );
      } else{
        result = SizedBox.shrink();
      }
      if (widget.showHeaders && widget.columns!=null){
        result = SliverStickyHeader(
          header: _getHeaderRow(context),
          sliver: result,
          sticky: widget.applyStickyHeaders,
        );
      }
      result = SliverPadding(
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding,),
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

  Widget _getHeaderRow(BuildContext context){
    if (widget.headerRowModel==null) SizedBox.shrink();
    bool export = context.findAncestorWidgetOfExactType<Export>()!=null;
    final row = widget.headerRowModel!;
    int cols = ((row.values.length-disabledColumnCount) + (row.onCheckBoxSelected==null ? 0 : 1)) * (widget.verticalDivider==null ? 1 : 2) + (widget.verticalDivider==null ? 0 : 1) + (row.actions==null ? 0 : 1);
    Widget result =  Container(
      color: Material.of(context)!.color,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(cols, (j) {
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
                if (result==null && widget.columns![j].flex==0){
                  return SizedBox.shrink();
                }
                if (!kIsWeb && Platform.isWindows){
                  result = Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0, bottom: -1,
                        left: j==0 ? 0 : -1,
                        right: j==cols-1 ? 0 : -1,
                        child: Container(
                          decoration: _getDecoration(row, -1, j, header: true),
                        ),
                      ),
                      if (result!=null)
                        result,
                    ],
                  );
                } else{
                  result = Container(
                    decoration: _getDecoration(row, -1, j, header: true),
                    child: result,
                  );
                }
                if (addSizing){
                  if (widget.columns![j].width!=null){
                    result = SizedBox(width: widget.columns![j].width, child: result,);
                  } else{
                    result = Flexible(flex: _getFlex(j), child: result,);
                  }
                }
                return result;
              }),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Row(
              children: List.generate(cols, (j) {
                if (row.actions!=null && j==cols-1){
                  return SizedBox(width: TableFromZero._checkmarkWidth*row.actions!.length,);
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
                    if (widget.onAllSelected!=null && (filtered.length>2||!(filtered[1] is _ErrorRow))){
                      return SizedBox(
                        width: TableFromZero._checkmarkWidth,
                        child: LoadingCheckbox(
                          value: filtered.any((element) => element.selected==null) ? null : !filtered.any((element) => element.selected==false),
                          onChanged: widget.onAllSelected!,
                        ),
                      );
                    } else{
                      return SizedBox(width: TableFromZero._checkmarkWidth,);
                    }
                  } else{
                    j--;
                  }
                }
                if (widget.columns![j].flex==0){
                  return SizedBox.shrink();
                }
                Widget result = InkWell(
                  onTap: widget.columns![j].onHeaderTap!=null||widget.columns![j].sortEnabled==true ? () {
                    if (widget.columns![j].sortEnabled==true){
                      if (sortedColumnIndex==j) {
                        setState(() {
                          sortedAscending = !(sortedAscending==null||sortedAscending);
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
                  onDoubleTap: widget.columns![j].onHeaderDoubleTap!=null ? () => widget.columns![j].onHeaderDoubleTap!(j) : null,
                  onLongPress: widget.columns![j].onHeaderLongPress!=null ? () => widget.columns![j].onHeaderLongPress!(j) : null,
                  onHover: widget.columns![j].onHeaderHover!=null ? (value) => widget.columns![j].onHeaderHover!(j, value) : null,
                  child: Container(
                    width: double.infinity,
                    height: row.height,
                    alignment: _getAlignment(j)==TextAlign.right ? Alignment.centerRight
                        : _getAlignment(j)==TextAlign.center ? Alignment.center
                        : Alignment.centerLeft,
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
                                sortedAscending==null||sortedAscending ? MaterialCommunityIcons.sort_ascending : MaterialCommunityIcons.sort_descending,
                                key: ValueKey(sortedAscending==null||sortedAscending),
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
                                    widget.availableFilters![j].length+1,
                                        (index) => PopupMenuItem(
                                      child: Text(index==0 ? "  --sin filtro--" : widget.availableFilters![j][index-1].toString()),
                                      value: index==0 ? EmptyFilter() : widget.availableFilters![j][index-1].toString(),
                                    ),
                                  ),
                                  onSelected: (value) {
                                    setState(() {
                                      filters[j] = value;
                                      filter();
                                    });
                                  },
                                  initialValue: filters[j],
                                  tooltip: "Filtros", //TODO 3 internationalize
                                ),
                              ),
                            )
                          ),
                      ],
                    ),
                  ),
                );
                if (widget.columns![j].width!=null){
                  return SizedBox(width: widget.columns![j].width, child: result,);
                } else{
                  return Flexible(flex: _getFlex(j), child: result,);
                }
              }),
            ),
          ),
        ],
      ),
    );

    if (widget.horizontalDivider!=null){
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if(widget.showFirstHorizontalDivider) widget.horizontalDivider!,
          result,
          widget.horizontalDivider!,
        ],
      );
    }
    if (widget.horizontalPadding>0){
      result = Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: result,
      );
    }
    if (widget.headerAddon!=null && (widget.applyMinWidthToHeaderAddon||widget.minWidth==null)){
      Widget headerAddon = widget.maxWidth==null||!widget.applyMaxWidthToHeaderAddon ? widget.headerAddon!
          : Align(
            alignment: widget.alignmentWhenOverMaxWidth ?? Alignment.center,
            child: ConstrainedBox(constraints: BoxConstraints(maxWidth: widget.maxWidth!), child: widget.headerAddon,),
          );
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            child: headerAddon,
          ),
          result,
        ],
      );
    }
    if (widget.minWidth!=null || widget.maxWidth!=null){
      return LayoutBuilder(
        builder: (context, constraints) {
          Widget r;
          if (widget.minWidth!=null&&constraints.maxWidth<widget.minWidth! || widget.maxWidth!=null&&constraints.maxWidth>widget.maxWidth!){
            r = ScrollOpacityGradient(
              maxSize: 0,
              scrollController: sharedController,
              direction: OpacityGradient.horizontal,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) => true,
                child: Align(
                  alignment: widget.alignmentWhenOverMaxWidth ?? Alignment.center,
                  child: SingleChildScrollView(
                    controller: sharedController,
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: (widget.minWidth!=null&&constraints.maxWidth<widget.minWidth!) ? widget.minWidth : widget.maxWidth,
                      child: result,
                    ),
                  ),
                ),
              ),
            );
          } else{
            r = result;
          }
          if (widget.headerAddon!=null && !widget.applyMinWidthToHeaderAddon){
            Widget headerAddon = widget.maxWidth==null||!widget.applyMaxWidthToHeaderAddon ? widget.headerAddon!
                : Align(
                  alignment: widget.alignmentWhenOverMaxWidth ?? Alignment.center,
                  child: ConstrainedBox(constraints: BoxConstraints(maxWidth: widget.maxWidth!), child: widget.headerAddon,),
                );
            r = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerAddon,
                r,
              ],
            );
          }
          return r;
        },
      );
    }
    return result;
  }


  Widget _getRow(BuildContext context, int i, RowModel row){
    if (widget.rowBuilder==null){
      return _defaultGetRow(context, i, row);
    } else{
      return widget.rowBuilder!(context, i, row);
    }
  }
  Widget _defaultGetRow(BuildContext context, int i, RowModel row){

    if (row is _ErrorRow){
      return AnimatedEntryWidget(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: ErrorSign(
            icon: Icon(MaterialCommunityIcons.clipboard_alert_outline, size: 64, color: Theme.of(context).disabledColor,),
            title: "No hay datos que mostrar...", //TODO 3 internationalize
            subtitle: filters.any((element) => element!=EmptyFilter()) ? "Intente desactivar algunos filtros." : "No existen datos correspondientes a esta consulta.",
          ),
        ),
        transitionBuilder: (child, animation) => SizeFadeTransition(animation: animation, child: child, sizeFraction: 0.7, curve: Curves.easeOut,),
      );
    }

    int cols = ((row.values.length-disabledColumnCount) + (row.onCheckBoxSelected==null ? 0 : 1)) * (widget.verticalDivider==null ? 1 : 2) + (widget.verticalDivider==null ? 0 : 1) + (row.actions==null ? 0 : 1);
    final backgrounds = List.generate(cols, (j) {
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
              top: i==0 ? 0 : -1,
              bottom: i==filtered.length-1 ? 0 : -1,
              left: j==0 ? 0 : -1,
              right: j==cols-1 ? 0 : -1,
              child: Container(
                decoration: _getDecoration(row, i, j),
              ),
            ),
            if (result!=null)
              result,
          ],
        );
      } else{
        result = Container(
          decoration: _getDecoration(row, i, j),
          child: result,
        );
      }
      if (addSizing){
        if (widget.columns!=null && widget.columns![j].width!=null){
          result = SizedBox(width: widget.columns![j].width, child: result,);
        } else{
          result = Expanded(flex: _getFlex(j), child: result,);
        }
      }
      return result;
    });
    final cells = List.generate(cols, (j) {
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
            child: LoadingCheckbox(
              value: row.selected, onChanged: (value) => row.onCheckBoxSelected!(row, value),
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
        padding: widget.itemPadding,
        child: Container(
            width: double.infinity,
            child: (widget.cellBuilder??defaultCellBuilder)
                .call(context, row, widget.columns==null?null:widget.columns![j], j)
        ),
      );
      if (widget.columns!=null && widget.columns![j].width!=null){
        return SizedBox(width: widget.columns![j].width, child: result,);
      } else{
        return Flexible(flex: _getFlex(j), child: result,);
      }
    });
    Widget result = Stack(
      key: row.rowKey,
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: Row(
            children: backgrounds,
          ),
        ),
        _buildRowGestureDetector(
          context: context,
          row: row,
          child: Row(
            children: cells,
          ),
        ),
      ],
    );

    if (row.rowAddon!=null){
      if (widget.applyStickyHeaders){
        result = StickyHeader(
          controller: widget.mainScrollController,
          header: result,
          content: row.rowAddon!,
          stickOffset: i==0 ? 0 : widget.stickyOffset+widget.headerRowModel!.height,
        );
      } else{
        result = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            result,
            row.rowAddon!
          ],
        );
      }
    }

    if (widget.horizontalDivider!=null)
    result = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        result,
        widget.horizontalDivider!,
      ],
    );
    if (widget.horizontalPadding>0){
      result = Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
        child: result,
      );
    }
    if (widget.rowGestureDetectorCoversRowAddon){
      result = Stack(
        children: [
          result,
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: row.onRowTap!=null ? () => row.onRowTap!(row) : null,
                onDoubleTap: row.onRowDoubleTap!=null ? () => row.onRowDoubleTap!(row) : null,
                onLongPress: row.onRowLongPress!=null ? () => row.onRowLongPress!(row) : null,
                onHover: row.onRowHover!=null ? (value) => row.onRowHover!(row, value) : null,
                child: Container(),
              ),
            ),
          )
        ],
      );
    }
    if (widget.minWidth!=null || widget.maxWidth!=null){
      return LayoutBuilder(
        builder: (context, constraints) {
          if (widget.minWidth!=null&&constraints.maxWidth<widget.minWidth! || widget.maxWidth!=null&&constraints.maxWidth>widget.maxWidth!){
            return ScrollOpacityGradient(
//                size: widget.horizontalPadding,
              scrollController: sharedController,
              direction: OpacityGradient.horizontal,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => true,
                  child: Align(
                    alignment: widget.alignmentWhenOverMaxWidth ?? Alignment.center,
                    child: SingleChildScrollView(
                      controller: sharedController,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: (widget.minWidth!=null&&constraints.maxWidth<widget.minWidth!) ? widget.minWidth : widget.maxWidth,
                        child: result,
                      ),
                    ),
                  ),
                ),
            );
          } else{
            return result;
          }
        },
      );
    }
    return result;
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

  Widget defaultCellBuilder(BuildContext context, RowModel row, ColModel? col, int j){
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

  BoxDecoration _getDecoration(RowModel row, int i, int j, {bool header=false}){
    Color? backgroundColor = _getBackgroundColor(row, i, j, header);
    bool applyDarker = i>=0 && widget.applyRowAlternativeColors==true
        && _shouldApplyDarkerBackground(backgroundColor, row, i, j, header);
    if (header){
      backgroundColor = backgroundColor ?? widget.headerRowColor;
    }
    if (backgroundColor==null){
      backgroundColor = Material.of(context)!.color;
    }
    if (header){
      backgroundColor =  backgroundColor!.withOpacity(backgroundColor.opacity*(0.5));
    }
    if (backgroundColor!.opacity<1){
      backgroundColor = Color.alphaBlend(backgroundColor, Material.of(context)!.color!);
    }
    if(applyDarker){
      backgroundColor = Color.alphaBlend(backgroundColor.withOpacity(0.965), Colors.black);
    }
    return BoxDecoration(color: backgroundColor);
//    List<double> stops = [0, 0.1, 0.55, 1,];
//    if (_getAlignment(j)==TextAlign.right)
//      stops = [0, 0.45, 0.9, 1,]; //TODO 3 make gradient edges take the exact same lenght as padding
//    return backgroundColor!=null ? BoxDecoration(
//        gradient: LinearGradient( //TODO 3 add an option to disable gradient
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
  Color? _getBackgroundColor(RowModel row, int i, int j, bool header){
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
  bool _shouldApplyDarkerBackground(Color? current, RowModel row, int i, int j, bool header){
//    if (filtered[i]!=row) return false;
    if (i==0){
      return false;
    } else{
      Color? previous = _getBackgroundColor(filtered[i-1], i-1, j, header);
      if (previous!=current) return false;
      return !_shouldApplyDarkerBackground(previous, filtered[i-1], i-1, j, header);
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
        return sortedAscending==null || sortedAscending
            ? a.values[sortedColumnIndex!]!.compareTo(b.values[sortedColumnIndex!])
            : b.values[sortedColumnIndex!]!.compareTo(a.values[sortedColumnIndex!]);
      }));
    filter();
  }
  void filter(){
    filtered = sorted.where((element) {
      bool pass = true;
      for (int i=0; i<filters.length && pass; i++){
        pass = filters[i]==EmptyFilter() || filters[i]==element.values[i];
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
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
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

  Map<int, dynamic>? initialFilters;

  VoidCallback? _filter;
  void filter(){
    _filter?.call();
  }

  List<dynamic>? _filters;
  List<dynamic>? get filters => _filters;
  set filters(List<dynamic>? value) {
    _filters = value;
    filter();
  }

}