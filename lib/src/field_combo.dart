import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/field_validators.dart';


class ComboField<T extends DAO> extends Field<T> {

  final FieldValueGetter<List<T>?, ComboField<T>>? possibleValuesGetter;
  List<T>? get possibleValues => possibleValuesGetter?.call(this, dao);
  final FieldValueGetter<Future<List<T>>?, ComboField<T>>? futurePossibleValuesGetter;
  Future<List<T>>? get futurePossibleValues => futurePossibleValuesGetter?.call(this, dao);
  final bool showSearchBox;
  final ExtraWidgetBuilder<T>? extraWidget;
  final FieldValueGetter<DAO?, ComboField<T>>? newObjectTemplateGetter;
  DAO? get newObjectTemplate => newObjectTemplateGetter?.call(this, dao);
  final bool showViewActionOnDAOs;
  final bool showDropdownIcon;
  final bool invalidateValuesNotInPossibleValues;

  set value(T? v) {
    if (v!=value) {
      passedFirstEdit = true;
      super.value = v;
    }
  }

  ComboField({
    required FieldValueGetter<String, Field> uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter,
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter,
    double maxWidth = 512,
    FieldValueGetter<String?, Field>? hintGetter,
    this.possibleValuesGetter,
    this.futurePossibleValuesGetter,
    this.showSearchBox = true,
    this.showViewActionOnDAOs = true,
    this.showDropdownIcon = true,
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
  }) :  assert(possibleValuesGetter!=null || futurePossibleValuesGetter!=null),
        assert(possibleValuesGetter==null || futurePossibleValuesGetter==null),
        super(
          uiNameGetter: uiNameGetter,
          value: value,
          dbValue: dbValue,
          clearableGetter: clearableGetter,
          enabledGetter: enabledGetter,
          maxWidth: maxWidth,
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
  ComboField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    FieldValueGetter<List<T>?, ComboField<T>>? possibleValuesGetter,
    FieldValueGetter<Future<List<T>>?, ComboField<T>>? futurePossibleValuesGetter,
    FieldValueGetter<String?, Field>? hintGetter,
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
  }) {
    return ComboField<T>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabledGetter: enabledGetter??this.enabledGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      possibleValuesGetter: possibleValuesGetter??this.possibleValuesGetter,
      futurePossibleValuesGetter: futurePossibleValuesGetter??this.futurePossibleValuesGetter,
      hintGetter: hintGetter??this.hintGetter,
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
      undoValues: undoValues ?? this.undoValues,
      redoValues: redoValues ?? this.redoValues,
    );
  }

  @override
  Future<bool> validate(BuildContext context, DAO dao) async {
    super.validate(context, dao);
    List<T> possibleValues;
    if (futurePossibleValues!=null) {
      possibleValues = await futurePossibleValues!;
    } else {
      possibleValues = this.possibleValues!;
    }
    if (invalidateValuesNotInPossibleValues && value!=null && !possibleValues.contains(value)) {
      validationErrors.add(InvalidatingError(
        error: FromZeroLocalizations.of(context).translate("validation_combo_not_possible"),
        defaultValue: null,
      ));
    }
    return validationErrors.where((e) => e.isBlocking).isEmpty;
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
        return ComboFromZero<T>(
          enabled: enabled,
          clearable: clearable,
          title: uiName,
          hint: hint,
          value: value,
          possibleValues: possibleValues,
          futurePossibleValues: futurePossibleValues,
          showSearchBox: showSearchBox,
          onSelected: _onSelected,
          popupWidth: maxWidth,
          buttonChildBuilder: buttonContentBuilder,
          extraWidget: extraWidget ?? this.extraWidget,
          showViewActionOnDAOs: showViewActionOnDAOs,
          showDropdownIcon: showDropdownIcon,
        );
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

  bool? _onSelected(T? v) {
    value = v;
  }

  static Widget buttonContentBuilder(BuildContext context, String? title, String? hint, dynamic value, bool enabled, bool clearable, {
    bool showDropdownIcon = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: enabled&&clearable ? 40 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 8,),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MaterialKeyValuePair(
                  title: title,
                  padding: 6,
                  value: value==null ? (hint ?? '') : value.toString(),
                  valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                    height: 1,
                    color: value==null ? Theme.of(context).textTheme.caption!.color!
                        : Theme.of(context).textTheme.bodyText1!.color!,
                  ),
                ),
                SizedBox(height: 4,),
              ],
            ),
          ),
          SizedBox(width: 4,),
          if (showDropdownIcon && enabled && !clearable)
            Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyText1!.color,),
          SizedBox(width: 4,),
          // SizedBox(width: !(enabled && clearable) ? 36 : 4,),
        ],
      ),
    );
  }

}