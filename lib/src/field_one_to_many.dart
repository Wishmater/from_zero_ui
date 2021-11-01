import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/dao.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/field_validators.dart';
import 'package:dartx/dartx.dart';


typedef Widget RowActionBuilder(DAO e);


class OneToManyRelationField extends Field<String> {

  DAO objectTemplate;
  List<DAO>? dbObjects;
  Future<List<DAO>>? futureObjects;
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
  bool showActionView;
  bool showActionEdit;
  bool showActionDuplicate;
  bool showActionDelete;
  bool skipDeleteConfirmation;
  bool showTableHeaders;
  bool showDefaultSnackBars;
  List<RowActionBuilder> extraRowActionBuilders; //TODO 3 also allow global action builders
  bool showEditDialogOnAdd;
  bool showAddButtonAtEndOfTable;
  Key? tableKey;
  Widget Function(Object? e, Object? st)? futureErrorWidgetBuilder;
  Object? futureError;
  Object? futureStackTrace;
  Widget? tableErrorWidget;
  int? initialSortColumn;
  ValueChanged<RowModel>? onRowTap;
  bool? tableSortable;
  bool? tableFilterable;

  List<DAO>? _objects;
  List<DAO>? get objects => _objects;
  set objects(List<DAO>? value) {
    _objects = value;
    notifyListeners();
  }
  void addListeners() {
    _objects?.forEach((element) {
      element.addListener(notifyListeners);
    });
  }

  ValueNotifier<Map<DAO, bool>> selectedObjects = ValueNotifier({});
  ValueNotifier<List<DAO>?> filtered = ValueNotifier(null);


  // TODO ?????? how does undo/redo even work here LOL, objects should just be values, maybe make getter/setter that redirects, for compatibility
  OneToManyRelationField({
    required FieldValueGetter<String, Field> uiNameGetter,
    required this.objectTemplate,
    this.availableObjectsPoolGetter,
    this.allowDuplicateObjectsFromAvailablePool = false,
    this.showObjectsFromAvailablePoolAsTable = false,
    this.allowAddNew = true,
    FieldValueGetter<bool, Field> clearableGetter = trueFieldGetter, /// Unused in table
    FieldValueGetter<bool, Field> enabledGetter = trueFieldGetter, //TODO implement enabled
    this.tableCellsEditable = false,
    double maxWidth = double.infinity,
    List<DAO>? objects,
    List<DAO>? dbObjects,
    this.futureObjects,
    this.tableController,
    this.collapsed = false,
    this.allowMultipleSelection = false,
    this.collapsible = true,
    bool? viewOnRowTap,
    bool? showActionView,
    this.showActionEdit = false,
    this.showActionDuplicate = false,
    this.showActionDelete = true,
    this.showTableHeaders = true,
    this.showDefaultSnackBars = true,
    bool? skipDeleteConfirmation,
    this.extraRowActionBuilders = const [],
    this.showAddButtonAtEndOfTable = false,
    bool? showEditDialogOnAdd,
    FieldValueGetter<String?, Field>? hintGetter,
    this.tableKey,
    this.tableErrorWidget,
    this.futureErrorWidgetBuilder,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.initialSortColumn,
    this.onRowTap,
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool validateOnlyOnConfirm = false,
    this.tableSortable,
    this.tableFilterable,
    FieldValueGetter<SimpleColModel, Field> colModelBuilder = Field.fieldDefaultGetColumn,
  }) :  assert(objects==null || futureObjects==null),
        _objects = objects,
        dbObjects = dbObjects ?? List.from(objects ?? []),
        showEditDialogOnAdd = showEditDialogOnAdd ?? (tableCellsEditable ? false : objectTemplate.onSave!=null),
        this.skipDeleteConfirmation = availableObjectsPoolGetter!=null,
        this.viewOnRowTap = viewOnRowTap ?? (onRowTap==null && !tableCellsEditable),
        this.showActionView = showActionView ?? !(viewOnRowTap ?? onRowTap==null),
        super(
          uiNameGetter: uiNameGetter,
          value: '',
          dbValue: '',
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
        ) {
    addListeners();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      if (objects==null && futureObjects==null) {
        this.objects = [];
        this.dbObjects = [];
      } else if (futureObjects!=null) {
        futureObjects!.then((o) {
          this.objects = List.from(o);
          this.dbObjects = List.from(o);
          notifyListeners();
        }).onError((error, stackTrace) {
          this.futureError = error;
          this.futureStackTrace = stackTrace;
          notifyListeners();
        });
      }
    });
  }

  @override
  bool get isEdited {
    bool edited = objects?.length != dbObjects?.length;
    for (var i = 0; !edited && i < (objects?.length??0); ++i) {
      edited = objects?[i] != dbObjects?[i];
    }
    if (!edited) {
      edited = objects==null || objects!.any((element) => element.isEdited);
    }
    return edited;
  }

  @override
  OneToManyRelationField copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    String? value,
    String? dbValue,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<bool, Field>? enabledGetter,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
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
    bool? showActionEdit,
    bool? showActionDuplicate,
    bool? showActionDelete,
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
    FieldValueGetter<List<FieldValidator<String>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    TableController? tableController,
    bool? tableSortable,
    bool? tableFilterable,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<String?>? undoValues,
    List<String?>? redoValues,
  }) {
    return OneToManyRelationField(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      enabledGetter: enabledGetter??this.enabledGetter,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      objectTemplate: objectTemplate??this.objectTemplate,
      objects: objects??this.objects?.map((e) => e.copyWith()).toList(),
      dbObjects: dbObjects??objects??this.dbObjects?.map((e) => e.copyWith()).toList(),
      futureObjects: (objects??this.objects)!=null ? null : futureObjects??this.futureObjects,
      hintGetter: hintGetter??this.hintGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      collapsible: collapsible ?? this.collapsible,
      showActionEdit: showActionEdit ?? this.showActionEdit,
      showActionDuplicate: showActionDuplicate ?? this.showActionDuplicate,
      showActionDelete: showActionDelete ?? this.showActionDelete,
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
    );
  }

  void revertChanges() {
    objects = dbObjects?.map((e) => e.copyWith()).toList();
    notifyListeners();
  }
  
  void addRow(context) async {
    DAO emptyDAO = objectTemplate.copyWith();
    if (availableObjectsPoolGetter!=null) {
      var availableObjects = availableObjectsPoolGetter!(context);
      if (!allowDuplicateObjectsFromAvailablePool) {
        availableObjects = availableObjects.then((v) => v.where((e) => !objects!.contains(e)).toList());
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
                  child: ScrollbarFromZero(
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
                              children: OneToManyRelationField(
                                uiNameGetter: (field, dao) => emptyDAO.classUiNamePluralGetter(dao),
                                objectTemplate: emptyDAO,
                                tableCellsEditable: false,
                                collapsible: false,
                                showActionDelete: false,
                                futureObjects: availableObjects,
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
        await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.2),
          builder: (context) {
            final animation = CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeInOutCubic,
            );
            Offset? referencePosition;
            Size? referenceSize;
            try {
              RenderBox box = headerGlobalKey.currentContext!.findRenderObject()! as RenderBox;
              referencePosition = box.localToGlobal(Offset.zero); //this is global position
              referenceSize = box.size;
            } catch(_) {}
            return CustomSingleChildLayout(
              delegate: DropdownChildLayoutDelegate(
                referencePosition: referencePosition,
                referenceSize: referenceSize,
                align: DropdownChildLayoutDelegateAlign.bottomRight
              ),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return SizedBox(
                    width: 312,
                    child: ClipRect(
                      clipper: RectPercentageClipper(
                        widthPercent: (animation.value*2.0).clamp(0.0, 1),
                      ),
                      child: child,
                    ),
                  );
                },
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.vertical,
                  axisAlignment: 0,
                  child: Card(
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
                  ),
                ),
              ),
            );
          },
        );
      }
      if (selected!=null) {
        _add(selected!);
      }
    } else {
      bool add = true;
      if (showEditDialogOnAdd) {
        add = await emptyDAO.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars);
      }
      if (add) {
        _add(emptyDAO);
      }
    }
  }
  void _add (DAO dao) {
    dao.addListener(notifyListeners);
    objects!.add(dao);
    passedFirstEdit = true;
    notifyListeners();
  }
  
  void duplicate(List<DAO> elements) {
    if (objects!=null) {
      elements.forEach((e) {
        int index = objects!.indexOf(e);
        if (index<0) {
          objects!.add(e.copyWith());
        } else {
          objects!.insert(index+1, e.copyWith());
        }
      });
      passedFirstEdit = true;
      notifyListeners();
    }
  }
  

  final headerGlobalKey = GlobalKey();
  @override
  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard=true,
    bool asSliver = true,
    bool expandToFillContainer = true,
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
    Map<String, Field> propsShownOnTable = Map.from(objectTemplate.props)..removeWhere((k, v) => v.hiddenInTable);
    double width = 48*((showActionDelete?1:0) + (showActionDuplicate?1:0) + (showActionEdit?1:0) + (showActionView?1:0));
    propsShownOnTable.forEach((key, value) {
      width += value.tableColumnWidth ?? 192;
    });
    result = AnimatedBuilder(
      key: fieldGlobalKey,
      animation:  this,
      builder: (context, child) {
        if (collapsed || objects==null) {
          Widget result;
          if (collapsed) {
            result = SizedBox(
              width: maxWidth==double.infinity ? width : maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getTableHeader(context),
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
          } else if (futureError!=null) {
            result = SizedBox(
                width: maxWidth==double.infinity ? width : maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getTableHeader(context),
                    futureErrorWidgetBuilder?.call(futureError, futureStackTrace)
                        ?? defaultErrorBuilder(context, futureError, futureStackTrace),
                  ],
                )
            );
          } else {
            result = SizedBox(
              width: maxWidth==double.infinity ? width : maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getTableHeader(context),
                  SizedBox(height: 96, child: LoadingSign()),
                ],
              )
            );
          }
          if (asSliver) {
            result = SliverToBoxAdapter(
              child: result,
            );
          }
          return result;
        }
        return TableFromZero(
          key: tableKey ?? ValueKey(objects!.length),
          maxWidth: maxWidth==double.infinity ? width : maxWidth,
          minWidth: width,
          initialSortedColumnIndex: initialSortColumn ?? 0,
          tableController: tableController,
          layoutWidgetType: asSliver
              ? objects!.length<=10 ? TableFromZero.sliverAnimatedListViewBuilder : TableFromZero.sliverListViewBuilder
              : !expandToFillContainer
                  ? TableFromZero.column
                  : objects!.length<=10 ? TableFromZero.animatedListViewBuilder : TableFromZero.listViewBuilder,
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
          rows: objects!.map((e) {
            // e.props.remove(columnName);
            return SimpleRowModel(
              id: e,
              values: propsShownOnTable.keys.map((k) => e.props[k]).toList(),
              height: tableCellsEditable ? 72 : 42,
              onRowTap: onRowTap ?? (viewOnRowTap ? (row) {
                e.pushViewDialog(context);
              } : null), //TODO if null, show view, if not show view as icon
              actions: [
                ...extraRowActionBuilders.map((builder) => builder(e)).toList(),
                if (showActionView)
                  IconButton(
                    icon: Icon(Icons.remove_red_eye),
                    tooltip: FromZeroLocalizations.of(context).translate('view'),
                    onPressed: () async {
                      e.pushViewDialog(context);
                    },
                  ),
                if (showActionEdit)
                  IconButton(
                    icon: Icon(Icons.edit_outlined),
                    tooltip: FromZeroLocalizations.of(context).translate('edit'),
                    onPressed: () async {
                      if (await e.maybeEdit(context, showDefaultSnackBars: showDefaultSnackBars)) {
                        passedFirstEdit = true;
                        notifyListeners();
                      }
                    },
                  ),
                if (showActionDuplicate)
                  IconButton(
                    icon: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
                    tooltip: FromZeroLocalizations.of(context).translate('duplicate'),
                    onPressed: () {
                      duplicate([e]);
                    },
                  ),
                if (showActionDelete)
                  IconButton(
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
            final widgets = (row.values[j] as Field).buildFieldEditorWidgets(context, expandToFillContainer: false);
            return Column(
              mainAxisSize: MainAxisSize.min,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: widgets.map((widget) {
                return Expanded(
                  child: widget is SliverToBoxAdapter ? widget.child! : widget,
                );
              }).toList(),
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
              ?? (availableObjectsPoolGetter==null
                  ? Container(
                    color: Material.of(context)!.color ?? Theme.of(context).cardColor,
                    width: maxWidth==double.infinity ? width : maxWidth,
                    child: ErrorSign(
                      title: FromZeroLocalizations.of(context).translate('no_data'),
                      subtitle: FromZeroLocalizations.of(context).translate('no_data_add'),
                    ),
                  ) : SizedBox.shrink()),
          headerAddon: _getTableHeader(context),
        );
      }
    );
    // if (addCard) {
    //   result = Card(
    //     clipBehavior: Clip.hardEdge,
    //     child: result,
    //   );
    // }
    List<Widget> resultList = [
      SizedBox(height: 1,),
      result,
      if ((allowAddNew||availableObjectsPoolGetter!=null) && showAddButtonAtEndOfTable)
        AnimatedBuilder(
          animation:  this,
          builder: (context, child) {
            if (collapsed || objects==null) {
              return SizedBox.shrink();
            }
            return Transform.translate(
              offset: Offset(0, -12),
              child: Container(
                width: maxWidth==double.infinity ? width : maxWidth,
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
                      onPressed: () => addRow(context),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ValidationMessage(errors: validationErrors),
      SizedBox(height: 1,),
    ];
    if (asSliver) {
      resultList = resultList.map((e) => (e==result) ? e : SliverToBoxAdapter(child: e,)).toList();
    }
    return resultList;
  }


  Widget buildViewWidget(BuildContext context, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=true,
  }) {
    if (hiddenInView) {
      return SizedBox.shrink();
    }
    final uiNames = objects==null ? null : (objects!.map((e) => e.toString()).toList()..sort());
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
            child: uiNames==null ? SizedBox.shrink() : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: uiNames.mapIndexed((i, e) {
                return InkWell(
                  onTap: () => linkToInnerDAOs ? objects![i].pushViewDialog(context) : null,
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


  Widget _getTableHeader(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: filtered,
      builder: (context, List<DAO>? filtered, child) {
        List<DAO>? currentSelected = filtered?.where((element) => selectedObjects.value[element]==true).toList();
        List<Widget> actions = [];
        if (filtered!=null && currentSelected!=null) {
          actions = [
            if (!collapsed && currentSelected.length>0 && showActionEdit)
              AppbarAction(
                icon: IconBackground(
                  color: Theme.of(context).accentColor.withOpacity(0.25),
                  child: Icon(Icons.edit_outlined),
                ),
                title: '${FromZeroLocalizations.of(context).translate('edit')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
                onTap: (context) {
                  maybeEditMultiple(context, currentSelected);
                },
              ),
            if (!collapsed && currentSelected.length>0 && showActionDuplicate)
              AppbarAction(
                icon: IconBackground(
                  color: Theme.of(context).accentColor.withOpacity(0.25),
                  child: Icon(MaterialCommunityIcons.content_duplicate, size: 21,),
                ),
                title: '${FromZeroLocalizations.of(context).translate('duplicate')} ${FromZeroLocalizations.of(context).translate('selected_plur')}',
                onTap: (context) {
                  duplicate(currentSelected);
                },
              ),
            if (!collapsed && currentSelected.length>0 && showActionDelete)
              AppbarAction(
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
              AppbarAction(
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
              AppbarAction(
                title: '${FromZeroLocalizations.of(context).translate('add')} ${objectTemplate.uiName}',
                icon: Icon(Icons.add),
                onTap: (context) {
                  addRow(context);
                },
                breakpoints: {
                  0: ActionState.icon,
                  256: ActionState.button,
                },
              ),
          ];
        }
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(

              // iconTheme: Theme.of(context).iconTheme,
              // textTheme: Theme.of(context).textTheme,
              // backgroundColor: Material.of(context)!.color ?? Theme.of(context).cardColor,
            ),
          ),
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
                      style: Theme.of(context).textTheme.headline6?.copyWith(color: Theme.of(context).appBarTheme.brightness==Brightness.light ? Colors.black : Colors.white,),
                    ),
                    if (filtered!=null)
                      ValueListenableBuilder<Map<DAO, bool>>(
                        valueListenable: selectedObjects,
                        builder: (context, selectedObjects, child) {
                          int count = filtered.where((element) => selectedObjects[element]==true).length;
                          Widget result;
                          if (objects==null) {
                            result = SizedBox.shrink();
                          } else {
                            final objects = collapsed ? this.objects : filtered;
                            if (collapsed || count==0) {
                              result = Text(objects!.length==0 ? FromZeroLocalizations.of(context).translate('no_elements')
                                  : '${objects.length} ${objects.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                                                                          : FromZeroLocalizations.of(context).translate('element_sing')}',
                                // key: ValueKey('normal'),
                                style: Theme.of(context).textTheme.caption?.copyWith(color: Theme.of(context).appBarTheme.brightness==Brightness.light ? Colors.black : Colors.white,),
                              );
                            } else {
                              result = Text('$count ${count>1 ? FromZeroLocalizations.of(context).translate('selected_plur')
                                                              : FromZeroLocalizations.of(context).translate('selected_sing')}',
                                // key: ValueKey('selected'),
                                style: Theme.of(context).textTheme.caption?.copyWith(color: Theme.of(context).accentColor.withOpacity(0.9)),
                              );
                            }
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
        );
      },
    );
  }

  Future<bool> maybeDelete(BuildContext context, List<DAO> elements,) async {
    if (elements.isEmpty) return false;
    bool? delete = skipDeleteConfirmation || (await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(FromZeroLocalizations.of(context).translate('confirm_delete_title')),
          content: Text('${FromZeroLocalizations.of(context).translate('confirm_delete_desc')} ${elements.length} ${elements.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                                                                                                                                      : FromZeroLocalizations.of(context).translate('element_sing')}?'),
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
      if (availableObjectsPoolGetter!=null) {
        elements.forEach((e) {
          bool v = objects!.remove(e);
          if (!result) {
            result = v;
          }
        });
        notifyListeners();
      } else {
        if (elements.length>1) {
          throw new UnimplementedError('multiple deletion handling not implemented');
        }
        showModal(
          context: context,
          configuration: const FadeScaleTransitionConfiguration(barrierDismissible: false,),
          builder: (context) {
            return LoadingSign();
          },
        );
        bool confirm = await elements.first.delete(context, showDefaultSnackBar: showDefaultSnackBars);
        if (confirm) {
          elements.forEach((e) {
            bool v = objects!.remove(e);
            if (!result) {
              result = v;
            }
          });
        }
        Navigator.of(context).pop();
        notifyListeners();
      }
      return result;
    }
    return false;
  }

  static void maybeEditMultiple(BuildContext context, List<DAO> elements) async {
    // TODO 3 test this well, rework it visually to be like maybeEdit
    Map<String, Field> props = {};
    elements.first.props.forEach((key, value) {
      props[key] = value.copyWith(
        hintGetter: (_, __) => FromZeroLocalizations.of(context).translate('keep_value'),
      ) ..value = null
        ..dbValue = null;
    });
    final DAO dao = elements.first.copyWith(
      // props: props, // TODO 3 need to change hint on all props from all groups
    );
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
                          slivers: dao.buildFormWidgets(context, showActionButtons: false,),
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
