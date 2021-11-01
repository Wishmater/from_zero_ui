import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/field_validators.dart';

enum StringFieldType {
  short,
  long,
}

class StringField extends Field<String> {

  TextEditingController controller;
  StringFieldType type;
  int? minLines;
  int? maxLines;
  InputDecoration? inputDecoration;
  List<TextInputFormatter>? inputFormatters;
  bool obfuscate;
  bool showObfuscationToggleButton; // TODO implement obfuscation toggle button

  set value(String? v) {
    super.value = v ?? '';
    if (value != controller.text) {
      controller.text = value ?? '';
    }
  }
  set dbValue(String? v) {
    super.dbValue = v ?? '';
  }

  StringField({
    required FieldValueGetter<String, Field> uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter,
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    this.type = StringFieldType.short,
    int? minLines,
    int? maxLines,
    this.obfuscate = false,
    bool? showObfuscationToggleButton,
    this.inputDecoration,
    this.inputFormatters,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<String?>? undoValues,
    List<String?>? redoValues,
  }) :  this.minLines = minLines ?? (type==StringFieldType.short ? null : 3),
        this.maxLines = maxLines ?? (type==StringFieldType.short ? 1 : 999999999),
        this.showObfuscationToggleButton = showObfuscationToggleButton ?? obfuscate,
        this.controller = TextEditingController(text: value),
        super(
          uiNameGetter: uiNameGetter,
          value: value ?? '',
          dbValue: dbValue ?? value ?? '',
          clearableGetter: clearableGetter,
          enabledGetter: enabledGetter,
          hintGetter: hintGetter,
          maxWidth: maxWidth ?? (type==StringFieldType.short ? 512 : 512), //768
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
  StringField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    StringFieldType? type,
    int? minLines,
    int? maxLines,
    InputDecoration? inputDecoration,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<String?>? undoValues,
    List<String?>? redoValues,
  }) {
    return StringField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabledGetter: enabledGetter??this.enabledGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      type: type??this.type,
      minLines: minLines??this.minLines,
      maxLines: maxLines??this.maxLines,
      inputDecoration: inputDecoration??this.inputDecoration,
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
            minLines: minLines,
            maxLines: minLines==null||minLines!<=(maxLines??0) ? maxLines : minLines,
            obscureText: obfuscate,
            onChanged: (v) {
              value = v;
            },
            inputFormatters: inputFormatters,
            decoration: inputDecoration??InputDecoration(
              labelText: uiName,
              hintText: hint,
              floatingLabelBehavior: hint==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
              labelStyle: TextStyle(height: largeVertically ? 0.75 : 0.2,
                color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!,
              ),
              hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
              contentPadding: EdgeInsets.only(top: 10, bottom: 8, right: enabled&&clearable ? 40 : 0),
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
                      if (value==null || value!.trim().isEmpty) {
                        return SizedBox.shrink();
                      } else {
                        return IconButton(
                          icon: Icon(Icons.close),
                          tooltip: FromZeroLocalizations.of(context).translate('clear'),
                          onPressed: () {
                            value = '';
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
        color: enabled ? null : Color.lerp(Theme.of(context).cardColor, Colors.black, 0.18),
        child: Padding(
          padding: EdgeInsets.only(left: 15, right: 15, bottom: largeVertically ? 6 : 0),
          child: result,
        ),
      );
    } else {
      result = Container(

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

}