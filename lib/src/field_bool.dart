import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';


class BoolComparable with Comparable {

  final bool value;

  const BoolComparable(this.value);

  @override
  String toString() => value.toString();

  @override
  bool operator == (dynamic other) => other is BoolComparable && this.value==other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(other) => other is BoolComparable ? value==true ? other.value==true ? 0
                                                                                    : 1
                                                                : other.value==true ? -1
                                                                : 0
                                                  : 1;

}


extension ComparableBoolExtension on bool {
  BoolComparable get comparable => BoolComparable(this);
}


enum BoolFieldDisplayType {
  checkBoxTile,
  switchTile,
  compactCheckBox,
  compactSwitch,
  combo,
  radio,
}


class BoolField extends Field<BoolComparable> {

  BoolFieldDisplayType displayType;
  FieldValueGetter<String, Field>? uiNameTrueGetter;
  String get uiNameTrue => (uiNameTrueGetter??uiNameGetter)(this, dao) ;
  FieldValueGetter<String, Field>? uiNameFalseGetter;
  String get uiNameFalse => (uiNameFalseGetter??uiNameGetter)(this, dao);
  String get uiNameValue => value!.value ? uiNameTrue : uiNameFalse;
  ListTileControlAffinity listTileControlAffinity;
  bool showBothNeutralAndSpecificUiName;

  @override
  set value(BoolComparable? v) {
    assert(v!=null, 'BoolField is non-nullable by design.');
    super.value = v;
  }

  BoolField({
    required FieldValueGetter<String, Field> uiNameGetter,
    this.displayType = BoolFieldDisplayType.checkBoxTile,
    this.uiNameTrueGetter,
    this.uiNameFalseGetter,
    this.listTileControlAffinity = ListTileControlAffinity.leading,
    bool? showBothNeutralAndSpecificUiName,
    BoolComparable value = const BoolComparable(false),
    BoolComparable? dbValue,
    // FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, // non-nullable by design
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<BoolComparable>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<BoolComparable?>? undoValues,
    List<BoolComparable?>? redoValues,
  }) :  showBothNeutralAndSpecificUiName = showBothNeutralAndSpecificUiName ?? (uiNameFalseGetter!=null||uiNameTrueGetter!=null),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue ?? value,
          clearableGetter: falseFieldGetter,
          enabledGetter: enabledGetter,
          maxWidth: maxWidth ?? ( displayType==BoolFieldDisplayType.compactCheckBox ? 96
                                : displayType==BoolFieldDisplayType.compactSwitch ? 96
                                : 512),
          hintGetter: hintGetter,
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
  BoolField copyWith({
    BoolFieldDisplayType? displayType,
    FieldValueGetter<String, Field>? uiNameTrueGetter,
    FieldValueGetter<String, Field>? uiNameFalseGetter,
    ListTileControlAffinity? listTileControlAffinity,
    FieldValueGetter<String, Field>? uiNameGetter,
    BoolComparable? value,
    BoolComparable? dbValue,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    FieldValueGetter<String?, Field>? hintGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<BoolComparable>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<BoolComparable?>? undoValues,
    List<BoolComparable?>? redoValues,
  }) {
    return BoolField(
      displayType: displayType??this.displayType,
      uiNameTrueGetter: uiNameTrueGetter??this.uiNameTrueGetter,
      uiNameFalseGetter: uiNameFalseGetter??this.uiNameFalseGetter,
      listTileControlAffinity: listTileControlAffinity??this.listTileControlAffinity,
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value!,
      dbValue: dbValue??this.dbValue,
      enabledGetter: enabledGetter??this.enabledGetter,
      maxWidth: maxWidth??this.maxWidth,
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
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        Widget result;
        switch(displayType) {
          case BoolFieldDisplayType.checkBoxTile:
            result = CheckboxListTile(
              value: value!.value,
              dense: true,
              controlAffinity: listTileControlAffinity,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              title: !showBothNeutralAndSpecificUiName ? null : Transform.translate(
                offset: Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -12 : 3,
                  -4,
                ),
                child: Text(uiName, style: Theme.of(context).textTheme.caption,),
              ),
              subtitle:  Transform.translate(
                offset:  Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -12 : 3,
                  showBothNeutralAndSpecificUiName ? -4 : -10,
                ),
                child: Text(uiNameValue, style: Theme.of(context).textTheme.subtitle1,),
              ),
              onChanged: !enabled ? null : (value) {
                this.value = value!.comparable;
              },
            );
            break;
          case BoolFieldDisplayType.switchTile:
            result = SwitchListTile(
              value: value!.value,
              dense: true,
              controlAffinity: listTileControlAffinity,
              contentPadding: EdgeInsets.symmetric(horizontal: 8),
              title: !showBothNeutralAndSpecificUiName ? null : Transform.translate(
                offset: Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -8 : 7,
                  -4,
                ),
                child: Text(uiName, style: Theme.of(context).textTheme.caption,),
              ),
              subtitle:  Transform.translate(
                offset:  Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -8 : 7,
                  showBothNeutralAndSpecificUiName ? -4 : -10,
                ),
                child: Text(uiNameValue, style: Theme.of(context).textTheme.subtitle1,),
              ),
              onChanged: !enabled ? null : (value) {
                this.value = value.comparable;
              },
            );
            break;
          case BoolFieldDisplayType.compactCheckBox:
            result = Stack(
              children: [
                CheckboxListTile(
                  value: value!.value,
                  dense: true,
                  subtitle: SizedBox.shrink(),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.only(left: (maxWidth/2)-20, top: 14),
                  onChanged: !enabled ? null : (value) {
                    this.value = value!.comparable;
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2, right: 2, top: 4, bottom: 22),
                      child: Center(
                        child: AutoSizeText(uiNameValue,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            break;
          case BoolFieldDisplayType.compactSwitch:
            result = Stack(
              children: [
                SwitchListTile(
                  value: value!.value,
                  dense: true,
                  subtitle: SizedBox.shrink(),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.only(left: (maxWidth/2)-32, top: 14),
                  onChanged: !enabled ? null : (value) {
                    this.value = value.comparable;
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2, right: 2, top: 4, bottom: 22),
                      child: Center(
                        child: AutoSizeText(uiNameValue,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            break;
          case BoolFieldDisplayType.combo:
            result = ComboFromZero<DAO>(
              enabled: enabled,
              clearable: false,
              title: uiName,
              hint: hint,
              value: DAO(
                id: value,
                classUiNameGetter: (dao) => uiName,
                uiNameGetter: (dao) => dao.id==true.comparable ? uiNameTrue : uiNameFalse,
              ),
              possibleValues: [
                DAO(
                  id: true.comparable,
                  classUiNameGetter: (dao) => uiName,
                  uiNameGetter: (dao) => uiNameTrue,
                ),
                DAO(
                  id: false.comparable,
                  classUiNameGetter: (dao) => uiName,
                  uiNameGetter: (dao) => uiNameFalse,
                ),
              ],
              showSearchBox: false,
              onSelected: (value) {
                this.value = value!.id as BoolComparable;
              },
              popupWidth: maxWidth,
              buttonChildBuilder: ComboField.buttonContentBuilder,
              showViewActionOnDAOs: false,
              showDropdownIcon: true,
            );
            break;
          case BoolFieldDisplayType.radio:
            result = Text('Unimplemented type'); // TODO 3 implement radio BoolField, maybe also radio ComboField
            break;
        }
        return result;
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
            ValidationMessage(errors: validationErrors),
          ],
        ),
      ),
    );
    return result;
  }

}