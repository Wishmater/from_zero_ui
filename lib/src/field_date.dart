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
    required String uiName,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? value,
    DateTime? dbValue,
    bool clearable = true,
    bool enabled = true,
    double maxWidth = 512,
    DateFormat? formatter,
    String? hint,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    List<FieldValidator<DateTime>> validators = const[],
    bool validateOnlyOnConfirm = false,
  }) :  this.firstDate = firstDate ?? DateTime(1900),
        this.lastDate = lastDate ?? DateTime(2200),
        this.formatter = formatter ?? DateFormat(DateFormat.YEAR_MONTH_DAY),
        super(
          uiName: uiName,
          value: value,
          dbValue: dbValue,
          clearable: clearable,
          enabled: enabled,
          maxWidth: maxWidth,
          hint: hint,
          tableColumnWidth: tableColumnWidth,
          hidden: hidden,
          hiddenInTable: hiddenInTable,
          hiddenInView: hiddenInView,
          hiddenInForm: hiddenInForm,
          validators: validators,
          validateOnlyOnConfirm: validateOnlyOnConfirm,
        );

  @override
  DateField copyWith({
    String? uiName,
    DateTime? value,
    DateTime? dbValue,
    bool? clearable,
    bool? enabled,
    double? maxWidth,
    DateTime? firstDate,
    DateTime? lastDate,
    String? hint,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    List<FieldValidator<DateTime>>? validators,
    bool? validateOnlyOnConfirm,
  }) {
    return DateField(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearable: clearable??this.clearable,
      enabled: enabled??this.enabled,
      maxWidth: maxWidth??this.maxWidth,
      firstDate: firstDate??this.firstDate,
      lastDate: lastDate??this.lastDate,
      hint: hint??this.hint,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTable: hiddenInTable ?? hidden ?? this.hiddenInTable,
      hiddenInView: hiddenInView ?? hidden ?? this.hiddenInView,
      hiddenInForm: hiddenInForm ?? hidden ?? this.hiddenInForm,
      validators: validators ?? this.validators,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
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
    Widget result = ChangeNotifierBuilder(
      changeNotifier: this,
      builder: (context, v, child) {
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
      child: Center(
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
              if (validationErrors.isNotEmpty)
                ValidationMessage(errors: validationErrors),
            ],
          ),
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