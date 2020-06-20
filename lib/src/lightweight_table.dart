import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

typedef OnRowHoverCallback = void Function(int i, bool focused);

class TableFromZero extends StatelessWidget {

  static const int column = 0;
  static const int listViewBuilder = 1;
  static const int sliverListViewBuilder = 2;

  static const double _checkmarkWidth = 48;


  List<List<String>> rows;
  List<String> columnNames;
  List<TextStyle> colStyles;
  List<TextStyle> rowStyles;
  List<TextAlign> columnAlignments;
  List<int> columnFlexes;
  List<Color> colBackgroundColors;
  List<Color> rowBackgroundColors;
  bool rowTakesPriorityOverColumn;
  int layoutWidgetType;
  double itemHeight;
  EdgeInsets itemPadding;
  bool showHeaders;
  /// Only used if layoutWidgetType==listViewBuilder
  ScrollController controller;
  double verticalPadding;
  ValueChanged<int> onRowTap;
  ValueChanged<int> onRowDoubleTap;
  ValueChanged<int> onRowLongPress;
  OnRowHoverCallback onRowHover;
  ValueChanged<int> onHeaderTap;
  ValueChanged<int> onHeaderDoubleTap;
  ValueChanged<int> onHeaderLongPress;
  OnRowHoverCallback onHeaderHover;
  OnRowHoverCallback onCheckBoxSelected;
  ValueChanged<bool> onAllSelected;
  int sortedColumnIndex;
  bool sortedAscending;
  List<bool> selectedRows;
  bool showFirstHorizontalDivider;
  Widget horizontalDivider;
  Widget verticalDivider;
  List<Widget> actions;


  TableFromZero.fromRowList({
    @required this.rows,
    this.showHeaders = true,
    this.columnNames,
    this.colStyles,
    this.rowStyles,
    this.rowTakesPriorityOverColumn = true,
    this.columnAlignments,
    this.columnFlexes,
    this.colBackgroundColors,
    this.rowBackgroundColors,
    this.layoutWidgetType = listViewBuilder,
    this.itemHeight,
    this.controller,
    this.verticalPadding = 0,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowHover,
    this.onHeaderTap,
    this.onHeaderDoubleTap,
    this.onHeaderLongPress,
    this.onHeaderHover,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.sortedColumnIndex,
    this.sortedAscending,
    this.onCheckBoxSelected,
    this.onAllSelected,
    this.selectedRows,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.actions,
  });
  TableFromZero.fromColList({
    @required List<List<String>> cols,
    this.showHeaders = true,
    this.columnNames,
    this.colStyles,
    this.rowStyles,
    this.rowTakesPriorityOverColumn = true,
    this.columnAlignments,
    this.columnFlexes,
    this.colBackgroundColors,
    this.rowBackgroundColors,
    this.layoutWidgetType = listViewBuilder,
    this.itemHeight,
    this.controller,
    this.verticalPadding = 0,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowHover,
    this.onHeaderTap,
    this.onHeaderDoubleTap,
    this.onHeaderLongPress,
    this.onHeaderHover,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.sortedColumnIndex,
    this.sortedAscending,
    this.onCheckBoxSelected,
    this.onAllSelected,
    this.selectedRows,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.actions,
  }) {
    rows = [];
    if (cols!=null && cols.isNotEmpty){
      for (int i=0; i<cols[0].length; i++){
        List<String> row = [];
        cols.forEach((element) {
          row.add(element[i]);
        });
        rows.add(row);
      }
    }
  }
  TableFromZero.fromJson({
    @required List<Map<String, dynamic>> json,
    @required List<String> jsonColumnKeys,
    this.showHeaders = true,
    this.columnNames,
    this.colStyles,
    this.rowStyles,
    this.rowTakesPriorityOverColumn = true,
    this.columnAlignments,
    this.columnFlexes,
    this.colBackgroundColors,
    this.rowBackgroundColors,
    this.layoutWidgetType = listViewBuilder,
    this.itemHeight,
    this.controller,
    this.verticalPadding = 0,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowHover,
    this.onHeaderTap,
    this.onHeaderDoubleTap,
    this.onHeaderLongPress,
    this.onHeaderHover,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.sortedColumnIndex,
    this.sortedAscending,
    this.onCheckBoxSelected,
    this.onAllSelected,
    this.selectedRows,
    this.horizontalDivider = const Divider(height: 1,),
    this.verticalDivider = const VerticalDivider(width: 1,),
    this.showFirstHorizontalDivider = true,
    this.actions,
  }) {
    rows = [];
    json.forEach((element) {
      List<String> row = [];
      jsonColumnKeys.forEach((key) {
        row.add(element[key]);
      });
      rows.add(row);
    });
  }




  @override
  Widget build(BuildContext context) {
    int childCount = (rows.length+(showHeaders && columnNames!=null ? 1 : 0))*2+1;
    if (layoutWidgetType==column){
      return Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Column(
          children: List.generate(
            childCount,
            (index) => _getRow(context, index),
          ),
        ),
      );
    } else if (layoutWidgetType==listViewBuilder){
      if (controller==null) controller = ScrollController();
      return ListView.builder(
        itemBuilder: _getRow,
        controller: controller,
        itemCount: childCount,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
      );
    } else if (layoutWidgetType==sliverListViewBuilder){
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i){
            if (i==0 || i>childCount){
              return SizedBox(height: verticalPadding,);
            }
            return _getRow(context, i-1);
          },
          childCount: childCount+2,
        ),
      );
    }
  }

  Widget _getRow(BuildContext context, int i){
    if (i%2==0) return horizontalDivider==null||i==0&&!showFirstHorizontalDivider ? SizedBox.shrink() : horizontalDivider;
    i = (i-1)~/2;
    int cols = ((columnNames??rows[0]).length + (onCheckBoxSelected==null ? 0 : 1)) * (verticalDivider==null ? 1 : 2) + (verticalDivider==null ? 0 : 1) + (actions==null ? 0 : 1);
    if (i==0 && showHeaders && columnNames!=null){

      return Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(cols, (j) {
                if (actions!=null && j==cols-1){
                  return SizedBox(width: _checkmarkWidth*actions.length,);
                }
                if (verticalDivider!=null){
                  if (j%2==0) return verticalDivider;
                  j = (j-1)~/2;
                }
                if (onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(width: _checkmarkWidth,);
                  } else{
                    j--;
                  }
                }
                return Flexible(
                  flex: _getFlex(j),
                  child: Container(
                    decoration: _getDecoration(i, j, header: true),
                  ),
                );
              }),
            ),
          ),
          Row(
            children: List.generate(cols, (j) {
              if (actions!=null && j==cols-1){
                return SizedBox(width: _checkmarkWidth*actions.length,);
              }
              if (verticalDivider!=null){
                if (j%2==0) return verticalDivider;
                j = (j-1)~/2;
              }
              if (onCheckBoxSelected!=null){
                if (j==0){
                  if (onAllSelected!=null){
                    return SizedBox(
                      width: _checkmarkWidth,
                      child: Checkbox(
                        value: !selectedRows.contains(false), onChanged: onAllSelected,
                      ),
                    );
                  } else{
                    return SizedBox(width: _checkmarkWidth,);
                  }
                } else{
                  j--;
                }
              }
              return Flexible(
                flex: _getFlex(j),
                child: InkWell(
                  onTap: onHeaderTap!=null ? () => onHeaderTap(j) : null,
                  onDoubleTap: onHeaderDoubleTap!=null ? () => onHeaderDoubleTap(j) : null,
                  onLongPress: onHeaderLongPress!=null ? () => onHeaderLongPress(j) : null,
                  onHover: onHeaderHover!=null ? (value) => onHeaderHover(j, value) : null,
                  child: Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    padding: itemPadding,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                columnNames[j],
                                style: Theme.of(context).textTheme.subtitle2,
                                textAlign: _getAlignment(j),
                              ),
                            ),
                            if (sortedColumnIndex==j)
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Icon(
                                sortedAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                key: ValueKey(sortedAscending),
//                              color: Theme.of(context).accentColor,
                              ),
                              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child,),
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

      if (showHeaders && columnNames!=null) i--;
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: Row(
              children: List.generate(cols, (j) {
                if (actions!=null && j==cols-1){
                  return SizedBox(width: _checkmarkWidth*actions.length,);
                }
                if (verticalDivider!=null){
                  if (j%2==0) return verticalDivider;
                  j = (j-1)~/2;
                }
                if (onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(width: _checkmarkWidth,);
                  } else{
                    j--;
                  }
                }
                return Flexible(
                  flex: _getFlex(j),
                  child: Container(
                    decoration: _getDecoration(i, j),
                  ),
                );
              }),
            ),
          ),
          InkWell(
            onTap: onRowTap!=null ? () => onRowTap(i) : null,
            onDoubleTap: onRowDoubleTap!=null ? () => onRowDoubleTap(i) : null,
            onLongPress: onRowLongPress!=null ? () => onRowLongPress(i) : null,
            onHover: onRowHover!=null ? (value) => onRowHover(i, value) : null,
            child: Row(
              children: List.generate(cols, (j) {
                if (actions!=null && j==cols-1){
                  return SizedBox(
                    width: _checkmarkWidth*actions.length,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actions,
                    ),
                  );
                }
                if (verticalDivider!=null){
                  if (j%2==0) return verticalDivider;
                  j = (j-1)~/2;
                }
                if (onCheckBoxSelected!=null){
                  if (j==0){
                    return SizedBox(
                      width: _checkmarkWidth,
                      child: Checkbox(
                        value: _getSelected(i), onChanged: (value) => onCheckBoxSelected(i, value),
                      ),
                    );
                  } else{
                    j--;
                  }
                }
                return Flexible( //TODO 2 use AutoResizeText and take a number for maxLines
                  flex: _getFlex(j),
                  child: Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    padding: itemPadding,
                    child: Container(
                      width: double.infinity,
                      child: Text(
                        rows[i][j]!=null ? rows[i][j] : "",
                        style: _getStyle(context, i, j),
                        textAlign: _getAlignment(j),
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
  }

  BoxDecoration _getDecoration(int i, int j, {bool header=false}){
    Color backgroundColor;
    if (header){
      backgroundColor = colBackgroundColors!=null && j<colBackgroundColors.length ? colBackgroundColors[j] : null;
    } else{
      if (rowTakesPriorityOverColumn){
        backgroundColor = rowBackgroundColors!=null && i<rowBackgroundColors.length ? rowBackgroundColors[i] : null;
        if (backgroundColor==null)
          backgroundColor = colBackgroundColors!=null && j<colBackgroundColors.length ? colBackgroundColors[j] : null;
      } else{
        backgroundColor = colBackgroundColors!=null && j<colBackgroundColors.length ? colBackgroundColors[j] : null;
        if (backgroundColor==null)
          backgroundColor = rowBackgroundColors!=null && i<rowBackgroundColors.length ? rowBackgroundColors[i] : null;
      }
    }
    List<double> stops = [0, 0.1, 0.55, 1,];
    if (_getAlignment(j)==TextAlign.right)
      stops = [0, 0.45, 0.9, 1,]; //TODO 3 make gradient edges take the exact same lenght as padding
    return backgroundColor!=null ? BoxDecoration(
        gradient: LinearGradient( //TODO 3 add an option to disable gradient
            colors: [
              backgroundColor.withOpacity(0),
              backgroundColor.withOpacity(backgroundColor.opacity*(header ? 0.5 : 1)),
              backgroundColor.withOpacity(backgroundColor.opacity*(header ? 0.5 : 1)),
              backgroundColor.withOpacity(0),
            ],
            stops: stops,
        )
    ) : null;
  }

  TextAlign _getAlignment(int j){
    return columnAlignments!=null && j<columnAlignments.length ? columnAlignments[j] : TextAlign.left;
  }

  TextStyle _getStyle(BuildContext context, int i, int j){
    TextStyle style;
    if (rowTakesPriorityOverColumn){
      style = rowStyles!=null && i<rowStyles.length ? rowStyles[i] : null;
      if (style==null)
        style = colStyles!=null && j<colStyles.length ? colStyles[j] : null;
    } else{
      style = colStyles!=null && j<colStyles.length ? colStyles[j] : null;
      if (style==null)
        style = rowStyles!=null && i<rowStyles.length ? rowStyles[i] : null;
    }
    return style!=null ? style : Theme.of(context).textTheme.bodyText1;
  }

  int _getFlex(j){
    if (columnFlexes!=null && columnFlexes[j]!=null)
      return columnFlexes[j];
    return 1;
  }

  bool _getSelected(i){
    if (selectedRows!=null && i<selectedRows.length)
      return selectedRows[i];
    return false;
  }

}







