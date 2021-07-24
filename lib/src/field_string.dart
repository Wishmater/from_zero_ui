import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';

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
    required String uiName,
    String? value,
    String? dbValue,
    bool clearable = true,
    bool enabled = true,
    double? maxWidth,
    String? hint,
    this.type = StringFieldType.short,
    int? minLines,
    int? maxLines,
    this.inputDecoration,
    this.inputFormatters,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
  }) :  minLines = minLines ?? (type==StringFieldType.short ? null : 3),
        maxLines = maxLines ?? (type==StringFieldType.short ? 1 : 999999999),
        controller = TextEditingController(text: value),
        super(
          uiName: uiName,
          value: value ?? '',
          dbValue: dbValue ?? value ?? '',
          clearable: clearable,
          enabled: enabled,
          hint: hint,
          maxWidth: maxWidth ?? (type==StringFieldType.short ? 512 : 512), //768
          tableColumnWidth: tableColumnWidth,
          hidden: hidden,
          hiddenInTable: hiddenInTable,
          hiddenInView: hiddenInView,
          hiddenInForm: hiddenInForm,
        );


  @override
  StringField copyWith({
    String? uiName,
    String? value,
    String? dbValue,
    String? hint,
    bool? clearable,
    bool? enabled,
    double? maxWidth,
    StringFieldType? type,
    int? minLines,
    int? maxLines,
    InputDecoration? inputDecoration,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
  }) {
    return StringField(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearable: clearable??this.clearable,
      enabled: enabled??this.enabled,
      maxWidth: maxWidth??this.maxWidth,
      type: type??this.type,
      minLines: minLines??this.minLines,
      maxLines: maxLines??this.maxLines,
      inputDecoration: inputDecoration??this.inputDecoration,
      hint: hint??this.hint,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTable: hiddenInTable ?? hidden ?? this.hiddenInTable,
      hiddenInView: hiddenInView ?? hidden ?? this.hiddenInView,
      hiddenInForm: hiddenInForm ?? hidden ?? this.hiddenInForm,
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
  Widget _buildFieldEditorWidget(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeVertically = true,
    bool largeHorizontally = false,
    FocusNode? focusNode,
  }) {
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
            onChanged: (v) {
              value = v;
            },
            inputFormatters: inputFormatters,
            decoration: inputDecoration??InputDecoration(
              labelText: uiName,
              hintText: hint,
              floatingLabelBehavior: hint==null ? FloatingLabelBehavior.auto : FloatingLabelBehavior.always,
              labelStyle: TextStyle(height: largeVertically ? 0.75 : 0.2),
              hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
              contentPadding: EdgeInsets.only(top: 10, bottom: 8, right: enabled&&clearable ? 40 : 0),
            ),
          ),
          if (enabled && clearable)
            Positioned(
              right: -4, top: 6, bottom: 0,
              child: ExcludeFocus(
                child: Center(
                  child: IconButton(
                    icon: Icon(Icons.close),
                    tooltip: FromZeroLocalizations.of(context).translate('clear'),
                    onPressed: () {
                      value = '';
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
      padding: EdgeInsets.symmetric(horizontal: largeHorizontally ? 12 : 0),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: result,
        ),
      ),
    );
  }

}