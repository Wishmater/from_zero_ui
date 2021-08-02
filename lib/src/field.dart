import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/table_from_zero_models.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';
import 'package:from_zero_ui/src/util.dart';

typedef String? FieldValidator<T extends Comparable>(BuildContext context, DAO dao, Field<T> field);

class Field<T extends Comparable> extends ChangeNotifier implements Comparable, ContainsValue {

  GlobalKey fieldGlobalKey;
  String uiName;
  String? hint;
  T? dbValue;
  bool clearable;
  bool enabled;
  bool hiddenInTable;
  bool hiddenInView;
  bool hiddenInForm;
  double maxWidth;
  FocusNode? focusNode;
  double? tableColumnWidth;
  List<FieldValidator<T>> validators;
  bool validateOnlyOnConfirm;
  bool passedFirstEdit = false;
  List<String> validationErrors = [];

  T? _value;
  T? get value => _value;
  set value(T? value) {
    if (_value!=value) {
      _value = value;
      notifyListeners();
    }
  }

  Field({
    required this.uiName,
    T? value,
    T? dbValue,
    this.enabled = true,
    this.clearable = true,
    this.maxWidth = 512,
    this.hint,
    this.focusNode,
    this.tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    this.validators = const [],
    this.validateOnlyOnConfirm = false,
    GlobalKey? fieldGlobalKey,
  }) :  _value = value,
        dbValue = dbValue ?? value,
        this.fieldGlobalKey = fieldGlobalKey ?? GlobalKey(),
        this.hiddenInTable = hiddenInTable ?? hidden ?? false,
        this.hiddenInView = hiddenInView ?? hidden ?? false,
        this.hiddenInForm = hiddenInForm ?? hidden ?? false;


  Field copyWith({
    String? uiName,
    T? value,
    T? dbValue,
    bool? enabled,
    bool? clearable,
    double? maxWidth,
    String? hint,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    List<FieldValidator<T>>? validators,
    bool? validateOnlyOnConfirm,
  }) {
    return Field<T>(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabled: enabled??this.enabled,
      clearable: clearable??this.clearable,
      maxWidth: maxWidth??this.maxWidth,
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
  String toString() => value==null ? '' : value.toString();

  @override
  bool operator == (dynamic other) => other is Field<T> && this.value==other.value;

  @override
  int get hashCode => value.hashCode;

  bool get isEditted => value!=dbValue;

  @override
  int compareTo(other) => other is Field ? value==null||(value is String && (value as String).isEmpty) ? 1 : value!.compareTo(other.value) : 1;

  void revertChanges() {
    value = dbValue;
    notifyListeners();
  }

  bool validate(BuildContext context, DAO dao) {
    if (hiddenInForm) {
      return true;
    }
    validationErrors = [];
    validators.forEach((e) {
      String? error = e(context, dao, this);
      if (error!=null) {
        validationErrors.add(error);
      }
    });
    return validationErrors.isEmpty;
  }

  SimpleColModel getColModel() {
    return SimpleColModel(
      name: uiName,
      filterEnabled: true,
      width: tableColumnWidth,
    );
  }



  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard = false,
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
    result = ListTile(
      leading: Icon(Icons.error_outline),
      title: Text('Unimplemented Widget for type: ${T.toString()}'),
    );
    if (addCard) {
      result = Card(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12,),
          child: result,
        ),
      );
    }
    result = ResponsiveHorizontalInsets(
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: result,
        ),
      ),
    );
    if (asSliver) {
      result = SliverToBoxAdapter(
        child: result,
      );
    }
    return [result];
  }

  Widget buildViewWidget(BuildContext context, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=true,
  }) {
    if (hiddenInView) {
      return SizedBox.shrink();
    }
    return InkWell(
      onTap: linkToInnerDAOs&&(value is DAO) ? ()=>(value as DAO).pushViewDialog(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            // TODO this probably wont do well on a mobile layout
            Expanded(
              flex: 1000000,
              child: Text(uiName,
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Container(
              height: 24,
              child: VerticalDivider(width: 16,),
            ),
            Expanded(
              flex: 1618034,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(toString(),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                  if (showViewButtons && (value is DAO))
                    IconButton(
                      icon: Icon(Icons.remove_red_eye),
                      padding: EdgeInsets.all(0),
                      constraints: BoxConstraints(maxHeight: 32),
                      onPressed: () => (value as DAO).pushViewDialog(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}