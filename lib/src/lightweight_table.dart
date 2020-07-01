import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/small_splash_popup_menu_button.dart' as small_popup;
import 'package:collection/algorithms.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

typedef OnRowHoverCallback = void Function(RowModel row, bool focused);
typedef OnHeaderHoverCallback = void Function(int i, bool focused);


class TableFromZero extends StatefulWidget {

  static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;
  static const int animatedColumn = 3;
  static const int animatedListViewBuilder = 4;
  static const int sliverAnimatedListViewBuilder = 5;

  static const double _checkmarkWidth = 48;

  List<RowModel> rows;
  List<ColModel> columns;
  bool rowTakesPriorityOverColumn;
  int layoutWidgetType;
  EdgeInsets itemPadding;
  bool showHeaders;
  /// Only used if layoutWidgetType==listViewBuilder
  ScrollController controller;
  /// Only used if layoutWidgetType==listViewBuilder
  double verticalPadding;
  ValueChanged<bool> onAllSelected;
  int initialSortedColumnIndex;
  bool showFirstHorizontalDivider;
  Widget horizontalDivider;
  Widget verticalDivider;
  int autoSizeTextMaxLines;
  RowModel headerRowModel;
  List<List<dynamic>> availableFilters;


  TableFromZero({
    @required List<RowModel> rows,
    this.columns,
    this.layoutWidgetType = listViewBuilder,
    this.controller,
    this.verticalPadding = 0,
    this.showHeaders = true,
    this.rowTakesPriorityOverColumn = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.initialSortedColumnIndex,
    this.onAllSelected,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
  }) {
    this.rows = List.from(rows);
    _init();
  }

  @deprecated
  TableFromZero.fromRowList({
    @required List<List<String>> rows,
    this.layoutWidgetType = listViewBuilder,
    this.controller,
    this.verticalPadding = 0,
    this.showHeaders = true,
    this.rowTakesPriorityOverColumn = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.initialSortedColumnIndex,
    this.onAllSelected,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
    List<String> columnNames,
    List<TextStyle> colStyles,
    List<TextStyle> rowStyles,
    List<TextAlign> columnAlignments,
    List<int> columnFlexes,
    List<Color> colBackgroundColors,
    List<Color> rowBackgroundColors,
    double itemHeight,
    ValueChanged<RowModel> onRowTap,
    ValueChanged<RowModel> onRowDoubleTap,
    ValueChanged<RowModel> onRowLongPress,
    OnRowHoverCallback onRowHover,
    ValueChanged<int> onHeaderTap,
    ValueChanged<int> onHeaderDoubleTap,
    ValueChanged<int> onHeaderLongPress,
    OnHeaderHoverCallback onHeaderHover,
    OnRowHoverCallback onCheckBoxSelected,
    List<bool> selectedRows,
    List<Widget> actions,
    List<dynamic> rowIdsForAnimation,
  }) {
    _initModelsFromParameters(rows, columnNames, colStyles, rowStyles, columnAlignments, columnFlexes, colBackgroundColors,
        rowBackgroundColors, itemHeight, onRowTap, onRowDoubleTap, onRowLongPress, onRowHover, onHeaderTap, onHeaderDoubleTap,
        onHeaderLongPress, onHeaderHover, onCheckBoxSelected, selectedRows, actions, rowIdsForAnimation);
    _init();
  }

  @deprecated
  TableFromZero.fromColList({
    @required List<List<String>> cols,
    this.layoutWidgetType = listViewBuilder,
    this.controller,
    this.verticalPadding = 0,
    this.showHeaders = true,
    this.rowTakesPriorityOverColumn = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.initialSortedColumnIndex,
    this.onAllSelected,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
    List<String> columnNames,
    List<TextStyle> colStyles,
    List<TextStyle> rowStyles,
    List<TextAlign> columnAlignments,
    List<int> columnFlexes,
    List<Color> colBackgroundColors,
    List<Color> rowBackgroundColors,
    double itemHeight,
    ValueChanged<RowModel> onRowTap,
    ValueChanged<RowModel> onRowDoubleTap,
    ValueChanged<RowModel> onRowLongPress,
    OnRowHoverCallback onRowHover,
    ValueChanged<int> onHeaderTap,
    ValueChanged<int> onHeaderDoubleTap,
    ValueChanged<int> onHeaderLongPress,
    OnHeaderHoverCallback onHeaderHover,
    OnRowHoverCallback onCheckBoxSelected,
    List<bool> selectedRows,
    List<Widget> actions,
    List<dynamic> rowIdsForAnimation,
  }) {
    List<List<String>> rows = [];
    if (cols!=null && cols.isNotEmpty){
      for (int i=0; i<cols[0].length; i++){
        List<String> row = [];
        cols.forEach((element) {
          row.add(element[i]);
        });
        rows.add(row);
      }
    }
    _initModelsFromParameters(rows, columnNames, colStyles, rowStyles, columnAlignments, columnFlexes, colBackgroundColors,
      rowBackgroundColors, itemHeight, onRowTap, onRowDoubleTap, onRowLongPress, onRowHover, onHeaderTap, onHeaderDoubleTap,
      onHeaderLongPress, onHeaderHover, onCheckBoxSelected, selectedRows, actions, rowIdsForAnimation);
    _init();
  }

  @deprecated
  TableFromZero.fromJson({
    @required List<Map<String, dynamic>> json,
    @required List<String> jsonColumnKeys,
    this.layoutWidgetType = listViewBuilder,
    this.controller,
    this.verticalPadding = 0,
    this.showHeaders = true,
    this.rowTakesPriorityOverColumn = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.initialSortedColumnIndex,
    this.onAllSelected,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.autoSizeTextMaxLines = 1,
    List<String> columnNames,
    List<TextStyle> colStyles,
    List<TextStyle> rowStyles,
    List<TextAlign> columnAlignments,
    List<int> columnFlexes,
    List<Color> colBackgroundColors,
    List<Color> rowBackgroundColors,
    double itemHeight,
    ValueChanged<RowModel> onRowTap,
    ValueChanged<RowModel> onRowDoubleTap,
    ValueChanged<RowModel> onRowLongPress,
    OnRowHoverCallback onRowHover,
    ValueChanged<int> onHeaderTap,
    ValueChanged<int> onHeaderDoubleTap,
    ValueChanged<int> onHeaderLongPress,
    OnHeaderHoverCallback onHeaderHover,
    OnRowHoverCallback onCheckBoxSelected,
    List<bool> selectedRows,
    List<Widget> actions,
    List<dynamic> rowIdsForAnimation,
  }) {
    List<List<String>> rows = [];
    json.forEach((element) {
      List<String> row = [];
      jsonColumnKeys.forEach((key) {
        row.add(element[key]);
      });
      rows.add(row);
    });
    _initModelsFromParameters(rows, columnNames, colStyles, rowStyles, columnAlignments, columnFlexes, colBackgroundColors,
        rowBackgroundColors, itemHeight, onRowTap, onRowDoubleTap, onRowLongPress, onRowHover, onHeaderTap, onHeaderDoubleTap,
        onHeaderLongPress, onHeaderHover, onCheckBoxSelected, selectedRows, actions, rowIdsForAnimation);
    _init();
  }

  void _init(){
    if (showHeaders && columns!=null){
      int actionsIndex = rows.indexWhere((element) => element.actions!=null);
      headerRowModel = SimpleRowModel(
        id: "header_row",
        values: List.generate(columns.length, (index) => columns[index].name),
        onCheckBoxSelected: rows.any((element) => element.onCheckBoxSelected!=null) ? (_, __){} : null,
        actions: actionsIndex!=-1 ? List.generate(rows[actionsIndex].actions.length, (index) => null) : null,
        selected: true,
      );
      availableFilters = [];
      for (int i=0; i<columns.length; i++){
        List<dynamic> available = [];
        if (columns[i].filterEnabled==true){
          rows.forEach((element) {
            if (!available.contains(element.values[i]))
              available.add(element.values[i]);
          });
        }
        availableFilters.add(available);
      }
    }
  }

  void _initModelsFromParameters(
      List<List<String>> rows,
      List<String> columnNames,
      List<TextStyle> colStyles,
      List<TextStyle> rowStyles,
      List<TextAlign> columnAlignments,
      List<int> columnFlexes,
      List<Color> colBackgroundColors,
      List<Color> rowBackgroundColors,
      double itemHeight,
      ValueChanged<RowModel> onRowTap,
      ValueChanged<RowModel> onRowDoubleTap,
      ValueChanged<RowModel> onRowLongPress,
      OnRowHoverCallback onRowHover,
      ValueChanged<int> onHeaderTap,
      ValueChanged<int> onHeaderDoubleTap,
      ValueChanged<int> onHeaderLongPress,
      OnHeaderHoverCallback onHeaderHover,
      OnRowHoverCallback onCheckBoxSelected,
      List<bool> selectedRows,
      List<Widget> actions,
      List<dynamic> rowIdsForAnimation,
      ) {
    this.rows = [];
    for (int i=0; i<rows.length; i++){
      this.rows.add(SimpleRowModel(
        id: rowIdsForAnimation==null ? null : rowIdsForAnimation[i],
        values: rows==null ? null : rows[i],
        height: itemHeight,
        backgroundColor: rowBackgroundColors==null ? null : rowBackgroundColors[i],
        actions: actions,
        onCheckBoxSelected: onCheckBoxSelected,
        onRowDoubleTap: onRowDoubleTap,
        onRowHover: onRowHover,
        onRowLongPress: onRowLongPress,
        onRowTap: onRowTap,
        selected: selectedRows==null ? null : selectedRows[i],
        textStyle: rowStyles==null ? null : rowStyles[i],
      ));
    }
    if (columnNames!=null){ //TODO 3 if no columnNames are provided, the rest of the column functionality cannot be used
      this.columns = [];
      for (int i=0; i<columnNames.length; i++){
        this.columns.add(SimpleColModel(
          name: columnNames==null ? null : columnNames[i],
          textStyle: colStyles==null ? null : colStyles[i],
          backgroundColor: colBackgroundColors==null ? null : colBackgroundColors[i],
          alignment: columnAlignments==null ? null : columnAlignments[i],
          flex: columnFlexes==null ? null : columnFlexes[i],
          onHeaderDoubleTap: onHeaderDoubleTap,
          onHeaderHover: onHeaderHover,
          onHeaderLongPress: onHeaderLongPress,
          onHeaderTap: onHeaderTap,
          defaultSortAscending: true,
          filterEnabled: false,
          sortEnabled: initialSortedColumnIndex!=null && initialSortedColumnIndex>=0,
        ));
      }
    }
  }

  @override
  _TableFromZeroState createState() => _TableFromZeroState(initialSortedColumnIndex);

}


class _TableFromZeroState extends State<TableFromZero> {

  List<RowModel> sorted;
  List<RowModel> filtered;
  List<dynamic> filters;
  int sortedColumnIndex;
  bool sortedAscending;

  _TableFromZeroState(this.sortedColumnIndex);

  @override
  void initState() {
    super.initState();
    filters = List.generate(widget.columns==null? 0 : widget.columns.length, (index) => _EmptyFilter());
    if (sortedColumnIndex!=null && sortedColumnIndex>=0) sortedAscending = widget.columns[sortedColumnIndex].defaultSortAscending;
    sorted = List.from(widget.rows);
    sort();
  }

  @override
  void didUpdateWidget(TableFromZero oldWidget) {
    sorted = List.from(widget.rows);
    sort();
  }

  @override
  Widget build(BuildContext context) {
//    int childCount = (rows.length+(showHeaders && columnNames!=null ? 1 : 0))*2+1;
    int childCount = filtered.length;
    Widget result;
    if (widget.layoutWidgetType==TableFromZero.column){
      result = Padding(
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
        child: Column(
          children: List.generate(
            childCount,
            (index) => _getRow(context, index, filtered[index]),
          ),
        ),
      );
    } else if (widget.layoutWidgetType==TableFromZero.listViewBuilder){
      if (widget.controller==null) widget.controller = ScrollController();
      result = ListView.builder(
        itemBuilder: (context, index) => _getRow(context, index, filtered[index]),
        controller: widget.controller,
        itemCount: childCount,
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
      );
    } else if (widget.layoutWidgetType==TableFromZero.sliverListViewBuilder){
      result = SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) => _getRow(context, i, filtered[i]),
          childCount: childCount,
        ),
      );
    } else if (widget.layoutWidgetType==TableFromZero.animatedColumn || widget.layoutWidgetType==TableFromZero.animatedListViewBuilder){
      if (widget.controller==null) widget.controller = ScrollController();
      result = ImplicitlyAnimatedList<RowModel>(
        controller: widget.controller,
        items: filtered,
        areItemsTheSame: (a, b) => a==b,
        padding: EdgeInsets.symmetric(vertical: widget.verticalPadding),
        shrinkWrap: widget.layoutWidgetType==TableFromZero.animatedColumn,
        itemBuilder: (context, animation, item, index) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-1, 0), end: Offset(0, 0)).animate(animation),
            child: SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              child: _getRow(context, index, item),
            ),
          );
        },
        updateItemBuilder: (context, animation, item) {
          return FadeUpwardsFadeTransition(
            routeAnimation: animation,
            child: FadeUpwardsSlideTransition(
              routeAnimation: animation,
              child: _getRow(context, 1, item),
            ),
          );
        },
        updateDuration: Duration(milliseconds: 300),
      );
    } else if (widget.layoutWidgetType==TableFromZero.sliverAnimatedListViewBuilder){
      result = SliverImplicitlyAnimatedList<RowModel>(
        items: filtered,
        areItemsTheSame: (a, b) => a==b,
        itemBuilder: (context, animation, item, index) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-1, 0), end: Offset(0, 0)).animate(animation),
            child: SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              child: _getRow(context, index, item),
            ),
          );
        },
        updateItemBuilder: (context, animation, item) {
          return FadeUpwardsFadeTransition(
            routeAnimation: animation,
            child: FadeUpwardsSlideTransition(
              routeAnimation: animation,
              child: _getRow(context, 1, item),
            ),
          );
        },
        updateDuration: Duration(milliseconds: 300),
      );
    }
    return result;
  }

  Widget _getRow(BuildContext context, int i, RowModel row){
//    if (i%2==0) return horizontalDivider==null||i==0&&!showFirstHorizontalDivider ? SizedBox.shrink() : horizontalDivider;
//    i = (i-1)~/2;

    if (row is _ErrorRow){
      return AnimatedEntryWidget(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: ErrorSign(
            icon: Icon(Icons.error_outline, size: 64, color: Theme.of(context).disabledColor,),
            title: "No hay datos que mostrar...", //TODO 3 internationalize
            subtitle: filters.any((element) => element!=_EmptyFilter()) ? "Intente desactivar algunos filtros." : "No existen datos correspondientes a esta consulta.",
          ),
        ),
        transitionBuilder: (child, animation) => SizeFadeTransition(animation: animation, child: child, sizeFraction: 0.7, curve: Curves.easeOut,),
      );
    }

    int cols = (row.values.length + (row.onCheckBoxSelected==null ? 0 : 1)) * (widget.verticalDivider==null ? 1 : 2) + (widget.verticalDivider==null ? 0 : 1) + (row.actions==null ? 0 : 1);
    Widget result;
    if (i==0 && widget.headerRowModel!=null){

      result = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(cols, (j) {
                if (row.actions!=null && j==cols-1){
                  return SizedBox(width: TableFromZero._checkmarkWidth*row.actions.length,);
                }
                if (widget.verticalDivider!=null){
                  if (j%2==0) return widget.verticalDivider;
                  j = (j-1)~/2;
                }
                if (row.onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(width: TableFromZero._checkmarkWidth,);
                  } else{
                    j--;
                  }
                }
                return Flexible(
                  flex: _getFlex(j),
                  child: Container(
                    decoration: _getDecoration(row, j, header: true),
                  ),
                );
              }),
            ),
          ),
          Row(
            children: List.generate(cols, (j) {
              if (row.actions!=null && j==cols-1){
                return SizedBox(width: TableFromZero._checkmarkWidth*row.actions.length,);
              }
              if (widget.verticalDivider!=null){
                if (j%2==0) return widget.verticalDivider;
                j = (j-1)~/2;
              }
              if (row.onCheckBoxSelected!=null){
                if (j==0){
                  if (widget.onAllSelected!=null && (filtered.length>2||!(filtered[1] is _ErrorRow))){
                    return SizedBox(
                      width: TableFromZero._checkmarkWidth,
                      child: LoadingCheckbox(
                        value: filtered.any((element) => element.selected==null) ? null : !filtered.any((element) => element.selected==false),
                        onChanged: widget.onAllSelected,
                      ),
                    );
                  } else{
                    return SizedBox(width: TableFromZero._checkmarkWidth,);
                  }
                } else{
                  j--;
                }
              }
              return Flexible(
                flex: _getFlex(j),
                child: InkWell(
                  onTap: widget.columns[j].onHeaderTap!=null||widget.columns[j].sortEnabled==true ? () {
                    if (widget.columns[j].sortEnabled==true){
                      if (sortedColumnIndex==j) {
                        setState(() {
                          sortedAscending = !(sortedAscending==null||sortedAscending);
                          sort();
                        });
                      } else {
                        setState(() {
                          sortedColumnIndex = j;
                          sortedAscending = widget.columns[j].defaultSortAscending;
                          sort();
                        });
                      }
                    }
                    if (widget.columns[j].onHeaderTap!=null){
                      widget.columns[j].onHeaderTap(j);
                    }
                  } : null,
                  onDoubleTap: widget.columns[j].onHeaderDoubleTap!=null ? () => widget.columns[j].onHeaderDoubleTap(j) : null,
                  onLongPress: widget.columns[j].onHeaderLongPress!=null ? () => widget.columns[j].onHeaderLongPress(j) : null,
                  onHover: widget.columns[j].onHeaderHover!=null ? (value) => widget.columns[j].onHeaderHover(j, value) : null,
                  child: Container(
                    height: row.height,
                    alignment: Alignment.center,
                    padding: widget.itemPadding,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: (sortedColumnIndex==j) ? Icon(
                                sortedAscending==null||sortedAscending ? MaterialCommunityIcons.sort_ascending : MaterialCommunityIcons.sort_descending,
                                key: ValueKey(sortedAscending==null||sortedAscending),
                              ) : SizedBox(height: 24,),
                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child,),
                            ),
                            Positioned.fill(
                              child: AnimatedPadding(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.only(left: sortedColumnIndex==j ? 28 : 4, right: widget.columns[j].filterEnabled==true ? 28 : 4),
                                curve: Curves.easeOut,
                                child: AutoSizeText(
                                  widget.columns[j].name,
                                  style: Theme.of(context).textTheme.subtitle2,
                                  textAlign: _getAlignment(j),
                                  maxLines: widget.autoSizeTextMaxLines,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (widget.columns[j].filterEnabled==true)
                            Positioned(
                              right: -4,
                              child: small_popup.PopupMenuButton<dynamic>(
                                icon: Icon(filters[j]==_EmptyFilter() ? MaterialCommunityIcons.filter_outline : MaterialCommunityIcons.filter),
                                itemBuilder: (context) => List.generate(
                                  widget.availableFilters[j].length+1,
                                  (index) => PopupMenuItem(
                                    child: Text(index==0 ? "  --sin filtro--" : widget.availableFilters[j][index-1].toString()),
                                    value: index==0 ? _EmptyFilter() : widget.availableFilters[j][index-1].toString(),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );

    } else{

      result = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(cols, (j) {
                if (row.actions!=null && j==cols-1){
                  return SizedBox(width: TableFromZero._checkmarkWidth*row.actions.length,);
                }
                if (widget.verticalDivider!=null){
                  if (j%2==0) return widget.verticalDivider;
                  j = (j-1)~/2;
                }
                if (row.onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(width: TableFromZero._checkmarkWidth,);
                  } else{
                    j--;
                  }
                }
                return Flexible(
                  flex: _getFlex(j),
                  child: Container(
                    decoration: _getDecoration(row, j),
                  ),
                );
              }),
            ),
          ),
          InkWell(
            onTap: row.onRowTap!=null ? () => row.onRowTap(row) : null,
            onDoubleTap: row.onRowDoubleTap!=null ? () => row.onRowDoubleTap(row) : null,
            onLongPress: row.onRowLongPress!=null ? () => row.onRowLongPress(row) : null,
            onHover: row.onRowHover!=null ? (value) => row.onRowHover(row, value) : null,
            child: Row(
              children: List.generate(cols, (j) {
                if (row.actions!=null && j==cols-1){
                  return SizedBox(
                    width: TableFromZero._checkmarkWidth*row.actions.length,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.actions,
                    ),
                  );
                }
                if (widget.verticalDivider!=null){
                  if (j%2==0) return widget.verticalDivider;
                  j = (j-1)~/2;
                }
                if (row.onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(
                      width: TableFromZero._checkmarkWidth,
                      child: LoadingCheckbox(
                        value: row.selected, onChanged: (value) => row.onCheckBoxSelected(row, value),
                      ),
                    );
                  } else{
                    j--;
                  }
                }
                return Flexible(
                  flex: _getFlex(j),
                  child: Container(
                    height: row.height,
                    alignment: Alignment.center,
                    padding: widget.itemPadding,
                    child: Container(
                      width: double.infinity,
                      child: AutoSizeText(
                        row.values[j]!=null ? row.values[j].toString() : "",
                        style: _getStyle(context, row, j),
                        textAlign: _getAlignment(j),
                        maxLines: widget.autoSizeTextMaxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );

    }

    if (widget.horizontalDivider!=null)
    result = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if(i==0 && widget.showFirstHorizontalDivider) widget.horizontalDivider,
        result,
        widget.horizontalDivider,
      ],
    );
    return result;
  }

  BoxDecoration _getDecoration(RowModel row, int j, {bool header=false}){
    Color backgroundColor;
    if (header){
      backgroundColor = widget.columns!=null && j<widget.columns.length ? widget.columns[j].backgroundColor : null;
    } else{
      if (widget.rowTakesPriorityOverColumn){
        backgroundColor = row.backgroundColor;
        if (backgroundColor==null)
          backgroundColor = widget.columns!=null && j<widget.columns.length ? widget.columns[j].backgroundColor : null;
      } else{
        backgroundColor = widget.columns!=null && j<widget.columns.length ? widget.columns[j].backgroundColor : null;
        if (backgroundColor==null)
          backgroundColor = row.backgroundColor;
      }
    }
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
    return backgroundColor!=null ? BoxDecoration(
      color: backgroundColor.withOpacity(backgroundColor.opacity*(header ? 0.5 : 1)),
    ) : null;
  }

  TextAlign _getAlignment(int j){
    return widget.columns!=null && j<widget.columns.length ? widget.columns[j].alignment : TextAlign.left;
  }

  TextStyle _getStyle(BuildContext context, RowModel row, int j){
    TextStyle style;
    if (widget.rowTakesPriorityOverColumn){
      style = row.textStyle;
      if (style==null)
        style = widget.columns!=null && j<widget.columns.length ? widget.columns[j].textStyle : null;
    } else{
      style = widget.columns!=null && j<widget.columns.length ? widget.columns[j].textStyle : null;
      if (style==null)
        style = row.textStyle;
    }
    return style!=null ? style : Theme.of(context).textTheme.bodyText1;
  }

  int _getFlex(j){
    if (widget.columns!=null && widget.columns[j].flex!=null)
      return widget.columns[j].flex;
    return 1;
  }

  void sort() {
    if (sortedColumnIndex!=null && sortedColumnIndex>=0)
    mergeSort(sorted, compare: ((a, b){
      return sortedAscending==null || sortedAscending
          ? a.values[sortedColumnIndex].compareTo(b.values[sortedColumnIndex])
          : b.values[sortedColumnIndex].compareTo(a.values[sortedColumnIndex]);
    }));
    filter();
  }
  void filter(){
    filtered = sorted.where((element) {
      bool pass = true;
      for (int i=0; i<filters.length && pass; i++){
        pass = filters[i]==_EmptyFilter() || filters[i]==element.values[i];
      }
      return pass;
    }).toList();
    if (filtered.isEmpty) filtered.add(_ErrorRow());
    if (widget.headerRowModel!=null) filtered.insert(0, widget.headerRowModel);
  }

}



abstract class RowModel{
  dynamic get id;
  List<Comparable> get values;
  Color get backgroundColor => null;
  TextStyle get textStyle => null;
  double get height => null;
  bool get selected => null;
  ValueChanged<RowModel> get onRowTap => null;
  ValueChanged<RowModel> get onRowDoubleTap => null;
  ValueChanged<RowModel> get onRowLongPress => null;
  OnRowHoverCallback get onRowHover => null;
  OnRowHoverCallback get onCheckBoxSelected => null;
  List<Widget> get actions => null;
  @override
  bool operator == (dynamic other) => other is RowModel && !(other is _ErrorRow) && this.id==other.id;
  @override
  int get hashCode => id.hashCode;
}
///The widget assumes columns will be constant, so bugs may arise when changing columns
abstract class ColModel{
  String get name;
  Color get backgroundColor => null;
  TextStyle get textStyle => null;
  TextAlign get alignment => null;
  int get flex => null; //TODO 3 maybe rows could also have a set width instead of a flex
  ValueChanged<int> get onHeaderTap => null;
  ValueChanged<int> get onHeaderDoubleTap => null;
  ValueChanged<int> get onHeaderLongPress => null;
  OnHeaderHoverCallback get onHeaderHover => null;
  bool get defaultSortAscending => null;
  bool get sortEnabled => true;
  bool get filterEnabled => null;
}

class SimpleRowModel extends RowModel{
  dynamic id;
  List<Comparable> values;
  Color backgroundColor;
  TextStyle textStyle;
  double height;
  bool selected;
  ValueChanged<RowModel> onRowTap;
  ValueChanged<RowModel> onRowDoubleTap;
  ValueChanged<RowModel> onRowLongPress;
  OnRowHoverCallback onRowHover;
  OnRowHoverCallback onCheckBoxSelected;
  List<Widget> actions;
  SimpleRowModel({
    @required this.id,
    @required this.values,
    this.backgroundColor,
    this.textStyle,
    this.height,
    this.selected,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowHover,
    this.onCheckBoxSelected,
    this.actions,
  });
}
class SimpleColModel extends ColModel{
  String name;
  Color backgroundColor;
  TextStyle textStyle;
  TextAlign alignment;
  int flex;
  ValueChanged<int> onHeaderTap;
  ValueChanged<int> onHeaderDoubleTap;
  ValueChanged<int> onHeaderLongPress;
  OnHeaderHoverCallback onHeaderHover;
  bool defaultSortAscending;
  bool sortEnabled;
  bool filterEnabled;
  SimpleColModel({
    @required this.name,
    this.backgroundColor,
    this.textStyle,
    this.alignment,
    this.flex,
    this.onHeaderTap,
    this.onHeaderDoubleTap,
    this.onHeaderLongPress,
    this.onHeaderHover,
    this.defaultSortAscending,
    this.sortEnabled = true,
    this.filterEnabled,
  });
}

class _EmptyFilter{
  @override
  bool operator == (dynamic other) => other is _EmptyFilter;
  @override
  int get hashCode => 0;
}
class _ErrorRow extends RowModel{
  @override
  bool operator == (dynamic other) => other is _EmptyFilter;
  @override
  int get hashCode => -1;
  @override
  get id => throw UnimplementedError();
  @override
  List<Comparable> get values => throw UnimplementedError();
}

