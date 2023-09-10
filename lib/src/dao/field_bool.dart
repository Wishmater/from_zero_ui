import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_ensure_visible_when_focused.dart';


class BoolComparable implements Comparable {

  final bool value;

  const BoolComparable(this.value);

  @override
  String toString() => value ? 'SÍ': 'NO'; // TODO 3 internationalize

  @override
  bool operator == (dynamic other) => other is BoolComparable && value==other.value;

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
  intrinsicHeightCheckBoxTile,
  switchTile,
  intrinsicHeightSwitchTile,
  compactCheckBox,
  compactSwitch,
  combo,
  radio,
}
enum BoolFieldShowViewCheckmark {
  always,
  whenTrue,
  whenFalse,
}
enum BoolFieldShowBothNeutralAndSpecificUiName {
  no,
  specificBelow, // previous behaviour
  specificAbove,
}


class BoolField extends Field<BoolComparable> {

  BoolFieldDisplayType displayType;
  FieldValueGetter<String, Field>? uiNameTrueGetter;
  String get uiNameTrue => (uiNameTrueGetter??uiNameGetter)(this, dao) ;
  FieldValueGetter<String, Field>? uiNameFalseGetter;
  String get uiNameFalse => (uiNameFalseGetter??uiNameGetter)(this, dao);
  String get uiNameValue => value!.value ? uiNameTrue : uiNameFalse;
  ListTileControlAffinity listTileControlAffinity;
  BoolFieldShowBothNeutralAndSpecificUiName showBothNeutralAndSpecificUiName;
  ContextFulFieldValueGetter<Color?, BoolField>? selectedColor;
  BoolFieldShowViewCheckmark showViewCheckmark;

  @override
  set value(BoolComparable? v) {
    assert(v!=null, 'BoolField is non-nullable by design.');
    super.value = v;
  }

  BoolField({
    required super.uiNameGetter,
    this.displayType = BoolFieldDisplayType.checkBoxTile,
    this.uiNameTrueGetter,
    this.uiNameFalseGetter,
    this.listTileControlAffinity = ListTileControlAffinity.leading,
    BoolFieldShowBothNeutralAndSpecificUiName? showBothNeutralAndSpecificUiName,
    BoolComparable super.value = const BoolComparable(false),
    BoolComparable? dbValue,
    // FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, // non-nullable by design
    double? maxWidth,
    double? minWidth,
    super.flex,
    super.hintGetter,
    super.tooltipGetter,
    super.tableColumnWidth,
    super.hiddenGetter,
    super.hiddenInTableGetter,
    super.hiddenInViewGetter,
    super.hiddenInFormGetter,
    super.validatorsGetter,
    super.validateOnlyOnConfirm,
    super.colModelBuilder,
    super.undoValues,
    super.redoValues,
    super.fieldGlobalKey,
    super.focusNode,
    super.invalidateNonEmptyValuesIfHiddenInForm,
    super.defaultValue = const BoolComparable(false),
    super.backgroundColor,
    this.selectedColor,
    super.actionsGetter,
    super.viewWidgetBuilder = BoolField.defaultViewWidgetBuilder,
    super.onValueChanged,
    this.showViewCheckmark = BoolFieldShowViewCheckmark.always,
  }) :  showBothNeutralAndSpecificUiName = showBothNeutralAndSpecificUiName
            ?? (uiNameFalseGetter!=null||uiNameTrueGetter!=null
                ? BoolFieldShowBothNeutralAndSpecificUiName.specificBelow
                : BoolFieldShowBothNeutralAndSpecificUiName.no),
        super(
          dbValue: dbValue ?? value,
          clearableGetter: falseFieldGetter,
          maxWidth: maxWidth ?? ( displayType==BoolFieldDisplayType.compactCheckBox ? 96
                                : displayType==BoolFieldDisplayType.compactSwitch ? 96
                                : 512),
          minWidth: minWidth ?? ( displayType==BoolFieldDisplayType.compactCheckBox ? 96
                                : displayType==BoolFieldDisplayType.compactSwitch ? 96
                                : 128),
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
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter,
    ViewWidgetBuilder<BoolComparable>? viewWidgetBuilder,
    BoolFieldShowBothNeutralAndSpecificUiName? showBothNeutralAndSpecificUiName,
    OnFieldValueChanged<BoolComparable?>? onValueChanged,
    BoolFieldShowViewCheckmark? showViewCheckmark,
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
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      showBothNeutralAndSpecificUiName: showBothNeutralAndSpecificUiName ?? this.showBothNeutralAndSpecificUiName,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      showViewCheckmark: showViewCheckmark ?? this.showViewCheckmark,
    );
  }

  @override
  String toString() {
    return showBothNeutralAndSpecificUiName!=BoolFieldShowBothNeutralAndSpecificUiName.no
        ? '$uiName: $uiNameValue' : uiNameValue;
  }

  @override
  Future<bool> validateRequired(BuildContext context, DAO dao, int currentValidationId, bool normalValidationResult, {
    BoolComparable? emptyValue,
  }) async => false; // BoolField is never nullable


  static Widget defaultViewWidgetBuilder
  (BuildContext context, Field<BoolComparable> fieldParam, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=false,
    bool dense = false,
    bool? hidden,
  }) {
    if (hidden ?? fieldParam.hiddenInView) {
      return const SizedBox.shrink();
    }
    final field = fieldParam as BoolField;
    final value = field.value!.value;
    if (value&&fieldParam.showViewCheckmark==BoolFieldShowViewCheckmark.whenFalse
        || !value&&fieldParam.showViewCheckmark==BoolFieldShowViewCheckmark.whenTrue) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final valueName = value
        ? field.uiNameTrueGetter==null ? null : field.uiNameTrue
        : field.uiNameFalseGetter==null ? null : field.uiNameFalse;
    Widget? icon;
    final activeColor = field.selectedColor?.call(context, field, field.dao) ?? Colors.green;
    if (field.displayType==BoolFieldDisplayType.checkBoxTile
        || field.displayType==BoolFieldDisplayType.compactCheckBox) {
      icon = value
          ? Icon(Icons.check,
            color: activeColor,
          )
          : const Icon(Icons.close,
            color: Colors.red,
          );
    } else if (field.displayType==BoolFieldDisplayType.switchTile
        || field.displayType==BoolFieldDisplayType.compactSwitch) {
      icon = value
          ? Icon(MaterialCommunityIcons.toggle_switch,
            color: activeColor,
          )
          : const Icon(MaterialCommunityIcons.toggle_switch_off_outline,
            color: Colors.grey,
          );
    }
    return Padding(
      padding: dense
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          if (icon!=null)
            icon,
          if (icon!=null)
            const SizedBox(width: 2,),
          if (valueName!=null)
            Expanded(
              child: dense
                  ? AutoSizeText(valueName,
                    style: theme.textTheme.titleMedium,
                    textAlign: field.getColModel().alignment,
                    maxLines: 1,
                    minFontSize: 14,
                    overflowReplacement: TooltipFromZero(
                      message: valueName,
                      waitDuration: Duration.zero,
                      verticalOffset: -16,
                      child: AutoSizeText(valueName,
                        style: theme.textTheme.titleMedium,
                        textAlign: field.getColModel().alignment,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  )
                  : SelectableText(valueName,
                    style: theme.textTheme.titleMedium,
                  ),
            ),
        ],
      ),
    );
  }

  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=false,
    bool asSliver = true,
    expandToFillContainer = true,
    bool dense = false,
    bool ignoreHidden = false,
    FocusNode? focusNode,
    ScrollController? mainScrollController,
  }) {
    focusNode ??= this.focusNode;
    Widget result;
    if (hiddenInForm && !ignoreHidden) {
      result = const SizedBox.shrink();
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
  void _focusNext(FocusNode focusNode, FocusNode node) {
    if (focusNode.hasFocus) {
      node.nextFocus();
      print ('faslgjharfgjhafldshgafklshgalfksghakdfsghak');
      Future.delayed(Duration(milliseconds: 200)).then((_) {
        _focusNext(focusNode, node);
      });
    }
  }
  Widget _buildFieldEditorWidget(BuildContext context, {
    required FocusNode focusNode,
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeHorizontally = false,
    bool dense = false,
  }) {
    final theme = Theme.of(context);
    final isSizeNotHardRestricted = displayType==BoolFieldDisplayType.intrinsicHeightSwitchTile
        || displayType==BoolFieldDisplayType.intrinsicHeightCheckBoxTile;
    final hackFocusTraversalPolicy = ReadingOrderTraversalPolicy( // hack to prevent switch/checkbox from interrupting traversal
      requestFocusCallback: (node, {alignment, alignmentPolicy, curve, duration}) {
        if (focusNode.hasFocus) {
          _focusNext(focusNode, node);
        } else {
          node.requestFocus();
        }
      },
    );
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        final visibleValidationErrors = passedFirstEdit
            ? validationErrors
            : validationErrors.where((e) => e.isBeforeEditing);
        Widget result;
        switch(displayType) {
          case BoolFieldDisplayType.checkBoxTile:
          case BoolFieldDisplayType.intrinsicHeightCheckBoxTile:
            result = Theme(
              data: theme.copyWith(
                listTileTheme: theme.listTileTheme.copyWith(
                  horizontalTitleGap: 10, // for some reason SwitchListTile take horizontalTitleGap from the Theme, but you can't specify it directly as a parameter... really stupid
                ),
              ),
              child: FocusTraversalGroup(
                policy: hackFocusTraversalPolicy,
                child: CheckboxListTile(
                  onFocusChange: (value) {
                    print ('$value ${focusNode.hasFocus}');
                  },
                  focusNode: focusNode,
                  value: value!.value,
                  dense: true,
                  controlAffinity: listTileControlAffinity,
                  contentPadding: EdgeInsets.only(
                    left: dense ? 0 : 12,
                    right: dense ? 0 : 12,
                    bottom: isSizeNotHardRestricted ? 0
                      : dense ? 22 : addCard ? 16 : 12,
                ),
                tileColor: dense && visibleValidationErrors.isNotEmpty
                    ? ValidationMessage.severityColors[theme.brightness.inverse]![visibleValidationErrors.first.severity]!.withOpacity(0.2)
                    : backgroundColor?.call(context, this, dao),
                checkColor: selectedColor?.call(context, this, dao),
                onChanged: !enabled ? null : (value) {
                  focusNode.requestFocus();
                  userInteracted = true;
                  this.value = value!.comparable;
                },
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!dense && showBothNeutralAndSpecificUiName==BoolFieldShowBothNeutralAndSpecificUiName.specificBelow)
                        Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(uiName,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                          ),
                        ),
                      ),
                    Text(uiNameValue,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                        height: 1.2,
                      ),
                    ),
                    if (!dense && showBothNeutralAndSpecificUiName==BoolFieldShowBothNeutralAndSpecificUiName.specificAbove)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(uiName,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                          ),
                        ),
                      ),
                  ],),
                ),
              ),
            );
          case BoolFieldDisplayType.switchTile:
          case BoolFieldDisplayType.intrinsicHeightSwitchTile:
            result = Theme(
              data: theme.copyWith(
                listTileTheme: theme.listTileTheme.copyWith(
                  horizontalTitleGap: 10, // for some reason SwitchListTile take horizontalTitleGap from the Theme, but you can't specify it directly as a parameter... really stupid
                ),
              ),
              child: FocusTraversalGroup(
                policy: hackFocusTraversalPolicy,
                child: SwitchListTile(
                  onFocusChange: (value) {
                    print ('$value ${focusNode.hasFocus}');
                  },
                  focusNode: focusNode,
                  value: value!.value,
                  dense: true,
                  controlAffinity: listTileControlAffinity,
                  contentPadding: EdgeInsets.only(
                    left: dense ? 0 : 8,
                    right: dense ? 0 : 8,
                    bottom: isSizeNotHardRestricted ? 0
                      : dense ? 22 : addCard ? 16 : 12,
                ),
                tileColor: dense && visibleValidationErrors.isNotEmpty
                    ? ValidationMessage.severityColors[theme.brightness.inverse]![visibleValidationErrors.first.severity]!.withOpacity(0.2)
                    : backgroundColor?.call(context, this, dao),
                activeColor: selectedColor?.call(context, this, dao),
                activeTrackColor: selectedColor?.call(context, this, dao)?.withOpacity(0.33),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!dense && showBothNeutralAndSpecificUiName==BoolFieldShowBothNeutralAndSpecificUiName.specificBelow)
                        Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(uiName,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                          ),
                        ),
                      ),
                    Text(uiNameValue,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                        height: 1.2,
                      ),
                    ),
                    if (!dense && showBothNeutralAndSpecificUiName==BoolFieldShowBothNeutralAndSpecificUiName.specificAbove)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(uiName,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                          ),
                        ),
                      ),
                  ],
                ),
                onChanged: !enabled ? null : (value) {
                  focusNode.requestFocus();
                  userInteracted = true;
                  this.value = value.comparable;
                },),
              ),
            );
          case BoolFieldDisplayType.compactCheckBox:
            result = FocusTraversalGroup(
              policy: hackFocusTraversalPolicy,
              child: Stack(
                children: [
                  CheckboxListTile(
                    focusNode: focusNode,
                    value: value!.value,
                    dense: true,
                    subtitle: const SizedBox.shrink(),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.only(left: (maxWidth/2)-20, top: dense ? 8 : 14),
                    tileColor: dense && visibleValidationErrors.isNotEmpty
                        ? ValidationMessage.severityColors[theme.brightness.inverse]![visibleValidationErrors.first.severity]!.withOpacity(0.2)
                        : backgroundColor?.call(context, this, dao),
                    checkColor: selectedColor?.call(context, this, dao),
                    onChanged: !enabled ? null : (value) {
                      focusNode.requestFocus();
                      userInteracted = true;
                      this.value = value!.comparable;
                    },
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.only(left: 2, right: 2, top: 0, bottom: dense ? 30 : 22),
                        child: Center(
                          child: AutoSizeText(uiNameValue,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              height: 1,
                              color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                            ),
                            overflowReplacement: AutoSizeText(uiNameValue,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                height: 1,
                                color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          case BoolFieldDisplayType.compactSwitch:
            result = Stack(
              children: [
                Material(
                  type: MaterialType.card,
                  elevation: 0,
                  color: dense && visibleValidationErrors.isNotEmpty
                      ? ValidationMessage.severityColors[theme.brightness.inverse]![visibleValidationErrors.first.severity]!.withOpacity(0.2)
                      : backgroundColor?.call(context, this, dao),
                  child: InkWell(
                    focusNode: focusNode,
                    onTap: !enabled ? null : () {
                      focusNode.requestFocus();
                      userInteracted = true;
                      value = (!(value?.value??false)).comparable;
                    },
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ExcludeFocusTraversal(
                        child: FractionalTranslation(
                          translation: const Offset(0, 0.2),
                          child: Transform.scale(
                            scaleY: 0.7, scaleX: 0.8,
                            filterQuality: FilterQuality.low,
                            child: Switch(
                              value: value!.value,
                              activeColor: selectedColor?.call(context, this, dao),
                              activeTrackColor: selectedColor?.call(context, this, dao)?.withOpacity(0.33),
                              onChanged: !enabled ? null : (value) {
                                focusNode.requestFocus();
                                userInteracted = true;
                                this.value = value.comparable;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.only(left: 2, right: 2, top: 0, bottom: dense ? 30 : 22),
                      child: Center(
                        child: AutoSizeText(uiNameValue,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            height: 1,
                            color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                          ),
                          overflowReplacement: AutoSizeText(uiNameValue,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              height: 1,
                              color: theme.textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
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
                focusNode.requestFocus();
                userInteracted = true;
                this.value = value!.id as BoolComparable;
              },
              popupWidth: maxWidth,
              buttonChildBuilder: ComboField.buttonContentBuilder,
              showViewActionOnDAOs: false,
              showDropdownIcon: true,
            );
          case BoolFieldDisplayType.radio:
            result = const Text('Unimplemented type'); // TODO 3 implement radio BoolField, maybe also radio ComboField
        }
        result = TooltipFromZero(
          message: validationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
            return a.toString().trim().isEmpty ? b.toString()
                : b.toString().trim().isEmpty ? a.toString()
                : '$a\n$b';
          }),
          waitDuration: enabled ? const Duration(seconds: 1) : Duration.zero,
          child: result,
        );
        // TODO 3 implement actions in FieldBool
        if (addCard) {
          result = Card(
            clipBehavior: Clip.hardEdge,
            color: enabled ? null : theme.canvasColor,
            child: result,
          );
        }
        return result;
      },
    );
    if (!isSizeNotHardRestricted) {
      result = SizedBox(
        height: 64,
        child: result,
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
              result,
              if (!dense)
                ValidationMessage(errors: validationErrors, passedFirstEdit: passedFirstEdit,),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  static SimpleColModel numFieldDefaultGetColumn(Field field, DAO dao) {
    return BoolColModel(
      name: field.uiName,
      flex: field.tableColumnWidth?.round() ?? 192,
    );
  }

}