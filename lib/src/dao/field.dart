import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/action_from_zero.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';
import 'package:from_zero_ui/src/ui_utility/ui_utility_widgets.dart';
import 'package:from_zero_ui/src/ui_utility/util.dart';
import 'package:dartx/dartx.dart';

typedef ValidationError? FieldValidator<T extends Comparable>(BuildContext context, DAO dao, Field<T> field);
typedef T FieldValueGetter<T, R extends Field>(R field, DAO dao);
typedef T ContextFulFieldValueGetter<T, R extends Field>(BuildContext context, R field, DAO dao);
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
  T? defaultValue; /// used for reversing the field to default state when hidden, noly if invalidateNonEmptyValuesIfHiddenInForm==true, default null
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
  double minWidth;
  /// only used when using FlexibleLayoutFromZero for FieldGroup
  double flex;
  FocusNode focusNode;
  double? tableColumnWidth;
  FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter;
  List<FieldValidator<T>> get validators => validatorsGetter?.call(this, dao) ?? [];
  bool validateOnlyOnConfirm;
  bool passedFirstEdit = false;
  List<ValidationError> validationErrors = [];
  FieldValueGetter<SimpleColModel, Field> colModelBuilder;
  bool invalidateNonEmptyValuesIfHiddenInForm;
  ContextFulFieldValueGetter<Color?, Field>? backgroundColor;
  ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions;

  T? _value;
  T? get value => _value;
  @mustCallSuper
  set value(T? value) {
    if (_value!=value) {
      passedFirstEdit = true;
      undoValues.add(_value); // TODO 1 Fields that override value setter must override undo logic as well (important on textfields)
      dao.addUndoEntry(this);
      redoValues = [];
      _value = value;
      dao.validate(dao.contextForValidation!,
        validateNonEditedFields: false,
      );
      // notifyListeners();
    }
  }
  List<T?> undoValues;
  List<T?> redoValues;

  Field({
    required this.uiNameGetter,
    T? value,
    T? dbValue,
    this.clearableGetter = Field.defaultClearableGetter,
    this.maxWidth = 512,
    this.minWidth = 128,
    this.flex = 0,
    this.hintGetter,
    this.tooltipGetter,
    this.tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.validatorsGetter,
    this.validateOnlyOnConfirm = false,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    this.colModelBuilder = fieldDefaultGetColumn,
    List<T?>? undoValues,
    List<T?>? redoValues,
    this.invalidateNonEmptyValuesIfHiddenInForm = true,  // TODO 1 implement on each field, override if necessary
    this.defaultValue,
    this.backgroundColor,
    this.actions,
  }) :  this._value = value,
        this.dbValue = dbValue ?? value,
        this.undoValues = undoValues ?? [],
        this.redoValues = redoValues ?? [],
        this.fieldGlobalKey = fieldGlobalKey ?? GlobalKey(),
        this.focusNode = focusNode ?? FocusNode(),
        this.hiddenInTableGetter = hiddenInTableGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInViewGetter = hiddenInViewGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInFormGetter = hiddenInFormGetter ?? hiddenGetter ?? falseFieldGetter;

  Field copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
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
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    T? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) {
    return Field<T>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? List.from(this.undoValues),
      redoValues: redoValues ?? List.from(this.redoValues),
      invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm ?? this.invalidateNonEmptyValuesIfHiddenInForm,
      defaultValue: defaultValue ?? this.defaultValue,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actions: actions ?? this.actions,
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
    dao.removeAllUndoEntries(this);
    redoValues = [];
    dao.removeAllRedoEntries(this);
    notifyListeners();
  }

  void undo({
    bool removeEntryFromDAO = false,
  }) {
    assert(undoValues.isNotEmpty);
    redoValues.add(value);
    dao.addRedoEntry(this);
    _value = undoValues.removeLast();
    if (removeEntryFromDAO) {
      dao.removeLastUndoEntry(this);
    }
    notifyListeners();
  }
  void redo({
    bool removeEntryFromDAO = false,
  }) {
    assert(redoValues.isNotEmpty);
    undoValues.add(value);
    dao.addUndoEntry(this);
    _value = redoValues.removeLast();
    if (removeEntryFromDAO) {
      dao.removeLastRedoEntry(this);
    }
    notifyListeners();
  }

  Future<bool> validate(BuildContext context, DAO dao, {
    bool validateIfNotEdited=false,
  }) async {
    validationErrors = [];
    if (hiddenInForm) {
      if (invalidateNonEmptyValuesIfHiddenInForm && value!=defaultValue) {
        validationErrors.add(InvalidatingError(
          field: this,
          error: uiName + ' ' + FromZeroLocalizations.of(context).translate("validation_combo_hidden_with_value"),
          defaultValue: defaultValue,
        ));
        return false;
      }
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
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    return validationErrors.where((e) => e.isBlocking).isEmpty;
  }

  SimpleColModel getColModel() => colModelBuilder(this, dao);
  static SimpleColModel fieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      flex: field.tableColumnWidth?.round(),
    );
  }

  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard = false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
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

  List<ActionFromZero> buildDefaultActions(BuildContext context) {
    return [
      ActionFromZero(
        title: 'Deshacer', // TODO 1 internationalize
        icon: Icon(MaterialCommunityIcons.undo_variant),
        onTap: (context) => undo(removeEntryFromDAO: true),
        enabled: undoValues.isNotEmpty,
      ),
      ActionFromZero(
        title: 'Rehacer', // TODO 1 internationalize
        icon: Icon(MaterialCommunityIcons.redo_variant),
        onTap: (context) => redo(removeEntryFromDAO: true),
        enabled: redoValues.isNotEmpty,
      ),
      ActionFromZero(
        title: 'Limpiar', // TODO 1 internationalize
        icon: Icon(Icons.clear),
        onTap: (context) => value = defaultValue,
        enabled: clearable && value!=defaultValue,
      ),
    ];
  }

  static bool defaultClearableGetter<T extends Comparable>(Field field, DAO dao) {
    return trueFieldGetter(field, dao);
    //return !field.validators.contains(fieldValidatorRequired<T>);
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
  final bool useLayoutFromZero;
  /// only used when building FlexibleLayoutFromZero
  double get maxWidth => max(fields.values.maxBy((e) => e.maxWidth)?.maxWidth ?? 0,
                              childGroups.maxBy((e) => e.maxWidth)?.maxWidth ?? 0);
  /// only used when building FlexibleLayoutFromZero
  double get minWidth => max(fields.values.maxBy((e) => e.minWidth)?.minWidth ?? 0,
                              childGroups.maxBy((e) => e.minWidth)?.minWidth ?? 0);

  const FieldGroup({
    this.fields = const {},
    this.name,
    this.primary = true,
    this.childGroups = const [],
    this.useLayoutFromZero = true,
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