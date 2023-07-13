import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/src/table/empty_widget.dart';
import 'package:from_zero_ui/src/table/table_header.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/util/comparable_list.dart';
import 'package:from_zero_ui/src/ui_utility/translucent_ink_well.dart' as translucent;
import 'package:preload_page_view/preload_page_view.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:dartx/dartx.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';


enum RowTapType {
  view,
  edit,
  none
}

enum ListFieldDisplayType {
  table,
  popupButton,
  tabbedForm,
}

typedef T AvailablePoolTransformerFunction<T>(T selected);

class ListField<T extends DAO<U>, U> extends Field<ComparableList<T>> {

  FieldValueGetter<T, ListField<T, U>> objectTemplateGetter;
  TableController<T>? _tableController;
  TableController<T> get tableController {
    _tableController ??= TableController<T>();
    return _tableController!;
  }
  ContextFulFieldValueGetter<Future<List<T>>, ListField<T, U>>? availableObjectsPoolGetter;
  ContextFulFieldValueGetter<ApiProvider<List<T>>, ListField<T, U>>? availableObjectsPoolProvider;
  bool invalidateValuesNotInAvailablePool;
  bool allowDuplicateObjectsFromAvailablePool;
  bool allowAddMultipleFromAvailablePool;
  bool showObjectsFromAvailablePoolAsTable;
  AvailablePoolTransformerFunction<T>? transformSelectedFromAvailablePool; /// transformation applied to selected items from available pool before adding them to ListField rows
  ContextFulFieldValueGetter<List<ActionFromZero>, Field>? availablePoolTableActions;
  bool? _allowAddNew;
  bool get allowAddNew => _allowAddNew ?? objectTemplate.canSave;
  bool collapsed;
  bool allowMultipleSelection;
  bool selectionDefault;
  bool tableCellsEditable;
  bool collapsible;
  bool allowTableCustomization;
  RowTapType rowTapType;
  ListFieldDisplayType displayType;
  bool validateChildren;
  String Function(ListField<T, U> field) toStringGetter;
  Map<double, ActionState> actionViewBreakpoints;
  Map<double, ActionState> actionEditBreakpoints;
  Map<double, ActionState> actionDuplicateBreakpoints;
  Map<double, ActionState> actionDeleteBreakpoints;
  Map<String, ColModel> Function(DAO dao, ListField<T, U> listField, T objectTemplate)? tableColumnsBuilder;
  RowModel<T> Function(T element, BuildContext context, ListField<T, U> field, DAO dao, Map<String, ColModel> columns, ValueChanged<RowModel<T>>? onRowTap, Widget? rowAddonWidget)? tableRowBuilder;
  Widget? Function(BuildContext context, RowModel<T> row, int index, double? minWidth, Widget Function(BuildContext context, RowModel<T> row, int index, double? minWidth) defaultRowBuilder)? tableRowWidgetBuilder;
  /// this means that save() will be called on the object when adding a row
  /// and delete() will be called when removing a row, default false
  bool? _skipDeleteConfirmation;
  bool get skipDeleteConfirmation => _skipDeleteConfirmation ?? !objectTemplate.canDelete;
  bool showTableHeaders;
  bool showTableHeaderAddon;
  bool showElementCount;
  double? rowHeight;
  bool? _showDefaultSnackBars;
  bool get showDefaultSnackBars => _showDefaultSnackBars ?? objectTemplate.canSave;
  ContextFulFieldValueGetter<List<RowAction<T>>, ListField<T, U>>? extraRowActionsBuilder; //TODO 3 also allow global action builders
  bool showEditDialogOnAdd;
  bool showAddButtonAtEndOfTable;
  Widget? tableErrorWidget;
  dynamic initialSortedColumn;
  ValueChanged<RowModel>? onRowTap;
  bool? tableSortable;
  bool? tableFilterable;
  bool expandHorizontally;
  List<ValidationError> listFieldValidationErrors = [];
  Widget? icon; /// only used if !collapsible
  List<RowModel<T>> Function(List<RowModel<T>>)? onFilter;
  FutureOr<String>? exportPathForExcel;
  bool buildViewWidgetAsTable;
  bool addSearchAction;
  double tableFooterStickyOffset;
  double tableHorizontalPadding;
  String? rowAddonField;
  double? separateScrollableBreakpoint;
  FieldValueGetter<List<ListField<T, U>>, ListField<T, U>>? proxiedListFields; // objects from these fields will also show here
  String? Function(RowModel<T> row)? rowDisabledValidator;
  String? Function(RowModel<T> row)? rowTooltipGetter;

  T get objectTemplate => objectTemplateGetter(this, dao)..parentDAO = dao;
  List<T> get objects {
    if (proxiedListFields==null) {
      return value!.list;
    } else {
      final proxiedFields = proxiedListFields!(this, dao);
      return [
        ...value!.list,
        ...proxiedFields.map((e) {
          e.addListener(notifyListenersAndReinitTable);
          for (final e in e.value!.list) {
            e.addListener(notifyListenersAndReinitTable);
          }
          return e.value!.list;
        }).flatten(),
      ];
    }
  }
  List<T> get dbObjects {
    if (proxiedListFields==null) {
      return dbValue!.list;
    } else {
      final proxiedFields = proxiedListFields!(this, dao);
      return [
        ...dbValue!.list,
        ...proxiedFields.map((e) => e.dbValue!.list).flatten(),
      ];
    }
  }
  void notifyListenersAndReinitTable() {
    tableController.reInit();
    notifyListeners();
  }
  @override
  set value(ComparableList<T>? value) {
    assert(value!=null, 'ListField is non-nullable by design.');
    super.value = value;
    tableController.reInit();
  }
  @override
  void commitUndo(ComparableList<T>? currentValue, {
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitUndo(currentValue,
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
    tableController.reInit();
  }
  @override
  void commitRedo(ComparableList<T>? currentValue, {
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    super.commitRedo(currentValue,
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
    tableController.reInit();
  }
  @override
  void revertChanges() {
    super.revertChanges();
    tableController.reInit();
  }

  bool get enabled => DAO.ignoreBlockingErrors ? true : listFieldValidationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling).isEmpty;

  bool get userInteracted => super.userInteracted || objects.any((e) => e.userInteracted);

  late ValueNotifier<Map<T, bool>> selectedObjects;

  static String defaultToString(ListField field) {
    return listToStringSmart(field.objects,
      modelNameSingular: field.objectTemplate.classUiName,
      modelNamePlural: field.objectTemplate.classUiNamePlural,
    );
  }
  static String listToStringSmart(List list, {
    String? modelNameSingular,
    String? modelNamePlural,
    BuildContext? context, // for localization
  }) {
    return list.length>5
        ? listToStringCount(list, modelNameSingular: modelNameSingular, modelNamePlural: modelNamePlural)
        : listToStringAll(list);
  }
  static String listToStringAll<T>(Iterable<T> list, {
    String Function(T value)? converter,
  }) {
    String result = '';
    for (final e in list) {
      if (result.isNotEmpty) {
        result += ', ';
      }
      result += converter?.call(e) ?? e.toString();
    }
    return result;
  }
  static String listToStringCount(Iterable list, {
    String? modelNameSingular,
    String? modelNamePlural,
    BuildContext? context, // for localization
  }) {
    final name = list.length==1
        ? (modelNameSingular.isNotNullOrBlank ? modelNameSingular : (context==null ? ''
            : FromZeroLocalizations.of(context).translate('element_sing')))
        : (modelNamePlural.isNotNullOrBlank ? modelNamePlural : (context==null ? ''
            : FromZeroLocalizations.of(context).translate('element_plur')));
    return '${list.length} $name';
  }

  ListField({
    required FieldValueGetter<String, Field> uiNameGetter,
    required this.objectTemplateGetter,
    required List<T> objects,
    List<T>? dbObjects,
    this.availableObjectsPoolGetter,
    this.availableObjectsPoolProvider,
    this.allowDuplicateObjectsFromAvailablePool = false,
    this.showObjectsFromAvailablePoolAsTable = false,
    this.transformSelectedFromAvailablePool,
    this.availablePoolTableActions,
    bool? allowAddNew,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, /// Unused in table
    this.tableCellsEditable = false,
    bool? allowTableCustomization,
    double maxWidth = double.infinity,
    double minWidth = 512,
    double flex = 0,
    TableController<T>? tableController,
    this.collapsed = false,
    this.allowMultipleSelection = false,
    this.selectionDefault = false,
    this.collapsible = false,
    this.displayType = ListFieldDisplayType.table,
    this.toStringGetter = defaultToString,
    RowTapType? rowTapType,
    Map<double, ActionState>? actionViewBreakpoints,
    Map<double, ActionState>? actionEditBreakpoints,
    Map<double, ActionState>? actionDuplicateBreakpoints,
    Map<double, ActionState>? actionDeleteBreakpoints,
    this.tableColumnsBuilder,
    this.tableRowBuilder,
    this.tableRowWidgetBuilder,
    this.showTableHeaders = true,
    this.showTableHeaderAddon = true,
    this.showElementCount = true,
    this.rowHeight,
    bool? showDefaultSnackBars,
    bool? skipDeleteConfirmation,
    this.extraRowActionsBuilder,
    this.showAddButtonAtEndOfTable = false,
    bool? showEditDialogOnAdd,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    this.tableErrorWidget,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.initialSortedColumn,
    this.onRowTap,
    FieldValueGetter<List<FieldValidator<ComparableList<T>>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    this.tableSortable,
    bool? tableFilterable,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<ComparableList<T>?>? undoValues,
    List<ComparableList<T>?>? redoValues,
    GlobalKey? fieldGlobalKey,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    this.invalidateValuesNotInAvailablePool = false,
    ComparableList<T>? defaultValue,
    this.expandHorizontally = true,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    super.actionsGetter,
    ViewWidgetBuilder<ComparableList<T>> viewWidgetBuilder = ListField.defaultViewWidgetBuilder,
    this.icon,
    this.onFilter,
    this.exportPathForExcel,
    this.buildViewWidgetAsTable = false,
    this.addSearchAction = false,
    bool? validateChildren,
    OnFieldValueChanged<ComparableList<T>?>? onValueChanged,
    this.tableFooterStickyOffset = 12,
    this.tableHorizontalPadding = 8,
    this.rowAddonField,
    this.allowAddMultipleFromAvailablePool = true,
    ValueNotifier<Map<T, bool>>? selectedObjects,
    this.pageNotifier,
    this.separateScrollableBreakpoint = 30,
    this.proxiedListFields,
    this.rowDisabledValidator,
    this.rowTooltipGetter,
  }) :  assert(availableObjectsPoolGetter==null || availableObjectsPoolProvider==null),
        this.tableFilterable = tableFilterable ?? false,
        this.showEditDialogOnAdd = showEditDialogOnAdd ?? (displayType==ListFieldDisplayType.table && !tableCellsEditable),
        this._showDefaultSnackBars = showDefaultSnackBars,
        this._skipDeleteConfirmation = skipDeleteConfirmation,
        this.rowTapType = rowTapType ?? (onRowTap==null && !tableCellsEditable ? RowTapType.view : RowTapType.none),
        this.actionEditBreakpoints = actionEditBreakpoints ?? {0: displayType==ListFieldDisplayType.tabbedForm ? ActionState.none : ActionState.popup},
        this.actionDuplicateBreakpoints = actionDuplicateBreakpoints ?? {0: ActionState.none},
        this.actionDeleteBreakpoints = actionDeleteBreakpoints ?? {0: ActionState.icon},
        this.actionViewBreakpoints = actionViewBreakpoints ?? {0: ActionState.popup},
        this._tableController = tableController,
        this._allowAddNew = allowAddNew,
        this.validateChildren = tableCellsEditable && (validateChildren ?? true),
        this.allowTableCustomization = allowTableCustomization ?? !tableCellsEditable,
        super(
          uiNameGetter: uiNameGetter,
          value: ComparableList(list: objects),
          dbValue: ComparableList(list: dbObjects ?? objects),
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
          fieldGlobalKey: fieldGlobalKey,
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue ?? ComparableList<T>(),
          backgroundColor: backgroundColor,
          viewWidgetBuilder: viewWidgetBuilder,
          onValueChanged: onValueChanged,
        ) {
    this.selectedObjects = selectedObjects ?? ValueNotifier({});
    addListeners();
  }

  void addListeners() {
    value!.list.forEach((element) {
      element.addListener(notifyListeners);
    });
  }

  @override
  set dao(DAO dao) {
    super.dao = dao;
    value!.list.forEach((element) {
      element.parentDAO = dao;
    });
  }

  @override
  String toString() {
    return toStringGetter(this);
  }

  @override
  bool get isEdited {
    bool edited = objects.length != dbObjects.length;
    for (var i = 0; !edited && i < objects.length; ++i) {
      edited = objects[i] != dbObjects[i];
    }
    if (!edited) {
      edited = objects.any((element) => element.isEdited);
    }
    return edited;
  }
  bool get hasAvailableObjectsPool
      => availableObjectsPoolGetter!=null || availableObjectsPoolProvider!=null;

  @override
  Future<bool> validate(BuildContext context, DAO dao, int currentValidationId, {
    bool validateIfNotEdited=false,
    bool validateIfHidden=false,
  }) async {
    final objects = this.objects;
    final superResult = super.validate(context, dao, currentValidationId,
      validateIfNotEdited: validateIfNotEdited,
      validateIfHidden: validateIfHidden,
    );
    if (currentValidationId!=dao.validationCallCount) return false;
    if (!validateChildren && !invalidateValuesNotInAvailablePool) {
      bool success = await superResult;
      listFieldValidationErrors = List.from(validationErrors);
      return success;
    }
    List<Future<bool>> results = [];
    final templateProps = transformSelectedFromAvailablePool==null
        ? objectTemplate.props
        : transformSelectedFromAvailablePool!(objectTemplate).props;
    List<T>? possibleValues;
    List<T>? confirmedValidValues;
    if (invalidateValuesNotInAvailablePool) {
      confirmedValidValues = [];
      final provider = availableObjectsPoolProvider?.call(context, this, dao);
      if (provider!=null) {
        possibleValues = await (context as WidgetRef).watch(provider.notifier).future;
      } else {
        possibleValues = await availableObjectsPoolGetter?.call(context, this, dao);
      }
    }
    for (final e in objects) {
      final objectProps = e.props;
      if (invalidateValuesNotInAvailablePool && possibleValues!=null && !possibleValues.contains(e)) {
        // don't add to confirmed, so it will be removed by the invalidatingError
      } else {
        confirmedValidValues?.add(e);
        if (validateChildren) {
          for (final key in templateProps.keys) {
            final field = objectProps[key];
            if (field!=null) {
              if (currentValidationId!=dao.validationCallCount) return false;
              results.add(field.validate(context, e, currentValidationId,
                validateIfNotEdited: validateIfNotEdited,
              ));
            }
          }
        }
      }
    }
    if (currentValidationId!=dao.validationCallCount) return false;
    bool success = await superResult;
    listFieldValidationErrors = List.from(validationErrors);
    for (final e in results) {
      success = success && await e;
      if (currentValidationId!=dao.validationCallCount) return false;
    }
    if (invalidateValuesNotInAvailablePool && confirmedValidValues!=null && confirmedValidValues.length!=objects.length) {
      validationErrors.add(InvalidatingError<ComparableList<T>>(
        field: this,
        error: FromZeroLocalizations.of(context).translate("validation_combo_not_possible"),
        defaultValue: ComparableList(list: confirmedValidValues),
      ));
    }
    for (final e in objects) {
      final objectProps = e.props;
      for (final key in templateProps.keys) {
        final field = objectProps[key];
        if (field!=null) {
          validationErrors.addAll(field.validationErrors
              .map((err) => err.copyWith(
                error: err.error.isNullOrBlank
                    ? '' : '${e.classUiName} - ${err.error}',
              )));
        }
      }
    }
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    return validationErrors.where((e) => e.isBlocking).isEmpty;
  }

  @override
  ListField<T, U> copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    ComparableList<T>? value,
    ComparableList<T>? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    FieldValueGetter<T, ListField<T, U>>? objectTemplateGetter,
    Future<List<T>>? futureObjects,
    List<T>? objects,
    List<T>? dbObjects,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    bool? collapsible,
    Map<double, ActionState>? actionViewBreakpoints,
    Map<double, ActionState>? actionEditBreakpoints,
    Map<double, ActionState>? actionDuplicateBreakpoints,
    Map<double, ActionState>? actionDeleteBreakpoints,
    Map<String, ColModel> Function(DAO dao, ListField<T, U> listField, T objectTemplate)? tableColumnsBuilder,
    RowModel<T> Function(T element, BuildContext context, ListField<T, U> field, DAO dao, Map<String, ColModel> columns, ValueChanged<RowModel<T>>? onRowTap, Widget? rowAddonWidget)? tableRowBuilder,
    Widget? Function(BuildContext context, RowModel<T> row, int index, double? minWidth, Widget Function(BuildContext context, RowModel<T> row, int index, double? minWidth) defaultRowBuilder)? tableRowWidgetBuilder,
    bool? skipDeleteConfirmation,
    bool? showTableHeaders,
    bool? showTableHeaderAddon,
    bool? showElementCount,
    double? rowHeight,
    ContextFulFieldValueGetter<Future<List<T>>, ListField<T, U>>? availableObjectsPoolGetter,
    ContextFulFieldValueGetter<ApiProvider<List<T>>, ListField<T, U>>? availableObjectsPoolProvider,
    bool? allowDuplicateObjectsFromAvailablePool,
    bool? showObjectsFromAvailablePoolAsTable,
    AvailablePoolTransformerFunction<T>? transformSelectedFromAvailablePool,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? availablePoolTableActions,
    bool? allowAddNew,
    ListFieldDisplayType? displayType,
    String Function(ListField field)? toStringGetter,
    ContextFulFieldValueGetter<List<RowAction<T>>, ListField<T, U>>? extraRowActionBuilders,
    int? initialSortColumn,
    bool? tableCellsEditable,
    bool? allowTableCustomization,
    bool? allowMultipleSelection,
    bool? selectionDefault,
    ValueChanged<RowModel>? onRowTap,
    bool? showAddButtonAtEndOfTable,
    bool? showEditDialogOnAdd,
    Widget? tableErrorWidget,
    bool? showDefaultSnackBars,
    FieldValueGetter<List<FieldValidator<ComparableList<T>>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    TableController<T>? tableController,
    bool? tableSortable,
    bool? tableFilterable,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<ComparableList<T>?>? undoValues,
    List<ComparableList<T>?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    bool? invalidateValuesNotInAvailablePool,
    ComparableList<T>? defaultValue,
    bool? expandHorizontally,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter,
    ViewWidgetBuilder<ComparableList<T>>? viewWidgetBuilder,
    Widget? icon,
    List<RowModel<T>> Function(List<RowModel<T>>)? onFilter,
    FutureOr<String>? exportPathForExcel,
    bool? buildViewWidgetAsTable,
    bool? addSearchAction,
    OnFieldValueChanged<ComparableList<T>?>? onValueChanged,
    RowTapType? rowTapType,
    double? tableFooterStickyOffset,
    double? tableHorizontalPadding,
    String? rowAddonField,
    bool? allowAddMultipleFromAvailablePool,
    ValueNotifier<int>? pageNotifier,
    double? separateScrollableBreakpoint,
    FieldValueGetter<List<ListField<T, U>>, ListField<T, U>>? proxiedListFields,
    String? Function(RowModel<T> row)? rowDisabledValidator,
    String? Function(RowModel<T> row)? rowTooltipGetter,
  }) {
    return ListField<T, U>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      objectTemplateGetter: objectTemplateGetter??this.objectTemplateGetter,
      objects: objects??this.objects.map((e) => e.copyWith() as T).toList(),
      dbObjects: dbObjects??objects??this.dbObjects.map((e) => e.copyWith() as T).toList(),
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      collapsible: collapsible ?? this.collapsible,
      actionViewBreakpoints: actionViewBreakpoints ?? this.actionViewBreakpoints,
      actionEditBreakpoints: actionEditBreakpoints ?? this.actionEditBreakpoints,
      actionDuplicateBreakpoints: actionDuplicateBreakpoints ?? this.actionDuplicateBreakpoints,
      actionDeleteBreakpoints: actionDeleteBreakpoints ?? this.actionDeleteBreakpoints,
      availableObjectsPoolGetter: availableObjectsPoolGetter ?? this.availableObjectsPoolGetter,
      availableObjectsPoolProvider: availableObjectsPoolProvider ?? this.availableObjectsPoolProvider,
      allowDuplicateObjectsFromAvailablePool: allowDuplicateObjectsFromAvailablePool ?? this.allowDuplicateObjectsFromAvailablePool,
      availablePoolTableActions: availablePoolTableActions ?? this.availablePoolTableActions,
      allowAddNew: allowAddNew ?? this._allowAddNew,
      displayType: displayType ?? this.displayType,
      toStringGetter: toStringGetter ?? this.toStringGetter,
      extraRowActionsBuilder: extraRowActionBuilders ?? this.extraRowActionsBuilder,
      skipDeleteConfirmation: skipDeleteConfirmation ?? this._skipDeleteConfirmation,
      showTableHeaders: showTableHeaders ?? this.showTableHeaders,
      showTableHeaderAddon: showTableHeaderAddon ?? this.showTableHeaderAddon,
      showElementCount: showElementCount ?? this.showElementCount,
      rowHeight: rowHeight ?? this.rowHeight,
      initialSortedColumn: initialSortColumn ?? this.initialSortedColumn,
      tableCellsEditable: tableCellsEditable ?? this.tableCellsEditable,
      allowTableCustomization: allowTableCustomization ?? this.allowTableCustomization,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      selectionDefault: selectionDefault ?? this.selectionDefault,
      onRowTap: onRowTap ?? this.onRowTap,
      showAddButtonAtEndOfTable: showAddButtonAtEndOfTable ?? this.showAddButtonAtEndOfTable,
      showEditDialogOnAdd: showEditDialogOnAdd ?? this.showEditDialogOnAdd,
      tableErrorWidget: tableErrorWidget ?? this.tableErrorWidget,
      showDefaultSnackBars: showDefaultSnackBars ?? this._showDefaultSnackBars,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      showObjectsFromAvailablePoolAsTable: showObjectsFromAvailablePoolAsTable ?? this.showObjectsFromAvailablePoolAsTable,
      transformSelectedFromAvailablePool: transformSelectedFromAvailablePool ?? this.transformSelectedFromAvailablePool,
      tableController: tableController ?? this.tableController,
      tableSortable: tableSortable ?? this.tableSortable,
      tableFilterable: tableFilterable ?? this.tableFilterable,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? List.from(this.undoValues),
      redoValues: redoValues ?? List.from(this.redoValues),
      invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm ?? this.invalidateNonEmptyValuesIfHiddenInForm,
      invalidateValuesNotInAvailablePool: invalidateValuesNotInAvailablePool ?? this.invalidateValuesNotInAvailablePool,
      defaultValue: defaultValue ?? this.defaultValue,
      expandHorizontally: expandHorizontally ?? this.expandHorizontally,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      icon: icon ?? this.icon,
      onFilter: onFilter ?? this.onFilter,
      exportPathForExcel: exportPathForExcel ?? this.exportPathForExcel,
      buildViewWidgetAsTable: buildViewWidgetAsTable ?? this.buildViewWidgetAsTable,
      addSearchAction: addSearchAction ?? this.addSearchAction,
      onValueChanged: onValueChanged ?? this.onValueChanged,
      rowTapType: rowTapType ?? this.rowTapType,
      tableColumnsBuilder: tableColumnsBuilder ?? this.tableColumnsBuilder,
      tableRowBuilder: tableRowBuilder ?? this.tableRowBuilder,
      tableRowWidgetBuilder: tableRowWidgetBuilder ?? this.tableRowWidgetBuilder,
      tableFooterStickyOffset: tableFooterStickyOffset ?? this.tableFooterStickyOffset,
      tableHorizontalPadding: tableHorizontalPadding ?? this.tableHorizontalPadding,
      rowAddonField: rowAddonField ?? this.rowAddonField,
      allowAddMultipleFromAvailablePool: allowAddMultipleFromAvailablePool ?? this.allowAddMultipleFromAvailablePool,
      pageNotifier: pageNotifier ?? this.pageNotifier,
      separateScrollableBreakpoint: separateScrollableBreakpoint ?? this.separateScrollableBreakpoint,
      proxiedListFields: proxiedListFields ?? this.proxiedListFields,
      rowDisabledValidator: rowDisabledValidator ?? this.rowDisabledValidator,
      rowTooltipGetter: rowTooltipGetter ?? this.rowTooltipGetter,
    );
  }

  void addRow (T element, [int? insertIndex]) => addRows([element], insertIndex);
  void addRows (Iterable<T> elements, [int? insertIndex]) {
    for (final e in elements) {
      e.addListener(notifyListeners);
      e.parentDAO = dao;
    }
    final newValue = value!.copyWith();
    if (insertIndex==null || insertIndex<0 || insertIndex>newValue.length) {
      newValue.addAll(elements);
    } else {
      for (final e in elements) {
        newValue.insert(insertIndex!, e);
        insertIndex++;
      }
    }
    value = newValue;
    focusObject(elements.first);
  }

  bool replaceRow(T oldRow, T newRow) => replaceRows({oldRow: newRow});
  bool replaceRows(Map<T, T> elements) {
    bool result = true;
    final newValue = value!.copyWith();
    elements.forEach((key, value) {
      value.parentDAO = dao;
      int index = newValue.indexOf(key);
      bool foundInProxy = false;
      if (index<0 && proxiedListFields!=null) {
        for (final proxiedList in proxiedListFields!(this, dao)) {
          if (proxiedList.value!.contains(key)) {
            foundInProxy = true;
            proxiedList.replaceRow(key, value);
          }
        }
      }
      if (!foundInProxy) {
        if (index>=0) {
          newValue.removeAt(index);
        } else {
          result = false;
        }
        if (index>=0) {
          newValue.insert(index, value);
        } else {
          newValue.add(value);
        }
      }
    });
    value = newValue;
    focusObject(elements.values.first);
    return result;
  }

  void duplicateRow(T element) => duplicateRows([element]);
  void duplicateRows(Iterable<T> elements) {
    final newValue = value!.copyWith();
    elements.forEach((e) {
      e.parentDAO = dao;
      int index = newValue.indexOf(e);
      final newItem = (e.copyWith()..id = null) as T;
      if (index<0) {
        newValue.add(newItem);
      } else {
        newValue.insert(index+1, newItem);
      }
    });
    value = newValue;
    focusObject(elements.first);
  }

  bool removeRow(T element) => removeRows([element]);
  bool removeRows(Iterable<T> elements) {
    bool result = false;
    final newValue = value!.copyWith();
    elements.forEach((e) {
      result = newValue.remove(e) || result;
      if (proxiedListFields!=null) {
        for (final proxiedList in proxiedListFields!(this, dao)) {
          result = proxiedList.removeRow(e) || result;
        }
      }
    });
    if (result) {
      value = newValue;
    }
    return result;
  }


  void focusObject(T object) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        if (tableCellsEditable) {
          object.props.values.firstOrNullWhere((e) => !e.hiddenInForm)?.focusNode.requestFocus();
        } else {
          _builtRows[object]?.focusNode.requestFocus();
        }
      } catch (_) {}
    });
  }

  Future<dynamic> maybeAddRow(context, [int? insertIndex]) async {
    focusNode.requestFocus();
    final objectTemplate = this.objectTemplate;
    T emptyDAO = (objectTemplate.copyWith() as T)..id=null;
    if (emptyDAO is LazyDAO) (emptyDAO as LazyDAO).ensureInitialized();
    emptyDAO.contextForValidation = dao.contextForValidation;
    if (hasAvailableObjectsPool) {
      var selected;
      if (showObjectsFromAvailablePoolAsTable) {
        final ValueNotifier<Map<T, bool>> selectedObjects = ValueNotifier({});
        ValueNotifier<List<T>?> availableData = ValueNotifier(null);
        emptyDAO.onDidSave = (BuildContext context, U? model, DAO<U> dao) {
          objectTemplate.onDidSave?.call(context, model, dao);
          try {
            if ((model as dynamic).id!=-1) dao.id = (model as dynamic).id;
          } catch (_) {
            try {
              if (dao.id!=-1) dao.id = model;
            } catch(_) {}
          }
          selectedObjects.value[dao as T] = true;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            Navigator.of(context).pop(dao);
          });
        };
        Widget content = AnimatedBuilder(
          animation:  this,
          builder: (context, child) {
            return Stack(
              children: [
                availableObjectsPoolProvider==null
                    ? FutureBuilderFromZero<List<T>>(
                        future: availableObjectsPoolGetter!(context, this, dao),
                        loadingBuilder: _availablePoolLoadingBuilder,
                        errorBuilder: (context, error, stackTrace) => _availablePoolErrorBuilder(context, error, stackTrace is StackTrace ? stackTrace : null),
                        successBuilder: (context, data) {
                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                            availableData.value = data;
                          });
                          return _availablePoolTableDataBuilder(context, data, emptyDAO,
                            selectedObjects: selectedObjects,
                          );
                        },
                      )
                    : ApiProviderBuilder<List<T>>(
                        provider: availableObjectsPoolProvider!(context, this, dao),
                        loadingBuilder: _availablePoolLoadingBuilder,
                        errorBuilder: _availablePoolErrorBuilder,
                        dataBuilder: (context, data) {
                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                            availableData.value = data;
                          });
                          return _availablePoolTableDataBuilder(context, data, emptyDAO,
                            selectedObjects: selectedObjects,
                          );
                        },
                      ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).cardColor.withOpacity(0),
                              Theme.of(context).cardColor,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(bottom: 8, right: 16,),
                        color: Theme.of(context).cardColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FlatButton(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              textColor: Theme.of(context).textTheme.caption!.color,
                              onPressed: () {
                                Navigator.of(context).pop(); // Dismiss alert dialog
                              },
                            ),
                            if (allowAddMultipleFromAvailablePool)
                              MultiValueListenableBuilder(
                                valueListenables: [
                                  availableData,
                                  selectedObjects,
                                ],
                                builder: (context, values, child) {
                                  List<T>? availableData = values[0];
                                  Map<T, bool> selectedObjects = values[1];
                                  final selected = availableData==null ? [] : availableData.where((e) {
                                    return selectedObjects[e] ?? selectionDefault;
                                  }).toList();
                                  return FlatButton(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(FromZeroLocalizations.of(context).translate('accept_caps'),
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    textColor: Colors.blue,
                                    onPressed: selected.isEmpty ? null : () {
                                      Navigator.of(context).pop(selected);
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
        selected = await showPopupFromZero(
          context: context,
          anchorKey: headerGlobalKey,
          width: maxWidth==double.infinity ? null : maxWidth,
          builder: (modalContext) {
            return content;
          },
        );
      } else {
        selected = await showPopupFromZero(
          context: context,
          anchorKey: headerGlobalKey,
          builder: (context) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16+42,),
                  child: availableObjectsPoolProvider==null
                      ? FutureBuilderFromZero<List<T>>(
                          future: availableObjectsPoolGetter!(context, this, dao),
                          loadingBuilder: _availablePoolLoadingBuilder,
                          errorBuilder: (context, error, stackTrace) => _availablePoolErrorBuilder(context, error, stackTrace is StackTrace ? stackTrace : null),
                          successBuilder: (context, data) {
                            return _availablePoolComboDataBuilder(context, data, emptyDAO);
                          },
                        )
                      : ApiProviderBuilder<List<T>>(
                          provider: availableObjectsPoolProvider!(context, this, dao),
                          loadingBuilder: _availablePoolLoadingBuilder,
                          errorBuilder: _availablePoolErrorBuilder,
                          dataBuilder: (context, data) {
                            return _availablePoolComboDataBuilder(context, data, emptyDAO);
                          },
                        ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).cardColor.withOpacity(0),
                              Theme.of(context).cardColor,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(bottom: 8, right: 16,),
                        color: Theme.of(context).cardColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FlatButton(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              textColor: Theme.of(context).textTheme.caption!.color,
                              onPressed: () {
                                Navigator.of(context).pop(); // Dismiss alert dialog
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }
      if (selected!=null) {
        if (selected is T) {
          if (transformSelectedFromAvailablePool!=null) {
            selected = transformSelectedFromAvailablePool!(selected);
          }
          addRow(selected, insertIndex);
        } else {
          if (transformSelectedFromAvailablePool!=null) {
            selected = (selected as List<T>).map((e) => transformSelectedFromAvailablePool!(e)).toList();
          }
          addRows(selected as List<T>, insertIndex);
        }
        return selected;
      }
    } else {
      dynamic result;
      if (showEditDialogOnAdd) {
        result = await emptyDAO.maybeEdit(dao.contextForValidation ?? context, showDefaultSnackBars: showDefaultSnackBars);
        if (result!=null) {
          addRow(emptyDAO, insertIndex);
          return emptyDAO;
        }
      } else {
        addRow(emptyDAO, insertIndex);
        return emptyDAO;
      }
    }
  }
  Widget _availablePoolErrorBuilder(BuildContext context, Object? error, StackTrace? stackTrace, [VoidCallback? onRetry]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42),
      child: IntrinsicHeight(
        child: ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace, onRetry),
      ),
    );
  }

  Widget _availablePoolLoadingBuilder(BuildContext context, [ValueListenable<double?>? progress]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42),
      child: SizedBox(
        height: 128,
        child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
      ),
    );
  }
  Widget _availablePoolTableDataBuilder(BuildContext context, List<T> data, T emptyDAO, {
    ValueNotifier<Map<T, bool>>? selectedObjects,
  }) {
    ScrollController scrollController = ScrollController();
    if (!allowDuplicateObjectsFromAvailablePool) {
      data = data.where((e) => !objects.contains(e)).toList();
    }
    final listField = ListField<T, U>(
      uiNameGetter: (field, dao) => uiName,
      objectTemplateGetter: (field, dao) => emptyDAO,
      tableCellsEditable: false,
      collapsible: false,
      actionDeleteBreakpoints: {0: ActionState.none},
      actionViewBreakpoints: actionViewBreakpoints,
      actionEditBreakpoints: actionEditBreakpoints,
      objects: data,
      actionsGetter: availablePoolTableActions,
      allowAddNew: allowAddNew && emptyDAO.canSave,
      initialSortedColumn: initialSortedColumn,
      tableFooterStickyOffset: 56,
      addSearchAction: true,
      allowMultipleSelection: allowAddMultipleFromAvailablePool,
      selectedObjects: selectedObjects,
      selectionDefault: selectionDefault,
      rowTapType: RowTapType.none,
      onRowTap: allowAddMultipleFromAvailablePool ? null : (value) {
        Navigator.of(context).pop(value.id);
      },
    );
    listField.dao = dao;
    return ScrollbarFromZero(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        shrinkWrap: true,
        slivers: [
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
          //     child: Text('${FromZeroLocalizations.of(context).translate("add_add")} $uiName',
          //       style: Theme.of(context).textTheme.headline6,
          //     ),
          //   ),
          // ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
              child: Text('${FromZeroLocalizations.of(context).translate("add_add")} $uiName',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
          ...listField.buildFieldEditorWidgets(context,
            asSliver: true,
            addCard: false,
          ),
          SliverToBoxAdapter(child: SizedBox(height: 32+16+42,)),
        ],
      ),
    );
  }
  Widget _availablePoolComboDataBuilder(BuildContext context, List<T> data, T emptyDAO) {
    if (!allowDuplicateObjectsFromAvailablePool) {
      data = data.where((e) => !objects.contains(e)).toList();
    }
    return ComboFromZeroPopup<T>(
      possibleValues: data,
      showSearchBox: true,
      title: '${FromZeroLocalizations.of(context).translate("add_add")} $uiName',
      extraWidget: allowAddNew ? (context, onSelected) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2,),
            child: TextButton(
              onPressed: () async {
                final model = await emptyDAO.maybeEdit(dao.contextForValidation ?? context, showDefaultSnackBars: showDefaultSnackBars);
                if (model!=null) {
                  Navigator.of(context).pop(emptyDAO);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6,),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 6),
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(width: 6,),
                    Text('${FromZeroLocalizations.of(context).translate("add")} ${emptyDAO.classUiName}', style: TextStyle(fontSize: 16),),
                    SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      } : null,
    );
  }

  Future<bool> maybeDelete(BuildContext context, List<T> elements,) async {
    if (elements.isEmpty) return false;
    bool? delete = skipDeleteConfirmation || hasAvailableObjectsPool || (await showModal(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(FromZeroLocalizations.of(context).translate('confirm_delete_title')),
          content: Text('${FromZeroLocalizations.of(context).translate('confirm_delete_desc')} ${elements.length} ${elements.length>1 ? FromZeroLocalizations.of(context).translate('element_plur') : FromZeroLocalizations.of(context).translate('element_sing')}?'),
          // TODO 2 show more details about elements to be deleted
          actions: [
            FlatButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(FromZeroLocalizations.of(context).translate('cancel_caps'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              textColor: Theme.of(context).textTheme.caption!.color,
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss alert dialog
              },
            ),
            FlatButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(FromZeroLocalizations.of(context).translate('delete_caps'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              textColor: Colors.red,
              onPressed: () {
                Navigator.of(context).pop(true); // Dismiss alert dialog
              },
            ),
            SizedBox(width: 2,),
          ],
        );
      },
    ) ?? false);
    if (delete) {
      bool result = false;
      if (!hasAvailableObjectsPool && objectTemplate.canDelete) {
        if (elements.length>1) {
          throw new UnimplementedError('multiple deletion handling not implemented');
        }
        result = await elements.first.delete(dao.contextForValidation ?? context, showDefaultSnackBar: showDefaultSnackBars);
        if (result) {
          result = removeRows(elements);
        }
      } else {
        result = removeRows(elements);
      }
      return result;
    }
    return false;
  }

  static void maybeEditMultiple<T extends DAO>(BuildContext context, List<T> elements) async {
    // TODO 3 test this well, rework it visually to be like maybeEdit

    final T dao = elements.first.copyWith() as T;
    // change hints and clear all properties
    dao.beginUndoTransaction();
    dao.props.forEach((key, value) {
      // TODO 3 should we remove validators / disable validation
      value.hintGetter = (_, __) => FromZeroLocalizations.of(context).translate('keep_value');
      value.dbValue = null;
      value.value = null;
      value.undoValues = [];
      value.redoValues = [];
    });
    // discard undo stack
    dao.beginUndoTransaction(); dao.commitUndoTransaction();
    ScrollController scrollController = ScrollController();
    bool? confirm = await showModal(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            if (!dao.isEdited) return true;
            bool? pop = await showModal(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(FromZeroLocalizations.of(context).translate('confirm_close_title')),
                  content: Text(FromZeroLocalizations.of(context).translate('confirm_close_desc')),
                  actions: [
                    FlatButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(FromZeroLocalizations.of(context).translate('cancel_caps'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: Theme.of(context).textTheme.caption!.color,
                      onPressed: () {
                        Navigator.of(context).pop(false); // Dismiss alert dialog
                      },
                    ),
                    AnimatedBuilder(
                      animation:  dao,
                      builder: (context, child) {
                        return FlatButton(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(FromZeroLocalizations.of(context).translate('close_caps'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          textColor: Colors.red,
                          onPressed: () {
                            Navigator.of(context).pop(true); // Dismiss alert dialog
                          },
                        );
                      },
                    ),
                    SizedBox(width: 2,),
                  ],
                );
              },
            );
            return pop??false;
          },
          child: Center(
            child: SizedBox(
              width: 512+128,
              child: ResponsiveInsetsDialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 32, right: 32,),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(FromZeroLocalizations.of(context).translate('edit_multiple_title'),
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          SizedBox(height: 12,),
                          Text('${FromZeroLocalizations.of(context).translate('edit_multiple_desc1')} ${elements.length} ${elements.length>1  ? FromZeroLocalizations.of(context).translate('element_plur')
                              : FromZeroLocalizations.of(context).translate('element_sing')} ${FromZeroLocalizations.of(context).translate('edit_multiple_desc2')}',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ],
                      ),
                    ),
                    ScrollbarFromZero(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: CustomScrollView(
                          controller: scrollController,
                          shrinkWrap: true,
                          slivers: dao.buildFormWidgets(context, showActionButtons: false,), // TODO 3 why not use maybeEdit to show everything
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FlatButton(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(FromZeroLocalizations.of(context).translate('cancel_caps'),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                            textColor: Theme.of(context).textTheme.caption!.color,
                            onPressed: () {
                              Navigator.of(context).maybePop(); // Dismiss alert dialog
                            },
                          ),
                          AnimatedBuilder(
                            animation:  dao,
                            builder: (context, child) {
                              return FlatButton(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(FromZeroLocalizations.of(context).translate('accept_caps'),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                textColor: Colors.blue,
                                onPressed: dao.isEdited ? () async {
                                  bool? edit = await showModal(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(FromZeroLocalizations.of(context).translate('confirm_save_title')),
                                        content: Text('${FromZeroLocalizations.of(context).translate('edit_multiple_confirm')} ${elements.length} ${elements.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                                            : FromZeroLocalizations.of(context).translate('element_sing')}?'),
                                        // TODO 3 show all details about each field about to change
                                        actions: [
                                          FlatButton(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(FromZeroLocalizations.of(context).translate('cancel_caps'),
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            textColor: Theme.of(context).textTheme.caption!.color,
                                            onPressed: () {
                                              Navigator.of(context).pop(false); // Dismiss alert dialog
                                            },
                                          ),
                                          FlatButton(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(FromZeroLocalizations.of(context).translate('accept_caps'),
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            textColor: Colors.blue,
                                            onPressed: () {
                                              Navigator.of(context).pop(true); // Dismiss alert dialog
                                            },
                                          ),
                                          SizedBox(width: 2,),
                                        ],
                                      );
                                    },
                                  );
                                  if (edit??false) {
                                    Navigator.of(context).pop(true);
                                  }
                                } : null,
                              );
                            },
                          ),
                          SizedBox(width: 2,),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (confirm??false) {
      dao.props.forEach((key, value) {
        if (value.isEdited) {
          elements.forEach((e) {
            e.props[key]?.value = value.value;
          });
        }
      });
    }
  }

  GlobalKey headerGlobalKey = GlobalKey();
  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    bool ignoreHidden = false,
    FocusNode? focusNode,
    ScrollController? mainScrollController,
  }) {
    if (hiddenInForm && !ignoreHidden) {
      Widget result;
      result = SizedBox.shrink();
      if (asSliver) {
        result = SliverToBoxAdapter(child: result,);
      }
      return [result];
    }
    if (dense || displayType==ListFieldDisplayType.popupButton) {
      return builWidgetsAsPopupButton(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
      );
    } else if (displayType==ListFieldDisplayType.tabbedForm) {
      return builWidgetsAsTabbedForm(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
      );
    } else {
      return buildWidgetsAsTable(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
        mainScrollController: mainScrollController,
      );
    }
  }

  List<Widget> builWidgetsAsPopupButton(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    FocusNode? focusNode,
  }) {
    focusNode ??= this.focusNode;
    Widget result;
    if (expandToFillContainer) {
      result = LayoutBuilder(
        builder: (context, constraints) {
          return _builWidgetsAsPopupButton(context,
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
      result = _builWidgetsAsPopupButton(context,
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
  Widget _builWidgetsAsPopupButton(BuildContext context, {
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
        Widget result = TextButton(
          focusNode: focusNode,
          style: TextButton.styleFrom(
            padding: dense ? EdgeInsets.zero : null,
          ),
          child: ComboField.buttonContentBuilder(context, uiName, hint ?? uiName, toString(), enabled, false,
            showDropdownIcon: false,
            dense: dense,
          ),
          onPressed: () async {
            focusNode.requestFocus();
            await showPopupFromZero<bool>(
              context: context,
              anchorKey: fieldGlobalKey,
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...buildWidgetsAsTable(context,
                      addCard: false,
                      asSliver: false, // TODO 3 try to do it as sliver for better performance
                      expandToFillContainer: false,
                      dense: false,
                      focusNode: FocusNode(),
                      collapsed: false,
                      collapsible: false,
                      fieldGlobalKey: ValueKey('popup'),
                    ),
                  ],
                );
              },
            );
          },
        );
        final visibleListFieldValidationErrors = passedFirstEdit
            ? listFieldValidationErrors
            : listFieldValidationErrors.where((e) => e.isBeforeEditing);
        result = AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: dense && visibleListFieldValidationErrors.isNotEmpty
              ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![visibleListFieldValidationErrors.first.severity]!.withOpacity(0.2)
              : backgroundColor?.call(context, this, dao),
          curve: Curves.easeOut,
          child: result,
        );
        result = TooltipFromZero(
          message: listFieldValidationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
            return a.toString().trim().isEmpty ? b.toString()
                : b.toString().trim().isEmpty ? a.toString()
                : '$a\n$b';
          }),
          child: result,
          waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
        );
        final actions = buildActions(dao.contextForValidation ?? context, focusNode);
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
      key: fieldGlobalKey,
      child: Padding(
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
                ValidationMessage(errors: listFieldValidationErrors, passedFirstEdit: passedFirstEdit,),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  ValueNotifier<int>? pageNotifier;
  int? lastPage;
  List<Widget> builWidgetsAsTabbedForm(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    FocusNode? focusNode,
  }) {
    focusNode ??= this.focusNode;
    Widget result;
    pageNotifier ??= ValueNotifier(0);
    result = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        final tabBarScrollController = ScrollController();
        final userActions = buildActions(dao.contextForValidation ?? context, focusNode);
        final defaultActions = buildDefaultActions(context);
        final allActions = [
          ...userActions,
          if (userActions.isNotEmpty && defaultActions.isNotEmpty)
            ActionFromZero.divider(),
          ...defaultActions,
        ];
        Widget result = Column(
          children: [
            ExcludeFocus(
              child: TooltipFromZero(
                message: listFieldValidationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
                  return a.toString().trim().isEmpty ? b.toString()
                      : b.toString().trim().isEmpty ? a.toString()
                      : '$a\n$b';
                }),
                waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppbarFromZero(
                        titleSpacing: 0,
                        addContextMenu: enabled,
                        backgroundColor: Theme.of(context).cardColor,
                        onShowContextMenu: () => focusNode!.requestFocus(),
                        title: Row(
                          children: [
                            SizedBox(width: 24,),
                            Expanded(
                              child: OverflowScroll(
                                autoscrollSpeed: null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(uiName,
                                      style: Theme.of(context).textTheme.headline6!.copyWith(
                                        fontSize: Theme.of(context).textTheme.headline6!.fontSize!*0.85,
                                      ),
                                    ),
                                    Text(objects.length==0 ? FromZeroLocalizations.of(context).translate('no_elements')
                                        : '${objects.length} ${objects.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                                        : FromZeroLocalizations.of(context).translate('element_sing')}',
                                      style: Theme.of(context).textTheme.caption,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        elevation: 0,
                        actions: allActions,
                      ),
                      ScrollbarFromZero(
                        controller: tabBarScrollController,
                        opacityGradientDirection: OpacityGradient.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: tabBarScrollController,
                          child: TabBar( // TODO 3 replace this with an actual widget: PageIndicatorFromzero. Allow to have an indicator + building children dinamically according to selected
                            isScrollable: true,
                            indicatorWeight: 4,
                            tabs: objects.mapIndexed((i, e) {
                              String name = e.toString();
                              if (name.isBlank) {
                                name = 'Pág. ${i+1}'; // TODO 3 internationalize
                              }
                              return ContextMenuFromZero(
                                enabled: enabled,
                                addOnTapDown: false,
                                onShowMenu: () => focusNode!.requestFocus(),
                                actions: [
                                  if ((allowAddNew||hasAvailableObjectsPool))
                                    ActionFromZero(
                                      title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
                                      icon: Icon(Icons.add, color: Colors.blue),
                                      breakpoints: {0: ActionState.popup,},
                                      onTap: (context) async {
                                        final result = await maybeAddRow(dao.contextForValidation ?? context, i);
                                        if (result!=null) {
                                          userInteracted = true;
                                        }
                                        pageNotifier!.value = i+1;
                                      },
                                    ),
                                  if ((allowAddNew||hasAvailableObjectsPool))
                                    RowAction.divider(),
                                  ActionFromZero(
                                    icon: Icon(Icons.edit_outlined),
                                    title: FromZeroLocalizations.of(context).translate('edit'),
                                    breakpoints: actionEditBreakpoints,
                                    onTap: (context) async {
                                      final copy = e.copyWith() as T;
                                      copy.parentDAO = null;
                                      copy.contextForValidation = dao.contextForValidation;
                                      final result = await copy.maybeEdit(dao.contextForValidation ?? context, showDefaultSnackBars: showDefaultSnackBars);
                                      if (result!=null) {
                                        replaceRow(e, copy);
                                        userInteracted = true;
                                        notifyListeners();
                                      }
                                    },
                                  ),
                                  ActionFromZero(
                                    icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
                                    title: FromZeroLocalizations.of(context).translate('duplicate'),
                                    breakpoints: actionDuplicateBreakpoints,
                                    onTap: (context) async {
                                      userInteracted = true;
                                      duplicateRows([e]);
                                    },
                                  ),
                                  if (objectTemplate.canDelete || hasAvailableObjectsPool)
                                    ActionFromZero(
                                      icon: Icon(!hasAvailableObjectsPool ? Icons.delete_forever_outlined : Icons.clear),
                                      title: FromZeroLocalizations.of(context).translate('delete'),
                                      breakpoints: actionDeleteBreakpoints,
                                      onTap: (context) async {
                                        if (await maybeDelete(context, [e],)) {
                                          focusNode!.requestFocus();
                                          userInteracted = true;
                                          passedFirstEdit = true;
                                          notifyListeners();
                                        }
                                      },
                                    ),
                                ],
                                child: Container(
                                  height: 38,
                                  padding: EdgeInsets.only(bottom: 6),
                                  alignment: Alignment.center,
                                  child: Text(name, style: Theme.of(context).textTheme.subtitle1,),
                                ),
                              );
                            }).toList(),
                            onTap: (value) {
                              pageNotifier!.value = value;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 0,
              child: TabBarView(
                children: List.filled(objects.length, Container()),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: pageNotifier!,
              builder: (context, page, child) {
                final tabController = DefaultTabController.of(context);
                if (page < 0 || page>objects.length-1) {
                  if (objects.length > 0) {
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      if (page < 0 || page>objects.length-1) {
                        pageNotifier!.value = objects.length-1;
                      }
                    });
                  }
                  return SizedBox.shrink();
                }
                if (page != tabController!.index) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if (page != tabController.index) {
                      tabController.animateTo(page);
                    }
                  });
                }
                final e = objects[page];
                String name = e.toString();
                if (name.isBlank) {
                  name = 'Pág. ${page+1}'; // TODO 3 internationalize
                }
                Widget result = PageTransitionSwitcher(
                  duration: Duration(milliseconds: 300),
                  reverse: lastPage!=null && lastPage!>page,
                  layoutBuilder: (List<Widget> entries) {
                    entries.sort((a, b) {
                      return ((b as KeyedSubtree).key as ValueKey).value
                          .compareTo(((a as KeyedSubtree).key as ValueKey).value);
                    },);
                    return Stack(
                      children: entries.sublist(0, min(2, entries.length)),
                      alignment: Alignment.topCenter,
                    );
                  },
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: Container(
                    key: ValueKey(page),
                    padding: const EdgeInsets.only(top: 2, bottom: 10, left: 8, right: 8,),
                    child: Column(
                      children: e.buildFormWidgets(context,
                        asSlivers: false,
                        showActionButtons: false,
                      ),
                    ),
                  ),
                );
                lastPage = page;
                return result;
              },
            ),
          ],
        );
        result = Stack(
          children: [
            Positioned(
              bottom: 8, top: 48,
              left: 2, right: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.all(
                    width: 2,
                    color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            result,
          ],
        );
        final visibleListFieldValidationErrors = passedFirstEdit
            ? listFieldValidationErrors
            : listFieldValidationErrors.where((e) => e.isBeforeEditing);
        result = DefaultTabController(
          length: objects.length,
          child: result,
        );
        result = AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: dense && visibleListFieldValidationErrors.isNotEmpty
              ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![visibleListFieldValidationErrors.first.severity]!.withOpacity(0.2)
              : backgroundColor?.call(context, this, dao),
          curve: Curves.easeOut,
          child: result,
        );
        return result;
      },
    );
    result = EnsureVisibleWhenFocused(
      focusNode: focusNode,
      key: fieldGlobalKey,
      child: SizedBox(
        width: maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            result,
            if (!dense)
              ValidationMessage(errors: listFieldValidationErrors, passedFirstEdit: passedFirstEdit,),
          ],
        ),
      ),
    );
    if (asSliver) {
      result = SliverToBoxAdapter(
        child: result,
      );
    }
    return [result];
  }


  late final _errorWidgetFocusNode = FocusNode();
  late Map<T, RowModel<T>> _builtRows;
  List<Widget> buildWidgetsAsTable(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    FocusNode? focusNode, /// unused
    bool? collapsible,
    bool? collapsed,
    Key? fieldGlobalKey,
    ScrollController? mainScrollController,
  }) {
    collapsible ??= this.collapsible;
    collapsed ??= this.collapsed;
    fieldGlobalKey ??= this.fieldGlobalKey;
    focusNode ??= this.focusNode;
    T objectTemplate = this.objectTemplate;
    if (transformSelectedFromAvailablePool!=null) {
      objectTemplate = transformSelectedFromAvailablePool!(objectTemplate);
    }
    final allowAddNew = this.allowAddNew;
    Widget result;
    final actions = buildActions(dao.contextForValidation ?? context, focusNode);
    final defaultActions = buildDefaultActions(context, focusNode: focusNode);
    if (actions.isNotEmpty && defaultActions.isNotEmpty) {
      actions.add(ActionFromZero.divider(breakpoints: actions.first.breakpoints,));
    }
    actions.addAll(defaultActions);
    double rowHeight = this.rowHeight ?? (tableCellsEditable ? 48 : 36);
    result = AnimatedBuilder(
      key: fieldGlobalKey,
      animation:  this,
      builder: (context, child) {
        _builtRows = {};
        final Map<String, ColModel> columns = tableColumnsBuilder!=null
            ? tableColumnsBuilder!(dao, this, objectTemplate)
            : defaultTableColumnsBuilder(dao, this, objectTemplate);
        for (final e in objects) {
          final ValueChanged<RowModel<T>>? onRowTap;
          if (this.onRowTap!=null) {
            onRowTap = this.onRowTap;
          } else {
            switch(this.rowTapType) {
              case RowTapType.view:
                onRowTap = (row) {
                  e.pushViewDialog(dao.contextForValidation ?? context,
                    showDefaultSnackBars: showDefaultSnackBars,
                  );
                };
                break;
              case RowTapType.edit:
                onRowTap = (row) async {
                  final copy = row.id.copyWith() as T;
                  copy.parentDAO = null;
                  copy.contextForValidation = dao.contextForValidation;
                  final result = await copy.maybeEdit(dao.contextForValidation ?? context, showDefaultSnackBars: showDefaultSnackBars);
                  if (result!=null) {
                    replaceRow(row.id, copy);
                    notifyListeners();
                  }
                };
                break;
              case RowTapType.none:
                onRowTap = null;
                break;
            }
          }
          Widget? rowAddonWidget;
          if (rowAddonField!=null) {
            final rowAddonField = e.props[this.rowAddonField!]!;
            if (rowAddonField.value!=null && rowAddonField.value.toString().isNotBlank) {
              rowAddonWidget = Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.copyWith(
                    subtitle1: Theme.of(context).textTheme.bodyText1!.copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: (tableHorizontalPadding-6).coerceAtLeast(0),
                    right: (tableHorizontalPadding-6).coerceAtLeast(0),
                    bottom: 12,
                  ),
                  child: IgnorePointer(
                    ignoring: onRowTap!=null,
                    child: Builder(
                      builder: (context) {
                        return rowAddonField.buildViewWidget(context,
                          showViewButtons: false,
                          linkToInnerDAOs: false,
                          dense: false,
                        );
                      },
                    ),
                  ),
                ),
              );
            }
          }
          final ValueChanged<RowModel<T>>? onRowTapFocused = onRowTap==null ? null : (value) {
            value.focusNode.requestFocus();
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              onRowTap!(value);
            });
          };
          if (tableRowBuilder!=null) {
            _builtRows[e] = tableRowBuilder!(e, context, this, dao, columns, onRowTapFocused, rowAddonWidget);
          } else {
            _builtRows[e] = SimpleRowModel<T>(
              id: e,
              values: columns.map((key, value) => MapEntry(key, e.props[key])),
              height: rowHeight,
              onRowTap: onRowTapFocused,
              selected: allowMultipleSelection ? (selectedObjects.value[e] ?? selectionDefault) : null,
              // backgroundColor: selectedObjects.value[e]??false ? Theme.of(context).accentColor.withOpacity(0.2) : null,
              onCheckBoxSelected: allowMultipleSelection ? (row, focused) {
                selectedObjects.value[row.id] = focused??false;
                (row as SimpleRowModel).selected = focused??false;
                selectedObjects.notifyListeners();
                tableController.notifyListeners();
                notifyListeners();
                return true;
              } : null,
              rowAddon: rowAddonWidget,
              rowAddonIsExpandable: true,
              rowAddonIsSticky: false,
              rowAddonIsCoveredByGestureDetector: true,
              rowAddonIsCoveredByScrollable: false,
              rowAddonIsCoveredByBackground: true,
            );
          }
        }
        final getMinWidth = (Iterable currentColumnKeys) {
          double width = 0;
          for (final key in currentColumnKeys) {
            final value = columns[key];
            width += value?.flex ?? 192;
          }
          return width;
        };
        final getMaxWidth = (Iterable currentColumnKeys) {
          return max(minWidth, 1.4 * getMinWidth(currentColumnKeys));
        };
        if (collapsed!) {
          Widget result = SizedBox(
            width: expandHorizontally ? null : maxWidth==double.infinity ? getMinWidth(columns.keys) : maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showTableHeaderAddon)
                  _buildTableHeader(context,
                    focusNode: focusNode!,
                    collapsed: collapsed,
                    collapsible: collapsible,
                    actions: actions,
                    asSliver: asSliver,
                  ),
                InitiallyAnimatedWidget(
                  duration: Duration(milliseconds: 300),
                  builder: (animationController, child) {
                    return Container(
                      color: backgroundColor?.call(context, this, dao) ?? Material.of(context)!.color ?? Theme.of(context).cardColor,
                      height: 128*CurveTween(curve: Curves.easeInCubic).chain(Tween(begin: 1.0, end: 0.0,)).evaluate(animationController),
                    );
                  },
                ),
              ],
            ),
          );
          if (asSliver) {
            result = SliverToBoxAdapter(
              child: result,
            );
          }
          return result;
        }
        final extraRowActions = extraRowActionsBuilder?.call(dao.contextForValidation ?? context, this, dao) ?? [];
        Widget result = TableFromZero<T>(
          scrollController: mainScrollController,
          minWidthGetter: getMinWidth,
          maxWidthGetter: asSliver ? getMaxWidth : null,
          initialSortedColumn: initialSortedColumn,
          tableController: tableController,
          allowCustomization: allowTableCustomization,
          alternateRowBackgroundSmartly: false,
          onFilter: onFilter,
          exportPathForExcel: exportPathForExcel ?? dao.defaultExportPath,
          columns: columns,
          showHeaders: showTableHeaders,
          footerStickyOffset: tableFooterStickyOffset,
          tableHorizontalPadding: tableHorizontalPadding,
          rows: _builtRows.values.toList(),
          rowBuilder: tableRowWidgetBuilder,
          enableFixedHeightForListRows: rowAddonField==null,
          cellPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          backgroundColor: backgroundColor?.call(context, this, dao),
          ignoreWidthGettersIfEmpty: !addCard,
          rowDisabledValidator: rowDisabledValidator,
          rowTooltipGetter: rowTooltipGetter,
          cellBuilder: tableCellsEditable ? (context, row, colKey) {
            final widgets = (row.values[colKey] as Field).buildFieldEditorWidgets(context,
              expandToFillContainer: false,
              addCard: false,
              asSliver: false,
              dense: true,
              ignoreHidden: true,
            );
            return SizedBox(
              height: row.height,
              child: OverflowBox(
                minHeight: rowHeight, maxHeight: double.infinity,
                alignment: Alignment(0, -0.4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widgets,
                ),
              ),
            );
          } : (context, row, colKey) {
            return (row.values[colKey] as Field).buildViewWidget(context,
              linkToInnerDAOs: false,
              showViewButtons: false,
              dense: true,
              hidden: false
            );
          },
          rowActions: [
            ...extraRowActions,
            if (extraRowActions.isNotEmpty)
              RowAction.divider(),
            if ((allowAddNew||hasAvailableObjectsPool))
              RowAction<T>(
                title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
                icon: Icon(Icons.add, color: Colors.blue),
                breakpoints: {0: ActionState.popup,},
                onRowTap: (context, row) async {
                  row.focusNode.requestFocus();
                  final result = await maybeAddRow(dao.contextForValidation ?? context, objects.indexOf(row.id)+1);
                  if (result!=null) {
                    userInteracted = true;
                  }
                },
              ),
            if ((allowAddNew||hasAvailableObjectsPool))
              RowAction.divider(),
            RowAction<T>(
              icon: Icon(Icons.info_outline),
              title: FromZeroLocalizations.of(context).translate('view'),
              breakpoints: actionViewBreakpoints,
              onRowTap: (context, row) async {
                userInteracted = true; // can't know if the item was edited from within its view dialog
                row.focusNode.requestFocus();
                row.id.pushViewDialog(dao.contextForValidation ?? context);
              },
            ),
            RowAction<T>(
              icon: Icon(Icons.edit_outlined),
              title: FromZeroLocalizations.of(context).translate('edit'),
              breakpoints: actionEditBreakpoints,
              onRowTap: (context, row) async {
                final copy = row.id.copyWith() as T;
                copy.parentDAO = null;
                copy.contextForValidation = dao.contextForValidation;
                final result = await copy.maybeEdit(dao.contextForValidation ?? context, showDefaultSnackBars: showDefaultSnackBars);
                if (result!=null) {
                  replaceRow(row.id, copy);
                  userInteracted = true;
                  notifyListeners();
                }
              },
            ),
            RowAction<T>(
              icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
              title: FromZeroLocalizations.of(context).translate('duplicate'),
              breakpoints: actionDuplicateBreakpoints,
              onRowTap: (context, row) async {
                userInteracted = true;
                row.focusNode.requestFocus();
                duplicateRows([row.id]);
              },
            ),
            if (objectTemplate.canDelete || hasAvailableObjectsPool)
              RowAction<T>(
                icon: Icon(!hasAvailableObjectsPool ? Icons.delete_forever_outlined : Icons.clear),
                title: FromZeroLocalizations.of(context).translate('delete'),
                breakpoints: actionDeleteBreakpoints,
                onRowTap: (context, row) async {
                  row.focusNode.requestFocus();
                  if (await maybeDelete(context, [row.id])) {
                    focusNode!.requestFocus();
                    userInteracted = true;
                    passedFirstEdit = true;
                    notifyListeners();
                  }
                },
              ),
          ],
          onAllSelected: allowMultipleSelection ? (value, rows) {
            rows.forEach((row) {
              selectedObjects.value[row.id] = value??false;
              (row as SimpleRowModel).selected = value??false;
            });
            selectedObjects.notifyListeners();
            tableController.notifyListeners();
            notifyListeners();
          } : null,
          emptyWidget: tableErrorWidget
             ?? Focus(
                  focusNode: _errorWidgetFocusNode,
                  skipTraversal: true,
                  child: Material(
                    color: enabled ? Theme.of(context).cardColor : Theme.of(context).canvasColor,
                    child: (allowAddNew||hasAvailableObjectsPool)&&objects.isEmpty
                        ? ContextMenuFromZero(
                            actions: actions,
                            onShowMenu: () => _errorWidgetFocusNode.requestFocus(),
                            child: buildAddAddon(context: context, collapsed: collapsed),
                          )
                        : TableEmptyWidget(
                            tableController: tableController,
                            actions: actions,
                            onShowMenu: () => _errorWidgetFocusNode.requestFocus(),
                          ),
                  ),
                ),
          headerWidgetAddon: !showTableHeaderAddon ? null : _buildTableHeader(context,
            actions: actions,
            focusNode: focusNode!,
            collapsed: collapsed,
            collapsible: collapsible,
            asSliver: asSliver,
          ),
        );
        if (asSliver) {
          if (!enabled) {
            result = SliverStack(
              children: [
                SliverIgnorePointer(sliver: result),
                SliverPositioned.fill(
                  child: TooltipFromZero(
                    message: listFieldValidationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
                      return a.toString().trim().isEmpty ? b.toString()
                          : b.toString().trim().isEmpty ? a.toString()
                          : '$a\n$b';
                    }),
                    child: Center(
                      child: Container(
                        width: getMaxWidth(columns.keys),
                        color: enabled ? Colors.transparent : Colors.black.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        } else {
          if (separateScrollableBreakpoint!=null && objects.length>separateScrollableBreakpoint!) {
            final mediaQuery = MediaQuery.of(context);
            final scrollController = ScrollController();
            result = Material(
              color: enabled
                  ? (backgroundColor?.call(context, this, dao) ?? Theme.of(context).cardColor)
                  : Theme.of(context).canvasColor,
              child: Container(
                padding: addCard ? null : const EdgeInsets.only(right: 24),
                height: mediaQuery.size.height - mediaQuery.padding.vertical - mediaQuery.viewInsets.vertical - 256,
                child: ScrollbarFromZero(
                  controller: scrollController,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [result],
                  ),
                ),
              ),
            );
          } else {
            result = Material(
              color: enabled
                  ? (backgroundColor?.call(context, this, dao) ?? Theme.of(context).cardColor)
                  : Theme.of(context).canvasColor,
              child: CustomScrollView(
                shrinkWrap: !expandToFillContainer,
                physics: NeverScrollableScrollPhysics(),
                slivers: [result],
              ),
            );
          }
          result = TooltipFromZero(
            message: listFieldValidationErrors.where((e) => dense || e.severity==ValidationErrorSeverity.disabling).fold('', (a, b) {
              return a.toString().trim().isEmpty ? b.toString()
                  : b.toString().trim().isEmpty ? a.toString()
                  : '$a\n$b';
            }),
            child: result,
            waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
          );
          if (!enabled) {
            result = IgnorePointer(
              child: result,
            );
            // result = MouseRegion(
            //   cursor: SystemMouseCursors.forbidden,
            //   child: result,
            // );
          }
          if (addCard) {
            result = Card(
              clipBehavior: Clip.hardEdge,
              color: enabled ? null : Theme.of(context).canvasColor,
              child: result,
            );
          }
        }
        return result;
      }
    );
    List<Widget> resultList = [
      result,
      if (enabled && (allowAddNew||hasAvailableObjectsPool) && showAddButtonAtEndOfTable && !collapsed && !dense)
        buildAddAddon(
          context: context,
          collapsed: collapsed,
        ),
      if (!dense)
        ValidationMessage(errors: listFieldValidationErrors, passedFirstEdit: passedFirstEdit,),
    ];
    if (asSliver) {
      resultList = resultList.map((e) => (e==result) ? e : SliverToBoxAdapter(child: e,)).toList();
    }
    return resultList;
  }

  Widget buildAddAddon({
    required BuildContext context,
    required bool? collapsed,
  }) {
    collapsed ??= this.collapsed;
    return AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        if (collapsed! || !enabled) {
          return SizedBox.shrink();
        }
        return Container(
          color: backgroundColor?.call(context, this, dao) ?? Material.of(context)!.color ?? Theme.of(context).cardColor,
          child: TextButton(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10,),
              child: Center(
                child: IntrinsicWidth(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.blue),
                      SizedBox(width: 8,),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text('${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}', style: TextStyle(fontSize: 16),),
                        ),
                      ),
                      SizedBox(width: 8,),
                    ],
                  ),
                ),
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.2),
            ),
            onPressed: () {
              userInteracted = true;
              maybeAddRow(dao.contextForValidation ?? context);
            },
          ),
        );
      },
    );
  }


  static Widget defaultViewWidgetBuilder<T extends DAO>
  (BuildContext context, Field<ComparableList<DAO>> fieldParam, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=false,
    bool dense = false,
    bool? hidden,
  }) {
    if (dense) {
      return Field.defaultViewWidgetBuilder(context, fieldParam,
        showViewButtons: showViewButtons,
        linkToInnerDAOs: linkToInnerDAOs,
        dense: dense,
      );
    }
    if (hidden ?? fieldParam.hiddenInView) {
      return SizedBox.shrink();
    }
    final field = fieldParam as ListField;
    final List<DAO> sortedObjects = List.from(field.objects);
    if (field.initialSortedColumn!=null) {
      sortedObjects.sort();
    }
    if (field.separateScrollableBreakpoint!=null && field.objects.length>field.separateScrollableBreakpoint!) {
      final scrollController = ScrollController();
      final mediaQuery = MediaQuery.of(context);
      return Container(
        height: mediaQuery.size.height - mediaQuery.padding.vertical - mediaQuery.viewInsets.vertical - 256,
        padding: EdgeInsets.only(right: 24),
        child: ScrollbarFromZero(
          controller: scrollController,
          child: ListView.builder(
            controller: scrollController,
            itemCount: sortedObjects.length,
            padding: dense
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(vertical: 3),
            itemBuilder: (context, index) {
              return defaultViewWidgetBuilderElement(context, sortedObjects[index],
                linkToInnerDAOs: linkToInnerDAOs,
                showViewButtons: showViewButtons,
                dense: dense,
              );
            },
          ),
        ),
      );
    } else {
      return Padding(
        padding: dense
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedObjects.map((e) {
            return defaultViewWidgetBuilderElement(context, e,
              linkToInnerDAOs: linkToInnerDAOs,
              showViewButtons: showViewButtons,
              dense: dense,
            );
          }).toList(),
        ),
      );
    }
  }
  static Widget defaultViewWidgetBuilderElement(BuildContext context, DAO e, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=false,
    bool dense = false,
  }) {
    final objectLinkToInnerDAOs = linkToInnerDAOs && e.wantsLinkToSelfFromOtherDAOs;
    final onTap = objectLinkToInnerDAOs
        ? () => e.pushViewDialog(context)
        : null;
    final uiName = dense ? e.uiNameDense : e.toString();
    return Stack(
      children: [
        Padding(
          padding: dense
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: dense
                    ? Text(uiName,
                  style: Theme.of(context).textTheme.subtitle1,
                ) : SelectableText(uiName,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ),
              if (showViewButtons && onTap!=null)
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: Icon(Icons.info_outline),
                    padding: EdgeInsets.all(0),
                    constraints: BoxConstraints(maxHeight: 32),
                    onPressed: onTap,
                  ),
                ),
            ],
          ),
        ),
        if (onTap!=null)
          Positioned.fill(
            child: translucent.InkWell(
              onTap: onTap,
            ),
          ),
      ],
    );
  }


  Widget _buildTableHeader(BuildContext context, {
    required FocusNode focusNode,
    required bool? collapsible,
    required bool? collapsed,
    required bool asSliver,
    required List<ActionFromZero> actions,
  }) {
    collapsible ??= this.collapsible;
    collapsed ??= this.collapsed;
    return EnsureVisibleWhenFocused(
      key: ValueKey(actions.map((e) => e.title)),
      focusNode: focusNode,
      child: Focus(
        focusNode: focusNode,
        key: headerGlobalKey,
        skipTraversal: true,
        canRequestFocus: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: (tableHorizontalPadding-8).coerceAtLeast(0)),
          child: ValidationRequiredOverlay(
            isRequired: isRequired,
            isEmpty: enabled && value==null || value!.isEmpty,
            errors: validationErrors,
            child: Stack(
              children: [
                TableHeaderFromZero<T>(
                  controller: tableController,
                  title: Text(uiName),
                  actions: actions,
                  onShowAppbarContextMenu: () => focusNode.requestFocus(),
                  exportPathForExcel: exportPathForExcel ?? dao.defaultExportPath,
                  addSearchAction: addSearchAction,
                  backgroundColor: backgroundColor?.call(context, this, dao),
                  showColumnMetadata: showTableHeaders,
                  leading: !collapsible ? icon : IconButton(
                    icon: Icon(collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                    onPressed: () {
                      focusNode.requestFocus();
                      this.collapsed = !this.collapsed;
                      notifyListeners();
                    },
                  ),
                ),
                if (availableObjectsPoolProvider!=null)
                  Positioned(
                    left: 3, top: 3,
                    child: ApiProviderBuilder(
                      provider: availableObjectsPoolProvider!.call(context, this, dao),
                      dataBuilder: (context, data) {
                        return SizedBox.shrink();
                      },
                      loadingBuilder: (context, progress) {
                        return SizedBox(
                          height: 10, width: 10,
                          child: LoadingSign(
                            value: null,
                            padding: EdgeInsets.zero,
                            size: 12,
                            color: Theme.of(context).splashColor.withOpacity(1),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace, onRetry) {
                        return SizedBox(
                          height: 10, width: 10,
                          child: Icon(
                            Icons.error_outlined,
                            color: Colors.red,
                            size: 12,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  List<ActionFromZero> buildDefaultActions(BuildContext context, {FocusNode? focusNode}) {
    focusNode ??= this.focusNode;
    final objectTemplate = this.objectTemplate;
    final allowAddNew = this.allowAddNew;
    List<T> currentSelected = [];
    // TODO 3 re-implement multiple edition, test well. Enabling this might break current uses of selection (when selecion is used for external purposes, like in PageSend EntidadContacto selection)
    // try {
    //   currentSelected = tableController.filtered.where((element) => selectedObjects.value[element]??selectionDefault).map((e) => e.id).toList();
    // } catch (_) {}
    return [
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: Icon(Icons.edit_outlined),
          title: '${FromZeroLocalizations.of(context).translate('edit')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            userInteracted = true;
            focusNode?.requestFocus();
            maybeEditMultiple(context, currentSelected);
          },
          breakpoints: actionEditBreakpoints[0]==ActionState.none ? actionEditBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
          title: '${FromZeroLocalizations.of(context).translate('duplicate')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            userInteracted = true;
            focusNode?.requestFocus();
            duplicateRows(currentSelected);
          },
          breakpoints: actionDuplicateBreakpoints[0]==ActionState.none ? actionDuplicateBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0 && (objectTemplate.canDelete || hasAvailableObjectsPool))
        ActionFromZero(
          icon: Icon(!hasAvailableObjectsPool ? Icons.delete_forever_outlined : Icons.clear),
          title: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) async {
            focusNode?.requestFocus();
            if (await maybeDelete(context, currentSelected)) {
              userInteracted = true;
              focusNode?.requestFocus();
            }
          },
          breakpoints: actionDeleteBreakpoints[0]==ActionState.none ? actionDeleteBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: Icon(Icons.cancel_outlined),
          title: FromZeroLocalizations.of(context).translate('cancel_selection'),
          onTap: (context) {
            focusNode?.requestFocus();
            selectedObjects.value = {};
            notifyListeners();
          },
        ),
      if ((allowAddNew||hasAvailableObjectsPool) && !collapsed && currentSelected.length==0)
        ActionFromZero(
          title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
          icon: Icon(Icons.add, color: Colors.blue),
          onTap: (context) async {
            focusNode?.requestFocus();
            final result = await maybeAddRow(dao.contextForValidation ?? context);
            if (result!=null) {
              userInteracted = true;
              pageNotifier?.value = objects.length-1;
            }
          },
        ),
      if (dao.enableUndoRedoMechanism)
        ActionFromZero.divider(breakpoints: {0: ActionState.popup,},),
      if (dao.enableUndoRedoMechanism)
        ActionFromZero(
          title: 'Deshacer', // TODO 3 internationalize
          icon: Icon(MaterialCommunityIcons.undo_variant),
          onTap: (context) {
            userInteracted = true;
            focusNode?.requestFocus();
            undo(removeEntryFromDAO: true);
          },
          enabled: undoValues.isNotEmpty,
          breakpoints: {
            0: ActionState.popup,
          },
        ),
      if (dao.enableUndoRedoMechanism)
        ActionFromZero(
          title: 'Rehacer', // TODO 3 internationalize
          icon: Icon(MaterialCommunityIcons.redo_variant),
          onTap: (context) {
            userInteracted = true;
            focusNode?.requestFocus();
            redo(removeEntryFromDAO: true);
          },
          enabled: redoValues.isNotEmpty,
          breakpoints: {
            0: ActionState.popup,
          },
        ),
      if (availableObjectsPoolProvider!=null)
        ActionFromZero.divider(
          breakpoints: {0: ActionState.popup},
        ),
      if (availableObjectsPoolProvider!=null)
        ActionFromZero(
          title: 'Refrescar Datos', // TODO 3 internationalize
          icon: Icon(Icons.refresh,),
          breakpoints: {0: ActionState.popup},
          onTap: (context) {
            focusNode?.requestFocus();
            final ref = dao.contextForValidation! as WidgetRef;
            final provider = availableObjectsPoolProvider!(context, this, dao);
            final stateNotifier = ref.read(provider.notifier);
            stateNotifier.refresh(ref);
          },
        ),
    ];
  }

  static Map<String, ColModel> defaultTableColumnsBuilder<T extends DAO<U>, U>
      (DAO dao, ListField<T, U> listField, T objectTemplate) {
    Map<String, Field> propsShownOnTable = {};
    objectTemplate.props.forEach((key, value) {
      if (!value.hiddenInTable && key!=listField.rowAddonField) {
        propsShownOnTable[key] = value;
      }
    });
    final columns = propsShownOnTable.map((key, value) {
      final SimpleColModel result = value.getColModel();
      if (listField.tableFilterable!=null) {
        result.filterEnabled = listField.tableFilterable;
      }
      if (listField.tableSortable!=null) {
        result.sortEnabled = listField.tableSortable;
      }
      return MapEntry(key, result);
    });
    return columns;
  }

}




