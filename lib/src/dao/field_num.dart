import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_ensure_visible_when_focused.dart';
import 'package:intl/intl.dart';



class NumField extends Field<num> {

  late final TextEditingController controller = TextEditingController(text: toStringStatic(value, formatter));
  NumberFormat? formatter;
  InputDecoration? inputDecoration;
  int digitsAfterComma;
  bool allowNegative;
  Timer? valUpdateTimer;

  @override
  set value(num? v) {
    super.value = v;
    syncTextEditingController();
  }

  @override
  void undo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitUndo(getTextVal(controller.text),
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
    syncTextEditingController();
  }
  @override
  void redo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitRedo(getTextVal(controller.text),
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
    syncTextEditingController();
  }
  @override
  void revertChanges() {
    super.revertChanges();
    syncTextEditingController();
  }

  void syncTextEditingController({
    FocusNode? focusNode,
  }) {
    final textVal = getTextVal(controller.text);
    final string = toString();
    if (value!=textVal || (!(focusNode??this.focusNode).hasFocus && string!=controller.text)) {
      controller.text = string;
      controller.selection = TextSelection.collapsed(offset: string.length);
    }
  }

  NumField({
    required super.uiNameGetter,
    super.value,
    super.dbValue,
    super.clearableGetter,
    this.formatter,
    this.inputDecoration,
    this.digitsAfterComma = 0,
    super.maxWidth,
    super.minWidth,
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
    super.colModelBuilder = numFieldDefaultGetColumn,
    super.undoValues,
    super.redoValues,
    super.fieldGlobalKey,
    super.focusNode,
    super.invalidateNonEmptyValuesIfHiddenInForm,
    super.defaultValue,
    super.backgroundColor,
    super.actionsGetter,
    super.viewWidgetBuilder,
    super.onValueChanged,
    this.allowNegative = false,
  }) :  assert(digitsAfterComma>=0);

  @override
  String toString() => toStringStatic(value, formatter);
  static String toStringStatic(num? value, NumberFormat? formatter) {
    return value==null  ? ''
                        : formatter==null ? value.toString()
                                          : formatter.format(value);
  }

  @override
  NumField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    NumberFormat? formatter,
    num? value,
    num? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    int? digitsAfterComma,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<num>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<num?>? undoValues,
    List<num?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    num? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter,
    ViewWidgetBuilder<num>? viewWidgetBuilder,
    OnFieldValueChanged<num?>? onValueChanged,
    bool? allowNegative,
  }) {
    return NumField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      formatter: formatter??this.formatter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      digitsAfterComma: digitsAfterComma??this.digitsAfterComma,
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
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      allowNegative: allowNegative ?? this.allowNegative,
    );
  }

  num? getTextVal(String? text) {
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
            largeVertically: false,
            largeHorizontally: constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium,
            focusNode: focusNode!,
            dense: dense,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        focusNode: focusNode,
        largeVertically: false,
        dense: dense,
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
    required FocusNode focusNode,
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeVertically = false,
    bool largeHorizontally = false,
    bool dense = false,
  }) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        valUpdateTimer?.cancel();
        final textVal = getTextVal(controller.text);
        if (textVal != value) {
          super.value = textVal;
        } else {
          syncTextEditingController(focusNode: focusNode);
        }
        if (!passedFirstEdit) {
          passedFirstEdit = true;
          validate(dao.contextForValidation!, dao, dao.validationCallCount);
          notifyListeners();
        }
      }
    });
    Widget result = NotificationListener(
      onNotification: (notification) => true,
      child: AnimatedBuilder(
        animation: this,
        builder: (context, child) {
          final enabled = this.enabled;
          final visibleValidationErrors = passedFirstEdit
              ? validationErrors
              : validationErrors.where((e) => e.isBeforeEditing);
          final actions = buildActions(context, focusNode);
          final defaultActions = buildDefaultActions(context, focusNode: focusNode);
          var allActions = [
            ...actions,
            if (actions.isNotEmpty && defaultActions.isNotEmpty)
              ActionFromZero.divider(breakpoints: {0: ActionState.popup}),
            ...defaultActions,
          ];
          if (!enabled) {
            allActions = allActions.map((e) => e.copyWith(
              disablingError: '',
            ),).toList();
          }
          Widget result = Stack(
            fit: largeVertically ? StackFit.loose : StackFit.expand,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: focusNode,
                  builder: (context, child) {
                    final backgroundColor = this.backgroundColor?.call(context, this, dao);
                    final focusColor = Theme.of(context).focusColor.withOpacity(Theme.of(context).focusColor.opacity*0.6);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      color: dense && visibleValidationErrors.isNotEmpty
                          ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![visibleValidationErrors.first.severity]!.withOpacity(0.2)
                          : focusNode.hasFocus  ? backgroundColor!=null ? Color.alphaBlend(focusColor, backgroundColor)
                          : focusColor
                          : focusColor.withOpacity(0),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
              KeyboardListener(
                includeSemantics: false,
                focusNode: FocusNode()..skipTraversal=true,
                onKeyEvent: (value) {
                  if (value is KeyDownEvent) {
                    final selectionStart = controller.selection.start;
                    if (value.logicalKey==LogicalKeyboardKey.arrowDown && selectionStart==controller.text.length) {
                      // focusNode.focusInDirection(TraversalDirection.down);
                      focusNode.nextFocus(); // because directional focus is REALLY buggy
                    } else if (value.logicalKey==LogicalKeyboardKey.arrowUp && selectionStart==0) {
                      // focusNode.focusInDirection(TraversalDirection.up);
                      focusNode.previousFocus(); // because directional focus is REALLY buggy
                    }
                  }
                },
                child: Builder(
                  builder: (context) {
                    return StringField.buildDaoTextFormField(context,
                      uiName: uiName,
                      value: value?.toString(),
                      dense: dense,
                      controller: controller,
                      enabled: enabled,
                      focusNode: focusNode,
                      hint: hint,
                      inputDecoration: inputDecoration,
                      minLines: 1,
                      maxLines: 1,
                      largeVertically: largeVertically,
                      obfuscate: false,
                      textAlign: dense ? TextAlign.right : TextAlign.left,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9${digitsAfterComma==0 ? '' : '.'}${allowNegative ? '-' : ''}]')),],
                      actions: allActions,
                      onChanged: (v) {
                        userInteracted = true;
                        valUpdateTimer?.cancel();
                        int? lastMinusIndex;
                        do {
                          lastMinusIndex = v.contains('-') ? v.lastIndexOf('-') : null;
                          if (lastMinusIndex!=null && lastMinusIndex>0) {
                            v = v.substring(0, lastMinusIndex) + v.substring(lastMinusIndex+1);
                          }
                        } while(lastMinusIndex!=null && lastMinusIndex>0);
                        if (digitsAfterComma>0) {
                          bool update = false;
                          int commaIndex = v.indexOf('.');
                          if (commaIndex==0 || (commaIndex==1 && v[0]=='-')) {
                            v = '${v.substring(0, commaIndex)}0${v.substring(commaIndex)}';
                            commaIndex++;
                            update = true;
                          }
                          int lastCommaIndex = v.lastIndexOf('.');
                          if (commaIndex>0) {
                            if (commaIndex!=lastCommaIndex) {
                              v = v.replaceAll('.', '');
                              v = '${v.substring(0, commaIndex)}.${v.substring(commaIndex)}';
                              update = true;
                            }
                            if (v.length-1 - commaIndex > digitsAfterComma) {
                              v = v.substring(0, min(commaIndex+digitsAfterComma+1, v.length));
                              update = true;
                            }
                          }
                          if (update) {
                            final previousBase = controller.selection.baseOffset;
                            final previousExtent = controller.selection.extentOffset;
                            controller.text = v;
                            controller.selection = TextSelection(
                              baseOffset: previousBase.clamp(0, v.length),
                              extentOffset: previousExtent.clamp(0, v.length),
                            );
                          }
                        }
                        final textVal = getTextVal(v);
                        if (v.isEmpty || v.characters.last=='.' || v.characters.last==',' || !isEdited) {
                          value = textVal;
                        } else if (value!=textVal) {
                          addUndoEntry(value);
                        }
                        valUpdateTimer = Timer(const Duration(seconds: 2), () {
                          value = textVal;
                        });
                      },
                      onEditingComplete: () {
                        focusNode.nextFocus();
                      },
                    );
                  },
                ),
              ),
            ],
          );
          result = TooltipFromZero(
            message: (dense ? visibleValidationErrors : visibleValidationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling)).fold('', (a, b) {
              return a.toString().trim().isEmpty ? b.toString()
                  : b.toString().trim().isEmpty ? a.toString()
                  : '$a\n$b';
            }),
            waitDuration: enabled ? const Duration(seconds: 1) : Duration.zero,
            child: result,
          );
          if (!dense) {
            result = AppbarFromZero(
              addContextMenu: false, // shown in TextField contextMenuBuilder instead
              backgroundColor: Colors.transparent,
              elevation: 0,
              useFlutterAppbar: false,
              extendTitleBehindActions: true,
              toolbarHeight: largeVertically ? null : 56,
              paddingRight: 6,
              actionPadding: 0,
              skipTraversalForActions: true,
              constraints: const BoxConstraints(),
              actions: allActions,
              title: SizedBox(height: largeVertically ? null : 56, child: result),
            );
          }
          result = ValidationRequiredOverlay(
            isRequired: isRequired,
            isEmpty: enabled && value==null,
            errors: validationErrors,
            dense: dense,
            textAlign: dense ? TextAlign.right : TextAlign.left,
            child: result,
          );
          return result;
        },
      ),
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
        color: enabled ? null : Theme.of(context).canvasColor,
        child: result,
      );
    }
    return EnsureVisibleWhenFocused(
      focusNode: focusNode,
      child: Padding(
        key: fieldGlobalKey,
        padding: EdgeInsets.symmetric(horizontal: !dense && largeHorizontally ? 12 : 0),
        child: SizedBox(
          width: maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: largeVertically ? null : 64,
                child: result,
              ),
              if (!dense)
                ValidationMessage(errors: validationErrors, passedFirstEdit: passedFirstEdit,),
            ],
          ),
        ),
      ),
    );
  }

  static SimpleColModel numFieldDefaultGetColumn(Field field, DAO dao) {
    return NumColModel(
      name: field.uiName,
      filterEnabled: true,
      flex: field.tableColumnWidth?.round() ?? 192,
      formatter: field is NumField ? field.formatter : null,
    );
  }

}