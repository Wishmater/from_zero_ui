import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/src/app_scaffolding/api_snackbar.dart';
import 'package:from_zero_ui/src/dao/field.dart';
import 'package:from_zero_ui/src/dao/field_validators.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'field_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


typedef Future<ModelType?> OnSaveCallback<ModelType>(BuildContext context, DAO<ModelType> e);
typedef ApiState<ModelType?> OnSaveAPICallback<ModelType>(BuildContext context, DAO<ModelType> e);
typedef void OnDidSaveCallback<ModelType>(BuildContext context, ModelType? model, DAO<ModelType> dao);
typedef Future<String?> OnDeleteCallback<ModelType>(BuildContext context, DAO<ModelType> e);
typedef ApiState OnDeleteAPICallback<ModelType>(BuildContext context, DAO<ModelType> e);
typedef void OnDidDeleteCallback<ModelType>(BuildContext context, DAO<ModelType> dao);
typedef Widget DAOWidgetBuilder<ModelType>(BuildContext context, DAO<ModelType> dao);
typedef T DAOValueGetter<T, ModelType>(DAO<ModelType> dao);

class DAO<ModelType> extends ChangeNotifier implements Comparable {

  dynamic id;
  DAOValueGetter<String, ModelType> classUiNameGetter;
  String get classUiName => classUiNameGetter(this);
  DAOValueGetter<String, ModelType> classUiNamePluralGetter;
  String get classUiNamePlural => classUiNamePluralGetter(this);
  DAOValueGetter<String, ModelType> uiNameGetter;
  String get uiName => uiNameGetter(this);
  /// props shouldn't be added or removed manually, only changes at construction and on load()
  List<FieldGroup> fieldGroups;
  Map<String, Field> get props {
    return {
      if (fieldGroups.isNotEmpty)
        ...fieldGroups.map((e) => e.props).reduce((value, element) => {...value, ...element}),
    };
  }
  OnSaveCallback<ModelType>? onSave;
  OnSaveAPICallback<ModelType>? onSaveAPI;
  OnDidSaveCallback<ModelType>? onDidSave;
  OnDeleteCallback<ModelType>? onDelete;
  OnDeleteAPICallback<ModelType>? onDeleteAPI;
  OnDidDeleteCallback<ModelType>? onDidDelete;
  List<ValueChanged<DAO<ModelType>>> _selfUpdateListeners = [];
  DAOWidgetBuilder<ModelType>? viewWidgetBuilder;
  bool useIntrinsicHeightForViewDialog;
  double viewDialogWidth;
  double formDialogWidth;
  bool viewDialogLinksToInnerDAOs;
  bool viewDialogShowsViewButtons;
  bool? viewDialogShowsEditButton;
  DAO? parentDAO; /// if not null, undo/redo calls will be relayed to the parent

  DAO({
    required this.classUiNameGetter,
    DAOValueGetter<String, ModelType>? classUiNamePluralGetter,
    required this.uiNameGetter,
    this.id,
    this.fieldGroups = const [],
    this.onSave,
    this.onSaveAPI,
    this.onDidSave,
    this.onDelete,
    this.onDeleteAPI,
    this.onDidDelete,
    this.viewWidgetBuilder,
    this.useIntrinsicHeightForViewDialog = true,
    this.viewDialogWidth = 512,
    this.formDialogWidth = 512,
    this.viewDialogLinksToInnerDAOs = true,
    this.viewDialogShowsViewButtons = true,
    this.viewDialogShowsEditButton,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    this.parentDAO,
  }) :  this._undoRecord = undoRecord ?? [],
        this._redoRecord = redoRecord ?? [],
        this.classUiNamePluralGetter = classUiNamePluralGetter ?? classUiNameGetter
        {
          this.props.forEach((key, value) {
            value.dao = this;
            value.addListener(() {
              notifyListeners();
            });
          });
          this.addListener(() {
            _selfUpdateListeners.forEach((element) {
              element(this);
            });
          });
        }

  /// @mustOverride
  DAO<ModelType> copyWith({
    DAOValueGetter<String, ModelType>? classUiNameGetter,
    DAOValueGetter<String, ModelType>? classUiNamePluralGetter,
    DAOValueGetter<String, ModelType>? uiNameGetter,
    dynamic id,
    List<FieldGroup>? fieldGroups,
    OnSaveCallback<ModelType>? onSave,
    OnSaveAPICallback<ModelType>? onSaveAPI,
    OnDidSaveCallback<ModelType>? onDidSave,
    OnDeleteCallback<ModelType>? onDelete,
    OnDeleteAPICallback<ModelType>? onDeleteAPI,
    OnDidDeleteCallback<ModelType>? onDidDelete,
    DAOWidgetBuilder<ModelType>? viewWidgetBuilder,
    bool? useIntrinsicHeightForViewDialog,
    double? viewDialogWidth,
    double? formDialogWidth,
    bool? viewDialogLinksToInnerDAOs,
    bool? viewDialogShowsViewButtons,
    bool? viewDialogShowsEditButton,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    DAO? parentDAO,
  }) {
    final result = DAO<ModelType>(
      id: id??this.id,
      classUiNameGetter: classUiNameGetter??this.classUiNameGetter,
      fieldGroups: fieldGroups??this.fieldGroups.map((e) => e.copyWith()).toList(),
      classUiNamePluralGetter: classUiNamePluralGetter??this.classUiNamePluralGetter,
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      onSave: onSave??this.onSave,
      onSaveAPI: onSaveAPI??this.onSaveAPI,
      onDidSave: onDidSave??this.onDidSave,
      onDelete: onDelete??this.onDelete,
      onDeleteAPI: onDeleteAPI??this.onDeleteAPI,
      onDidDelete: onDidDelete??this.onDidDelete,
      viewWidgetBuilder: viewWidgetBuilder??this.viewWidgetBuilder,
      useIntrinsicHeightForViewDialog: useIntrinsicHeightForViewDialog??this.useIntrinsicHeightForViewDialog,
      viewDialogWidth: viewDialogWidth??this.viewDialogWidth,
      formDialogWidth: formDialogWidth??this.formDialogWidth,
      viewDialogLinksToInnerDAOs: viewDialogLinksToInnerDAOs??this.viewDialogLinksToInnerDAOs,
      viewDialogShowsViewButtons: viewDialogShowsViewButtons??this.viewDialogShowsViewButtons,
      viewDialogShowsEditButton: viewDialogShowsEditButton??this.viewDialogShowsEditButton,
      undoRecord: undoRecord??this._undoRecord,
      redoRecord: redoRecord??this._redoRecord,
      parentDAO: parentDAO??this.parentDAO,
    );
    result._selfUpdateListeners = _selfUpdateListeners;
    return result;
  }

  bool get isNew => id==null;
  bool get isEdited => props.values.any((element) => element.isEdited);
  List<ValidationError> get validationErrors => props.values.map((e) => e.validationErrors).flatten().toList();
  bool get canSave => onSave!=null || onSaveAPI!=null;
  bool get canDelete => onDelete!=null || onDeleteAPI!=null;

  @override
  int compareTo(other) => (other is DAO) ? uiName.compareTo(other.uiName) : -1;

  @override
  String toString() => uiName;

  @override
  bool operator == (dynamic other) => (other is DAO)
      && (id==null
          ? hashCode==other.hashCode
          : (this.classUiName==other.classUiName && this.id==other.id));

  @override
  int get hashCode => id==null ? super.hashCode : (classUiName+id.toString()).hashCode;


  bool blockNotifyListeners = false;
  BuildContext? _contextForValidation;
  BuildContext? get contextForValidation => parentDAO?.contextForValidation ?? this._contextForValidation;
  @override
  void notifyListeners() {
    if (blockNotifyListeners) {
      return;
    }
    super.notifyListeners();
  }


  void addOnUpdate(ValueChanged<DAO> o) {
    if (!_selfUpdateListeners.contains(o)) {
      _selfUpdateListeners.add(o);
    }
  }
  bool removeOnUpdate(ValueChanged<DAO> o) {
    return _selfUpdateListeners.remove(o);
  }

  void revertChanges() {
    props.forEach((key, value) {
      value.revertChanges();
    });
    notifyListeners();
  }


  List<List<Field>> _undoRecord;
  List<List<Field>> _redoRecord;
  List<Field>? _undoTransaction;
  List<Field>? _redoTransaction;

  void beginUndoTransaction() {
    _undoTransaction = [];
  }
  void beginRedoTransaction() {
    _redoTransaction = [];
  }

  void commitUndoTransaction({
    bool clearRedo = true,
  }) {
    assert(_undoTransaction!=null, 'beginUndoTransaction was not called');
    if (_undoTransaction!.isNotEmpty) {
      _undoRecord.add(_undoTransaction!);
      if (clearRedo) {
        _redoRecord.clear();
      }
    }
    _undoTransaction = null;
  }
  void commitRedoTransaction() {
    assert(_redoTransaction!=null, 'beginRedoTransaction was not called');
    if (_redoTransaction!.isNotEmpty) {
      _redoRecord.add(_redoTransaction!);
    }
    _redoTransaction = null;
  }

  addUndoEntry(Field field, {
    bool clearRedo = true,
  }) {
    if (parentDAO!=null) {
      parentDAO!.addUndoEntry(field, clearRedo: clearRedo);
    } else {
      if (_undoTransaction != null) {
        _undoTransaction!.add(field);
      } else {
        _undoRecord.add([field]);
        if (clearRedo) {
          _redoRecord.clear();
        }
      }
    }
  }
  addRedoEntry(Field field) {
    if (parentDAO!=null) {
      parentDAO!.addRedoEntry(field);
    } else {
      if (_redoTransaction!=null) {
        _redoTransaction!.add(field);
      } else {
        _redoRecord.add([field]);
      }
    }
  }

  removeLastUndoEntry(Field field) {
    int index = -1;
    for (int i=_undoRecord.lastIndex; i>=0 && index==-1; i--) {
      index = _undoRecord[i].lastIndexOf(field);
      if (index!=-1) {
        _undoRecord[i].removeAt(index);
      }
      if (_undoRecord[i].isEmpty) {
        _undoRecord.removeAt(i);
      }
    }
  }
  removeLastRedoEntry(Field field) {
    int index = -1;
    for (int i=_redoRecord.lastIndex; i>=0 && index==-1; i--) {
      index = _redoRecord[i].lastIndexOf(field);
      if (index!=-1) {
        _redoRecord[i].removeAt(index);
      }
      if (_redoRecord[i].isEmpty) {
        _redoRecord.removeAt(i);
      }
    }
  }

  removeAllUndoEntries(Field field) {
    for (int i=_undoRecord.lastIndex; i>=0; i--) {
      _undoRecord[i].removeWhere((e) => e==field);
      if (_undoRecord[i].isEmpty) {
        _undoRecord.removeAt(i);
      }
    }
  }
  removeAllRedoEntries(Field field) {
    for (int i=_redoRecord.lastIndex; i>=0; i--) {
      _redoRecord[i].removeWhere((e) => e==field);
      if (_redoRecord[i].isEmpty) {
        _redoRecord.removeAt(i);
      }
    }
  }

  void undo() {
    assert(_undoRecord.isNotEmpty);
    blockNotifyListeners = true;
    beginRedoTransaction();
    for (int i=0; i<_undoRecord.last.length; i++) {
      _undoRecord.last[i].undo(
        removeEntryFromDAO: false,
        requestFocus: i==0,
      );
    }
    _undoRecord.removeLast();
    commitRedoTransaction();
    blockNotifyListeners = false;
    validate(contextForValidation, validateNonEditedFields: false,);
    notifyListeners();
  }
  void redo() {
    assert(_redoRecord.isNotEmpty);
    blockNotifyListeners = true;
    beginUndoTransaction();
    for (int i=0; i<_redoRecord.last.length; i++) {
      _redoRecord.last[i].redo(
        removeEntryFromDAO: false,
        requestFocus: i==0,
      );
    }
    _redoRecord.removeLast();
    commitUndoTransaction(clearRedo: false,);
    blockNotifyListeners = false;
    validate(contextForValidation, validateNonEditedFields: false,);
    notifyListeners();
  }


  Future<bool> validate(context, {
    bool validateNonEditedFields = true,
    bool focusBlockingField = false,
  }) async {
    if (blockNotifyListeners) {
      return false;
    }
    if (parentDAO!=null) {
      return parentDAO!.validate(parentDAO!.contextForValidation,
        validateNonEditedFields: validateNonEditedFields,
        focusBlockingField: focusBlockingField,
      );
    }
    bool success = true;
    List<Future<bool>> results = [];
    for (final e in props.values) {
      results.add(e.validate(contextForValidation!, this, validateIfNotEdited: validateNonEditedFields)..then((v) => notifyListeners()));
    }
    for (final e in results) {
      success = await e;
      if (!success) {
        break;
      }
    }
    if (focusBlockingField && !success) {
      final validationErrors = this.validationErrors;
      validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
      ValidationError error = validationErrors.first;
      error.field.requestFocus();
      try {
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          error.animationController?.forward(from: 0);
        });
      } catch(_) {}
    }
    notifyListeners();
    return success;
  }


  Future<ModelType?> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
  }) async {
    bool validation = await validate(context,
      validateNonEditedFields: true,
      focusBlockingField: true,
    );
    if (!validation) {
      return null;
    }
    bool? confirm = true;
    if (askForSaveConfirmation) {
      confirm = await showModal(
        context: context,
        builder: (context) {
          return SizedBox(
            width: formDialogWidth-32,
            child: AlertDialog(
              title: Text(FromZeroLocalizations.of(context).translate("confirm_save_title")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FromZeroLocalizations.of(context).translate("confirm_save_desc")),
                  SaveConfirmationValidationMessage(allErrors: validationErrors),
                ],
              ),
              actions: [
                FlatButton(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
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
                    child: Text(FromZeroLocalizations.of(context).translate("save_caps"),
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
            ),
          );
        },
      );
    }
    if (confirm??false) {
      return save(context,
        skipValidation: true,
        updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
        showDefaultSnackBar: showDefaultSnackBars,
      );
    } else {
      return null;
    }
  }

  Future<ModelType?> save(context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBar=true,
    bool skipValidation=false,
  }) async {
    if (!skipValidation) {
      bool validation = await validate(context,
        validateNonEditedFields: true,
        focusBlockingField: true,
      );
      if (!validation) {
        return null;
      }
    }
    bool newInstance = id==null || id==-1;
    bool success = false;
    ModelType? model;
    if (onSaveAPI!=null) {
      final stateNotifier = onSaveAPI!.call(contextForValidation??context, this);
      final Completer completer = Completer();
      final removeListener = stateNotifier.addListener((state) {
        state.mapOrNull(
          data: (data) {
            completer.complete(data.value);
            return model = data.value;
          },
          loading: (loading) => model = null,
          error: (error) => model = null,
        );
      });
      final controller = APISnackBar(
        context: context,
        stateNotifier: stateNotifier,
        successTitle: '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
            : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.',
      ).show();
      await Future.any([controller.closed, completer.future]);
      success = model!=null;
      removeListener();
    } else if (onSave==null) {
      success = true;
    } else {
      try {
        model = await onSave!.call(contextForValidation??context, this);
        success = model!=null;
      } catch (e, st) {
        success = false;
        print(e); print(st);
      }
    }
    if (success) {
      onDidSave?.call(contextForValidation??context, model, this);
    }
    if (updateDbValuesAfterSuccessfulSave && success) {
      props.forEach((key, value) {
        value.dbValue = value.value;
      });
    }
    if (onSaveAPI==null && showDefaultSnackBar) {
      SnackBarFromZero(
        context: context,
        type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
        title: Text(success
            ? '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
            : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
            : FromZeroLocalizations.of(context).translate("connection_error_long")),
      ).show(context);
    }
    return model;
  }


  Future<bool> maybeDelete(BuildContext context, {
    bool? showDefaultSnackBars,
  }) async {
    bool confirm = true;
    bool askForDeleteConfirmation = true;
    if (askForDeleteConfirmation) {
      confirm = await showModal(
        context: context,
        builder: (context) {
          return SizedBox(
            width: formDialogWidth-32,
            child: AlertDialog(
              title: Text(FromZeroLocalizations.of(context).translate('confirm_delete_title')),
              content: Text('${FromZeroLocalizations.of(context).translate('confirm_delete_desc')} $uiName?'),
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
            ),
          );
        },
      ) ?? false;
    }
    if (confirm) {
      return delete(context,
        showDefaultSnackBar: showDefaultSnackBars,
      );
    } else {
      return false;
    }
  }

  Future<bool> delete(context, {
    bool? showDefaultSnackBar,
  }) async {
    bool success = false;
    String? errorString;
    showDefaultSnackBar = showDefaultSnackBar ?? canDelete;
    if (onDeleteAPI!=null) {
      final stateNotifier = onDeleteAPI!.call(contextForValidation??context, this);
      final Completer completer = Completer();
      final removeListener = stateNotifier.addListener((state) {
        state.mapOrNull(
          data: (data) {
            completer.complete(true);
            return success = true;
          },
          loading: (loading) => success = false,
          error: (error) => success = false,
        );
      });
      final controller = APISnackBar(
        context: context,
        stateNotifier: stateNotifier,
        successTitle: '$classUiName ${FromZeroLocalizations.of(context).translate("deleted")} ${FromZeroLocalizations.of(context).translate("successfully")}.',
      ).show();
      await Future.any([controller.closed, completer.future]);
      removeListener();
    } else {
      try {
        errorString = await onDelete?.call(contextForValidation??context, this);
        success = errorString==null;
      } catch (e, st) {
        success = false;
        print(e); print(st);
      }
      if (showDefaultSnackBar) {
        SnackBarFromZero(
          context: context,
          type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
          title: Text(success
              ? '$classUiName ${FromZeroLocalizations.of(context).translate("deleted")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
              : (errorString ?? FromZeroLocalizations.of(context).translate("connection_error_long"))),
        ).show(context);
      }
    }
    if (success) {
      onDidDelete?.call(contextForValidation??context, this);
    }
    return success;
  }

  applyDefaultValues(List<InvalidatingError> invalidatingErrors) {
    beginUndoTransaction();
    for (final e in invalidatingErrors) {
      e.field.value = e.defaultValue;
    }
    commitUndoTransaction();
    if (_undoRecord.length>2) {
      final previousRecord = _undoRecord[_undoRecord.length-2];
      previousRecord.addAll(_undoRecord.removeLast());
    }
  }

  void maybeRevertChanges(BuildContext context) async {
    bool? revert = await showModal(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(FromZeroLocalizations.of(context).translate("confirm_reverse_title")),
          content: Text(FromZeroLocalizations.of(context).translate("confirm_reverse_desc")),
          actions: [
            FlatButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
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
                child: Text(FromZeroLocalizations.of(context).translate("reverse_caps"),
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
    );
    if (revert??false) {
      revertChanges();
    }
  }

  Future<ModelType?> maybeEdit(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool askForSaveConfirmation = true,
    bool showUndoRedo = true,
  }) async {
    final props = this.props;
    props.values.forEach((e) {
      e.passedFirstEdit = false;
      e.validationErrors = [];
    });
    _contextForValidation = context;
    validate(context,
      validateNonEditedFields: false,
      focusBlockingField: false,
    );
    final focusNode = FocusNode();
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        double widescreenDialogWidth = formDialogWidth*2+32+24+16+32+16+38;
        bool widescreen = constraints.maxWidth>=widescreenDialogWidth;
        Widget result = AnimatedBuilder(
          animation: this,
          builder: (context, child) {
            bool expandToFillContainer = false;
            if (props.values.where((e) => !e.hiddenInForm && (e is ListField)).isNotEmpty) {
              expandToFillContainer = true;
            } else if (widescreen && fieldGroups.where((e) => !e.primary && e.props.values.where((e) => !e.hiddenInForm).isNotEmpty).isNotEmpty) {
              expandToFillContainer = true;
            }
            ScrollController primaryScrollController = ScrollController();
            ScrollController tabBarScrollController = ScrollController();
            Map<String, ScrollController> secondaryScrollControllers = {};
            List<Widget> primaryFormWidgets = [];
            Map<String, Widget> secondaryFormWidgets = {};
            int i = 1;
            for (final e in fieldGroups) {
              if (e.props.values.where((e) => !e.hiddenInForm).isNotEmpty) {
                bool asPrimary = !widescreen || e.primary;
                final name = e.name ?? 'Grupo $i'; // TODO 3 internationalize
                final scrollController = asPrimary ? primaryScrollController : ScrollController();
                Widget groupWidget = buildGroupWidget(
                  context: context,
                  group: e,
                  mainScrollController: scrollController,
                  showCancelActionToPop: true,
                  expandToFillContainer: expandToFillContainer,
                  asSlivers: false,
                  focusNode: focusNode,
                  showDefaultSnackBars: showDefaultSnackBars,
                  showRevertChanges: showRevertChanges,
                  askForSaveConfirmation: askForSaveConfirmation,
                  showActionButtons: false,
                );
                if (asPrimary) {
                  primaryFormWidgets.add(groupWidget);
                } else {
                  secondaryScrollControllers[name] = scrollController;
                  secondaryFormWidgets[name] = FocusTraversalOrder(
                    order: NumericFocusOrder(i.toDouble()),
                    child: groupWidget,
                  );
                  i++;
                }
              }
            }
            List<Widget> formActions = buildActionButtons(context,
              showCancelActionToPop: true,
              showDefaultSnackBars: showDefaultSnackBars,
              showRevertChanges: showRevertChanges,
              askForSaveConfirmation: askForSaveConfirmation,
            );
            final pageController = PreloadPageController();
            Widget result = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
                  child: Row(
                    key: ValueKey(widescreen),
                    children: [
                      Expanded(
                        child: OverflowScroll(
                          child: Text('${id==null ? FromZeroLocalizations.of(context).translate("add")
                              : FromZeroLocalizations.of(context).translate("edit")} $classUiName',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                      ),
                      if (showUndoRedo)
                        IconButton(
                          tooltip: FromZeroLocalizations.of(context).translate("undo"),
                          icon: Icon(MaterialCommunityIcons.undo_variant,),
                          onPressed: _undoRecord.isEmpty ? null : () {
                            undo(); // TODO 3 add shortcut support (ctrl+z, ctrl+shift+z)
                          },
                        ),
                      if (showUndoRedo)
                        IconButton(
                          tooltip: FromZeroLocalizations.of(context).translate("redo"),
                          icon: Icon(MaterialCommunityIcons.redo_variant,),
                          onPressed: _redoRecord.isEmpty ? null : () {
                            redo();
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: FocusScope(
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: DefaultTabController(
                        length: secondaryFormWidgets.keys.length,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: secondaryFormWidgets.keys.isNotEmpty ? Alignment.centerLeft : null,
                                width: secondaryFormWidgets.keys.isNotEmpty ? formDialogWidth : null,
                                padding: EdgeInsets.only(left: secondaryFormWidgets.keys.isNotEmpty ? 12 : 0),
                                child: ScrollbarFromZero(
                                  controller: primaryScrollController,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12,),
                                    child: SingleChildScrollView(
                                      controller: primaryScrollController,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: FocusTraversalOrder(
                                          order: NumericFocusOrder(1),
                                          child: FocusTraversalGroup(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: primaryFormWidgets,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (secondaryFormWidgets.keys.isNotEmpty)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(right: 24),
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    width: formDialogWidth+12+16,
                                    child: Column(
                                      children: [
                                        if (secondaryFormWidgets.length>1 || secondaryFormWidgets.keys.first!='Grupo 1') // TODO 3 internationalize
                                          ExcludeFocus(
                                            child: ScrollbarFromZero(
                                              controller: tabBarScrollController,
                                              opacityGradientDirection: OpacityGradient.horizontal,
                                              child: Padding(
                                                padding: EdgeInsets.only(right: 12, bottom: PlatformExtended.isDesktop ? 8 : 0,),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  controller: tabBarScrollController,
                                                  child: IntrinsicWidth(
                                                    child: Card(
                                                      clipBehavior: Clip.hardEdge,
                                                      child: TabBar( // TODO 3 replace this with an actual widget: PageIndicatorFromzero. Allow to have an indicator + building children dinamically according to selected
                                                        isScrollable: true,
                                                        indicatorWeight: 3,
                                                        tabs: secondaryFormWidgets.keys.map((e) {
                                                          return Container(
                                                            height: 32,
                                                            alignment: Alignment.center,
                                                            child: Text(e, style: Theme.of(context).textTheme.subtitle1,),
                                                          );
                                                        }).toList(),
                                                        onTap: (value) {
                                                          pageController.animateToPage(value,
                                                            duration: kTabScrollDuration,
                                                            curve: Curves.ease,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          height: 0,
                                          child: TabBarView(
                                            children: List.filled(secondaryFormWidgets.keys.length, Container()),
                                          ),
                                        ),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              return PreloadPageView(
                                                controller: pageController,
                                                preloadPagesCount: 999,
                                                onPageChanged: (value) {
                                                  DefaultTabController.of(context)?.animateTo(value);
                                                },
                                                children: secondaryFormWidgets.keys.map((e) {
                                                  return ScrollbarFromZero(
                                                    controller: secondaryScrollControllers[e],
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(right: 12),
                                                      child: FocusTraversalGroup(
                                                        child: SingleChildScrollView(
                                                          controller: secondaryScrollControllers[e],
                                                          child: Padding(
                                                            padding: EdgeInsets.only(
                                                              top: secondaryFormWidgets.length==1 && secondaryFormWidgets.keys.first=='Grupo 1'
                                                                  ? 12 : 0,
                                                              bottom: 28,
                                                            ),
                                                            child: secondaryFormWidgets[e]!,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 12, left: 12, top: 8,),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: formActions,
                  ),
                ),
              ],
            );
            if (!expandToFillContainer) {
              result = IntrinsicHeight(
                child: result,
              );
            }
            Map<InvalidatingError, Field> invalidatingErrors = {};
            List<InvalidatingError> autoResolveInvalidatingErrors = [];
            bool allowSetInvalidatingFieldsToDefaultValues = true;
            bool allowUndoInvalidatingChanges = _undoRecord.isNotEmpty;
            for (Field e in props.values) {
              final errors = e.validationErrors.where((error) => error.severity==ValidationErrorSeverity.invalidating);
              errors.forEach((err) {
                final error = err as InvalidatingError;
                allowSetInvalidatingFieldsToDefaultValues = allowSetInvalidatingFieldsToDefaultValues && error.allowSetThisFieldToDefaultValue;
                allowUndoInvalidatingChanges = allowUndoInvalidatingChanges && error.allowUndoInvalidatingChange;
                if (error.showVisualConfirmation) {
                  invalidatingErrors[error] = error.field;
                } else {
                  autoResolveInvalidatingErrors.add(error);
                }
              });
            }
            if (autoResolveInvalidatingErrors.isNotEmpty) {
              WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                applyDefaultValues(autoResolveInvalidatingErrors);
              });
            }
            if (!allowSetInvalidatingFieldsToDefaultValues && !allowUndoInvalidatingChanges) {
              if (_undoRecord.isEmpty) {
                allowSetInvalidatingFieldsToDefaultValues = true;
              } else {
                allowUndoInvalidatingChanges = true;
              }
            }
            ScrollController invalidatingDialogScrollController = ScrollController();
            result = Stack(
              children: [
                Center(
                  child: AnimatedContainerFromChildSize(
                    clipBehavior: Clip.hardEdge,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: secondaryFormWidgets.keys.length==0
                          ? formDialogWidth+32+24+16
                          : widescreenDialogWidth,
                      child: Dialog(
                        backgroundColor: Theme.of(context).canvasColor,
                        clipBehavior: Clip.hardEdge,
                        insetPadding: EdgeInsets.all(16),
                        child: result,
                      ),
                    ),
                  ),
                ),
                PageTransitionSwitcher(
                  duration: Duration(milliseconds: 300),
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: invalidatingErrors.isEmpty ? SizedBox() : Container(
                    color: Colors.black38,
                    child: Center(
                      child: SizedBox(
                        width: formDialogWidth-32,
                        child: Dialog(
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
                                  child: OverflowScroll(
                                    child: Text(FromZeroLocalizations.of(context).translate("confirm_invalidating_change_title"),
                                      style: Theme.of(context).textTheme.headline6,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ScrollbarFromZero(
                                    controller: invalidatingDialogScrollController,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12,),
                                      child: SingleChildScrollView(
                                        controller: invalidatingDialogScrollController,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(FromZeroLocalizations.of(context).translate("confirm_invalidating_change_description1")),
                                            if (_undoRecord.isEmpty)
                                              Text(FromZeroLocalizations.of(context).translate("confirm_invalidating_no_undo_record")),
                                            if (_undoRecord.isNotEmpty)
                                              ..._undoRecord.last.map((e) => FieldDiffMessage(
                                                field: e,
                                                oldValue: e.undoValues.last,
                                                newValue: e.value,
                                              ),),
                                            SizedBox(height: 24,),
                                            Text(FromZeroLocalizations.of(context).translate(!allowSetInvalidatingFieldsToDefaultValues ? "confirm_invalidating_change_description2_1" : "confirm_invalidating_change_description2_2")),
                                            SizedBox(height: 6,),
                                            ValidationMessage(
                                              errors: invalidatingErrors.keys.toList(),
                                              errorTextStyle: Theme.of(context).textTheme.bodyText1,
                                              animate: false,
                                            ),
                                            if (allowSetInvalidatingFieldsToDefaultValues)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 24),
                                                child: Text(FromZeroLocalizations.of(context).translate(!allowUndoInvalidatingChanges ? "confirm_invalidating_change_description3_1" : "confirm_invalidating_change_description3_2")),
                                              ),
                                            if (allowSetInvalidatingFieldsToDefaultValues)
                                              ...invalidatingErrors.map((key, value) {
                                                return MapEntry(key, FieldDiffMessage(
                                                  field: value,
                                                  oldValue: value.value,
                                                  newValue: key.defaultValue,
                                                ));
                                              }).values.toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.only(bottom: 12, right: 12, left: 12, top: 8,),
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (allowUndoInvalidatingChanges)
                                        FlatButton(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          textColor: Theme.of(context).textTheme.caption!.color,
                                          onPressed: () {
                                            beginRedoTransaction();
                                            undo();
                                            beginRedoTransaction(); commitRedoTransaction(); // discard redo
                                          },
                                        ),
                                      if (allowSetInvalidatingFieldsToDefaultValues)
                                        FlatButton(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(FromZeroLocalizations.of(context).translate("accept_caps"),
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          onPressed: () {
                                            applyDefaultValues(invalidatingErrors.keys.toList());
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            return result;
          },
        );
        result = Actions(
          actions: {
            UndoIntent: CallbackAction(
              onInvoke: (intent) {
                if (_undoRecord.isNotEmpty) {
                  undo();
                }
                return false;
              },
            ),
            RedoIntent: CallbackAction(
              onInvoke: (intent) {
                if (_redoRecord.isNotEmpty) {
                  redo();
                }
                return false;
              },
            ),
          },
          child: result,
        );
        return result;
      },
    );
    // Future.delayed(Duration(milliseconds: 200)).then((value) => focusNode.requestFocus());
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
    ModelType? confirm = await showModal(
      context: context,
      builder: (modalContext) {
        return content;
      },
    );
    _contextForValidation = null;
    return confirm;
  }


  Future<dynamic> pushViewDialog(BuildContext context, {
    bool? showEditButton,
  }) {
    ScrollController scrollController = ScrollController();
    Widget content = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        return IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(uiName,
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          if (uiName.isNotEmpty)
                            SelectableText(classUiName,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                        ],
                      ),
                    ),
                    if (showEditButton ?? viewDialogShowsEditButton ?? canSave)
                      TextButton(
                        onPressed: () {
                          maybeEdit(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8,),
                              Text('${FromZeroLocalizations.of(context).translate('edit')}', style: TextStyle(fontSize: 16),),
                              SizedBox(width: 8,),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollbarFromZero(
                  controller: scrollController,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: buildViewWidget(context),
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
                        child: Text(FromZeroLocalizations.of(context).translate("close_caps"),
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
        );
      },
    );
    if (useIntrinsicHeightForViewDialog) {
      content = IntrinsicHeight(child: content,);
    }
    return showModal(context: context,
      builder: (context) {
        return Center(
          child: Dialog(
            insetPadding: EdgeInsets.all(16),
            backgroundColor: Theme.of(context).cardColor,
            child: content,
          ),
        );
      },
    );
  }
  Widget buildViewWidget(BuildContext context) {
    if (viewWidgetBuilder!=null) {
      return viewWidgetBuilder!(context, this);
    }
    bool clear = false;
    bool first = true;
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fieldGroups.map((group) {
          final fields = group.props.values.where((e) => !e.hiddenInView);
          Widget result;
          if (fields.isEmpty) {
            result = SizedBox.shrink();
          } else {
            result = Column(
              children: fields.map((e) {
                clear = !clear;
                return Material(
                  color: clear ? Theme.of(context).cardColor
                      : Color.alphaBlend(Theme.of(context).cardColor.withOpacity(0.965), Colors.black),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 1000000,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            alignment: Alignment.centerRight,
                            child: SelectableText(e.uiName,
                              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                                color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          child: VerticalDivider(width: 0,),
                        ),
                        Expanded(
                          flex: 1618034,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: e.buildViewWidget(context,
                              linkToInnerDAOs: this.viewDialogLinksToInnerDAOs,
                              showViewButtons: this.viewDialogShowsViewButtons,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }
          if (!first || group.name!=null) {
            result = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!first)
                  Container(
                    height: 8,
                    color: Theme.of(context).dividerColor,
                  ),
                if (group.name!=null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                    child: Text(group.name!,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                result,
              ],
            );
          }
          first = false;
          return result;
        }).toList(),
      ),
    );
  }

  Widget buildGroupWidget({
    required BuildContext context,
    required FieldGroup group,
    ScrollController? mainScrollController,
    bool asSlivers=true,
    bool showActionButtons=true,
    bool showRevertChanges=false,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
    bool firstIteration=true,
    bool wrapInLayoutFromZeroItem=false,
    FocusNode? focusNode,
    int groupBorderNestingCount = 0,
  }) {
    if (group.props.values.where((e) => !e.hiddenInForm).isEmpty) {
      return SizedBox.shrink();
    }
    bool verticalLayout = firstIteration || group.primary;
    List<Widget> Function({bool useLayoutFromZero}) getChildren = ({bool useLayoutFromZero = false}) => [
      ...buildFormWidgets(context,
        group: group,
        showCancelActionToPop: true,
        mainScrollController: mainScrollController,
        expandToFillContainer: verticalLayout && expandToFillContainer,
        asSlivers: false,
        focusNode: firstIteration && group.primary ? focusNode : null,
        showDefaultSnackBars: showDefaultSnackBars,
        showRevertChanges: showRevertChanges,
        askForSaveConfirmation: askForSaveConfirmation,
        showActionButtons: false,
        wrapInLayoutFromZeroItem: useLayoutFromZero,
      ),
      ...group.childGroups.map((e) {
        return buildGroupWidget(
          context: context,
          group: e,
          showCancelActionToPop: true,
          mainScrollController: mainScrollController,
          expandToFillContainer: verticalLayout && expandToFillContainer,
          asSlivers: false,
          focusNode: focusNode,
          showDefaultSnackBars: showDefaultSnackBars,
          showRevertChanges: showRevertChanges,
          askForSaveConfirmation: askForSaveConfirmation,
          showActionButtons: false,
          popAfterSuccessfulSave: popAfterSuccessfulSave,
          firstIteration: false,
          wrapInLayoutFromZeroItem: useLayoutFromZero,
          groupBorderNestingCount: groupBorderNestingCount + (group.name!=null ? 1 : 0),
        );
      }),
    ];
    Widget result;
    if (verticalLayout) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: getChildren(),
      );
    } else {
      if (group.useLayoutFromZero) {
        result = FlexibleLayoutFromZero(
          children: getChildren(useLayoutFromZero: true).map((e) => e as FlexibleLayoutItemFromZero).toList(),
          relevantAxisMaxSize: min(formDialogWidth,
              MediaQuery.of(context).size.width - 56 - (groupBorderNestingCount*16)),
          crossAxisAlignment: CrossAxisAlignment.start,
        );
      } else {
        ScrollController scrollController = ScrollController();
        result = ScrollbarFromZero(
          controller: scrollController,
          opacityGradientDirection: OpacityGradient.horizontal,
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: getChildren(),
            ),
          ),
        );
      }
    }
    if (!wrapInLayoutFromZeroItem) {
      result = SizedBox(
        width: formDialogWidth,
        child: result,
      );
    }
    if (group.name!=null) {
      result = Padding(
        padding: const EdgeInsets.only(bottom: 12,),
        child: Stack(
          children: [
            Positioned(
              bottom: 12, top: 20,
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
            Positioned(
              top: 0, left: 18,
              child: Text(group.name!),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 14, left: 8, right: 8,),
              child: result,
            ),
          ],
        ),
      );
    } else if (group.primary && firstIteration) {
      result = Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12,),
        child: result,
      );
    }
    if (wrapInLayoutFromZeroItem) {
      result = FlexibleLayoutItemFromZero(
        maxSize: group.maxWidth + (group.name!=null ? 16 : 0),
        minSize: group.minWidth + (group.name!=null ? 16 : 0),
        child: result,
      );
    }
    return result;
  }

  List<Widget> buildFormWidgets(BuildContext context, {
    FieldGroup? group,
    ScrollController? mainScrollController,
    bool asSlivers=true,
    bool showActionButtons=true,
    bool showRevertChanges=false,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
    bool wrapInLayoutFromZeroItem=false,
    FocusNode? focusNode,
  }) {
    assert(!asSlivers || !wrapInLayoutFromZeroItem, 'FlexibleLayoutFromZero does not support slivers.');
    final props = group?.fields ?? this.props;
    bool first = true;
    List<Widget> result = [
      ...props.values.map((e) {
        List<Widget> result = e.buildFieldEditorWidgets(context,
          addCard: true,
          asSliver: asSlivers,
          expandToFillContainer: e is ListField && !asSlivers // it will never make sense to build a ListView inside a FormGroup
              ? false : expandToFillContainer,
          focusNode: first ? focusNode : null,
          mainScrollController: mainScrollController,
        );
        first = false;
        result = result.mapIndexed((i, w) {
          if (asSlivers) {
            return e.hiddenInForm
                ? SliverToBoxAdapter(child: SizedBox.shrink(),)
                : SliverPadding(
                  padding: EdgeInsets.only(
                    top: i==0 ? 6 : 0,
                    bottom: i==result.lastIndex ? 6 : 0,
                  ),
                  sliver: w,
                );
          } else {
            return FlexibleLayoutItemFromZero(
              maxSize: e.maxWidth,
              minSize: e.minWidth,
              flex: e.flex,
              child: AnimatedSwitcher(
                duration: 300.milliseconds,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: e.hiddenInForm
                    ? SizedBox.shrink()
                    : Padding(
                      padding: EdgeInsets.only(
                        top: i==0 ? 6 : 0,
                        bottom: i==result.lastIndex ? 6 : 0,
                      ),
                      child: w,
                    ),
                transitionBuilder: (child, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    axisAlignment: -1,
                    child: Center(child: child),
                  );
                },
              ),
            );
          }
        }).toList();
        return result;
      }).flatten().toList(),
      if (showActionButtons)
        ...buildActionButtons(context,
          showRevertChanges: showRevertChanges,
          popAfterSuccessfulSave: popAfterSuccessfulSave,
          showCancelActionToPop: showCancelActionToPop,
          showDefaultSnackBars: showDefaultSnackBars,
          askForSaveConfirmation: askForSaveConfirmation,
        ),
    ];
    if (asSlivers) {
      result = result.map((e) => (e is SliverPadding) ? e : SliverToBoxAdapter(child: e)).toList();
    }
    return result;
  }

  List<Widget> buildActionButtons(BuildContext context, {
    bool showRevertChanges=false,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
  }) {
    return [
      SizedBox(height: 6,),
      Center(
        child: WillPopScope(
          onWillPop: () async {
            if (!isEdited) return true;
            bool? pop = (await showModal(
              context: context,
              builder: (modalContext) {
                return AlertDialog(
                  title: Text(FromZeroLocalizations.of(context).translate("confirm_close_title")),
                  content: Text(FromZeroLocalizations.of(context).translate("confirm_close_desc")),
                  actions: [
                    FlatButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: Theme.of(context).textTheme.caption!.color,
                      onPressed: () {
                        Navigator.of(modalContext).pop(false); // Dismiss alert dialog
                      },
                    ),
                    FlatButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(FromZeroLocalizations.of(context).translate("close_caps"),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      textColor: Colors.red,
                      onPressed: () {
                        Navigator.of(modalContext).pop(true); // Dismiss alert dialog
                      },
                    ),
                    SizedBox(width: 2,),
                  ],
                );
              },
            )) ?? false;
            if (pop) {
              revertChanges();
            }
            return pop;
          },
          child: ResponsiveHorizontalInsets(
            child: SizedBox(
              width: 512,
              child: Row(
                children: [
                  if (showCancelActionToPop)
                    Expanded(
                      child: FlatButton(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        textColor: Theme.of(context).textTheme.caption!.color,
                        onPressed: () {
                          Navigator.of(context).maybePop(null);
                        },
                      ),
                    ),
                  if (showCancelActionToPop)
                    SizedBox(width: 12,),
                  if (showRevertChanges)
                    Expanded(
                      child: ElevatedButton(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(FromZeroLocalizations.of(context).translate("reverse_changes_caps"),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey,
                        ),
                        onPressed: isEdited ? () {
                          maybeRevertChanges(context);
                        } : null,
                      ),
                    ),
                  if (showRevertChanges)
                    SizedBox(width: 12,),
                  Expanded(
                    child: ElevatedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(FromZeroLocalizations.of(context).translate("save_caps"),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
                        ),
                      ),
                      onPressed: isEdited ? () async {
                        ModelType? result = await maybeSave(context,
                          showDefaultSnackBars: showDefaultSnackBars,
                          askForSaveConfirmation: askForSaveConfirmation,
                        );
                        if (result != null) {
                          if (popAfterSuccessfulSave) {
                            Navigator.of(context).pop(result);
                          }
                        }
                      } : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 24,),
    ];
  }
  
}






