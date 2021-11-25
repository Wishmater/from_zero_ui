import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';


class ComboField<T extends DAO> extends Field<T> {

  final FieldValueGetter<List<T>?, ComboField<T>>? possibleValuesGetter;
  List<T>? get possibleValues => possibleValuesGetter?.call(this, dao);
  final FieldValueGetter<Future<List<T>>?, ComboField<T>>? futurePossibleValuesGetter;
  Future<List<T>>? get futurePossibleValues => futurePossibleValuesGetter?.call(this, dao);
  final bool showSearchBox;
  final ExtraWidgetBuilder<T>? extraWidget;
  final FieldValueGetter<DAO?, ComboField<T>>? newObjectTemplateGetter;
  DAO? get newObjectTemplate => newObjectTemplateGetter?.call(this, dao);
  final bool sort;
  final bool showViewActionOnDAOs;
  final bool showDropdownIcon;
  final bool invalidateValuesNotInPossibleValues;


  ComboField({
    required FieldValueGetter<String, Field> uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = Field.defaultClearableGetter,
    double maxWidth = 512,
    double minWidth = 128,
    double flex = 0,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    this.possibleValuesGetter,
    this.futurePossibleValuesGetter,
    this.sort = true,
    this.showSearchBox = true,
    this.showViewActionOnDAOs = true,
    this.showDropdownIcon = false,
    this.extraWidget,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.newObjectTemplateGetter,
    FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<T?>? undoValues,
    List<T?>? redoValues,
    this.invalidateValuesNotInPossibleValues = true,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    T? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) :  assert(possibleValuesGetter!=null || futurePossibleValuesGetter!=null),
        assert(possibleValuesGetter==null || futurePossibleValuesGetter==null),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          maxWidth: maxWidth,
          minWidth: minWidth,
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
  ComboField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    FieldValueGetter<List<T>?, ComboField<T>>? possibleValuesGetter,
    FieldValueGetter<Future<List<T>>?, ComboField<T>>? futurePossibleValuesGetter,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    bool? sort,
    bool? showSearchBox,
    bool? showViewActionOnDAOs,
    bool? showDropdownIcon,
    ExtraWidgetBuilder<T>? extraWidget,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<DAO?, ComboField<T>>? newObjectTemplateGetter,
    FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<T?>? undoValues,
    List<T?>? redoValues,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    T? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) {
    return ComboField<T>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      possibleValuesGetter: possibleValuesGetter??this.possibleValuesGetter,
      futurePossibleValuesGetter: futurePossibleValuesGetter??this.futurePossibleValuesGetter,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      sort: sort??this.sort,
      showSearchBox: showSearchBox??this.showSearchBox,
      extraWidget: extraWidget??this.extraWidget,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      newObjectTemplateGetter: newObjectTemplateGetter ?? this.newObjectTemplateGetter,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      showViewActionOnDAOs: showViewActionOnDAOs ?? this.showViewActionOnDAOs,
      showDropdownIcon: showDropdownIcon ?? this.showDropdownIcon,
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
  Future<bool> validate(BuildContext context, DAO dao, {
    bool validateIfNotEdited=false,
  }) async {
    super.validate(context, dao, validateIfNotEdited: validateIfNotEdited);
    List<T> possibleValues;
    if (futurePossibleValues!=null) {
      possibleValues = await futurePossibleValues!;
    } else {
      possibleValues = this.possibleValues!;
    }
    if (invalidateValuesNotInPossibleValues && value!=null && !possibleValues.contains(value)) {
      validationErrors.add(InvalidatingError<T>(
        field: this,
        error: FromZeroLocalizations.of(context).translate("validation_combo_not_possible"),
        defaultValue: null,
      ));
    }
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    return validationErrors.where((e) => e.isBlocking).isEmpty;
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
    ExtraWidgetBuilder<T>? extraWidget;
    final newObjectTemplate = this.newObjectTemplate;
    if (newObjectTemplate?.onSave!=null) {
      extraWidget = (context, onSelected) {
        final oldOnSave = newObjectTemplate!.onSave!;
        final newOnSave = (context, e) async {
          DAO? newDAO = await oldOnSave(context, e);
          if (newDAO!=null) {
            WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
              onSelected?.call(newDAO as T);
              Navigator.of(context).pop(true);
            });
          }
          return newDAO;
        };
        final emptyDAO = newObjectTemplate.copyWith(
          onSave: newOnSave,
        );
        return Column (
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (this.extraWidget!=null)
              this.extraWidget!(context, onSelected),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2,),
                child: TextButton(
                  onPressed: () async {
                     emptyDAO.maybeEdit(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6,),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 6),
                        Icon(Icons.add),
                        SizedBox(width: 6,),
                        Text('New ${emptyDAO.classUiName}', style: TextStyle(fontSize: 16),),
                        SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      };
    }
    Widget result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        Widget result = ComboFromZero<T>(
          focusNode: focusNode,
          enabled: enabled,
          clearable: clearable,
          title: uiName,
          hint: hint,
          value: value,
          possibleValues: possibleValues,
          futurePossibleValues: futurePossibleValues,
          sort: sort,
          showSearchBox: showSearchBox,
          onSelected: _onSelected,
          popupWidth: maxWidth,
          buttonPadding: dense ? EdgeInsets.zero : null,
          buttonChildBuilder: (context, title, hint, value, enabled, clearable, {showDropdownIcon=false}) {
            return buttonContentBuilder(context, title, hint, value, enabled, clearable,
              showDropdownIcon: showDropdownIcon,
              dense: dense,
            );
          },
          extraWidget: extraWidget ?? this.extraWidget,
          showViewActionOnDAOs: showViewActionOnDAOs,
          showDropdownIcon: showDropdownIcon,
        );
        result = AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: dense && validationErrors.isNotEmpty
          ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![validationErrors.first.severity]!.withOpacity(0.2)
              : backgroundColor?.call(context, this, dao),
          curve: Curves.easeOut,
          child: result,
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
        result = ContextMenuFromZero(
          enabled: enabled,
          addGestureDetector: !dense,
          actions: [
            ...actions,
            if (actions.isNotEmpty)
              ActionFromZero.divider(),
            ...buildDefaultActions(context),
          ],
          child: result,
        );
        return result;
      },
    );
    if (addCard) {
      result = Card(
        clipBehavior: Clip.hardEdge,
        color: enabled ? null : Theme.of(context).canvasColor,
        child: result,
      );
    }
    result = EnsureVisibleWhenFocused(
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
    return result;
  }

  bool? _onSelected(T? v) {
    value = v;
  }

  static Widget buttonContentBuilder(BuildContext context, String? title, String? hint, dynamic value, bool enabled, bool clearable, {
    bool showDropdownIcon = true,
    dense = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: enabled&&clearable ? 40 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: dense ? 0 : 8,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dense
                    ? Text(value==null ? (hint ?? title ?? '') : value.toString(), style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 0.8,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ))
                : value==null&&hint==null&&title!=null
                    ? Text(title, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                      ),)
                    : MaterialKeyValuePair(
                      padding: 6,
                      title: title,
                      titleStyle: Theme.of(context).textTheme.caption!.copyWith(
                        color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                      ),
                      value: value==null ? (hint ?? '') : value.toString(),
                      valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ),
                    ),
                SizedBox(height: 4,),
              ],
            ),
          ),
          SizedBox(width: dense ? 0 : 4,),
          if (!dense && showDropdownIcon && enabled && !clearable)
            Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyText1!.color,),
          SizedBox(width: dense ? 0 : 4,),
        ],
      ),
    );
  }

}