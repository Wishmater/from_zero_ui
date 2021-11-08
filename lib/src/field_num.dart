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
    this.formatter,
    this.inputDecoration,
    this.digitsAfterComma = 0,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
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
          hintGetter: hintGetter,
          tooltipGetter: tooltipGetter,
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
    FieldValueGetter<String?, Field>? tooltipGetter,
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
      clearableGetter: clearableGetter??this.clearableGetter,
      formatter: formatter??this.formatter,
      maxWidth: maxWidth??this.maxWidth,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
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
            largeVertically: false,
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
        largeVertically: false,
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
    bool largeVertically = false,
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
    Widget result = NotificationListener(
      onNotification: (notification) => true,
      child: AnimatedBuilder(
        animation: this,
        builder: (context, child) {
          Widget result = Stack(
            fit: largeVertically ? StackFit.loose : StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: largeVertically ? 16 : 0, top: largeVertically ? 12 : 2,),
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  focusNode: focusNode,
                  onChanged: (v) {
                    value = _getTextVal(v);
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(digitsAfterComma==0 ? (r'[0-9]') : (r'[0-9.]'))),],
                  decoration: inputDecoration??InputDecoration(
                    border: InputBorder.none,
                    labelText: uiName,
                    hintText: hint,
                    floatingLabelBehavior: enabled&&hint==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
                    labelStyle: TextStyle(height: largeVertically ? 0.75 : 1.85,
                      color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                    ),
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
                    contentPadding: EdgeInsets.only(
                      left: 16,
                      right: enabled&&clearable ? 16+40 : 16,
                    ),
                  ),
                ),
              ),
              if (enabled && clearable)
                Positioned(
                  right: 8, top: 0, bottom: 0,
                  child: ExcludeFocus(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: value!=null ? IconButton(
                          icon: Icon(Icons.close),
                          tooltip: FromZeroLocalizations.of(context).translate('clear'),
                          splashRadius: 20,
                          onPressed: () {
                            value = null;
                            controller.clear();
                          },
                        ) : SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              if (!enabled)
                Positioned.fill(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.forbidden,
                  ),
                ),
            ],
          );
          result = TooltipFromZero(
            message: validationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
              return a.toString().trim().isEmpty ? b.toString()
                  : b.toString().trim().isEmpty ? a.toString()
                  : '$a\n$b';
            }),
            child: result,
            triggerMode: enabled ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
            waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
          );
          return result;
        },
      ),
    );
    if (addCard) {
      result = Card(
        color: enabled ? null : Theme.of(context).canvasColor,
        child: result,
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
            SizedBox(
              height: largeVertically ? null : 64,
              child: result,
            ),
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