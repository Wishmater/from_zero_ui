import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_components/file_picker_from_zero.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_ensure_visible_when_focused.dart';
import 'package:path/path.dart' as path;


class FileField extends StringField {

  final FileType fileType;
  final List<String>? allowedExtensions;
  final bool enableDragAndDrop;
  final bool allowDragAndDropInWholeScreen;
  final bool pickDirectory;
  final bool allowTyping;
  final String? initialDirectory;


  File? get file => value.isNullOrEmpty ? null : File(value!);
  String? get filename {
    return value.isNullOrEmpty ? null
        : pickDirectory
            ? '$value${path.separator}'
            : value?.split('/').last.split('\\').last;
  }


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
    String? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    super.actionsGetter,
    ViewWidgetBuilder<String> viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    OnFieldValueChanged<String?>? onValueChanged,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.enableDragAndDrop = true,
    this.allowDragAndDropInWholeScreen = false,
    this.pickDirectory = false,
    this.allowTyping = false,
    this.initialDirectory,
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
    FileType? fileType,
    List<String>? allowedExtensions,
    bool? enableDragAndDrop,
    bool? allowDragAndDropInWholeScreen,
    bool? pickDirectory,
    bool? allowTyping,
    String? initialDirectory,
    // StringField fields
    bool? obfuscate,
    bool? showObfuscationToggleButton,
    bool? trimOnSave,
    StringFieldType? type,
    int? minLines,
    int? maxLines,
    InputDecoration? inputDecoration,
    List<TextInputFormatter>? inputFormatters,
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
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      fileType: fileType ?? this.fileType,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      allowDragAndDropInWholeScreen: allowDragAndDropInWholeScreen ?? this.allowDragAndDropInWholeScreen,
      pickDirectory: pickDirectory ?? this.pickDirectory,
      allowTyping: allowTyping ?? this.allowTyping,
      initialDirectory: initialDirectory ?? this.initialDirectory,
      // StringField fields
      // obfuscate: obfuscate ?? this.obfuscate,
      // showObfuscationToggleButton: showObfuscationToggleButton ?? this.showObfuscationToggleButton,
      // trimOnSave: trimOnSave ?? this.trimOnSave,
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
    if (allowTyping) {
      bool addedFilePicker = !enableDragAndDrop;
      return super.buildFieldEditorWidgets(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
        ignoreHidden: ignoreHidden,
        mainScrollController: mainScrollController,
      ).map((e) {
        if (!addedFilePicker) {
          addedFilePicker = true;
          return FilePickerFromZero(
            allowMultiple: false,
            dialogTitle: hint ?? uiName,
            fileType: fileType,
            allowedExtensions: allowedExtensions,
            enableDragAndDrop: enableDragAndDrop,
            allowDragAndDropInWholeScreen: allowDragAndDropInWholeScreen,
            onlyForDragAndDrop: true,
            pickDirectory: pickDirectory,
            initialDirectory: initialDirectory,
            enabled: enabled,
            onSelected: (value) {
              userInteracted = true;
              commitValue(value.first.absolute.path);
            },
            child: e,
          );
        }
        return e;
      }).toList();
    }
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
    BoxConstraints? constraints,
    required FocusNode focusNode,
  }) {
    String? initialDirectory;
    if (this.initialDirectory!=null) {
      initialDirectory = this.initialDirectory;
    } else if (value.isNotNullOrEmpty) {
      try { initialDirectory = File(value!).parent.path; } catch (_) {}
    }
    Widget result = NotificationListener(
      onNotification: (notification) => true,
      child: AnimatedBuilder(
        animation: this,
        builder: (context, child) {
          final visibleValidationErrors = passedFirstEdit
              ? validationErrors
              : validationErrors.where((e) => e.isBeforeEditing);
          Widget result = Stack(
            children: [
              Material(
                color: enabled ? Colors.transparent : Theme.of(context).canvasColor,
                child: FilePickerFromZero(
                  allowMultiple: false,
                  dialogTitle: hint ?? uiName,
                  fileType: fileType,
                  allowedExtensions: allowedExtensions,
                  enableDragAndDrop: enableDragAndDrop,
                  allowDragAndDropInWholeScreen: allowDragAndDropInWholeScreen,
                  pickDirectory: pickDirectory,
                  focusNode: focusNode,
                  initialDirectory: initialDirectory,
                  enabled: enabled,
                  onSelected: (value) {
                    userInteracted = true;
                    commitValue(value.first.absolute.path);
                  },
                  child: Builder(
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.only(right: dense ? 0 : context.findAncestorStateOfType<AppbarFromZeroState>()!.actions.length*40),
                        child: ComboField.buttonContentBuilder(context, uiName, hint, filename, enabled, false,
                          dense: dense,
                          showDropdownIcon: false,
                        ),
                      );
                    },
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
            message: (dense ? visibleValidationErrors : visibleValidationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling)).fold('', (a, b) {
              return a.toString().trim().isEmpty ? b.toString()
                  : b.toString().trim().isEmpty ? a.toString()
                  : '$a\n$b';
            }),
            waitDuration: enabled ? const Duration(seconds: 1) : Duration.zero,
            child: result,
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
              toolbarHeight: 56,
              paddingRight: 6,
              actionPadding: 0,
              skipTraversalForActions: true,
              constraints: const BoxConstraints(),
              actions: [
                ...actions,
                if (actions.isNotEmpty && defaultActions.isNotEmpty)
                  ActionFromZero.divider(breakpoints: {0: ActionState.popup}),
                ...defaultActions,
              ].map((e) => e.copyWith(
                enabled: enabled,
              ),).toList(),
              title: SizedBox(height: 56, child: result),
            );
          }
          result = ValidationRequiredOverlay(
            isRequired: isRequired,
            isEmpty: enabled && value==null,
            errors: validationErrors,
            dense: dense,
            child: result,
          );
          return result;
        },
      ),
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
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
                ValidationMessage(errors: validationErrors, passedFirstEdit: passedFirstEdit,),
            ],
          ),
        ),
      ),
    );
  }

  @override
  List<ActionFromZero> buildDefaultActions(BuildContext context, {FocusNode? focusNode}) {
    return [
      if (allowTyping)
        ActionFromZero(
          icon: const Icon(Icons.file_open),
          title: 'Load from File', // TODO 2 internationalize
          breakpoints: {0: ActionState.icon},
          onTap: (context) async {
            final result = await pickFileFromZero(
              dialogTitle: hint ?? uiName,
              fileType: fileType,
              allowedExtensions: allowedExtensions,
              pickDirectory: pickDirectory,
              initialDirectory: initialDirectory,
            );
            if (result!=null && result.isNotEmpty) {
              userInteracted = true;
              commitValue(result.first.absolute.path);
            }
          },
        ),
      ...super.buildDefaultActions(context, focusNode: focusNode),
    ];
  }

}

