import 'package:auto_size_text/auto_size_text.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/util/my_tooltip.dart';
import 'package:from_zero_ui/util/my_checkbox_list_tile.dart' as my_checkbox_list_tile;
import 'package:from_zero_ui/util/my_switch_list_tile.dart' as my_switch_list_tile;


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
  int compareTo(other) {
    bool otherValue;
    if (other is BoolComparable) {
      otherValue = other.value;
    } else if (other is bool) {
      otherValue = other;
    } else {
      return 1;
    }
    return value==true  ? otherValue==true  ? 0
                                            : 1
                        : otherValue==true  ? -1
                                            : 0;
  }

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
  ContextFulFieldValueGetter<Color?, BoolField>? selectedColor;

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
    double? maxWidth,
    double? minWidth,
    double flex = 0,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
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
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    BoolComparable? defaultValue = const BoolComparable(false),
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    this.selectedColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) :  showBothNeutralAndSpecificUiName = showBothNeutralAndSpecificUiName ?? (uiNameFalseGetter!=null||uiNameTrueGetter!=null),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue ?? value,
          clearableGetter: falseFieldGetter,
          maxWidth: maxWidth ?? ( displayType==BoolFieldDisplayType.compactCheckBox ? 96
                                : displayType==BoolFieldDisplayType.compactSwitch ? 96
                                : 512),
          minWidth: minWidth ?? ( displayType==BoolFieldDisplayType.compactCheckBox ? 96
                                : displayType==BoolFieldDisplayType.compactSwitch ? 96
                                : 128),
          flex: flex,
          hintGetter: hintGetter,
          tooltipGetter: tooltipGetter,
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
          fieldGlobalKey: fieldGlobalKey ?? GlobalKey(),
          focusNode: focusNode ?? FocusNode(),
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue,
          backgroundColor: backgroundColor,
          actions: actions,
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
    FieldValueGetter<List<FieldValidator<BoolComparable>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<BoolComparable?>? undoValues,
    List<BoolComparable?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    BoolComparable? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<Color?, Field>? selectedColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) {
    return BoolField(
      displayType: displayType??this.displayType,
      uiNameTrueGetter: uiNameTrueGetter??this.uiNameTrueGetter,
      uiNameFalseGetter: uiNameFalseGetter??this.uiNameFalseGetter,
      listTileControlAffinity: listTileControlAffinity??this.listTileControlAffinity,
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value!,
      dbValue: dbValue??this.dbValue,
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
      selectedColor: selectedColor ?? this.selectedColor,
      actions: actions ?? this.actions,
    );
  }

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    expandToFillContainer: true,
    bool dense = false,
    FocusNode? focusNode,
  }) {
    if (focusNode==null) {
      focusNode = this.focusNode;
    }
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
            dense: dense,
            focusNode: focusNode!,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
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
    bool largeHorizontally = false,
    bool dense = false,
    required FocusNode focusNode,
  }) {
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        Widget result;
        switch(displayType) {
          case BoolFieldDisplayType.checkBoxTile:
            result = my_checkbox_list_tile.CheckboxListTile(
              focusNode: focusNode,
              value: value!.value,
              dense: true,
              controlAffinity: listTileControlAffinity,
              contentPadding: EdgeInsets.symmetric(horizontal: dense ? 0 : 12),
              tileColor: dense && validationErrors.isNotEmpty
                  ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
                  : backgroundColor?.call(context, this, dao),
              checkColor: selectedColor?.call(context, this, dao),
              title: dense || !showBothNeutralAndSpecificUiName ? null : Transform.translate(
                offset: Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -12 : 3,
                  -4,
                ),
                child: Text(uiName, style: Theme.of(context).textTheme.caption!.copyWith(
                  color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                ),),
              ),
              subtitle: Transform.translate(
                offset:  Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -12 : 3,
                  !dense && showBothNeutralAndSpecificUiName ? -4 : -10,
                ),
                child: Text(uiNameValue, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                ),),
              ),
              onChanged: !enabled ? null : (value) {
                this.value = value!.comparable;
              },
            );
            break;
          case BoolFieldDisplayType.switchTile:
            result = my_switch_list_tile.SwitchListTile(
              focusNode: focusNode,
              value: value!.value,
              dense: true,
              controlAffinity: listTileControlAffinity,
              contentPadding: EdgeInsets.symmetric(horizontal: dense ? 0 : 8),
              tileColor: dense && validationErrors.isNotEmpty
                  ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
                  : backgroundColor?.call(context, this, dao),
              activeColor: selectedColor?.call(context, this, dao),
              activeTrackColor: selectedColor?.call(context, this, dao)?.withOpacity(0.33),
              title: dense || !showBothNeutralAndSpecificUiName ? null : Transform.translate(
                offset: Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -8 : 7,
                  -4,
                ),
                child: Text(uiName, style: Theme.of(context).textTheme.caption!.copyWith(
                  color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                ),),
              ),
              subtitle:  Transform.translate(
                offset:  Offset(
                  listTileControlAffinity==ListTileControlAffinity.leading ? -8 : 7,
                  !dense && showBothNeutralAndSpecificUiName ? -4 : -10,
                ),
                child: Text(uiNameValue, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                ),),
              ),
              onChanged: !enabled ? null : (value) {
                this.value = value.comparable;
              },
            );
            break;
          case BoolFieldDisplayType.compactCheckBox:
            result = Stack(
              children: [
                my_checkbox_list_tile.CheckboxListTile(
                  focusNode: focusNode,
                  value: value!.value,
                  dense: true,
                  subtitle: SizedBox.shrink(),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.only(left: (maxWidth/2)-20, top: 14),
                  tileColor: dense && validationErrors.isNotEmpty
                      ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
                      : backgroundColor?.call(context, this, dao),
                  checkColor: selectedColor?.call(context, this, dao),
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
                            color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
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
                my_switch_list_tile.SwitchListTile(
                  focusNode: focusNode,
                  value: value!.value,
                  dense: true,
                  subtitle: SizedBox.shrink(),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.only(left: (maxWidth/2)-32, top: 14),
                  tileColor: dense && validationErrors.isNotEmpty
                      ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
                      : backgroundColor?.call(context, this, dao),
                  activeColor: selectedColor?.call(context, this, dao),
                  activeTrackColor: selectedColor?.call(context, this, dao)?.withOpacity(0.33),
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
                            color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
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
              focusNode: focusNode,
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
        result = TooltipFromZero(
          message: validationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
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
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
        color: enabled ? null : Theme.of(context).canvasColor,
        child: Stack(
          children: [
            result,
            if (!enabled)
              Positioned.fill(
                child: MouseRegion(
                  opaque: false,
                  cursor: SystemMouseCursors.forbidden,
                ),
              ),
          ],
        ),
      );
    }
    result = EnsureVisibleWhenFocused(
      focusNode: focusNode,
      child: Padding(
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
              if (!dense)
                ValidationMessage(errors: validationErrors),
            ],
          ),
        ),
      ),
    );
    return result;
  }

}