import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/field_validators.dart';


class ComboField<T extends DAO> extends Field<T> {

  final List<T>? possibleValues;
  final Future<List<T>>? futurePossibleValues;
  final bool showSearchBox;
  final ExtraWidgetBuilder<T>? extraWidget;
  final DAO? newObjectTemplate;

  set value(T? v) {
    passedFirstEdit = true;
    super.value = v;
  }

  ComboField({
    required String uiName,
    T? value,
    T? dbValue,
    bool clearable = true,
    bool enabled = true,
    double maxWidth = 512,
    String? hint,
    this.possibleValues,
    this.futurePossibleValues,
    this.showSearchBox = true,
    this.extraWidget,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    this.newObjectTemplate,
    List<FieldValidator<T>> validators = const[],
    bool validateOnlyOnConfirm = false,
  }) :  assert(possibleValues!=null || futurePossibleValues!=null),
        super(
          uiName: uiName,
          value: value,
          dbValue: dbValue,
          clearable: clearable,
          enabled: enabled,
          maxWidth: maxWidth,
          hint: hint,
          tableColumnWidth: tableColumnWidth,
          hidden: hidden,
          hiddenInTable: hiddenInTable,
          hiddenInView: hiddenInView,
          hiddenInForm: hiddenInForm,
          validators: validators,
        validateOnlyOnConfirm: validateOnlyOnConfirm,
        );

  @override
  ComboField copyWith({
    String? uiName,
    T? value,
    T? dbValue,
    bool? clearable,
    bool? enabled,
    double? maxWidth,
    List<T>? possibleValues,
    Future<List<T>>? futurePossibleValues,
    String? hint,
    bool? showSearchBox,
    ExtraWidgetBuilder<T>? extraWidget,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
    DAO? newObjectTemplate,
    List<FieldValidator<T>>? validators,
    bool? validateOnlyOnConfirm,
  }) {
    return ComboField<T>(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearable: clearable??this.clearable,
      enabled: enabled??this.enabled,
      maxWidth: maxWidth??this.maxWidth,
      possibleValues: possibleValues??this.possibleValues,
      futurePossibleValues: futurePossibleValues??this.futurePossibleValues,
      hint: hint??this.hint,
      showSearchBox: showSearchBox??this.showSearchBox,
      extraWidget: extraWidget??this.extraWidget,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTable: hiddenInTable ?? hidden ?? this.hiddenInTable,
      hiddenInView: hiddenInView ?? hidden ?? this.hiddenInView,
      hiddenInForm: hiddenInForm ?? hidden ?? this.hiddenInForm,
      newObjectTemplate: newObjectTemplate ?? this.newObjectTemplate,
      validators: validators ?? this.validators,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
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
    ExtraWidgetBuilder<T>? extraWidget;
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
        final emptyDAO = newObjectTemplate!.copyWith(
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
    Widget result = ChangeNotifierBuilder(
      changeNotifier: this,
      builder: (context, v, child) {
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
          buttonChildBuilder: _buttonContentBuilder,
          extraWidget: extraWidget ?? this.extraWidget,
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
      child: Center(
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
              if (validationErrors.isNotEmpty)
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

  Widget _buttonContentBuilder(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable) {
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
          if (enabled && !clearable)
            Icon(Icons.arrow_drop_down),
          SizedBox(width: !(enabled && clearable) ? 36 : 4,),
        ],
      ),
    );
  }

}