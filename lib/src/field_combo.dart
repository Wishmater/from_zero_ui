import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';


class ComboField<T extends DAO> extends Field<T> {

  final List<T>? possibleValues;
  final Future<List<T>>? futurePossibleValues;
  final bool showSearchBox;
  final ExtraWidgetBuilder<T>? extraWidget;

  ComboField({
    required String uiName,
    T? value,
    T? dbValue,
    bool clearable = true,
    bool enabled = true,
    bool hidden = false,
    double maxWidth = 512,
    String? hint,
    this.possibleValues,
    this.futurePossibleValues,
    this.showSearchBox = true,
    this.extraWidget,
    double? tableColumnWidth,
  }) :  assert(possibleValues!=null || futurePossibleValues!=null),
        super(
          uiName: uiName,
          value: value,
          dbValue: dbValue,
          clearable: clearable,
          enabled: enabled,
          hidden: hidden,
          maxWidth: maxWidth,
          hint: hint,
          tableColumnWidth: tableColumnWidth,
        );

  @override
  ComboField copyWith({
    String? uiName,
    T? value,
    T? dbValue,
    bool? clearable,
    bool? enabled,
    bool? hidden,
    double? maxWidth,
    List<T>? possibleValues,
    Future<List<T>>? futurePossibleValues,
    String? hint,
    bool? showSearchBox,
    ExtraWidgetBuilder<T>? extraWidget,
    double? tableColumnWidth,
  }) {
    return ComboField(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearable: clearable??this.clearable,
      enabled: enabled??this.enabled,
      hidden: hidden??this.hidden,
      maxWidth: maxWidth??this.maxWidth,
      possibleValues: possibleValues??this.possibleValues,
      futurePossibleValues: futurePossibleValues??this.futurePossibleValues,
      hint: hint??this.hint,
      showSearchBox: showSearchBox??this.showSearchBox,
      extraWidget: extraWidget??this.extraWidget,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
    );
  }

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    expandToFillContainer: true,
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
        return ComboFromZero<T>(
          enabled: enabled,
          clearable: clearable,
          title: uiName,
          hint: hint,
          value: value,
          possibleValues: possibleValues,
          futurePossibleValues: futurePossibleValues,
          showSearchBox: showSearchBox,
          onSelected: _onSelected,
          popupWidth: maxWidth,
          buttonChildBuilder: _buttonContentBuilder,
          extraWidget: extraWidget,
          // autofocus: autofocus, //TODO implement autofocus in ComboFromZero
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
      padding: EdgeInsets.symmetric(horizontal: largeHorizontally ? 12 : 0),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          height: 64,
          child: result,
        ),
      ),
    );
    return result;
  }

  bool? _onSelected(T? v) {
    value = v;
  }

  Widget _buttonContentBuilder(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable) {
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
                  value: value==null ? (hint ?? '') : value.toString(),
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