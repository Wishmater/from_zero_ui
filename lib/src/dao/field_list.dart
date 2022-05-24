import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/src/table/table_header.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao/dao.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/util/comparable_list.dart';
import 'package:from_zero_ui/src/ui_utility/translucent_ink_well.dart' as translucent;
import 'package:sliver_tools/sliver_tools.dart';
import 'package:dartx/dartx.dart';


typedef List<RowAction<T>> RowActionsBuilder<T>(BuildContext context);



class ListField<T extends DAO> extends Field<ComparableList<T>> {

  FieldValueGetter<T, ListField<T>> objectTemplateGetter;
  TableController<T> tableController;
  ContextFulFieldValueGetter<Future<List<T>>, ListField<T>>? availableObjectsPoolGetter;
  ContextFulFieldValueGetter<ApiProvider<List<T>>, ListField<T>>? availableObjectsPoolProvider;
  bool allowDuplicateObjectsFromAvailablePool;
  bool showObjectsFromAvailablePoolAsTable;
  bool? _allowAddNew;
  bool get allowAddNew => _allowAddNew ?? objectTemplate.canSave;
  bool collapsed;
  bool allowMultipleSelection;
  bool tableCellsEditable;
  bool collapsible;
  bool viewOnRowTap;
  bool asPopup;
  bool validateChildren;
  String Function(ListField<T> field) toStringGetter;
  Map<double, ActionState> actionViewBreakpoints;
  Map<double, ActionState> actionEditBreakpoints;
  Map<double, ActionState> actionDuplicateBreakpoints;
  Map<double, ActionState> actionDeleteBreakpoints;
  /// this means that save() will be called on the object when adding a row
  /// and delete() will be called when removing a row, default false
  bool? _skipDeleteConfirmation;
  bool get skipDeleteConfirmation => _skipDeleteConfirmation ?? !objectTemplate.canDelete;
  bool showTableHeaders;
  bool showElementCount;
  double? rowHeight;
  bool? _showDefaultSnackBars;
  bool get showDefaultSnackBars => _showDefaultSnackBars ?? objectTemplate.canSave;
  RowActionsBuilder<T>? extraRowActionsBuilder; //TODO 3 also allow global action builders
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

  T get objectTemplate => objectTemplateGetter(this, dao)..parentDAO = dao;
  List<T> get objects => value!.list;
  List<T> get dbObjects => dbValue!.list;
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

  bool get enabled => listFieldValidationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling).isEmpty;

  ValueNotifier<Map<T, bool>> selectedObjects = ValueNotifier({});

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
        ? listToStringCount(list)
        : listToStringAll(list);
  }
  static String listToStringAll(List list) {
    String result = '';
    for (final e in list) {
      if (result.isNotEmpty) {
        result += ', ';
      }
      result += e.toString();
    }
    return result;
  }
  static String listToStringCount(List list, {
    String? modelNameSingular,
    String? modelNamePlural,
    BuildContext? context, // for localization
  }) {
    final name = list.length==1
        ? (modelNameSingular ?? (context==null ? ''
            : FromZeroLocalizations.of(context).translate('element_sing')))
        : (modelNamePlural ?? (context==null ? ''
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
    bool? allowAddNew,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, /// Unused in table
    this.tableCellsEditable = false,
    double maxWidth = double.infinity,
    double minWidth = 0,
    double flex = 0,
    TableController<T>? tableController,
    this.collapsed = false,
    this.allowMultipleSelection = false,
    this.collapsible = false,
    this.asPopup = false,
    this.toStringGetter = defaultToString,
    bool? viewOnRowTap,
    Map<double, ActionState>? actionViewBreakpoints,
    Map<double, ActionState>? actionEditBreakpoints,
    Map<double, ActionState>? actionDuplicateBreakpoints,
    Map<double, ActionState>? actionDeleteBreakpoints,
    this.showTableHeaders = true,
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
    ComparableList<T>? defaultValue,
    this.expandHorizontally = true,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<ComparableList<T>> viewWidgetBuilder = ListField.defaultViewWidgetBuilder,
    this.icon,
    this.onFilter,
    this.exportPathForExcel,
    this.buildViewWidgetAsTable = false,
    this.addSearchAction = false,
    bool? validateChildren,
    OnFieldValueChanged<ComparableList<T>?>? onValueChanged,
  }) :  assert(availableObjectsPoolGetter==null || availableObjectsPoolProvider==null),
        this.tableFilterable = tableFilterable ?? false,
        this.showEditDialogOnAdd = showEditDialogOnAdd ?? !tableCellsEditable,
        this._showDefaultSnackBars = showDefaultSnackBars,
        this._skipDeleteConfirmation = skipDeleteConfirmation,
        this.viewOnRowTap = viewOnRowTap ?? (onRowTap==null && !tableCellsEditable),
        this.actionEditBreakpoints = actionEditBreakpoints ?? {0: ActionState.popup},
        this.actionDuplicateBreakpoints = actionDuplicateBreakpoints ?? {0: ActionState.none},
        this.actionDeleteBreakpoints = actionDeleteBreakpoints ?? {0: ActionState.icon},
        this.actionViewBreakpoints = actionViewBreakpoints ?? (viewOnRowTap ?? (onRowTap==null && !tableCellsEditable) ? {0: ActionState.popup} : {0: ActionState.icon}),
        this.tableController = tableController ?? TableController<T>(),
        this._allowAddNew = allowAddNew,
        this.validateChildren = tableCellsEditable && (validateChildren ?? true),
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
          fieldGlobalKey: fieldGlobalKey ?? GlobalKey(),
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue ?? ComparableList<T>(),
          backgroundColor: backgroundColor,
          actions: actions,
          viewWidgetBuilder: viewWidgetBuilder,
          onValueChanged: onValueChanged,
        ) {
    addListeners();
  }

  @override
  set dao(DAO dao) {
    super.dao = dao;
    objects.forEach((element) {
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
  }) async {
    final superResult = super.validate(context, dao, currentValidationId,
        validateIfNotEdited: validateIfNotEdited);
    if (currentValidationId!=dao.validationCallCount) return false;
    if (!validateChildren) {
      bool success = await superResult;
      listFieldValidationErrors = List.from(validationErrors);
      return success;
    }
    List<Future<bool>> results = [];
    final templateProps = objectTemplate.props;
    for (final e in objects) {
      final objectProps = e.props;
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
    if (currentValidationId!=dao.validationCallCount) return false;
    bool success = await superResult;
    listFieldValidationErrors = List.from(validationErrors);
    for (final e in results) {
      success = success && await e;
      if (currentValidationId!=dao.validationCallCount) return false;
    }
    for (final e in objects) {
      final objectProps = e.props;
      for (final key in templateProps.keys) {
        final field = objectProps[key];
        if (field!=null) {
          validationErrors.addAll(field.validationErrors);
        }
      }
    }
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    return validationErrors.where((e) => e.isBlocking).isEmpty;
  }

  @override
  ListField<T> copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    ComparableList<T>? value,
    ComparableList<T>? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    FieldValueGetter<T, ListField<T>>? objectTemplateGetter,
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
    bool? skipDeleteConfirmation,
    bool? showTableHeaders,
    bool? showElementCount,
    double? rowHeight,
    ContextFulFieldValueGetter<Future<List<T>>, ListField<T>>? availableObjectsPoolGetter,
    ContextFulFieldValueGetter<ApiProvider<List<T>>, ListField<T>>? availableObjectsPoolProvider,
    bool? allowDuplicateObjectsFromAvailablePool,
    bool? showObjectsFromAvailablePoolAsTable,
    bool? allowAddNew,
    bool? asPopup,
    String Function(ListField field)? toStringGetter,
    RowActionsBuilder<T>? extraRowActionBuilders,
    int? initialSortColumn,
    bool? tableCellsEditable,
    bool? allowMultipleSelection,
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
    ComparableList<T>? defaultValue,
    bool? expandHorizontally,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
    ViewWidgetBuilder<ComparableList<T>>? viewWidgetBuilder,
    Widget? icon,
    List<RowModel<T>> Function(List<RowModel<T>>)? onFilter,
    FutureOr<String>? exportPathForExcel,
    bool? buildViewWidgetAsTable,
    bool? addSearchAction,
    OnFieldValueChanged<ComparableList<T>?>? onValueChanged,
  }) {
    return ListField<T>(
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
      allowAddNew: allowAddNew ?? this._allowAddNew,
      asPopup: asPopup ?? this.asPopup,
      toStringGetter: toStringGetter ?? this.toStringGetter,
      extraRowActionsBuilder: extraRowActionBuilders ?? this.extraRowActionsBuilder,
      skipDeleteConfirmation: skipDeleteConfirmation ?? this._skipDeleteConfirmation,
      showTableHeaders: showTableHeaders ?? this.showTableHeaders,
      showElementCount: showElementCount ?? this.showElementCount,
      rowHeight: rowHeight ?? this.rowHeight,
      initialSortedColumn: initialSortColumn ?? this.initialSortedColumn,
      tableCellsEditable: tableCellsEditable ?? this.tableCellsEditable,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      onRowTap: onRowTap ?? this.onRowTap,
      showAddButtonAtEndOfTable: showAddButtonAtEndOfTable ?? this.showAddButtonAtEndOfTable,
      showEditDialogOnAdd: showEditDialogOnAdd ?? this.showEditDialogOnAdd,
      tableErrorWidget: tableErrorWidget ?? this.tableErrorWidget,
      showDefaultSnackBars: showDefaultSnackBars ?? this._showDefaultSnackBars,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      showObjectsFromAvailablePoolAsTable: showObjectsFromAvailablePoolAsTable ?? this.showObjectsFromAvailablePoolAsTable,
      tableController: tableController ?? this.tableController,
      tableSortable: tableSortable ?? this.tableSortable,
      tableFilterable: tableFilterable ?? this.tableFilterable,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? List.from(this.undoValues),
      redoValues: redoValues ?? List.from(this.redoValues),
      invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm ?? this.invalidateNonEmptyValuesIfHiddenInForm,
      defaultValue: defaultValue ?? this.defaultValue,
      expandHorizontally: expandHorizontally ?? this.expandHorizontally,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actions: actions ?? this.actions,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      icon: icon ?? this.icon,
      onFilter: onFilter ?? this.onFilter,
      exportPathForExcel: exportPathForExcel ?? this.exportPathForExcel,
      buildViewWidgetAsTable: buildViewWidgetAsTable ?? this.buildViewWidgetAsTable,
      addSearchAction: addSearchAction ?? this.addSearchAction,
      onValueChanged: onValueChanged ?? this.onValueChanged,
    );
  }

  void addListeners() {
    objects.forEach((element) {
      element.addListener(notifyListeners);
    });
  }

  void addRow (T element, [int? insertIndex]) => addRows([element], insertIndex);
  void addRows (List<T> elements, [int? insertIndex]) {
    for (final e in elements) {
      e.addListener(notifyListeners);
      e.parentDAO = dao;
    }
    final newValue = value!.copyWith();
    if (insertIndex==null) {
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
    });
    value = newValue;
    focusObject(elements.values.first);
    return result;
  }

  void duplicateRow(T element) => duplicateRows([element]);
  void duplicateRows(List<T> elements) {
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
  bool removeRows(List<T> elements) {
    bool result = false;
    final newValue = value!.copyWith();
    elements.forEach((e) {
      result = newValue.remove(e) || result;
    });
    if (result) {
      value = newValue;
    }
    return result;
  }


  void focusObject(T object) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      try {
        if (tableCellsEditable) {
          object.props.values.firstOrNullWhere((e) => !e.hiddenInForm)?.focusNode.requestFocus();
        } else {
          builtRows[object]?.focusNode.requestFocus();
        }
      } catch (_) {}
    });
  }

  Future<T?> maybeAddRow(context, [int? insertIndex]) async {
    focusNode.requestFocus();
    final objectTemplate = this.objectTemplate;
    T emptyDAO = (objectTemplate.copyWith() as T)..id=null;
    emptyDAO.contextForValidation = dao.contextForValidation;
    if (hasAvailableObjectsPool) {
      T? selected;
      if (showObjectsFromAvailablePoolAsTable) {
        emptyDAO.onDidSave = (context, model, dao) {
          objectTemplate.onDidSave?.call(context, model, dao);
          WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
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
                          return _availablePoolTableDataBuilder(context, data, emptyDAO);
                        },
                      )
                    : ApiProviderBuilder<List<T>>(
                        provider: availableObjectsPoolProvider!(context, this, dao),
                        loadingBuilder: _availablePoolLoadingBuilder,
                        errorBuilder: _availablePoolErrorBuilder,
                        dataBuilder: (context, data) {
                          return _availablePoolTableDataBuilder(context, data, emptyDAO);
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
          width: emptyDAO.viewDialogWidth,
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
        addRow(selected, insertIndex);
        return selected;
      }
    } else {
      dynamic result;
      if (showEditDialogOnAdd) {
        result = await emptyDAO.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars);
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

  Widget _availablePoolLoadingBuilder(BuildContext context, [double? progress]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42),
      child: SizedBox(
        height: 128,
        child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
      ),
    );
  }
  Widget _availablePoolTableDataBuilder(BuildContext context, List<T> data, T emptyDAO) {
    ScrollController scrollController = ScrollController();
    if (!allowDuplicateObjectsFromAvailablePool) {
      data = data.where((e) => !objects.contains(e)).toList();
    }
    final listField = ListField(
      uiNameGetter: (field, dao) => uiName,
      objectTemplateGetter: (field, dao) => emptyDAO,
      tableCellsEditable: false,
      collapsible: false,
      actionDeleteBreakpoints: {0: ActionState.none},
      actionViewBreakpoints: actionViewBreakpoints,
      actionEditBreakpoints: actionEditBreakpoints,
      objects: data,
      allowAddNew: allowAddNew && emptyDAO.canSave,
      addSearchAction: true,
      onRowTap: (value) {
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
        );
      } : null,
    );
  }

  Future<bool> maybeDelete(BuildContext context, List<T> elements,) async {
    if (elements.isEmpty) return false;
    bool? delete = skipDeleteConfirmation || hasAvailableObjectsPool || (await showDialog(
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
              child: Dialog(
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
                                  bool? edit = await showDialog(
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
    FocusNode? focusNode,
    ScrollController? mainScrollController,
  }) {
    if (dense || asPopup) {
      return buildDenseWidgets(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
      );
    } else {
      return buildFullTableWidgets(context,
        addCard: addCard,
        asSliver: asSliver,
        expandToFillContainer: expandToFillContainer,
        dense: dense,
        focusNode: focusNode,
        mainScrollController: mainScrollController,
      );
    }
  }

  List<Widget> buildDenseWidgets(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    FocusNode? focusNode,
  }) {
    focusNode ??= this.focusNode;
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
          return _buildDenseWidget(context,
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
      result = _buildDenseWidget(context,
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
  late final popupGlobalKey = GlobalKey();
  Widget _buildDenseWidget(BuildContext context, {
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
                    ...buildFullTableWidgets(context,
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
        result = AnimatedContainer(
          duration: Duration(milliseconds: 300),
          color: dense && listFieldValidationErrors.isNotEmpty
              ? ValidationMessage.severityColors[Theme.of(context).brightness.inverse]![listFieldValidationErrors.first.severity]!.withOpacity(0.2)
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
                ValidationMessage(errors: listFieldValidationErrors),
            ],
          ),
        ),
      ),
    );
    return result;
  }

  late final errorWidgetFocusNode = FocusNode();
  late Map<T, RowModel<T>> builtRows;
  List<Widget> buildFullTableWidgets(BuildContext context, {
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
    final objectTemplate = this.objectTemplate;
    final allowAddNew = this.allowAddNew;
    Widget result;
    if (hiddenInForm) {
      result = SizedBox.shrink();
      if (asSliver) {
        result = SliverToBoxAdapter(child: result,);
      }
      return [result];
    }
    final actions = this.actions?.call(context, this, dao) ?? [];
    final defaultActions = buildDefaultActions(context, focusNode: focusNode);
    if (actions.isNotEmpty && defaultActions.isNotEmpty) {
      actions.add(ActionFromZero.divider(breakpoints: actions.first.breakpoints,));
    }
    actions.addAll(defaultActions);
    Map<String, Field> propsShownOnTable = {};
    objectTemplate.props.forEach((key, value) {
      if (!value.hiddenInTable) {
        propsShownOnTable[key] = value;
      }
    });
    double width = 0;
    propsShownOnTable.forEach((key, value) {
      width += value.tableColumnWidth ?? 192;
    });
    double rowHeight = this.rowHeight ?? (tableCellsEditable ? 48 : 36);
    result = AnimatedBuilder(
      key: fieldGlobalKey,
      animation:  this,
      builder: (context, child) {
        if (collapsed!) {
          Widget result = SizedBox(
            width: expandHorizontally ? null : maxWidth==double.infinity ? width : maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      color: Material.of(context)!.color ?? Theme.of(context).cardColor,
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
        builtRows = {};
        for (final e in objects) {
          final onRowTap = this.onRowTap ?? (viewOnRowTap ? (row) {
            e.pushViewDialog(dao.contextForValidation ?? context);
          } : null);
          builtRows[e] = SimpleRowModel(
            id: e,
            values: propsShownOnTable.map((key, value) => MapEntry(key, e.props[key])),
            height: rowHeight,
            onRowTap: onRowTap==null ? null : (value) {
              value.focusNode.requestFocus();
              onRowTap(value);
            },
            selected: allowMultipleSelection ? (selectedObjects.value[e]??false) : null,
            backgroundColor: selectedObjects.value[e]??false ? Theme.of(context).accentColor.withOpacity(0.2) : null,
            onCheckBoxSelected: allowMultipleSelection ? (row, focused) {
              selectedObjects.value[row.id] = focused??false;
              (row as SimpleRowModel).selected = focused??false;
              selectedObjects.notifyListeners();
              tableController.notifyListeners();
              notifyListeners();
              return true;
            } : null,
          );
        }
        final extraRowActions = extraRowActionsBuilder?.call(context) ?? [];
        Widget result = TableFromZero<T>(
          // key: ValueKey(value.hashCode),
          scrollController: mainScrollController,
          minWidth: width,
          initialSortedColumn: initialSortedColumn,
          tableController: tableController,
          alternateRowBackgroundSmartly: false,
          onFilter: onFilter,
          exportPathForExcel: exportPathForExcel,
          columns: propsShownOnTable.map((key, value) {
            final SimpleColModel result = value.getColModel();
            if (tableFilterable!=null) {
              result.filterEnabled = tableFilterable;
            }
            if (tableSortable!=null) {
              result.sortEnabled = tableSortable;
            }
            return MapEntry(key, result);
          }),
          showHeaders: showTableHeaders,
          footerStickyOffset: 12,
          rows: builtRows.values.toList(),
          cellBuilder: tableCellsEditable ? (context, row, colKey) {
            final widgets = (row.values[colKey] as Field).buildFieldEditorWidgets(context,
              expandToFillContainer: false,
              addCard: false,
              asSliver: false,
              dense: true,
            );
            return SizedBox(
              height: rowHeight,
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
            );
          },
          rowActions: [
            ...extraRowActions,
            if (extraRowActions.isNotEmpty)
              RowAction.divider(),
            if ((allowAddNew||hasAvailableObjectsPool))
              RowAction<T>(
                title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
                icon: Icon(Icons.add),
                breakpoints: {0: ActionState.popup,},
                onRowTap: (context, row) {
                  row.focusNode.requestFocus();
                  maybeAddRow(context, objects.indexOf(row.id)+1);
                },
              ),
            if ((allowAddNew||hasAvailableObjectsPool))
              RowAction.divider(),
            RowAction<T>(
              icon: Icon(Icons.info_outline),
              title: FromZeroLocalizations.of(context).translate('view'),
              breakpoints: actionViewBreakpoints,
              onRowTap: (context, row) async {
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
                final result = await copy.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars);
                if (result!=null) {
                  replaceRow(row.id, copy);
                  notifyListeners();
                }
              },
            ),
            RowAction<T>(
              icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
              title: FromZeroLocalizations.of(context).translate('duplicate'),
              breakpoints: actionDuplicateBreakpoints,
              onRowTap: (context, row) async {
                row.focusNode.requestFocus();
                duplicateRows([row.id]);
              },
            ),
            if (objectTemplate.canDelete) // TODO 3 maybe add allowDelete param
              RowAction<T>(
                icon: Icon(allowAddNew ? Icons.delete_forever_outlined : Icons.clear),
                title: FromZeroLocalizations.of(context).translate('delete'),
                breakpoints: actionDeleteBreakpoints,
                onRowTap: (context, row) async {
                  row.focusNode.requestFocus();
                  if (await maybeDelete(context, [row.id])) {
                    focusNode!.requestFocus();
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
              ?? ContextMenuFromZero(
                actions: actions,
                onShowMenu: () => errorWidgetFocusNode.requestFocus(),
                child: Focus(
                  focusNode: errorWidgetFocusNode,
                  skipTraversal: true,
                  child: Material(
                    color: enabled ? Theme.of(context).cardColor : Theme.of(context).canvasColor,
                    child: (allowAddNew||hasAvailableObjectsPool)&&objects.isEmpty
                        ? buildAddAddon(context: context, width: width, collapsed: collapsed)
                        : InkWell(
                          onTap: (allowAddNew||hasAvailableObjectsPool)&&objects.isEmpty ? () {
                            maybeAddRow(context);
                          } : null,
                          child: ErrorSign(
                            title: FromZeroLocalizations.of(context).translate('no_data'),
                            subtitle: (allowAddNew||hasAvailableObjectsPool)&&objects.isEmpty
                                ? FromZeroLocalizations.of(context).translate('no_data_add')
                                : FromZeroLocalizations.of(context).translate('no_data_filters'),
                          ),
                        ),
                  ),
                ),
              ),
          headerRowModel: SimpleRowModel(
            id: 'header', values: {},
            rowAddonIsCoveredByScrollable: false,
            rowAddonIsCoveredByBackground: false,
            rowAddon: _buildTableHeader(context,
              actions: actions,
              focusNode: focusNode!,
              collapsed: collapsed,
              collapsible: collapsible,
              asSliver: asSliver,
            ),
          ),
        );
        if (!expandHorizontally) {
          result = SliverCrossAxisConstrained(
            maxCrossAxisExtent: maxWidth==double.infinity ? width*1.6 : maxWidth,
            child: result,
          );
        }
        if (!asSliver) {
          result = Material(
            color: enabled ? Theme.of(context).cardColor : Theme.of(context).canvasColor,
            child: Container(
              color: Material.of(context)?.color ?? Theme.of(context).canvasColor,
              child: CustomScrollView(
                shrinkWrap: !expandToFillContainer,
                slivers: [result],
              ),
            ),
          );
        }
        return result;
      }
    );
    if (!asSliver && addCard) {
      if (!enabled) { // TODO 2 implement proper disabled logic in each sliver (color + tooltip + mouseRegion)
        result = MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: IgnorePointer(
            child: result,
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
        triggerMode: enabled ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
        waitDuration: enabled ? Duration(seconds: 1) : Duration.zero,
      );
      if (addCard) {  // TODO 3 implement addCard in table slivers, VERY HARD IPMLEMENTATION FOR LOW REWARD
        result = Card(
          clipBehavior: Clip.hardEdge,
          color: enabled ? null : Theme.of(context).canvasColor,
          child: result,
        );
      }
    }
    List<Widget> resultList = [
      result,
      if (enabled && (allowAddNew||hasAvailableObjectsPool) && showAddButtonAtEndOfTable && !collapsed && !dense)
        buildAddAddon(
          context: context,
          width: width,
          collapsed: collapsed,
        ),
      if (!dense)
        ValidationMessage(errors: listFieldValidationErrors),
    ];
    if (asSliver) {
      resultList = resultList.map((e) => (e==result) ? e : SliverToBoxAdapter(child: e,)).toList();
    }
    return resultList;
  }

  Widget buildAddAddon({
    required BuildContext context,
    required double width,
    required bool? collapsed,
  }) {
    collapsed ??= this.collapsed;
    return AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        if (collapsed! || !enabled) {
          return SizedBox.shrink();
        }
        return Transform.translate(
          offset: Offset(0, 0),
          child: Container(
            color: Material.of(context)!.color ?? Theme.of(context).cardColor,
            child: TextButton(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10,),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8,),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}', style: TextStyle(fontSize: 16),),
                      ),
                      SizedBox(width: 8,),
                    ],
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
              ),
              onPressed: () => maybeAddRow(context),
            ),
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
  }) {
    if (dense) {
      return Field.defaultViewWidgetBuilder(context, fieldParam,
        showViewButtons: showViewButtons,
        linkToInnerDAOs: linkToInnerDAOs,
        dense: dense,
      );
    }
    if (fieldParam.hiddenInView) {
      return SizedBox.shrink();
    }
    final field = fieldParam as ListField;
    final uiNames = {
      for (final e in field.objects)
        e: e.toString(),
    };
    final List<DAO> sortedObjects = List.from(field.objects);
    if (field.initialSortedColumn!=null) {
      sortedObjects.sort();
    }
    return Padding(
      padding: dense
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedObjects.map((e) {
          final objectLinkToInnerDAOs = linkToInnerDAOs && e.wantsLinkToSelfFromOtherDAOs;
          final onTap = objectLinkToInnerDAOs
              ? () => e.pushViewDialog(context)
              : null;
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
                          ? Text(uiNames[e]!,
                            style: Theme.of(context).textTheme.subtitle1,
                          ) : SelectableText(uiNames[e]!,
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
        }).toList(),
      ),
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
      focusNode: focusNode,
      child: Focus(
        focusNode: focusNode,
        key: headerGlobalKey,
        skipTraversal: true,
        canRequestFocus: true,
        child: Stack(
          children: [
            TableHeaderFromZero<T>(
              controller: tableController,
              title: Text(uiName),
              actions: actions,
              onShowAppbarContextMenu: () => focusNode.requestFocus(),
              exportPathForExcel: Export.getDefaultDirectoryPath('Cutrans 3.0'),
              addSearchAction: addSearchAction,
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
    );
  }

  @override
  List<ActionFromZero> buildDefaultActions(BuildContext context, {FocusNode? focusNode}) {
    focusNode ??= this.focusNode;
    final objectTemplate = this.objectTemplate;
    final allowAddNew = this.allowAddNew;
    List<T> currentSelected = [];
    try {
      currentSelected = tableController.filtered.where((element) => selectedObjects.value[element]==true).map((e) => e.id).toList();
    } catch (_) {}
    return [
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(Icons.edit_outlined),
          ),
          title: '${FromZeroLocalizations.of(context).translate('edit')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            focusNode?.requestFocus();
            maybeEditMultiple(context, currentSelected);
          },
          breakpoints: actionEditBreakpoints[0]==ActionState.none ? actionEditBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
          ),
          title: '${FromZeroLocalizations.of(context).translate('duplicate')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            duplicateRows(currentSelected);
          },
          breakpoints: actionDuplicateBreakpoints[0]==ActionState.none ? actionDuplicateBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0 && objectTemplate.canDelete)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(allowAddNew ? Icons.delete_forever_outlined : Icons.clear),
          ),
          title: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) async {
            if (await maybeDelete(context, currentSelected)) {
              focusNode?.requestFocus();
            }
          },
          breakpoints: actionDeleteBreakpoints[0]==ActionState.none ? actionDeleteBreakpoints : null,
        ),
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(Icons.cancel_outlined),
          ),
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
          icon: Icon(Icons.add),
          onTap: (context) {
            focusNode?.requestFocus();
            maybeAddRow(context);
          },
        ),
      if (dao.enableUndoRedoMechanism)
        ActionFromZero.divider(breakpoints: {0: ActionState.popup,},),
      if (dao.enableUndoRedoMechanism)
        ActionFromZero(
          title: 'Deshacer', // TODO 2 internationalize
          icon: Icon(MaterialCommunityIcons.undo_variant),
          onTap: (context) {
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
          title: 'Rehacer', // TODO 2 internationalize
          icon: Icon(MaterialCommunityIcons.redo_variant),
          onTap: (context) {
            focusNode?.requestFocus();
            redo(removeEntryFromDAO: true);
          },
          enabled: redoValues.isNotEmpty,
          breakpoints: {
            0: ActionState.popup,
          },
        ),
      // ActionFromZero( // maybe add a 'delete-all'
      //   title: 'Limpiar', // TODO 2 internationalize
      //   icon: Icon(Icons.clear),
      //   onTap: (context) => value = defaultValue,
      //   enabled: clearable && value!=defaultValue,
      //   breakpoints: {
      //     0: ActionState.popup,
      //   },
      // ),
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
            final ref = dao.contextForValidation! as WidgetRef;
            final provider = availableObjectsPoolProvider!(context, this, dao);
            final stateNotifier = ref.read(provider.notifier);
            stateNotifier.refresh(ref);
          },
        ),
    ];
  }

}



class IconBackground extends StatelessWidget {

  final Color color;
  final Widget child;
  final double overflowSize;

  IconBackground({
    required this.color,
    required this.child,
    this.overflowSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -overflowSize, bottom: -overflowSize, left: -overflowSize, right: -overflowSize,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color, color.withOpacity(0)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

}
