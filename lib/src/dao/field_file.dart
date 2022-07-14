import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:from_zero_ui/src/ui_components/file_picker_from_zero.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';


class FileField extends Field<String> {

  final FileType fileType;
  final List<String>? allowedExtensions;
  final bool enableDragAndDrop;
  final bool allowDragAndDropInWholeScreen;


  File? get file => value==null ? null : File(value!);
  String? get filename => value?.split('/').last.split('\\').last;


  FileField({
    required FieldValueGetter<String, Field> uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = Field.defaultClearableGetter,
    double maxWidth = 512,
    double minWidth = 128,
    double flex = 0,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    bool? showObfuscationToggleButton,
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
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<String> viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    OnFieldValueChanged<String?>? onValueChanged,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.enableDragAndDrop = true,
    this.allowDragAndDropInWholeScreen = false,
  }) :  super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue ?? value,
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
  FileField copyWith({
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
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<String>? viewWidgetBuilder,
    OnFieldValueChanged<String?>? onValueChanged,
    FileType? fileType,
    List<String>? allowedExtensions,
    bool? enableDragAndDrop,
    bool? allowDragAndDropInWholeScreen,
  }) {
    return FileField(
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
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      fileType: fileType ?? this.fileType,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      allowDragAndDropInWholeScreen: allowDragAndDropInWholeScreen ?? this.allowDragAndDropInWholeScreen,
    );
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
    bool largeHorizontally = false,
    bool dense = false,
    required FocusNode focusNode,
  }) {
    Widget result = NotificationListener(
      onNotification: (notification) => true,
      child: AnimatedBuilder(
        animation: this,
        builder: (context, child) {
          Widget result = Stack(
            children: [
              Material(
                type: MaterialType.transparency,
                child: FilePickerFromZero(
                  allowMultiple: false,
                  dialogTitle: hint ?? uiName,
                  fileType: fileType,
                  allowedExtensions: allowedExtensions,
                  enableDragAndDrop: enableDragAndDrop,
                  allowDragAndDropInWholeScreen: allowDragAndDropInWholeScreen,
                  focusNode: focusNode,
                  onSelected: (value) {
                    this.value = value.first.absolute.path;
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ComboField.buttonContentBuilder(context, uiName, hint, filename, enabled, clearable,
                      dense: dense,
                      showDropdownIcon: false,
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
  }

}

