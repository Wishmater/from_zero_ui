import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field_validators.dart';
import 'package:intl/intl.dart';
import 'package:from_zero_ui/src/field.dart';


class DateField extends Field<DateTime> {

  DateFormat formatter;
  DateTime firstDate;
  DateTime lastDate;

  set value(DateTime? v) {
    passedFirstEdit = true;
    super.value = v;
  }

  DateField({
    required FieldValueGetter<String, Field> uiNameGetter,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? value,
    DateTime? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter,
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter,
    double maxWidth = 512,
    DateFormat? formatter,
    FieldValueGetter<String?, Field>? hintGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<DateTime>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<DateTime?>? undoValues,
    List<DateTime?>? redoValues,
  }) :  this.firstDate = firstDate ?? DateTime(1900),
        this.lastDate = lastDate ?? DateTime(2200),
        this.formatter = formatter ?? DateFormat(DateFormat.YEAR_MONTH_DAY),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          enabledGetter: enabledGetter,
          maxWidth: maxWidth,
          hintGetter: hintGetter,
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
        );

  @override
  DateField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    DateTime? value,
    DateTime? dbValue,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    DateTime? firstDate,
    DateTime? lastDate,
    FieldValueGetter<String?, Field>? hintGetter,
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
  }) {
    return DateField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabledGetter: enabledGetter??this.enabledGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      firstDate: firstDate??this.firstDate,
      lastDate: lastDate??this.lastDate,
      hintGetter: hintGetter??this.hintGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? this.undoValues,
      redoValues: redoValues ?? this.redoValues,
    );
  }

  @override
  String toString() => value==null ? '' : formatter.format(value!);

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    expandToFillContainer: true,
    FocusNode? focusNode, /// unused
  }) {
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
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
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
  }) {
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        return Stack(
          children: [
            DatePickerFromZero(
              enabled: enabled,
              clearable: clearable,
              title: uiName,
              firstDate: firstDate,
              lastDate: lastDate,
              hint: hint,
              value: value,
              onSelected: (v) {value=v;},
              popupWidth: maxWidth,
              buttonChildBuilder: _buttonContentBuilder,
            ),
          ],
        );
      },
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
        child: result,
      );
    }
    result = Padding(
      key: fieldGlobalKey,
      padding: EdgeInsets.symmetric(horizontal: largeHorizontally ? 12 : 0),
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
            ValidationMessage(errors: validationErrors),
          ],
        ),
      ),
    );
    return result;
  }

  Widget _buttonContentBuilder(BuildContext context, String? title, String? hint, DateTime? value, formatter, bool enabled, bool clearable) {
    return Padding(
      padding: EdgeInsets.only(right: enabled&&clearable ? 40 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 8,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaterialKeyValuePair(
                  title: title,
                  padding: 6,
                  value: value==null ? (hint ?? '') : formatter.format(value),
                  valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                    height: 1,
                    color: value==null ? Theme.of(context).textTheme.caption!.color!
                        : Theme.of(context).textTheme.bodyText1!.color!,
                  ),
                ),
                SizedBox(height: 4,),
              ],
            ),
          ),
          SizedBox(width: 4,),
          if (enabled && !clearable)
            Icon(Icons.arrow_drop_down),
          SizedBox(width: !(enabled && clearable) ? 36 : 4,),
        ],
      ),
    );
  }

}