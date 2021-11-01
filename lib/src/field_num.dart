import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field_validators.dart';
import 'package:intl/intl.dart';
import 'package:from_zero_ui/src/field.dart';


class NumField extends Field<num> {

  TextEditingController controller;
  NumberFormat? formatter;
  InputDecoration? inputDecoration;
  int digitsAfterComma;

  set value(num? v) {
    super.value = v;
    final textVal = _getTextVal(controller.text);
    if (value != textVal) {
      controller.text = toString();
    }
  }

  NumField({
    required FieldValueGetter<String, Field> uiNameGetter,
    num? value,
    num? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter,
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter,
    this.formatter,
    this.inputDecoration,
    this.digitsAfterComma = 0,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<num>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = numFieldDefaultGetColumn,
    List<num?>? undoValues,
    List<num?>? redoValues,
  }) :  controller = TextEditingController(text: toStringStatic(value, formatter)),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          enabledGetter: enabledGetter,
          hintGetter: hintGetter,
          maxWidth: 512, //768
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
  String toString() => toStringStatic(value, formatter);
  static String toStringStatic(num? value, NumberFormat? formatter) {
    return value==null  ? ''
                        : formatter==null ? value.toString()
                                          : formatter.format(value);
  }

  @override
  NumField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    NumberFormat? formatter,
    num? value,
    num? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    int? digitsAfterComma,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<num>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<num?>? undoValues,
    List<num?>? redoValues,
  }) {
    return NumField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabledGetter: enabledGetter??this.enabledGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      formatter: formatter??this.formatter,
      maxWidth: maxWidth??this.maxWidth,
      hintGetter: hintGetter??this.hintGetter,
      digitsAfterComma: digitsAfterComma??this.digitsAfterComma,
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

  num? _getTextVal(String? text) {
    num? textVal;
    try {
      textVal = formatter==null ? num.parse(text!)
          : formatter!.parse(text!);
    } catch(_) {}
    return textVal;
  }

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    FocusNode? focusNode,
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
            largeVertically: constraints.maxHeight>64,
            largeHorizontally: constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium,
            focusNode: focusNode,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
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
  FocusNode _focusNode = FocusNode();
  Widget _buildFieldEditorWidget(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeVertically = true,
    bool largeHorizontally = false,
    FocusNode? focusNode,
  }) {
    if (focusNode==null) {
      focusNode = _focusNode;
    }
    focusNode.addListener(() {
      if (!passedFirstEdit && !focusNode!.hasFocus) {
        passedFirstEdit = true;
        notifyListeners();
      }
    });
    Widget result = NotificationListener<ScrollNotification>(
      onNotification: (notification) => true,
      child: Stack(
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            focusNode: focusNode,
            onChanged: (v) {
              value = _getTextVal(v);
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(digitsAfterComma==0 ? (r'[0-9]') : (r'[0-9.]'))),],
            decoration: inputDecoration??InputDecoration(
              labelText: uiName,
              hintText: hint,
              floatingLabelBehavior: hint==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
              labelStyle: TextStyle(height: largeVertically ? 0.75 : 0.2),
              hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
              contentPadding: EdgeInsets.only(top: 8, bottom: 8, right: enabled&&clearable ? 40 : 0),
            ),
          ),
          if (enabled && clearable)
            Positioned(
              right: -4, top: 6, bottom: 0,
              child: ExcludeFocus(
                child: Center(
                  child: AnimatedBuilder(
                    animation: this,
                    builder: (context, child) {
                      if (value==null) {
                        return SizedBox.shrink();
                      } else {
                        return IconButton(
                          icon: Icon(Icons.close),
                          tooltip: FromZeroLocalizations.of(context).translate('clear'),
                          onPressed: () {
                            value = null;
                            controller.clear();
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (addCard) {
      result = Card(
        child: Padding(
          padding: EdgeInsets.only(left: 15, right: 15, bottom: largeVertically ? 6 : 0),
          child: result,
        ),
      );
    }
    return Padding(
      key: fieldGlobalKey,
      padding: EdgeInsets.symmetric(horizontal: largeHorizontally ? 12 : 0),
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            result,
            ValidationMessage(errors: validationErrors),
          ],
        ),
      ),
    );
  }

  static SimpleColModel numFieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      width: field.tableColumnWidth,
      alignment: TextAlign.right,
      defaultSortAscending: false,
    );
  }

}