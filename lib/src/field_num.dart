import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:intl/intl.dart';


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
    required String uiName,
    num? value,
    num? dbValue,
    bool clearable = true,
    bool enabled = true,
    bool hidden = false,
    this.formatter,
    this.inputDecoration,
    this.digitsAfterComma = 0,
    double? maxWidth,
    String? hint,
    double? tableColumnWidth,
  }) :  controller = TextEditingController(text: toStringStatic(value, formatter)),
        super(
          uiName: uiName,
          value: value,
          dbValue: dbValue,
          clearable: clearable,
          enabled: enabled,
          hidden: hidden,
          hint: hint,
          maxWidth: 512, //768
          tableColumnWidth: tableColumnWidth,
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
    String? uiName,
    NumberFormat? formatter,
    num? value,
    num? dbValue,
    String? hint,
    bool? clearable,
    bool? enabled,
    bool? hidden,
    double? maxWidth,
    int? digitsAfterComma,
    double? tableColumnWidth,
  }) {
    return NumField(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearable: clearable??this.clearable,
      enabled: enabled??this.enabled,
      hidden: hidden??this.hidden,
      formatter: formatter??this.formatter,
      maxWidth: maxWidth??this.maxWidth,
      hint: hint??this.hint,
      digitsAfterComma: digitsAfterComma??this.digitsAfterComma,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
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
    bool autofocus = false,
  }) {
    Widget result;
    if (hidden) {
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
            autofocus: autofocus,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        autofocus: autofocus,
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
    bool autofocus = false,
  }) {
    Widget result = NotificationListener<ScrollNotification>(
      onNotification: (notification) => true,
      child: Stack(
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            autofocus: autofocus,
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
              child: Center(
                child: IconButton(
                  icon: Icon(Icons.close),
                  tooltip: FromZeroLocalizations.of(context).translate('clear'),
                  onPressed: () {
                    value = null;
                    controller.clear();
                  },
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

  @override
  SimpleColModel getColModel() {
    return SimpleColModel(
      name: uiName,
      filterEnabled: true, // TODO make actually good filters for values (range-picking)
      width: tableColumnWidth,
      alignment: TextAlign.right,
      defaultSortAscending: false,
    );
  }

}