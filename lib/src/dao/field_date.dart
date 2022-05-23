import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';
import 'package:from_zero_ui/util/my_tooltip.dart';
import 'package:intl/intl.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:dartx/dartx.dart';


class DateField extends Field<DateTime> {

  final DateFormat formatter;
  final DateTime firstDate;
  final DateTime lastDate;


  DateField({
    required FieldValueGetter<String, Field> uiNameGetter,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? value,
    DateTime? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = Field.defaultClearableGetter,
    double maxWidth = 512,
    double minWidth = 128,
    double flex = 0,
    DateFormat? formatter,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<DateTime>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = DateField.dateFieldDefaultGetColumn,
    List<DateTime?>? undoValues,
    List<DateTime?>? redoValues,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    DateTime? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<DateTime> viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    OnFieldValueChanged<DateTime?>? onValueChanged,
  }) :  this.firstDate = firstDate ?? DateTime(1900),
        this.lastDate = lastDate ?? DateTime(2200),
        this.formatter = formatter ?? DateFormat(DateFormat.YEAR_MONTH_DAY),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          maxWidth: maxWidth,
          minWidth: minWidth,
          flex: flex,
          hintGetter: hintGetter,
          tooltipGetter: tooltipGetter,
          tableColumnWidth: tableColumnWidth,
          hiddenGetter: hiddenGetter,
          hiddenInTableGetter: hiddenInTableGetter,
          hiddenInViewGetter: hiddenInViewGetter,
          hiddenInFormGetter: hiddenInFormGetter,
          validatorsGetter: validatorsGetter,
          validateOnlyOnConfirm: validateOnlyOnConfirm,
          colModelBuilder: colModelBuilder,
          undoValues: undoValues,
          redoValues: redoValues,
          fieldGlobalKey: fieldGlobalKey ?? GlobalKey(),
          focusNode: focusNode ?? FocusNode(),
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue,
          backgroundColor: backgroundColor,
          actions: actions,
          viewWidgetBuilder: viewWidgetBuilder,
          onValueChanged: onValueChanged,
        );

  @override
  DateField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    DateTime? value,
    DateTime? dbValue,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    DateTime? firstDate,
    DateTime? lastDate,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<DateTime>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<DateTime?>? undoValues,
    List<DateTime?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    DateTime? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<DateTime>? viewWidgetBuilder,
    OnFieldValueChanged<DateTime?>? onValueChanged,
  }) {
    return DateField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      firstDate: firstDate??this.firstDate,
      lastDate: lastDate??this.lastDate,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? List.from(this.undoValues),
      redoValues: redoValues ?? List.from(this.redoValues),
      invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm ?? this.invalidateNonEmptyValuesIfHiddenInForm,
      defaultValue: defaultValue ?? this.defaultValue,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actions: actions ?? this.actions,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
    );
  }

  @override
  String toString() => value==null ? '' : formatter.format(value!);

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    expandToFillContainer: true,
    bool dense = false,
    FocusNode? focusNode,
    ScrollController? mainScrollController,
  }) {
    if (focusNode==null) {
      focusNode = this.focusNode;
    }
    Widget result;
    if (hiddenInForm) {
      result = SizedBox.shrink();
      if (asSliver) {
        result = SliverToBoxAdapter(child: result,);
      }
      return [result];
    }
    if (expandToFillContainer) {
      result = LayoutBuilder(
        builder: (context, constraints) {
          return _buildFieldEditorWidget(context,
            addCard: addCard,
            asSliver: asSliver,
            expandToFillContainer: expandToFillContainer,
            largeHorizontally: constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium,
            dense: dense,
            focusNode: focusNode!,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
      );
    }
    if (asSliver) {
      result = SliverToBoxAdapter(
        child: result,
      );
    }
    return [result];
  }
  Widget _buildFieldEditorWidget(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeHorizontally = false,
    bool dense = false,
    required FocusNode focusNode,
  }) {
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        Widget result = DatePickerFromZero(
          focusNode: focusNode,
          enabled: enabled,
          clearable: clearable,
          title: uiName,
          firstDate: firstDate,
          lastDate: lastDate,
          hint: hint,
          value: value,
          onSelected: (v) {value=v;},
          popupWidth: maxWidth,
          buttonPadding: dense ? EdgeInsets.zero : null,
          formatter: formatter,
          buttonChildBuilder: (context, title, hint, value, formatter, enabled, clearable) {
            return _buttonContentBuilder(context, title, hint, value, formatter, enabled, clearable,
              dense: dense,
            );
          },
        );
        result = AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: dense && validationErrors.isNotEmpty
              ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
              : backgroundColor?.call(context, this, dao),
          curve: Curves.easeOut,
          child: result,
        );
        result = TooltipFromZero(
          message: validationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
            return a.toString().trim().isEmpty ? b.toString()
                : b.toString().trim().isEmpty ? a.toString()
                : '$a\n$b';
          }),
          child: result,
          triggerMode: enabled ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
          waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
        );
        final actions = this.actions?.call(context, this, dao) ?? [];
        final defaultActions = buildDefaultActions(context);
        result = ContextMenuFromZero(
          enabled: enabled,
          addGestureDetector: !dense,
          onShowMenu: () => focusNode.requestFocus(),
          actions: [
            ...actions,
            if (actions.isNotEmpty && defaultActions.isNotEmpty)
              ActionFromZero.divider(),
            ...defaultActions,
          ],
          child: result,
        );
        return result;
      },
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
        color: enabled ? null : Theme.of(context).canvasColor,
        child: result,
      );
    }
    result = EnsureVisibleWhenFocused(
      focusNode: focusNode,
      child: Padding(
        key: fieldGlobalKey,
        padding: EdgeInsets.symmetric(horizontal: !dense && largeHorizontally ? 12 : 0),
        child: SizedBox(
          width: maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 64,
                child: result,
              ),
              if (!dense)
                ValidationMessage(errors: validationErrors),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  Widget _buttonContentBuilder(BuildContext context, String? title, String? hint, DateTime? value, formatter, bool enabled, bool clearable, {
    dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: enabled&&clearable ? 40 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: dense ? 0 : 8,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dense
                    ? Text(value==null ? (hint ?? title ?? '') : formatter.format(value), style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 0.8,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ))
                : value==null&&hint==null&&title!=null
                    ? Text(title, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                    ),)
                    : MaterialKeyValuePair(
                      padding: 6,
                      title: title,
                      titleStyle: Theme.of(context).textTheme.caption!.copyWith(
                        color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                      ),
                      value: value==null ? (hint ?? '') : formatter.format(value),
                      valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ),
                    ),
                SizedBox(height: 4,),
              ],
            ),
          ),
          // SizedBox(width: dense ? 0 : 4,),
          // if (!dense && enabled && !clearable)
          //   Icon(Icons.arrow_drop_down),
          SizedBox(width: dense ? 0 : 4,),
        ],
      ),
    );
  }

  static SimpleColModel dateFieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      defaultSortAscending: false,
      flex: field.tableColumnWidth?.round() ?? 192,
    );
  }

}