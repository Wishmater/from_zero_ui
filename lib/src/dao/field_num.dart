import 'dart:math';
import 'dart:ui' as ui;

import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';
import 'package:intl/intl.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:dartx/dartx.dart';



class NumField extends Field<num> {

  late final TextEditingController controller = TextEditingController(text: toStringStatic(value, formatter));
  NumberFormat? formatter;
  InputDecoration? inputDecoration;
  int digitsAfterComma;
  bool allowNegative;

  set value(num? v) {
    super.value = v;
    syncTextEditingController();
  }

  @override
  void undo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitUndo(_getTextVal(controller.text),
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
    super.commitRedo(_getTextVal(controller.text),
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

  void syncTextEditingController() {
    final textVal = _getTextVal(controller.text);
    if (value != textVal) {
      final string = toString();
      controller.text = string;
      controller.selection = TextSelection.collapsed(offset: string.length);
    }
  }

  NumField({
    required FieldValueGetter<String, Field> uiNameGetter,
    num? value,
    num? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = Field.defaultClearableGetter,
    this.formatter,
    this.inputDecoration,
    this.digitsAfterComma = 0,
    double maxWidth = 512,
    double minWidth = 128,
    double flex = 0,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<num>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = numFieldDefaultGetColumn,
    List<num?>? undoValues,
    List<num?>? redoValues,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    num? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<num> viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    OnFieldValueChanged<num?>? onValueChanged,
    this.allowNegative = false,
  }) :  assert(digitsAfterComma>=0),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          hintGetter: hintGetter,
          tooltipGetter: tooltipGetter,
          maxWidth: maxWidth,
          minWidth: minWidth,
          flex: flex,
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
          fieldGlobalKey: fieldGlobalKey,
          focusNode: focusNode,
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue,
          backgroundColor: backgroundColor,
          actions: actions,
          viewWidgetBuilder: viewWidgetBuilder,
          onValueChanged: onValueChanged,
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
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
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
      actions: actions ?? this.actions,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      allowNegative: allowNegative ?? this.allowNegative,
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
    bool dense = false,
    FocusNode? focusNode,
    ScrollController? mainScrollController,
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
    bool addCard=false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool largeVertically = false,
    bool largeHorizontally = false,
    bool dense = false,
    required FocusNode focusNode,
  }) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        final textVal = _getTextVal(controller.text);
        if (textVal != value) {
          super.value = textVal;
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
                      duration: Duration(milliseconds: 250),
                      color: dense && validationErrors.isNotEmpty
                          ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
                          : focusNode.hasFocus  ? backgroundColor!=null ? Color.alphaBlend(focusColor, backgroundColor)
                          : focusColor
                          : focusColor.withOpacity(0),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: largeVertically ? 16 : 0,
                  top: dense ? 0 : largeVertically ? 12 : 2,
                ),
                child: KeyboardListener(
                  includeSemantics: false,
                  focusNode: FocusNode(skipTraversal: true),
                  onKeyEvent: (value) {
                    if (value is KeyDownEvent) {
                      if (value.logicalKey==LogicalKeyboardKey.arrowDown) {
                        focusNode.focusInDirection(TraversalDirection.down);
                      } else if (value.logicalKey==LogicalKeyboardKey.arrowUp) {
                        focusNode.focusInDirection(TraversalDirection.up);
                      }
                    }
                  },
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    focusNode: focusNode,
                    textAlign: dense ? TextAlign.right : TextAlign.left,
                    toolbarOptions: ToolbarOptions( // TODO 2 this might be really bad on Android
                      copy: false, cut: false, paste: false, selectAll: false,
                    ),
                    onEditingComplete: () {
                      focusNode.nextFocus();
                    },
                    onChanged: (v) {
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
                          v = v.substring(0, commaIndex) + '0' + v.substring(commaIndex);
                          commaIndex++;
                          update = true;
                        }
                        int lastCommaIndex = v.lastIndexOf('.');
                        if (commaIndex>0) {
                          if (commaIndex!=lastCommaIndex) {
                            v = v.replaceAll('.', '');
                            v = v.substring(0, commaIndex) + '.' + v.substring(commaIndex);
                            update = true;
                          }
                          if (v.length+1 - commaIndex > digitsAfterComma) {
                            v = v.substring(0, min(commaIndex+digitsAfterComma+1, v.length));
                            update = true;
                          }
                        }
                        if (update) {
                          controller.text = v;
                          controller.selection = TextSelection(
                            baseOffset: v.length,
                            extentOffset: v.length,
                          );
                        }
                      }
                      final textVal = _getTextVal(v);
                      if (v.isEmpty || v.characters.last=='.' || v.characters.last==',' || !isEdited) {
                        value = textVal;
                      } else if (value!=textVal) {
                        addUndoEntry(value);
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9${digitsAfterComma==0 ? '' : '.'}${allowNegative ? '-' : ''}]')),],
                    decoration: inputDecoration??InputDecoration(
                      border: InputBorder.none,
                      alignLabelWithHint: dense,
                      label: dense
                          ? Align(
                            alignment: Alignment.centerRight,
                            child: Text(uiName,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ) : Text(uiName,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                      hintText: hint,
                      floatingLabelBehavior: dense ? FloatingLabelBehavior.never
                          : !enabled ? (value==null) ? FloatingLabelBehavior.never : FloatingLabelBehavior.always
                          : hint!=null ? FloatingLabelBehavior.always : FloatingLabelBehavior.auto,
                      labelStyle: TextStyle(height: dense ? 0 : largeVertically ? 0.75 : 1.85,
                        color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                      ),
                      hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
                      contentPadding: EdgeInsets.only(
                        left: dense ? 0 : 16,
                        right: (dense ? 0 : 16) + (enabled&&clearable ? 40 : 0),
                        bottom: dense ? 10 : 0,
                      ),
                    ),
                  ),
                ),
              ),
              if (enabled && clearable && !dense)
                Positioned(
                  right: 8, top: 0, bottom: 0,
                  child: ExcludeFocus(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) {
                          return SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: value!=null ? TooltipFromZero(
                          message: FromZeroLocalizations.of(context).translate('clear'),
                          child: IconButton(
                            icon: Icon(Icons.close),
                            splashRadius: 20,
                            onPressed: () {
                              value = null;
                              controller.clear();
                              focusNode.requestFocus();
                            },
                          ),
                        ) : SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              if (!enabled)
                Positioned.fill(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.forbidden,
                  ),
                ),
            ],
          );
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
          final actions = this.actions?.call(context, this, dao) ?? [];
          final defaultActions = buildDefaultActions(context);
          result = ContextMenuFromZero(
            enabled: enabled,
            addGestureDetector: !dense,
            onShowMenu: () => focusNode.requestFocus(),
            actions: [
              ...actions,
              if (actions.isNotEmpty && defaultActions.isNotEmpty)
                ActionFromZero.divider(),
              ...defaultActions,
            ],
            child: result,
          );
          return result;
        },
      ),
    );
    if (addCard) {
      result = Card(
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
                ValidationMessage(errors: validationErrors),
            ],
          ),
        ),
      ),
    );
  }

  static SimpleColModel numFieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      flex: field.tableColumnWidth?.round() ?? 192,
      alignment: TextAlign.right,
      defaultSortAscending: false,
    );
  }

}