import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';

enum StringFieldType {
  short,
  long,
}

class StringField extends Field<String> {

  late final TextEditingController controller = TextEditingController(text: value);
  StringFieldType type;
  int? minLines;
  int? maxLines;
  InputDecoration? inputDecoration;
  List<TextInputFormatter>? inputFormatters;
  bool obfuscate;
  bool trimOnSave;
  bool showObfuscationToggleButton; // TODO 2 implement obfuscation toggle button
  Timer? valUpdateTimer;

  @override
  set dbValue(String? v) {
    super.dbValue = v ?? '';
  }

  @override
  set value(String? v) {
    valUpdateTimer?.cancel();
    v ??= '';
    if (v.isEmpty || v.characters.last == ' ' || v.characters.last == '\n' || !isEdited) {
      commitValue(v);
    } else if (value != controller.text) {
      addUndoEntry(value);
      valUpdateTimer = Timer(Duration(seconds: 2), () {
        commitValue(v);
      });
    }
  }
  void commitValue(String? v) {
    super.value = v;
    syncTextEditingController();
  }

  @override
  void undo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitUndo(controller.text,
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
    super.commitRedo(controller.text,
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
    if (value != controller.text) {
      controller.text = value ?? '';
      controller.selection = TextSelection.collapsed(offset: value!.length);
    }
  }

  StringField({
    required FieldValueGetter<String, Field> uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = Field.defaultClearableGetter,
    double maxWidth = 512,
    double minWidth = 128,
    double flex = 0,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    this.type = StringFieldType.short,
    int? minLines,
    int? maxLines,
    this.obfuscate = false,
    bool? showObfuscationToggleButton,
    this.inputDecoration,
    this.inputFormatters,
    this.trimOnSave = true,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<String?>? undoValues,
    List<String?>? redoValues,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    String? defaultValue = '',
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    super.actionsGetter,
    ViewWidgetBuilder<String> viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    OnFieldValueChanged<String?>? onValueChanged,
  }) :  this.minLines = minLines ?? (type==StringFieldType.short ? null : 3),
        this.maxLines = maxLines ?? (type==StringFieldType.short ? 1 : 999999999),
        this.showObfuscationToggleButton = showObfuscationToggleButton ?? obfuscate,
        super(
          uiNameGetter: uiNameGetter,
          value: value ?? '',
          dbValue: dbValue ?? value ?? '',
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
          viewWidgetBuilder: viewWidgetBuilder,
          onValueChanged: onValueChanged,
        );


  @override
  StringField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    StringFieldType? type,
    int? minLines,
    int? maxLines,
    bool? trimOnSave,
    InputDecoration? inputDecoration,
    List<TextInputFormatter>? inputFormatters,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<String?>? undoValues,
    List<String?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    String? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter,
    ViewWidgetBuilder<String>? viewWidgetBuilder,
    OnFieldValueChanged<String?>? onValueChanged,
    bool? obfuscate,
    bool? showObfuscationToggleButton,
  }) {
    return StringField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      type: type??this.type,
      minLines: minLines??this.minLines,
      maxLines: maxLines??this.maxLines,
      inputDecoration: inputDecoration??this.inputDecoration,
      inputFormatters: inputFormatters??this.inputFormatters,
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
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      trimOnSave: trimOnSave ?? this.trimOnSave,
      obfuscate: obfuscate ?? this.obfuscate,
      showObfuscationToggleButton: showObfuscationToggleButton ?? this.showObfuscationToggleButton,
    );
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
            largeVertically: maxLines!=1,
            largeHorizontally: constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium,
            focusNode: focusNode!,
            dense: dense,
            constraints: constraints,
          );
        },
      );
    } else {
      result = _buildFieldEditorWidget(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        focusNode: focusNode,
        largeVertically: maxLines!=1,
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
    bool largeVertically = true,
    bool largeHorizontally = false,
    bool dense = false,
    required FocusNode focusNode,
    BoxConstraints? constraints,
  }) {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        valUpdateTimer?.cancel();
        if (controller.text != value) {
          super.value = controller.text;
        }
        if (!passedFirstEdit) {
          if (dao.contextForValidation!=null) {
            passedFirstEdit = true;
            validate(dao.contextForValidation!, dao, dao.validationCallCount);
            notifyListeners();
          }
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
              KeyboardListener(
                includeSemantics: false,
                focusNode: FocusNode()..skipTraversal=true,
                onKeyEvent: (value) {
                  if (value is KeyDownEvent && type==StringFieldType.short) {
                    if (value.logicalKey==LogicalKeyboardKey.arrowDown) {
                      focusNode.focusInDirection(TraversalDirection.down);
                    } else if (value.logicalKey==LogicalKeyboardKey.arrowUp) {
                      focusNode.focusInDirection(TraversalDirection.up);
                    }
                  }
                },
                child: RawGestureDetector(
                  behavior: HitTestBehavior.translucent,
                  gestures: {
                    TransparentTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TransparentTapGestureRecognizer>(
                          () => TransparentTapGestureRecognizer(debugOwner: this),
                          (TapGestureRecognizer instance) {
                        instance // hack to fix textField breaking when window loses focus on desktop
                          ..onTapDown = (details) => controller.notifyListeners();
                      },
                    ),
                  },
                  child: Builder(
                    builder: (context) {
                      return TextFormField(
                        controller: controller,
                        enabled: enabled,
                        focusNode: focusNode,
                        toolbarOptions: ToolbarOptions( // TODO 2 this might be really bad on Android
                          copy: false, cut: false, paste: false, selectAll: false,
                        ),
                        onEditingComplete: () {
                          focusNode.nextFocus();
                        },
                        minLines: minLines,
                        maxLines: minLines==null||minLines!<=(maxLines??0) ? maxLines : minLines,
                        obscureText: obfuscate,
                        onChanged: (v) {
                          userInteracted = true;
                          value = v;
                        },
                        inputFormatters: inputFormatters,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                        ),
                        decoration: inputDecoration??InputDecoration(
                          border: InputBorder.none,
                          alignLabelWithHint: dense,
                          label: Padding(
                            padding: EdgeInsets.only(
                              top: !dense&&hint!=null ? 12 : largeVertically ? 0 : 8,
                              bottom: !dense&&hint!=null ? 12 : largeVertically ? 6 : 0,
                            ),
                            child: Text(uiName,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          hintText: hint,
                          floatingLabelBehavior: dense ? FloatingLabelBehavior.never
                              : !enabled ? (value==null||value!.isEmpty) ? FloatingLabelBehavior.never : FloatingLabelBehavior.always
                              : hint!=null ? FloatingLabelBehavior.always : FloatingLabelBehavior.auto,
                          labelStyle: TextStyle(
                            height: dense ? 0 : largeVertically ? 0.5 : hint!=null ? 1 : 0.7,
                            color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                          ),
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.caption!.color),
                          contentPadding: EdgeInsets.only(
                            left: dense ? 0 : 16,
                            right: dense ? 0 : (16 + (context.findAncestorStateOfType<AppbarFromZeroState>()!.actions.length*40)),
                            bottom: largeVertically ? 16 : dense ? 10 : 0,
                            top: largeVertically ? 16 : dense ? 0 : 6,
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),
              // if (!enabled)
              //   Positioned.fill(
              //     child: MouseRegion(
              //       cursor: SystemMouseCursors.forbidden,
              //     ),
              //   ),
            ],
          );
          result = TooltipFromZero(
            message: validationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
              return a.toString().trim().isEmpty ? b.toString()
                  : b.toString().trim().isEmpty ? a.toString()
                  : '$a\n$b';
            }),
            child: result,
            waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
          );
          if (!dense) {
            final actions = buildActions(context, focusNode);
            final defaultActions = buildDefaultActions(context);
            result = AppbarFromZero(
              addContextMenu: enabled,
              onShowContextMenu: () => focusNode.requestFocus(),
              backgroundColor: Colors.transparent,
              elevation: 0,
              useFlutterAppbar: false,
              extendTitleBehindActions: true,
              toolbarHeight: largeVertically ? null : 56,
              paddingRight: 6,
              actionPadding: 0,
              skipTraversalForActions: true,
              constraints: BoxConstraints(),
              actions: [
                ...actions,
                if (actions.isNotEmpty && defaultActions.isNotEmpty)
                  ActionFromZero.divider(breakpoints: {0: ActionState.popup}),
                ...defaultActions,
              ].map((e) => e.copyWith(
                enabled: enabled,
              )).toList(),
              title: SizedBox(height: largeVertically ? null : 56, child: result),
            );
          }
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
                ValidationMessage(errors: validationErrors),
            ],
          ),
        ),
      ),
    );
  }

}


class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

