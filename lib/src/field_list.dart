import 'package:animations/animations.dart';
import 'package:from_zero_ui/src/popup_from_zero.dart';
import 'package:from_zero_ui/util/my_ensure_visible_when_focused.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/util/comparable_list.dart';


typedef Widget RowActionBuilder(DAO e);



class ListField extends Field<ComparableList<DAO>> {

  DAO objectTemplate;
  TableController? tableController;
  Future<List<DAO>> Function(BuildContext context)? availableObjectsPoolGetter;
  bool allowDuplicateObjectsFromAvailablePool;
  bool showObjectsFromAvailablePoolAsTable;
  bool allowAddNew;
  bool collapsed;
  bool allowMultipleSelection;
  bool tableCellsEditable;
  bool collapsible;
  bool viewOnRowTap;
  Map<double, ActionState> actionViewBreakpoints;
  Map<double, ActionState> actionEditBreakpoints;
  Map<double, ActionState> actionDuplicateBreakpoints;
  Map<double, ActionState> actionDeleteBreakpoints;
  /// this means that save() will be called on the object when adding a row
  /// and delete() will be called when removing a row, default false
  bool updateObjectsInRealTime;
  bool skipDeleteConfirmation;
  bool showTableHeaders;
  bool showDefaultSnackBars;
  List<RowActionBuilder> extraRowActionBuilders; //TODO 3 also allow global action builders
  bool showEditDialogOnAdd;
  bool showAddButtonAtEndOfTable;
  Key? tableKey;
  Widget? tableErrorWidget;
  int? initialSortColumn;
  ValueChanged<RowModel>? onRowTap;
  bool? tableSortable;
  bool? tableFilterable;
  bool expandHorizontally;
  List<ValidationError> listValidationErrors = [];

  List<DAO> get objects => value!.list;
  List<DAO> get dbObjects => dbValue!.list;
  @override
  set value(ComparableList<DAO>? value) {
    assert(value!=null, 'ListField is non-nullable by design.');
    super.value = value;
  }

  ValueNotifier<Map<DAO, bool>> selectedObjects = ValueNotifier({});
  ValueNotifier<List<DAO>?> filtered = ValueNotifier(null);


  ListField({
    required FieldValueGetter<String, Field> uiNameGetter,
    required this.objectTemplate,
    required List<DAO> objects,
    List<DAO>? dbObjects,
    this.availableObjectsPoolGetter,
    this.allowDuplicateObjectsFromAvailablePool = false,
    this.showObjectsFromAvailablePoolAsTable = false,
    this.allowAddNew = true,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, /// Unused in table
    this.tableCellsEditable = false,
    double maxWidth = double.infinity,
    double minWidth = 0,
    double flex = 0,
    this.tableController,
    this.collapsed = false,
    this.allowMultipleSelection = false,
    this.collapsible = true,
    bool? viewOnRowTap,
    ActionState? actionViewType,
    Map<double, ActionState>? actionEditBreakpoints, //= {0: ActionState.popup},
    Map<double, ActionState>? actionDuplicateBreakpoints, //= ActionState.none,
    Map<double, ActionState>? actionDeleteBreakpoints,  // = ActionState.icon,
    this.showTableHeaders = true,
    this.updateObjectsInRealTime = false,
    bool? showDefaultSnackBars,
    bool? skipDeleteConfirmation,
    this.extraRowActionBuilders = const [],
    this.showAddButtonAtEndOfTable = false,
    bool? showEditDialogOnAdd,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    this.tableKey,
    this.tableErrorWidget,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.initialSortColumn,
    this.onRowTap,
    FieldValueGetter<List<FieldValidator<ComparableList<DAO>>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    this.tableSortable,
    this.tableFilterable,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
    List<ComparableList<DAO>?>? undoValues,
    List<ComparableList<DAO>?>? redoValues,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    bool invalidateNonEmptyValuesIfHiddenInForm = true,
    ComparableList<DAO>? defaultValue,
    this.expandHorizontally = true,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) :  assert(!updateObjectsInRealTime || availableObjectsPoolGetter==null
                    , 'It makes no sense to save/delete in real time if adding from a pool of pre-saved objects'),
        this.showEditDialogOnAdd = showEditDialogOnAdd ?? !tableCellsEditable,
        this.showDefaultSnackBars = showDefaultSnackBars ?? updateObjectsInRealTime,
        this.skipDeleteConfirmation = skipDeleteConfirmation ?? updateObjectsInRealTime,
        this.viewOnRowTap = viewOnRowTap ?? (onRowTap==null && !tableCellsEditable),
        this.actionViewType = actionViewType ?? (viewOnRowTap ?? (onRowTap==null && !tableCellsEditable) ? ActionState.popup : ActionState.icon),
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
          focusNode: focusNode ?? FocusNode(),
          invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm,
          defaultValue: defaultValue ?? ComparableList<DAO>(),
          backgroundColor: backgroundColor,
          actions: actions,
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
    return objects.isEmpty ? ''
        : '${objects.length} ${objects.length==1 ? objectTemplate.classUiName : objectTemplate.classUiNamePlural}';
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

  @override
  Future<bool> validate(BuildContext context, DAO dao, {
    bool validateIfNotEdited=false,
  }) async {
    final superResult = super.validate(context, dao, validateIfNotEdited: validateIfNotEdited);
    listValidationErrors = List.from(validationErrors);
    List<Future<bool>> results = [];
    for (final e in objects) {
      for (final f in e.props.values) {
        results.add(f.validate(context, e,
          validateIfNotEdited: validateIfNotEdited,
        ));
      }
    }
    bool success = await superResult;
    for (final e in results) {
      success = success && await e;
    }
    for (final e in objects) {
      validationErrors.addAll(e.validationErrors);
    }
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    return validationErrors.where((e) => e.isBlocking).isEmpty;
  }

  @override
  ListField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    ComparableList<DAO>? value,
    ComparableList<DAO>? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    DAO? objectTemplate,
    Future<List<DAO>>? futureObjects,
    List<DAO>? objects,
    List<DAO>? dbObjects,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    bool? collapsible,
    ActionState? actionEditType,
    ActionState? actionDuplicateType,
    ActionState? actionDeleteType,
    ActionState? actionViewType,
    bool? skipDeleteConfirmation,
    bool? showTableHeaders,
    Future<List<DAO>> Function(BuildContext contex)? availableObjectsPoolGetter,
    bool? allowDuplicateObjectsFromAvailablePool,
    bool? showObjectsFromAvailablePoolAsTable,
    bool? allowAddNew,
    List<RowActionBuilder>? extraRowActionBuilders,
    int? initialSortColumn,
    bool? tableCellsEditable,
    bool? allowMultipleSelection,
    ValueChanged<RowModel>? onRowTap,
    bool? showAddButtonAtEndOfTable,
    bool? showEditDialogOnAdd,
    Widget? tableErrorWidget,
    bool? showDefaultSnackBars,
    FieldValueGetter<List<FieldValidator<ComparableList<DAO>>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    TableController? tableController,
    bool? tableSortable,
    bool? tableFilterable,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<ComparableList<DAO>?>? undoValues,
    List<ComparableList<DAO>?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    ComparableList<DAO>? defaultValue,
    bool? expandHorizontally,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actions,
  }) {
    return ListField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      objectTemplate: objectTemplate??this.objectTemplate,
      objects: objects??this.objects.map((e) => e.copyWith()).toList(),
      dbObjects: dbObjects??objects??this.dbObjects.map((e) => e.copyWith()).toList(),
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      collapsible: collapsible ?? this.collapsible,
      actionEditType: actionEditType ?? this.actionEditType,
      actionDuplicateType: actionDuplicateType ?? this.actionDuplicateType,
      actionDeleteType: actionDeleteType ?? this.actionDeleteType,
      actionViewType: actionViewType ?? actionViewType,
      availableObjectsPoolGetter: availableObjectsPoolGetter ?? this.availableObjectsPoolGetter,
      allowDuplicateObjectsFromAvailablePool: allowDuplicateObjectsFromAvailablePool ?? this.allowDuplicateObjectsFromAvailablePool,
      allowAddNew: allowAddNew ?? this.allowAddNew,
      extraRowActionBuilders: extraRowActionBuilders ?? this.extraRowActionBuilders,
      skipDeleteConfirmation: skipDeleteConfirmation ?? this.skipDeleteConfirmation,
      showTableHeaders: showTableHeaders ?? this.showTableHeaders,
      initialSortColumn: initialSortColumn ?? this.initialSortColumn,
      tableCellsEditable: tableCellsEditable ?? this.tableCellsEditable,
      allowMultipleSelection: allowMultipleSelection ?? this.allowMultipleSelection,
      onRowTap: onRowTap ?? this.onRowTap,
      showAddButtonAtEndOfTable: showAddButtonAtEndOfTable ?? this.showAddButtonAtEndOfTable,
      showEditDialogOnAdd: showEditDialogOnAdd ?? this.showEditDialogOnAdd,
      tableErrorWidget: tableErrorWidget ?? this.tableErrorWidget,
      showDefaultSnackBars: showDefaultSnackBars ?? this.showDefaultSnackBars,
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
    );
  }

  void addListeners() {
    objects.forEach((element) {
      element.addListener(notifyListeners);
    });
  }

  void addRow (DAO element) => addRows([element]);
  void addRows (List<DAO> elements) {
    for (final e in elements) {
      e.addListener(notifyListeners);
      e.parentDAO = dao;
    }
    final newValue = value!.copyWith();
    newValue.addAll(elements);
    value = newValue;
  }

  void duplicateRow(DAO element) => duplicateRows([element]);
  void duplicateRows(List<DAO> elements) {
    final newValue = value!.copyWith();
    elements.forEach((e) {
      e.parentDAO = dao;
      int index = newValue.indexOf(e);
      if (index<0) {
        newValue.add(e.copyWith());
      } else {
        newValue.insert(index+1, e.copyWith());
      }
    });
    value = newValue;
  }

  Future<bool> removeRow(DAO element) => removeRows([element]);
  Future<bool> removeRows(List<DAO> elements) async {
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



  void maybeAddRow(context) async { // TODO 3 implement disabled logic in ListField (color + tooltip + mouseRegion)
    DAO emptyDAO = objectTemplate.copyWith();
    if (availableObjectsPoolGetter!=null) {
      var availableObjects = availableObjectsPoolGetter!(context);
      if (!allowDuplicateObjectsFromAvailablePool) {
        availableObjects = availableObjects.then((v) => v.where((e) => !objects.contains(e)).toList());
      }
      DAO? selected;
      if (showObjectsFromAvailablePoolAsTable) {
        final previousOnSave = emptyDAO.onSave;
        if (previousOnSave!=null) {
          final newOnSave;
          newOnSave = (context, e) async {
            DAO? newDAO = await previousOnSave(context, e);
            if (newDAO!=null) {
              WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                Navigator.of(context).pop(newDAO);
              });
            }
            return newDAO;
          };
          emptyDAO = emptyDAO.copyWith(
            onSave: newOnSave,
          );
        }
        Widget content = AnimatedBuilder(
          animation:  this,
          builder: (context, child) {
            ScrollController scrollController = ScrollController();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
                  child: Text('${FromZeroLocalizations.of(context).translate("add_add")} $uiName',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
                Expanded(
                  child: FutureBuilderFromZero<List<DAO>>(
                    future: availableObjects,
                    successBuilder: (context, data) {
                      return ScrollbarFromZero(
                        controller: scrollController,
                        child: ScrollOpacityGradient(
                          scrollController: scrollController,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 32),
                                child: Column(
                                  children: ListField(
                                    uiNameGetter: (field, dao) => emptyDAO.classUiNamePluralGetter(dao),
                                    objectTemplate: emptyDAO,
                                    tableCellsEditable: false,
                                    collapsible: false,
                                    actionDeleteType: ActionState.none,
                                    objects: data,
                                    allowAddNew: allowAddNew && emptyDAO.onSave!=null,
                                    onRowTap: (value) {
                                      Navigator.of(context).pop(value.id);
                                    },
                                  ).buildFieldEditorWidgets(context,
                                    expandToFillContainer: true,
                                    asSliver: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 12, left: 12, top: 8,),
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
            );
          },
        );
        selected = await showModal(
          context: context,
          builder: (modalContext) {
            return Center(
              child: SizedBox(
                width: 512+128,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Dialog(
                    clipBehavior: Clip.hardEdge,
                    child: Container(
                      color: Theme.of(context).canvasColor,
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      } else {
        final objects = await availableObjects;
        await showPopupFromZero(
          context: context,
          anchorKey: headerGlobalKey,
          builder: (context) {
            return Card(
              clipBehavior: Clip.hardEdge,
              child: ComboFromZeroPopup<DAO>(
                possibleValues: objects,
                onSelected: (value) {
                  selected = value;
                },
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
              ),
            );
          },
        );
      }
      if (selected!=null) {
        addRow(selected!);
      }
    } else {
      bool add = true;
      if (showEditDialogOnAdd) {
        add = await emptyDAO.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars);
      }
      if (add) {
        addRow(emptyDAO);
      }
    }
  }

  Future<bool> maybeDelete(BuildContext context, List<DAO> elements,) async {
    if (elements.isEmpty) return false;
    bool? delete = skipDeleteConfirmation || (await showDialog(
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
      if (updateObjectsInRealTime) {
        if (elements.length>1) {
          throw new UnimplementedError('multiple deletion realtime handling not implemented');
        }
        showModal(
          context: context,
          configuration: const FadeScaleTransitionConfiguration(barrierDismissible: false,),
          builder: (context) {
            return LoadingSign();
          },
        );
        result = await elements.first.delete(context, showDefaultSnackBar: showDefaultSnackBars);
        Navigator.of(context).pop();
        if (result) {
          result = await removeRows(elements);
        }
      } else {
        result = await removeRows(elements);
      }
      return result;
    }
    return false;
  }

  static void maybeEditMultiple(BuildContext context, List<DAO> elements) async {
    // TODO 3 test this well, rework it visually to be like maybeEdit

    final DAO dao = elements.first.copyWith();
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

  final headerGlobalKey = GlobalKey();
  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    FocusNode? focusNode, /// unused
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
    Map<String, Field> propsShownOnTable = Map.from(objectTemplate.props)..removeWhere((k, v) => v.hiddenInTable);
    double width = 48*((actionDeleteType.shownOnPrimaryToolbar?1:0) + (actionDuplicateType.shownOnPrimaryToolbar?1:0) + (actionEditType.shownOnPrimaryToolbar?1:0) + (actionViewType.shownOnPrimaryToolbar?1:0));
    propsShownOnTable.forEach((key, value) {
      width += value.tableColumnWidth ?? 192;
    });
    double rowHeight = tableCellsEditable ? 48 : 36;
    result = AnimatedBuilder(
      key: fieldGlobalKey,
      animation:  this,
      builder: (context, child) {
        if (collapsed) {
          Widget result = SizedBox(
            width: expandHorizontally ? null : maxWidth==double.infinity ? width : maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getTableHeader(context, focusNode: focusNode!),
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
        return Material(
          color: Theme.of(context).cardColor,
          child: Container(
            color: Material.of(context)?.color ?? Theme.of(context).canvasColor,
            child: TableFromZero(
              key: tableKey ?? ValueKey(objects.length),
              maxWidth: expandHorizontally ? null : maxWidth==double.infinity ? width : maxWidth,
              minWidth: width,
              initialSortedColumnIndex: initialSortColumn ?? 0,
              tableController: tableController,
              layoutWidgetType: asSliver
                  ? objects.length<=10 ? TableFromZero.sliverAnimatedListViewBuilder : TableFromZero.sliverListViewBuilder
                  : !expandToFillContainer
                      ? TableFromZero.column
                      : objects.length<=10 ? TableFromZero.animatedListViewBuilder : TableFromZero.listViewBuilder,
              applyMinWidthToHeaderAddon: false,
              verticalPadding: 0,
              useSmartRowAlternativeColors: false,
              columns: propsShownOnTable.values.map((e) {
                final SimpleColModel result = e.getColModel();
                if (tableFilterable!=null) {
                  result.filterEnabled = tableFilterable;
                }
                if (tableSortable!=null) {
                  result.sortEnabled = tableSortable;
                }
                return result;
              }).toList(),
              showHeaders: showTableHeaders,
              rows: objects.map((e) {
                // e.props.remove(columnName);
                return SimpleRowModel(
                  id: e,
                  values: propsShownOnTable.keys.map((k) => e.props[k]).toList(),
                  height: rowHeight,
                  onRowTap: onRowTap ?? (viewOnRowTap ? (row) {
                    e.pushViewDialog(context);
                  } : null),
                  actions: [
                    ...extraRowActionBuilders.map((builder) => builder(e)).toList(),
                    if (actionViewType)
                      ActionFromZero(
                        icon: Icon(Icons.remove_red_eye),
                        title: FromZeroLocalizations.of(context).translate('view'),
                        onTap: (context) async {
                          e.pushViewDialog(context);
                        },

                      ),
                    if (actionEditType)
                      ActionFromZero(
                        icon: Icon(Icons.edit_outlined),
                        tooltip: FromZeroLocalizations.of(context).translate('edit'),
                        onPressed: () async {
                          if (await e.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars)) {
                            passedFirstEdit = true;
                            notifyListeners();
                          }
                        },
                      ),
                    if (actionDuplicateType)
                      ActionFromZero(
                        icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
                        tooltip: FromZeroLocalizations.of(context).translate('duplicate'),
                        onPressed: () {
                          duplicateRows([e]);
                        },
                      ),
                    if (actionDeleteType)
                      ActionFromZero(
                        icon: Icon(Icons.delete_forever_outlined),
                        tooltip: FromZeroLocalizations.of(context).translate('delete'),
                        onPressed: () async {
                          if (await maybeDelete(context, [e])) {
                            passedFirstEdit = true;
                            notifyListeners();
                          }
                        },
                      ),
                  ],
                  selected: allowMultipleSelection ? (selectedObjects.value[e]??false) : null,
                  backgroundColor: selectedObjects.value[e]??false ? Theme.of(context).accentColor.withOpacity(0.2) : null,
                  onCheckBoxSelected: allowMultipleSelection ? (row, focused) {
                    selectedObjects.value[row.id] = focused??false;
                    selectedObjects.notifyListeners();
                    notifyListeners();
                  } : null,
                );
              }).toList(),
              cellBuilder: tableCellsEditable ? (context, row, col, j) {
                final widgets = (row.values[j] as Field).buildFieldEditorWidgets(context,
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
              } : null,
              onFilter: (rows) {
                filtered.value = rows.map((e) => e.id as DAO).toList();
                return rows;
              },
              onAllSelected: allowMultipleSelection ? (value, rows) {
                filtered.value = rows.map((e) => e.id as DAO).toList();
                filtered.value!.forEach((element) {
                  selectedObjects.value[element] = value??false;
                  selectedObjects.notifyListeners();
                });
                notifyListeners();
              } : null,
              errorWidget: tableErrorWidget
                    ?? Container(
                        color: Theme.of(context).cardColor,
                        width: expandHorizontally ? null : maxWidth==double.infinity ? width : maxWidth,
                        child: ErrorSign(
                          title: FromZeroLocalizations.of(context).translate('no_data'),
                          subtitle: FromZeroLocalizations.of(context).translate('no_data_add'),
                        ),
                      ),
              headerAddon: _getTableHeader(context, focusNode: focusNode!),
            ),
          ),
        );
      }
    );
    if (!asSliver && addCard) { // TODO 3 implement addCard in table, and add it to each sliver, VERY HARD IPMLEMENTATION FOR LOW REWARD
      result = Card(
        clipBehavior: Clip.hardEdge,
        child: result,
      );
    }
    List<Widget> resultList = [
      result,
      if ((allowAddNew||availableObjectsPoolGetter!=null) && showAddButtonAtEndOfTable && !collapsed && !dense)
        buildAddAddon(
          context: context,
          width: width,
        ),
      if (!dense)
        ValidationMessage(errors: listValidationErrors),
    ];
    if (asSliver) {
      resultList = resultList.map((e) => (e==result) ? e : SliverToBoxAdapter(child: e,)).toList();
    }
    return resultList;
  }

  Widget buildAddAddon({
    required BuildContext context,
    required double width,
  }) {
    return AnimatedBuilder(
      animation:  this,
      builder: (context, child) {
        if (collapsed) {
          return SizedBox.shrink();
        }
        return Transform.translate(
          offset: Offset(0, -12),
          child: Container(
            width: expandHorizontally ? null : maxWidth==double.infinity ? width : maxWidth,
            color: Material.of(context)!.color ?? Theme.of(context).cardColor,
            child: Column(
              children: [
                SizedBox(
                  height: 12,
                ),
                TextButton(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10,),
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8,),
                          Text('${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}', style: TextStyle(fontSize: 16),),
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
                SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildViewWidget(BuildContext context, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=true,
  }) {
    if (hiddenInView) {
      return SizedBox.shrink();
    }
    final uiNames = objects.map((e) => e.toString()).toList()..sort();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO this probably wont do well on a mobile layout
          Expanded(
            flex: 1000000,
            child: Padding(
              padding: const EdgeInsets.only(top: 2,),
              child: Text(uiName,
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Container(
            height: 24,
            child: VerticalDivider(width: 16,),
          ),
          Expanded(
            flex: 1618034,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: uiNames.mapIndexed((i, e) {
                return InkWell(
                  onTap: () => linkToInnerDAOs ? objects[i].pushViewDialog(context) : null,
                  child: Text(e,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _getTableHeader(BuildContext context, {
    required FocusNode focusNode,
  }) {
    return ValueListenableBuilder(
      valueListenable: filtered,
      builder: (context, List<DAO>? filtered, child) {
        final actions = this.actions?.call(context, this, dao) ?? [];
        if (actions.isNotEmpty) {
          actions.add(ActionFromZero.divider());
        }
        actions.addAll(buildDefaultActions(context));
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              color: Material.of(context)!.color ?? Theme.of(context).cardColor, // Colors.transparent
              iconTheme: Theme.of(context).iconTheme,
              titleTextStyle: Theme.of(context).textTheme.subtitle1,
              toolbarTextStyle: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          child: EnsureVisibleWhenFocused(
            focusNode: focusNode,
            child: Focus(
              focusNode: focusNode, // TODO 3 maybe this focus node should be somewhere else
              skipTraversal: true,
              canRequestFocus: true,
              child: AppbarFromZero(
                titleSpacing: 0,
                key: headerGlobalKey,
                title: Row(
                  children: [
                    SizedBox(width: 9,),
                    collapsible ? IconButton(
                      icon: Icon(collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                      onPressed: () {
                        collapsed = !collapsed;
                        notifyListeners();
                      },
                    ) : SizedBox(width: allowMultipleSelection ? 41 : 0,),
                    SizedBox(width: 9,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(uiName,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        if (filtered!=null)
                          ValueListenableBuilder<Map<DAO, bool>>(
                            valueListenable: selectedObjects,
                            builder: (context, selectedObjects, child) {
                              int count = filtered.where((element) => selectedObjects[element]==true).length;
                              Widget result;
                              final objects = collapsed ? this.objects : filtered;
                              if (collapsed || count==0) {
                                result = Text(objects.length==0 ? FromZeroLocalizations.of(context).translate('no_elements')
                                    : '${objects.length} ${objects.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                                    : FromZeroLocalizations.of(context).translate('element_sing')}',
                                  // key: ValueKey('normal'),
                                  style: Theme.of(context).textTheme.caption,
                                );
                              } else {
                                result = Text('$count ${count>1 ? FromZeroLocalizations.of(context).translate('selected_plur')
                                    : FromZeroLocalizations.of(context).translate('selected_sing')}',
                                  // key: ValueKey('selected'),
                                  style: Theme.of(context).textTheme.caption,
                                );
                              }
                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutCubic,
                                child: result,
                                transitionBuilder: (child, animation) {
                                  return SizeTransition(
                                    axisAlignment: -1,
                                    sizeFactor: animation,
                                    child: child,
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                elevation: 0,
                actions: actions,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  List<ActionFromZero> buildDefaultActions(BuildContext context) {
    List<DAO> currentSelected = filtered.value?.where((element) => selectedObjects.value[element]==true).toList() ?? [];
    return [
      if (!collapsed && currentSelected.length>0 && actionEditType)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(Icons.edit_outlined),
          ),
          title: '${FromZeroLocalizations.of(context).translate('edit')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            maybeEditMultiple(context, currentSelected);
          },
        ),
      if (!collapsed && currentSelected.length>0 && actionDuplicateType)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
          ),
          title: '${FromZeroLocalizations.of(context).translate('duplicate')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            duplicateRows(currentSelected);
          },
        ),
      if (!collapsed && currentSelected.length>0 && actionDeleteType)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(Icons.delete_forever_outlined),
          ),
          title: '${FromZeroLocalizations.of(context).translate('delete')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
          onTap: (context) {
            maybeDelete(context, currentSelected);
          },
        ),
      if (!collapsed && currentSelected.length>0)
        ActionFromZero(
          icon: IconBackground(
            color: Theme.of(context).accentColor.withOpacity(0.25),
            child: Icon(Icons.cancel_outlined),
          ),
          title: FromZeroLocalizations.of(context).translate('cancel_selection'),
          onTap: (context) {
            selectedObjects.value = {};
            notifyListeners();
          },
        ),
      if ((allowAddNew||availableObjectsPoolGetter!=null) && !collapsed && currentSelected.length==0)
        ActionFromZero(
          title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
          icon: Icon(Icons.add),
          onTap: (context) {
            maybeAddRow(context);
          },
        ),
      ActionFromZero.divider(breakpoints: {0: ActionState.popup,},),
      ActionFromZero(
        title: 'Deshacer', // TODO 1 internationalize
        icon: Icon(MaterialCommunityIcons.undo_variant),
        onTap: (context) => undo(removeEntryFromDAO: true),
        enabled: undoValues.isNotEmpty,
        breakpoints: {
          0: ActionState.popup,
        },
      ),
      ActionFromZero(
        title: 'Rehacer', // TODO 1 internationalize
        icon: Icon(MaterialCommunityIcons.redo_variant),
        onTap: (context) => redo(removeEntryFromDAO: true),
        enabled: redoValues.isNotEmpty,
        breakpoints: {
          0: ActionState.popup,
        },
      ),
      // ActionFromZero( // maybe add a 'delete-all'
      //   title: 'Limpiar', // TODO 1 internationalize
      //   icon: Icon(Icons.clear),
      //   onTap: (context) => value = defaultValue,
      //   enabled: clearable && value!=defaultValue,
      //   breakpoints: {
      //     0: ActionState.popup,
      //   },
      // ),
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
