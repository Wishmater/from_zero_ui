import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/comparable_list.dart';


typedef ShowFilterPopupCallback = Future<bool> Function({
  required BuildContext context,
  required dynamic colKey,
  required ColModel? col,
  required ValueNotifier<Map<dynamic, List<dynamic>>?> availableFilters,
  required Map<dynamic, List<ConditionFilter>> conditionFilters,
  required Map<dynamic, Map<Object?, bool>> valueFilters,
  GlobalKey? anchorKey,
});



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


abstract class RowModel<T> {
  T get id;
  Key? get rowKey => null;
  Map get values;
  Color? get backgroundColor => null;
  TextStyle? get textStyle => null;
  double? get height => 36;
  bool? get selected => null;
  ValueChanged<RowModel<T>>? get onRowTap => null;
  ValueChanged<RowModel<T>>? get onRowDoubleTap => null;
  ValueChanged<RowModel<T>>? get onRowLongPress => null;
  OnRowHoverCallback? get onRowHover => null;
  OnCellTapCallback? get onCellTap => null;
  OnCellTapCallback? get onCellDoubleTap => null;
  OnCellTapCallback? get onCellLongPress => null;
  OnCellHoverCallback? get onCellHover => null;
  OnCheckBoxSelectedCallback? get onCheckBoxSelected => null;
  Widget? get rowAddon => null;
  bool? get rowAddonIsCoveredByGestureDetector => null;
  bool? get rowAddonIsCoveredByBackground => null;
  bool? get rowAddonIsCoveredByScrollable => null;
  bool get rowAddonIsExpandable => false;
  bool? get rowAddonIsSticky => null;
  bool? get rowAddonIsAboveRow => null;
  bool? get alwaysOnTop => null;
  List<RowModel<T>> get children;
  bool expanded;
  int depth;
  late FocusNode focusNode = FocusNode();

  RowModel({
    this.expanded = false,
    this.depth = 0,
  });
  @override
  bool operator == (dynamic other) => other is RowModel && this.id==other.id;
  @override
  int get hashCode => id.hashCode;

  bool get isExpandable => children.isNotEmpty || (rowAddon!=null && rowAddonIsExpandable);
  List<RowModel<T>> get visibleRows => [this, if (expanded) ...children.map((e) => e.visibleRows).flatten()];
  List<RowModel<T>> get allRows => [this, ...children.map((e) => e.allRows).flatten()];
  int get length => 1 + (expanded ? children.sumBy((e) => e.length) : 0);
  void calculateDepth() {
    for (final e in children) {
      e.depth = depth+1;
      e.calculateDepth();
    }
  }
}
///The widget assumes columns will be constant, so bugs may happen when changing columns
abstract class ColModel<T>{
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
  bool Function(RowModel<T> row)? get rowCountSelector;
  ShowFilterPopupCallback? get showFilterPopupCallback;

  Object? getValue(RowModel row, dynamic key) {
    return row.values[key];
  }
  String getValueString(RowModel row, dynamic key) {
    final value = getValue(row, key);
    if (value is List || value is ComparableList) {
      final List list = value is List ? value
          : value is ComparableList ? value.list : [];
      return ListField.listToStringAll(list);
    } else {
      return value!=null ? value.toString() : "";
    }
  }
  String getSubtitleText(BuildContext context, List<RowModel<T>>? filtered) {
    if (filtered==null) {
      return '';
    } else {
      final count = rowCountSelector==null
          ? filtered.length
          : filtered.where((e) => rowCountSelector!(e)).length;
      return count==0 ? FromZeroLocalizations.of(context).translate('no_elements')
          : '$count ${count>1 ? FromZeroLocalizations.of(context).translate('element_plur')
          : FromZeroLocalizations.of(context).translate('element_sing')}';
    }
  }
  Widget? buildSortedIcon(BuildContext context, bool ascending) => null;
  List<ConditionFilter> getAvailableConditionFilters() => [
    // FilterIsEmpty(),
    // FilterTextExactly(),
    FilterTextContains(),
    FilterTextStartsWith(),
    FilterTextEndsWith(),
    // FilterNumberEqualTo(),
    // FilterNumberGreaterThan(),
    // FilterNumberLessThan(),
    // FilterDateExactDay(),
    // FilterDateAfter(),
    // FilterDateBefore(),
  ];
}

class SimpleRowModel<T> extends RowModel<T> {
  T id;
  Key? rowKey;
  Map values;
  Color? backgroundColor;
  TextStyle? textStyle;
  double? height;
  bool? selected;
  ValueChanged<RowModel<T>>? onRowTap;
  ValueChanged<RowModel<T>>? onRowDoubleTap;
  ValueChanged<RowModel<T>>? onRowLongPress;
  OnRowHoverCallback? onRowHover;
  OnCellTapCallback? onCellTap;
  OnCellTapCallback? onCellDoubleTap;
  OnCellTapCallback? onCellLongPress;
  OnCellHoverCallback? onCellHover;
  OnCheckBoxSelectedCallback? onCheckBoxSelected;
  Widget? rowAddon;
  bool? rowAddonIsCoveredByGestureDetector;
  bool? rowAddonIsCoveredByBackground;
  bool? rowAddonIsCoveredByScrollable;
  bool? rowAddonIsSticky;
  bool rowAddonIsExpandable;
  bool? rowAddonIsAboveRow;
  bool? alwaysOnTop;
  List<RowModel<T>> children;
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
    this.rowAddon,
    this.rowAddonIsCoveredByGestureDetector,
    this.rowAddonIsCoveredByBackground,
    this.rowAddonIsCoveredByScrollable,
    this.rowAddonIsSticky,
    this.rowAddonIsExpandable = false,
    this.rowAddonIsAboveRow,
    this.alwaysOnTop,
    this.onCellTap,
    this.onCellDoubleTap,
    this.onCellLongPress,
    this.onCellHover,
    this.children = const [],
    super.expanded = false,
    super.depth = 0,
  });
  SimpleRowModel copyWith({
    T? id,
    Key? rowKey,
    Map? values,
    Color? backgroundColor,
    TextStyle? textStyle,
    double? height,
    bool? selected,
    ValueChanged<RowModel<T>>? onRowTap,
    ValueChanged<RowModel<T>>? onRowDoubleTap,
    ValueChanged<RowModel<T>>? onRowLongPress,
    OnRowHoverCallback? onRowHover,
    OnCheckBoxSelectedCallback? onCheckBoxSelected,
    Widget? rowAddon,
    bool? rowAddonIsCoveredByGestureDetector,
    bool? rowAddonIsCoveredByBackground,
    bool? rowAddonIsCoveredByScrollable,
    bool? rowAddonIsSticky,
    bool? rowAddonIsExpandable,
    bool? rowAddonIsAboveRow,
    bool? alwaysOnTop,
    OnCellTapCallback? onCellTap,
    OnCellTapCallback? onCellDoubleTap,
    OnCellTapCallback? onCellLongPress,
    OnCellHoverCallback? onCellHover,
    List<RowModel<T>>? children,
    bool? expanded,
    int? depth,
  }) {
    return SimpleRowModel<T>(
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
      rowAddon: rowAddon ?? this.rowAddon,
      rowAddonIsCoveredByGestureDetector: rowAddonIsCoveredByGestureDetector ?? this.rowAddonIsCoveredByGestureDetector,
      rowAddonIsCoveredByBackground: rowAddonIsCoveredByBackground ?? this.rowAddonIsCoveredByBackground,
      rowAddonIsCoveredByScrollable: rowAddonIsCoveredByScrollable ?? this.rowAddonIsCoveredByScrollable,
      rowAddonIsSticky: rowAddonIsSticky ?? this.rowAddonIsSticky,
      rowAddonIsAboveRow: rowAddonIsAboveRow ?? this.rowAddonIsAboveRow,
      onCellTap: onCellTap ?? this.onCellTap,
      onCellDoubleTap: onCellDoubleTap ?? this.onCellDoubleTap,
      onCellLongPress: onCellLongPress ?? this.onCellLongPress,
      onCellHover: onCellHover ?? this.onCellHover,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      rowAddonIsExpandable: rowAddonIsExpandable ?? this.rowAddonIsExpandable,
      children: children ?? this.children,
      expanded: expanded ?? this.expanded,
      depth: depth ?? this.depth,
    );
  }
}
class SimpleColModel<T> extends ColModel<T>{
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
  bool Function(RowModel<T> row)? rowCountSelector;
  ShowFilterPopupCallback? showFilterPopupCallback;
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
    this.rowCountSelector,
    this.showFilterPopupCallback,
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
    bool Function(RowModel<T> row)? rowCountSelector,
    ShowFilterPopupCallback? showFilterPopupCallback,
  }){
    return SimpleColModel<T>(
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
      rowCountSelector: rowCountSelector ?? this.rowCountSelector,
      showFilterPopupCallback: showFilterPopupCallback ?? this.showFilterPopupCallback,
    );
  }
}


