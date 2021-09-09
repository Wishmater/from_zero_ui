import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


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
  bool operator == (dynamic other) => other is RowModel && !(other is ErrorRow) && this.id==other.id;
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
  bool? get neutralConditionFiltersEnabled => null;
  bool? get textConditionFiltersEnabled => null;
  bool? get numberConditionFiltersEnabled => null;
  bool? get dateConditionFiltersEnabled => null;
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
    dynamic id,
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
  bool? neutralConditionFiltersEnabled;
  bool? textConditionFiltersEnabled;
  bool? numberConditionFiltersEnabled;
  bool? dateConditionFiltersEnabled;
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
    this.neutralConditionFiltersEnabled,
    this.textConditionFiltersEnabled,
    this.numberConditionFiltersEnabled,
    this.dateConditionFiltersEnabled,
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
    bool? neutralConditionFiltersEnabled,
    bool? textConditionFiltersEnabled,
    bool? numberConditionFiltersEnabled,
    bool? dateConditionFiltersEnabled,
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
      neutralConditionFiltersEnabled: neutralConditionFiltersEnabled ?? this.neutralConditionFiltersEnabled,
      textConditionFiltersEnabled: textConditionFiltersEnabled ?? this.textConditionFiltersEnabled,
      numberConditionFiltersEnabled: numberConditionFiltersEnabled ?? this.numberConditionFiltersEnabled,
      dateConditionFiltersEnabled: dateConditionFiltersEnabled ?? this.dateConditionFiltersEnabled,
    );
  }
}

class ErrorRow extends RowModel{
  @override
  bool operator == (dynamic other) => false;
  @override
  int get hashCode => -1;
  @override
  get id => throw UnimplementedError();
  @override
  List<Comparable> get values => throw UnimplementedError();
}


