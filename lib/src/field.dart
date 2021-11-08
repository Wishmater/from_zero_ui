import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field_validators.dart';
import 'package:from_zero_ui/src/table_from_zero_models.dart';
import 'package:from_zero_ui/src/ui_utility_widgets.dart';
import 'package:from_zero_ui/src/util.dart';
import 'package:dartx/dartx.dart';

typedef ValidationError? FieldValidator<T extends Comparable>(BuildContext context, DAO dao, Field<T> field);
typedef T FieldValueGetter<T, R extends Field>(R field, DAO dao);
bool trueFieldGetter(_, __) => true;
bool falseFieldGetter(_, __) => false;
List defaultValidatorsGetter(_, __) => [];

class Field<T extends Comparable> extends ChangeNotifier implements Comparable, ContainsValue {

  late DAO dao;
  GlobalKey fieldGlobalKey;
  FieldValueGetter<String, Field> uiNameGetter;
  String get uiName => uiNameGetter(this, dao);
  FieldValueGetter<String?, Field>? hintGetter;
  String? get hint => hintGetter?.call(this, dao);
  FieldValueGetter<String?, Field>? tooltipGetter;
  String? get tooltip => tooltipGetter?.call(this, dao);
  T? dbValue;
  FieldValueGetter<bool, Field> clearableGetter;
  bool get clearable => clearableGetter(this, dao);
  bool get enabled => validationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling).isEmpty;
  FieldValueGetter<bool, Field> hiddenInTableGetter;
  bool get hiddenInTable => hiddenInTableGetter(this, dao);
  FieldValueGetter<bool, Field> hiddenInViewGetter;
  bool get hiddenInView => hiddenInViewGetter(this, dao);
  FieldValueGetter<bool, Field> hiddenInFormGetter;
  bool get hiddenInForm => hiddenInFormGetter(this, dao);
  double maxWidth;
  FocusNode? focusNode;
  double? tableColumnWidth;
  FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter;
  List<FieldValidator<T>> get validators => validatorsGetter?.call(this, dao) ?? [];
  bool validateOnlyOnConfirm;
  bool passedFirstEdit = false;
  List<ValidationError> validationErrors = [];
  FieldValueGetter<SimpleColModel, Field> colModelBuilder;

  T? _value;
  T? get value => _value;
  set value(T? value) {
    if (_value!=value) {
      passedFirstEdit = true;
      undoValues.add(_value); // TODO 1 Fields that override value setter must override undo logic as well (important on textfields)
      dao.undoRecord.add(this);
      redoValues = [];
      dao.redoRecord = []; // dao.redoRecord.removeWhere((e) => e==this);
      _value = value;
      notifyListeners();
    }
  }
  List<T?> undoValues;
  List<T?> redoValues;

  Field({
    required this.uiNameGetter,
    T? value,
    T? dbValue,
    this.clearableGetter = trueFieldGetter,
    this.maxWidth = 512,
    this.hintGetter,
    this.tooltipGetter,
    this.focusNode,
    this.tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.validatorsGetter,
    this.validateOnlyOnConfirm = false,
    GlobalKey? fieldGlobalKey,
    this.colModelBuilder = fieldDefaultGetColumn,
    List<T?>? undoValues,
    List<T?>? redoValues,
    bool invalidateNotNullValuesIfHiddenInForm = true,  // TODO 1 implement on each field, override if necessary
  }) :  _value = value,
        dbValue = dbValue ?? value,
        undoValues = undoValues ?? [],
        redoValues = redoValues ?? [],
        this.fieldGlobalKey = fieldGlobalKey ?? GlobalKey(),
        this.hiddenInTableGetter = hiddenInTableGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInViewGetter = hiddenInViewGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInFormGetter = hiddenInFormGetter ?? hiddenGetter ?? falseFieldGetter;


  Field copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<T?>? undoValues,
    List<T?>? redoValues,
  }) {
    return Field<T>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
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
  String toString() => value==null ? '' : value.toString();

  @override
  bool operator == (dynamic other) => other is Field<T> && this.value==other.value;

  @override
  int get hashCode => value.hashCode;

  bool get isEdited => value!=dbValue;

  @override
  int compareTo(other) => other is Field ? value==null||(value is String && (value as String).isEmpty) ? 1 : other.value==null ? -1 : value!.compareTo(other.value) : 1;

  void revertChanges() {
    value = dbValue;
    undoValues = [];
    dao.undoRecord.removeWhere((e) => e==this);
    redoValues = [];
    dao.redoRecord.removeWhere((e) => e==this);
    notifyListeners();
  }

  void undo() {
    assert(undoValues.isNotEmpty);
    redoValues.add(value);
    dao.redoRecord.add(this);
    _value = undoValues.removeLast();
    dao.undoRecord.removeAt(dao.undoRecord.lastIndexOf(this));
    notifyListeners();
  }

  void redo() {
    assert(redoValues.isNotEmpty);
    undoValues.add(value);
    dao.undoRecord.add(this);
    _value = redoValues.removeLast();
    dao.redoRecord.removeAt(dao.redoRecord.lastIndexOf(this));
    notifyListeners();
  }

  Future<bool> validate(BuildContext context, DAO dao, {
    bool validateIfNotEdited=false,
  }) async {
    validationErrors = [];
    if (hiddenInForm) {
      return true;
    }
    if (validateIfNotEdited) {
      passedFirstEdit = true;
    }
    validators.forEach((e) {
      final error = e(context, dao, this);
      if (error!=null && (error.isBeforeEditing || passedFirstEdit || validateIfNotEdited)) {
        validationErrors.add(error);
      }
    });
    return validationErrors.where((e) => e.isBlocking).isEmpty;
  }

  SimpleColModel getColModel() => colModelBuilder(this, dao);
  static SimpleColModel fieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      width: field.tableColumnWidth,
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
      child: SizedBox(
        width: maxWidth,
        child: result,
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



class FieldGroup {

  final String? name;
  final bool primary;
  final Map<String, Field> fields;
  final List<FieldGroup> childGroups;
  Map<String, Field> get props {
    return {
      ...fields,
      if (childGroups.isNotEmpty)
        ...childGroups.map((e) => e.props).reduce((value, element) => {...value, ...element}),
    };
  }

  const FieldGroup({
    this.fields = const {},
    this.name,
    this.primary = true,
    this.childGroups = const [],
  });

  FieldGroup copyWith({
    String? name,
    bool? primary,
    Map<String, Field>? fields,
    List<FieldGroup>? childGroups,
  }) {
    final result = FieldGroup(
      name: name??this.name,
      primary: primary??this.primary,
      fields: fields??this.fields.map((key, value) => MapEntry(key, value.copyWith())),
      childGroups: childGroups??this.childGroups.map((e) => e.copyWith()).toList(),
    );
    return result;
  }

}