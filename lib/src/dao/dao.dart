import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/api_snackbar.dart';
import 'package:from_zero_ui/util/comparable_list.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_ensure_visible_when_focused.dart';
import 'package:mlog/mlog.dart';
import 'package:preload_page_view/preload_page_view.dart';

part 'field.dart';
part 'lazy_dao.dart';


typedef OnSaveCallback<ModelType> = FutureOr<ModelType?> Function(BuildContext context, DAO<ModelType> e);
typedef OnSaveAPICallback<ModelType> = ApiState<ModelType?> Function(BuildContext context, DAO<ModelType> e);
typedef OnDidSaveCallback<ModelType> = void Function(BuildContext context, ModelType? model, DAO<ModelType> dao);
typedef OnDeleteCallback<ModelType> = FutureOr<String?> Function(BuildContext context, DAO<ModelType> e);
typedef OnDeleteAPICallback<ModelType> = ApiState Function(BuildContext context, DAO<ModelType> e);
typedef OnDidDeleteCallback<ModelType> = void Function(BuildContext context, DAO<ModelType> dao);
typedef DAOWidgetBuilder<ModelType> = Widget Function(BuildContext context, DAO<ModelType> dao);
typedef DAOValueGetter<T, ModelType> = T Function(DAO<ModelType> dao);

enum DoubleColumnLayoutType {
  tabbed,
  joined,
  none,
}

class DAO<ModelType> extends ChangeNotifier implements Comparable {

  static bool ignoreBlockingErrors = false; // VERY careful with this
  dynamic id; // TODO 3 id type should be declared as <>
  late DAOValueGetter<String, ModelType> classUiNameGetter;
  String get classUiName => classUiNameGetter(this);
  DAOValueGetter<String, ModelType>? classUiNamePluralGetter;
  String get classUiNamePlural => classUiNamePluralGetter?.call(this) ?? classUiName;
  late DAOValueGetter<String, ModelType> uiNameGetter;
  String get uiName => uiNameGetter(this);
  DAOValueGetter<String, ModelType>? uiNameDenseGetter; /// used in table, or whenever build is called with dense=true
  String get uiNameDense => uiNameDenseGetter?.call(this) ?? uiName;
  DAOValueGetter<String, ModelType>? searchNameGetter;
  String get searchName => searchNameGetter?.call(this) ?? uiName;
  /// props shouldn't be added or removed manually, only changes at construction and on load()
  late List<FieldGroup> fieldGroups;
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
  late List<ValueChanged<DAO<ModelType>>> _selfUpdateListeners = [];
  DAOWidgetBuilder<ModelType>? viewWidgetBuilder;
  List<Widget> Function(BuildContext context, DAO dao)? viewDialogExtraActions;
  List<Widget> Function(BuildContext context, DAO dao)? formDialogExtraActions;
  late double viewDialogWidth;
  late double formDialogWidth;
  late bool viewDialogLinksToInnerDAOs;
  late bool viewDialogShowsViewButtons;
  bool? viewDialogShowsEditButton;
  bool? viewDialogShowsDeleteButton;
  late bool wantsLinkToSelfFromOtherDAOs;
  late bool enableUndoRedoMechanism;
  late bool showConfirmDialogWithBlockingErrors;
  DAOValueGetter<DoubleColumnLayoutType, ModelType>? doubleColumnLayoutType;
  DAO? parentDAO; /// if not null, undo/redo calls will be relayed to the parent
  DAOValueGetter<String, ModelType>? editDialogTitle;
  DAOValueGetter<String, ModelType>? saveButtonTitle;
  DAOValueGetter<String, ModelType>? saveConfirmationDialogTitle;
  DAOValueGetter<Widget, ModelType>? saveConfirmationDialogDescription;
  FutureOr<String>? get defaultExportPath => null;


  DAO({
    required this.classUiNameGetter,
    required this.uiNameGetter,
    this.classUiNamePluralGetter,
    this.uiNameDenseGetter,
    this.id,
    this.fieldGroups = const [],
    this.onSave,
    this.onSaveAPI,
    this.onDidSave,
    this.onDelete,
    this.onDeleteAPI,
    this.onDidDelete,
    this.viewWidgetBuilder,
    this.viewDialogExtraActions,
    this.formDialogExtraActions,
    this.viewDialogWidth = 512,
    this.formDialogWidth = 512,
    this.viewDialogLinksToInnerDAOs = true,
    this.viewDialogShowsViewButtons = false,
    this.viewDialogShowsEditButton,
    this.viewDialogShowsDeleteButton,
    this.wantsLinkToSelfFromOtherDAOs = true,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    this.enableUndoRedoMechanism = true,
    this.showConfirmDialogWithBlockingErrors = true,
    this.parentDAO,
    this.doubleColumnLayoutType,
    this.searchNameGetter,
    this.editDialogTitle,
    this.saveConfirmationDialogTitle,
    this.saveButtonTitle,
    this.saveConfirmationDialogDescription,
  }) :  _undoRecord = undoRecord ?? [],
        _redoRecord = redoRecord ?? []
        {
          this.props.forEach((key, value) {
            value.dao = this;
            value.addListener(notifyListeners);
          });
          addListener(() {
            for (final element in _selfUpdateListeners) {
              element(this);
            }
          });
        }


  DAO._uninitialized();


  /// @mustOverride
  DAO<ModelType> copyWith({
    DAOValueGetter<String, ModelType>? classUiNameGetter,
    DAOValueGetter<String, ModelType>? classUiNamePluralGetter,
    DAOValueGetter<String, ModelType>? uiNameGetter,
    DAOValueGetter<String, ModelType>? uiNameDenseGetter,
    dynamic id,
    List<FieldGroup>? fieldGroups,
    OnSaveCallback<ModelType>? onSave,
    OnSaveAPICallback<ModelType>? onSaveAPI,
    OnDidSaveCallback<ModelType>? onDidSave,
    OnDeleteCallback<ModelType>? onDelete,
    OnDeleteAPICallback<ModelType>? onDeleteAPI,
    OnDidDeleteCallback<ModelType>? onDidDelete,
    DAOWidgetBuilder<ModelType>? viewWidgetBuilder,
    List<Widget> Function(BuildContext context, DAO dao)? viewDialogExtraActions,
    List<Widget> Function(BuildContext context, DAO dao)? formDialogExtraActions,
    bool? wantsLinkToSelfFromOtherDAOs,
    double? viewDialogWidth,
    double? formDialogWidth,
    bool? viewDialogLinksToInnerDAOs,
    bool? viewDialogShowsViewButtons,
    bool? viewDialogShowsEditButton,
    bool? viewDialogShowsDeleteButton,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    bool? showConfirmDialogWithBlockingErrors,
    DAO? parentDAO,
    DAOValueGetter<DoubleColumnLayoutType, ModelType>? enableDoubleColumnLayout,
    DAOValueGetter<String, ModelType>? searchNameGetter,
    DAOValueGetter<String, ModelType>? editDialogTitle,
    DAOValueGetter<String, ModelType>? saveConfirmationDialogTitle,
    DAOValueGetter<String, ModelType>? saveButtonTitle,
    DAOValueGetter<Widget, ModelType>? saveConfirmationDialogDescription,
  }) {
    final result = DAO<ModelType>(
      id: id??this.id,
      classUiNameGetter: classUiNameGetter??this.classUiNameGetter,
      fieldGroups: fieldGroups??this.fieldGroups.map((e) => e.copyWith()).toList(),
      classUiNamePluralGetter: classUiNamePluralGetter??this.classUiNamePluralGetter,
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      uiNameDenseGetter: uiNameDenseGetter??this.uiNameDenseGetter,
      onSave: onSave??this.onSave,
      onSaveAPI: onSaveAPI??this.onSaveAPI,
      onDidSave: onDidSave??this.onDidSave,
      onDelete: onDelete??this.onDelete,
      onDeleteAPI: onDeleteAPI??this.onDeleteAPI,
      onDidDelete: onDidDelete??this.onDidDelete,
      viewWidgetBuilder: viewWidgetBuilder??this.viewWidgetBuilder,
      viewDialogExtraActions: viewDialogExtraActions??this.viewDialogExtraActions,
      formDialogExtraActions: formDialogExtraActions??this.formDialogExtraActions,
      viewDialogWidth: viewDialogWidth??this.viewDialogWidth,
      formDialogWidth: formDialogWidth??this.formDialogWidth,
      viewDialogLinksToInnerDAOs: viewDialogLinksToInnerDAOs??this.viewDialogLinksToInnerDAOs,
      viewDialogShowsViewButtons: viewDialogShowsViewButtons??this.viewDialogShowsViewButtons,
      viewDialogShowsEditButton: viewDialogShowsEditButton??this.viewDialogShowsEditButton,
      viewDialogShowsDeleteButton: viewDialogShowsDeleteButton??this.viewDialogShowsDeleteButton,
      wantsLinkToSelfFromOtherDAOs: wantsLinkToSelfFromOtherDAOs??this.wantsLinkToSelfFromOtherDAOs,
      undoRecord: undoRecord??this._undoRecord,
      redoRecord: redoRecord??this._redoRecord,
      showConfirmDialogWithBlockingErrors: showConfirmDialogWithBlockingErrors??this.showConfirmDialogWithBlockingErrors,
      parentDAO: parentDAO??this.parentDAO,
      doubleColumnLayoutType: enableDoubleColumnLayout??this.doubleColumnLayoutType,
      searchNameGetter: searchNameGetter ?? this.searchNameGetter,
      editDialogTitle: editDialogTitle ?? this.editDialogTitle,
      saveConfirmationDialogTitle: saveConfirmationDialogTitle ?? this.saveConfirmationDialogTitle,
      saveButtonTitle: saveButtonTitle ?? this.saveButtonTitle,
      saveConfirmationDialogDescription: saveConfirmationDialogDescription ?? this.saveConfirmationDialogDescription,
    );
    result._selfUpdateListeners = _selfUpdateListeners;
    return result;
  }

  bool get isNew => id==null;
  bool get isEdited => props.values.any((e) => e.isEdited);
  bool get userInteracted => props.values.any((e) => e.userInteracted);
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
          ? this.hashCode==other.hashCode
          : this.id==other.id);

  @override
  int get hashCode => id==null ? super.hashCode : id.hashCode;


  bool blockNotifyListeners = false;
  BuildContext? _contextForValidation;
  set contextForValidation(BuildContext? value) => _contextForValidation = value;
  BuildContext? get contextForValidation => this._contextForValidation ?? parentDAO?.contextForValidation;
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
    _undoRecord.clear();
    _redoRecord.clear();
    props.forEach((key, value) {
      value.revertChanges();
    });
    notifyListeners();
  }


  late List<List<Field>> _undoRecord;
  late List<List<Field>> _redoRecord;
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

  void addUndoEntry(Field field, {
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
  void addRedoEntry(Field field) {
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

  void removeLastUndoEntry(Field field) {
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
  void removeLastRedoEntry(Field field) {
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

  void removeAllUndoEntries(Field field) {
    for (int i=_undoRecord.lastIndex; i>=0; i--) {
      _undoRecord[i].removeWhere((e) => e==field);
      if (_undoRecord[i].isEmpty) {
        _undoRecord.removeAt(i);
      }
    }
  }
  void removeAllRedoEntries(Field field) {
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


  int _validationCallCount = 0;
  int get validationCallCount => parentDAO==null
      ? _validationCallCount : parentDAO!.validationCallCount;
  set validationCallCount(int value) {
    _validationCallCount = value;
  }
  Future<bool> validate(context, {
    bool validateNonEditedFields = true,
  }) async {
    final currentValidationId = ++validationCallCount;
    if (blockNotifyListeners) {
      return false;
    }
    if (parentDAO!=null) {
      return parentDAO!.validate(parentDAO!.contextForValidation,
        validateNonEditedFields: validateNonEditedFields,
      );
    }
    bool success = true;
    List<Future<bool>> results = [];
    for (final e in props.values) {
      if (validateNonEditedFields) { // await syncing text controllers when saving
        if (e is StringField) {
          e.valUpdateTimer?.cancel();
          if (e.controller.text != e.value) {
            final previousValue = e._value;
            e._value = e.controller.text;
            e.passedFirstEdit = true;
            e.addUndoEntry(e._value);
            e.onValueChanged?.call(e.dao, e, e._value, previousValue);
            e.notifyListeners();
          }
        } else if (e is NumField) {
          e.valUpdateTimer?.cancel();
          final numVal = e.getTextVal(e.controller.text);
          while (numVal != e.value) {
            final previousValue = e._value;
            e._value = numVal;
            e.passedFirstEdit = true;
            e.addUndoEntry(e._value);
            e.onValueChanged?.call(e.dao, e, e._value, previousValue);
            e.notifyListeners();
          }
        }
      }
      if (currentValidationId!=validationCallCount) return false;
      final future = e.validate(
        contextForValidation!,
        this,
        currentValidationId,
        validateIfNotEdited: validateNonEditedFields,
      ).then((v) {
        e.notifyListeners();
        return v;
      });
      results.add(future);
    }
    if (currentValidationId!=validationCallCount) return false;
    for (final e in results) {
      success = await e;
      if (currentValidationId!=validationCallCount) return false;
      if (!success) {
        break;
      }
    }
    notifyListeners();
    return success && validationErrors.where((e) => e.isBlocking).isEmpty;
  }
  void focusFirstBlockingError() {
    final validationErrors = this.validationErrors;
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    final error = validationErrors.firstOrNull;
    if (error!=null) {
      focusError(error);
    }
  }
  void focusError(ValidationError error) {
    error.field.requestFocus();
    try {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        error.animationController?.forward(from: 0);
        // if the field is disabled, it can't be focused, so we need to manually scroll to it
        if (!error.field.enabled && error.field.fieldGlobalKey.currentContext!=null) {
          EnsureVisibleWhenFocusedState.ensureVisibleForContext(
            context: error.field.fieldGlobalKey.currentContext!,
          );
        }
      });
    } catch(_) {}
  }


  Future<ModelType?> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBars=true,
    bool? snackBarCancellable,
    bool askForSaveConfirmation=true,
    bool skipValidation = false,
  }) async {
    final validationFuture = skipValidation
        ? Future.value(true)
        : validate(context,
            validateNonEditedFields: true,
          );
    bool? confirm = await showModalFromZero(
      context: context,
      builder: (context) {
        final GlobalKey timerGlobalKey = GlobalKey();
        return SizedBox(
          width: formDialogWidth-32,
          child: ResponsiveInsetsDialog(
            clipBehavior: Clip.hardEdge,
            child: FutureBuilderFromZero<bool>(
              future: validationFuture,
              applyAnimatedContainerFromChildSize: true,
              loadingBuilder: (context) {
                return Container(
                  width: 512,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18,),
                        Text('Validando Datos...', // TODO 3 internationalize
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 200,
                            child: ApiProviderBuilder.defaultLoadingBuilder(context, null),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 512,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18,),
                      ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace as StackTrace?, null),
                      const SizedBox(height: 12,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DialogButton.cancel(
                            child: Text(FromZeroLocalizations.of(context).translate("close_caps")),
                          ),
                          const SizedBox(width: 2,),
                        ],
                      ),
                      const SizedBox(height: 12,),
                    ],
                  ),
                );
              },
              successBuilder: (context, validation) {
                validation = skipValidation
                    ? true
                    : validation && validationErrors.firstOrNullWhere((e) => e.isBlocking)==null;
                if (!showConfirmDialogWithBlockingErrors && !validation) {  // TODO 3 implement a parameter for always allowing to save, even on error
                  Navigator.of(context).pop(null);
                }
                if (!askForSaveConfirmation && validationErrors.where((e) => e.isBlocking || e.isVisibleAsSaveConfirmation).isEmpty) {
                  Navigator.of(context).pop(true);
                }
                String shownName = uiName;
                if (shownName.isNullOrEmpty) shownName = classUiName;
                return DialogFromZero(
                  includeDialogWidget: false,
                  maxWidth: 512,
                  title: Text(validation
                      ? (saveConfirmationDialogTitle?.call(this) ?? FromZeroLocalizations.of(context).translate("confirm_save_title"))
                      : 'Error de Validación', // TODO 3 internationalize
                  ),
                  content: AnimatedBuilder(
                    animation: this,
                    builder: (context, child) {
                      return IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            validation
                                ? (saveConfirmationDialogDescription?.call(this) ?? Text("${FromZeroLocalizations.of(context).translate("confirm_save_desc")}\r\n$shownName"))
                                : const Text('Debe resolver los siguientes errores de validación:',), // TODO 3 internationalize
                            SaveConfirmationValidationMessage(allErrors: validationErrors),
                          ],
                        ),
                      );
                    },
                  ),
                  dialogActions: [
                    const DialogButton.cancel(),
                    TimedOverlay(
                      key: timerGlobalKey,
                      duration: validationErrors.isEmpty || !validation
                          ? Duration.zero
                          : Duration(milliseconds: (1000 + 500*Set.from(validationErrors.where((e) => e.isVisibleAsSaveConfirmation).map((e) => e.error)).length).clamp(0, 10000)),
                      builder: (context, elapsed, remaining) {
                        return DialogButton.accept(
                          tooltip: validation ? null : 'No se puede guardar hasta resolver los errores de validación', // TODO 3 internationalize
                          onPressed: !ignoreBlockingErrors && (remaining!=Duration.zero || !validation) ? null : () {
                            Navigator.of(context).pop(true); // Dismiss alert dialog
                          },
                          child: Text((saveButtonTitle?.call(this).toUpperCase() ?? FromZeroLocalizations.of(context).translate("save_caps"))),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (confirm??false) {
      return save(context,
        skipValidation: true,
        updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
        showDefaultSnackBar: showDefaultSnackBars,
        snackBarCancellable: snackBarCancellable,
      );
    } else if (confirm==null) {
      final errors = validationErrors.where((e) => e.severity!=ValidationErrorSeverity.unfinished).toList();
      if (errors.isNotEmpty) {
        errors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
        focusError(errors.first);
      }
    }
    return null;
  }

  Future<ModelType?> save(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBar=true,
    bool? snackBarCancellable,
    bool skipValidation=false,
  }) async {
    if (!skipValidation) {
      bool validation = await validate(context,
        validateNonEditedFields: true,
      );
      if (!validation) {
        focusFirstBlockingError();
        return null;
      }
    }
    for (final e in props.values) {
      if (e is StringField && e.trimOnSave) {
        e.commitValue((e.value??'').trim());
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
        duration: showDefaultSnackBar ? 3.seconds : Duration.zero,
        cancelable: snackBarCancellable,
        successTitle: '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
            : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.',
      ).show();
      try {
        await Future.any([controller.closed, completer.future]);
        success = model!=null;
      } catch (e, st) {
        log(LgLvl.error, 'Error while saving $classUiName: $uiName', e: e, st: st, type: FzLgType.dao);
      }
      removeListener();
    } else if (onSave==null) {
      success = true;
    } else {
      try {
        model = await onSave!.call(contextForValidation??context, this);
        success = model!=null;
      } catch (e, st) {
        success = false;
        log(LgLvl.error, 'Error while saving $classUiName: $uiName', e: e, st: st, type: FzLgType.dao);
      }
    }
    if (success) {
      didSave(context, model);
    }
    if (updateDbValuesAfterSuccessfulSave && success) {
      props.forEach((key, value) {
        value.dbValue = value.value;
        value.undoValues.clear();
        value.redoValues.clear();
      });
      _undoRecord.clear();
      _redoRecord.clear();
    }
    if (onSaveAPI==null && showDefaultSnackBar) {
      SnackBarFromZero(
        context: context,
        type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
        title: Text(success
            ? '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
            : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
            : FromZeroLocalizations.of(context).translate("connection_error_long"),),
      ).show();
    }
    return model;
  }

  @mustCallSuper
  void didSave(BuildContext context, ModelType? model) {
    onDidSave?.call(contextForValidation??context, model, this);
  }


  Future<bool> maybeDelete(BuildContext context, {
    bool? showDefaultSnackBars,
  }) async {
    bool confirm = true;
    bool askForDeleteConfirmation = true;
    if (askForDeleteConfirmation) {
      confirm = await showModalFromZero(
        context: context,
        builder: (context) {
          return DialogFromZero(
            maxWidth: formDialogWidth-32,
            title: Text(FromZeroLocalizations.of(context).translate('confirm_delete_title')),
            content: Text('${FromZeroLocalizations.of(context).translate('confirm_delete_desc')} $uiName?'),
            dialogActions: [
              const DialogButton.cancel(),
              DialogButton(
                color: Colors.red,
                onPressed: () {
                  Navigator.of(context).pop(true); // Dismiss alert dialog
                },
                child: Text(FromZeroLocalizations.of(context).translate('delete_caps')),
              ),
            ],
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

  Future<bool> delete(BuildContext context, {
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
      try {
        await Future.any([controller.closed, completer.future]);
      } catch (e, st) {
        log(LgLvl.error, 'Error while deleting $classUiName: $uiName', e: e, st: st, type: FzLgType.dao);
      }
      removeListener();
    } else {
      try {
        errorString = await onDelete?.call(contextForValidation??context, this);
        success = errorString==null;
      } catch (e, st) {
        success = false;
        log(LgLvl.error, 'Error while deleting $classUiName: $uiName', e: e, st: st, type: FzLgType.dao);
      }
      if (showDefaultSnackBar && context.mounted) {
        SnackBarFromZero(
          context: context,
          type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
          title: Text(success
              ? '$classUiName ${FromZeroLocalizations.of(context).translate("deleted")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
              : (errorString ?? FromZeroLocalizations.of(context).translate("connection_error_long")),),
        ).show();
      }
    }
    if (success) {
      onDidDelete?.call(contextForValidation??context, this);
    }
    return success;
  }

  void applyDefaultValues(List<InvalidatingError> invalidatingErrors) {
    if (ignoreBlockingErrors) return;
    bool keepUndo = _undoRecord.isNotEmpty; // don't keep undo record if the invalidation error is thrown when opening dialog
    beginUndoTransaction();
    Map<Object, List<InvalidatingError>> map = {};
    for (final e in invalidatingErrors) {
      map[e.field.fieldGlobalKey] = [...(map[e.field.fieldGlobalKey]??[]), e];
    }
    for (final errorList in map.values) {
      final error = errorList.first;
      final field = error.field;
      if (error.setAsDbValue) {
        field.dbValue = error.defaultValue;
      }
      if (field is StringField) {
        field.commitValue(error.defaultValue as String?);
      } else {
        field.value = error.defaultValue;
      }
    }
    if (!keepUndo) beginUndoTransaction(); // discard undo transaction
    final fuse = _undoTransaction?.isNotEmpty ?? false;
    commitUndoTransaction();
    if (fuse) fuseLastTwoUndoRecords();
  }
  void fuseLastTwoUndoRecords() {
    if (_undoRecord.length>1) {
      final previousRecord = _undoRecord[_undoRecord.length-2];
      previousRecord.addAll(_undoRecord.removeLast());
    }
  }

  Future<void> maybeRevertChanges(BuildContext context) async {
    bool? revert = await showModalFromZero(
      context: context,
      builder: (context) {
        return DialogFromZero(
          title: Text(FromZeroLocalizations.of(context).translate("confirm_reverse_title")),
          content: Text(FromZeroLocalizations.of(context).translate("confirm_reverse_desc")),
          dialogActions: [
            const DialogButton.cancel(),
            DialogButton(
              color: Colors.red,
              onPressed: () {
                Navigator.of(context).pop(true); // Dismiss alert dialog
              },
              child: Text(FromZeroLocalizations.of(context).translate("reverse_caps")),
            ),
          ],
        );
      },
    );
    if (revert??false) {
      revertChanges();
    }
  }

  /// this code assumes it is called only once on showModal, if it is called multiple times inside a build() method it will behave weirdly
  late final List<int> _tabBarAnimationLocks = [];
  Widget buildEditModalWidget(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) {
    askForSaveConfirmation ??= showDefaultSnackBars;
    final props = this.props;
    parentDAO = null;
    for (final e in props.values) {
      e.undoValues.clear();
      e.redoValues.clear();
    }
    _undoRecord.clear();
    _redoRecord.clear();
    _contextForValidation = _contextForValidation ?? context;
    Map<String, ValueNotifier<Size?>> secondarySizeNotifiers = {}; // this needs to persist between rebuilds
    final initialValidation = validate(context,
      validateNonEditedFields: false,
    );
    final focusNode = FocusNode();
    PreloadPageController? pageController;
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        Widget result = AnimatedBuilder(
          animation: this,
          builder: (context, child) {
            double widescreenDialogWidth = formDialogWidth*2+32+24+16+32+16+38;
            final doubleColumnLayoutType = this.doubleColumnLayoutType?.call(this)??DoubleColumnLayoutType.tabbed;
            bool widescreen = doubleColumnLayoutType!=DoubleColumnLayoutType.none
                && constraints.maxWidth>=widescreenDialogWidth;
            ScrollController primaryScrollController = ScrollController();
            ScrollController tabBarScrollController = ScrollController();
            Map<String, ScrollController> secondaryScrollControllers = {};
            List<Widget> primaryFormWidgets = [];
            Map<String, Widget> secondaryFormWidgets = {};
            int i = 1;
            bool firstIteration = true;
            for (final e in fieldGroups) {
              if (e.props.values.where((e) => !e.hiddenInForm).isNotEmpty) {
                bool asPrimary = !widescreen || e.primary;
                final name = doubleColumnLayoutType==DoubleColumnLayoutType.tabbed
                    ? e.name ?? 'Grupo $i'
                    : 'Grupo 1'; // TODO 3 internationalize
                final scrollController = asPrimary ? primaryScrollController : ScrollController();
                Widget groupWidget = buildGroupWidget(
                  context: context,
                  group: e,
                  mainScrollController: scrollController,
                  showCancelActionToPop: true,
                  focusNode: firstIteration ? focusNode : null,
                  showDefaultSnackBars: showDefaultSnackBars,
                  showRevertChanges: showRevertChanges,
                  askForSaveConfirmation: askForSaveConfirmation!,
                  showActionButtons: false,
                  groupBorderNestingCount: asPrimary ? 0 : -1,
                );
                firstIteration = false;
                if (asPrimary) {
                  primaryFormWidgets.add(groupWidget);
                } else {
                  secondaryScrollControllers[name] = scrollController;
                  secondarySizeNotifiers[name] ??= ValueNotifier(Size.zero);
                  if (doubleColumnLayoutType==DoubleColumnLayoutType.tabbed) {
                    secondaryFormWidgets[name] = FocusTraversalOrder(
                      order: NumericFocusOrder(i.toDouble()),
                      child: groupWidget,
                    );
                    i++;
                  } else {
                    secondaryFormWidgets[name] = FocusTraversalOrder(
                      order: NumericFocusOrder(i.toDouble()),
                      child: Column(
                        children: [
                          ...(((secondaryFormWidgets[name] as FocusTraversalOrder?)?.child as Column?)?.children??[]),
                          groupWidget,
                        ],
                      ),
                    );
                  }
                }
              }
            }
            List<Widget> formActions = buildActionButtons(context,
              showCancelActionToPop: true,
              showDefaultSnackBars: showDefaultSnackBars,
              showRevertChanges: showRevertChanges,
              askForSaveConfirmation: askForSaveConfirmation!,
              topSpace: 0,
              bottomSpace: 12,
            );
            String shownName = uiName;
            if (shownName.isNullOrEmpty) shownName = classUiName;
            final primaryFormBuiltWidget = ScrollbarFromZero(
              controller: primaryScrollController,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12,),
                child: SingleChildScrollView(
                  controller: primaryScrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FocusTraversalOrder(
                      order: const NumericFocusOrder(1),
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
            );
            Widget result = DialogFromZero( // take advantage of DialogFromZero layout, to always have intrinsic height (without using the IntrinsicHeight widget)
              includeDialogWidget: false,
              contentPadding: EdgeInsets.zero,
              scrollController: ScrollController(), // disable default DialogFromZero scrolling
              appBar: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: AppbarFromZero(
                  constraints: constraints,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent, // match dialog
                  elevation: 0,
                  toolbarHeight: 56 + 12,
                  paddingRight: 18,
                  title: OverflowScroll(
                    child: Text(editDialogTitle?.call(this) ?? '${id==null
                        ? FromZeroLocalizations.of(context).translate("add")
                        : FromZeroLocalizations.of(context).translate("edit")} $shownName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  actions: [
                    ...(formDialogExtraActions?.call(contextForValidation??context, this) ?? []),
                    ...buildFormDialogDefaultActions(context, showUndoRedo: showUndoRedo),
                  ],
                ),
              ),
              content: FocusScope(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: secondaryFormWidgets.keys.isEmpty ? primaryFormBuiltWidget : DefaultTabController(
                    length: secondaryFormWidgets.keys.length,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: secondaryFormWidgets.keys.isNotEmpty ? 12 : 0),
                          child: SizedBox(
                            width: formDialogWidth+24,
                            child: primaryFormBuiltWidget,
                          ),
                        ),
                        if (secondaryFormWidgets.keys.isNotEmpty)
                          const Expanded(child: SizedBox.shrink()),
                        if (secondaryFormWidgets.keys.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: SizedBox(
                              width: formDialogWidth+24+16,
                              child: DialogFromZero( // take advantage of DialogFromZero layout, to always have intrinsic height (without using the IntrinsicHeight widget)
                                includeDialogWidget: false,
                                contentPadding: EdgeInsets.zero,
                                scrollController: ScrollController(), // disable default DialogFromZero scrolling
                                appBar: Column(
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
                                                  child: Builder(
                                                    builder: (context) {
                                                      return TabBar( // TODO 3 replace this with an actual widget: PageIndicatorFromzero. Allow to have an indicator + building children dinamically according to selected
                                                        isScrollable: true,
                                                        indicatorWeight: 3,
                                                        tabs: secondaryFormWidgets.keys.map((e) {
                                                          return Container(
                                                            height: 32,
                                                            alignment: Alignment.center,
                                                            child: Text(e, style: Theme.of(context).textTheme.titleMedium,),
                                                          );
                                                        }).toList(),
                                                        onTap: (value) async {
                                                          DefaultTabController.of(context).index = value;
                                                          pageController ??= PreloadPageController();
                                                          final future = pageController!.animateToPage(value,
                                                            duration: kTabScrollDuration,
                                                            curve: Curves.ease,
                                                          );
                                                          _tabBarAnimationLocks.add(future.hashCode);
                                                          await future;
                                                          _tabBarAnimationLocks.remove(future.hashCode);
                                                        },
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
                                  ],
                                ),
                                content: Builder(
                                  builder: (context) {
                                    final tabController = DefaultTabController.of(context);
                                    pageController ??= PreloadPageController(initialPage: tabController.index);
                                    return AnimatedBuilder(
                                      animation: tabController,
                                      builder: (context, child) {
                                        final currentIndex = tabController.index;
                                        final currentKey = secondaryFormWidgets.keys.toList()[currentIndex];
                                        return RelayedFiller(
                                          duration: kTabScrollDuration,
                                          notifier: secondarySizeNotifiers[currentKey]!,
                                          applyWidth: false,
                                          child: child,
                                        );
                                      },
                                      child: PreloadPageView(
                                        controller: pageController,
                                        preloadPagesCount: 999,
                                        onPageChanged: (value) {
                                          if (_tabBarAnimationLocks.isEmpty) {
                                            tabController.animateTo(value);
                                          }
                                        },
                                        children: secondaryFormWidgets.keys.map((e) {
                                          return ScrollbarFromZero(
                                            controller: secondaryScrollControllers[e],
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: FocusTraversalGroup(
                                                child: SingleChildScrollView(
                                                  controller: secondaryScrollControllers[e],
                                                  child: FillerRelayer(
                                                    notifier: secondarySizeNotifiers[e]!,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                        top: secondaryFormWidgets.length==1 && secondaryFormWidgets.keys.first=='Grupo 1'
                                                            ? 12 : 0,
                                                        bottom: 28,
                                                      ),
                                                      child: secondaryFormWidgets[e],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              dialogActions: [Column(
                mainAxisSize: MainAxisSize.min,
                children: formActions,
              ),],
            );
            Map<InvalidatingError, Field> invalidatingErrors = {};
            List<InvalidatingError> autoResolveInvalidatingErrors = [];
            bool allowSetInvalidatingFieldsToDefaultValues = true;
            bool allowUndoInvalidatingChanges = _undoRecord.isNotEmpty;
            for (final Field e in props.values) {
              final errors = e.validationErrors.whereType<InvalidatingError>();
              for (final error in errors) {
                allowSetInvalidatingFieldsToDefaultValues = allowSetInvalidatingFieldsToDefaultValues && error.allowSetThisFieldToDefaultValue;
                allowUndoInvalidatingChanges = allowUndoInvalidatingChanges && error.allowUndoInvalidatingChange;
                if (error.showVisualConfirmation) {
                  invalidatingErrors[error] = error.field;
                } else {
                  autoResolveInvalidatingErrors.add(error);
                }
              }
            }
            if (autoResolveInvalidatingErrors.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
                      width: secondaryFormWidgets.keys.isEmpty
                          ? formDialogWidth+32+24+16
                          : widescreenDialogWidth,
                      child: ResponsiveInsetsDialog(
                        backgroundColor: Theme.of(context).canvasColor,
                        clipBehavior: Clip.hardEdge,
                        child: result,
                      ),
                    ),
                  ),
                ),
                PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: invalidatingErrors.isEmpty ? const SizedBox() : ColoredBox(
                    color: Colors.black38,
                    child: Center(
                      child: SizedBox(
                        width: formDialogWidth-32,
                        child: ResponsiveInsetsDialog(
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
                                  child: OverflowScroll(
                                    child: Text(FromZeroLocalizations.of(context).translate("confirm_invalidating_change_title"),
                                      style: Theme.of(context).textTheme.titleLarge,
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
                                            const SizedBox(height: 24,),
                                            Text(FromZeroLocalizations.of(context).translate(!allowSetInvalidatingFieldsToDefaultValues ? "confirm_invalidating_change_description2_1" : "confirm_invalidating_change_description2_2")),
                                            const SizedBox(height: 6,),
                                            ValidationMessage(
                                              errors: invalidatingErrors.keys.toList(),
                                              passedFirstEdit: true,
                                              errorTextStyle: Theme.of(context).textTheme.bodyLarge,
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
                                                ),);
                                              }).values,
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
                                        DialogButton.cancel(
                                          onPressed: () {
                                            beginRedoTransaction();
                                            undo();
                                            beginRedoTransaction(); commitRedoTransaction(); // discard redo
                                          },
                                        ),
                                      if (allowSetInvalidatingFieldsToDefaultValues)
                                        DialogButton.accept(
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
        if (enableUndoRedoMechanism) {
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
        }
        return result;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
    return FutureBuilderFromZero(
      animatedSwitcherType: AnimatedSwitcherType.none,
      future: initialValidation,
      successBuilder: (context, data) => content,
      loadingBuilder: (context) {
        return Center(
          child: Card(
            child: SizedBox(
              width: formDialogWidth,
              height: 256,
              child: ApiProviderBuilder.defaultLoadingBuilder(context, null),
            ),
          ),
        );
      },
    );
  }


  List<Widget> buildViewDialogDefaultActions(BuildContext context, {
    bool? showEditButton,
    bool? showDeleteButton,
    bool showDefaultSnackBars = true,
    bool popAfterEditOrDeleteActions = true,
  }) {
    return [
      if (showEditButton ?? viewDialogShowsEditButton ?? canSave)
        ActionFromZero(
          title: FromZeroLocalizations.of(context).translate('edit'),
          icon: const Icon(Icons.edit_outlined),
          onTap: (context) async {
            final tempDao = copyWith();
            final result = await tempDao.maybeEdit(context,
              showDefaultSnackBars: showDefaultSnackBars,
            );
            if (result != null) {
              final tempProps = tempDao.props;
              props.forEach((key, value) {
                if (value.value != tempProps[key]!.value) {
                  value.value = tempProps[key]!.value;
                }
              });
              if (popAfterEditOrDeleteActions) Navigator.of(context).pop();
            }
          },
        ),
      if (showDeleteButton ?? viewDialogShowsDeleteButton ?? false) // always default false for now, to avoid breaking existing DAOs, should be ?? canDelete
        ActionFromZero(
          title: FromZeroLocalizations.of(context).translate('delete'),
          icon: const Icon(Icons.delete_forever),
          breakpoints: {0: ActionState.overflow},
          onTap: (context) async {
            final result = await maybeDelete(context);
            if (result) {
              if (popAfterEditOrDeleteActions) Navigator.of(context).pop();
            }
          },
        ),
    ];
  }

  List<Widget> buildFormDialogDefaultActions(BuildContext context, {
    bool showUndoRedo = true,
  }) {
    return [
      if (enableUndoRedoMechanism && showUndoRedo)
        ActionFromZero(
          title: FromZeroLocalizations.of(context).translate("undo"),
          icon: const Icon(MaterialCommunityIcons.undo_variant,),
          breakpoints: {
            ScaffoldFromZero.screenSizeSmall: ActionState.overflow,
            ScaffoldFromZero.screenSizeMedium: ActionState.icon,
          },
          onTap: _undoRecord.isEmpty ? null : (context) {
            undo();
          },
        ),
      if (enableUndoRedoMechanism && showUndoRedo)
        ActionFromZero(
          title: FromZeroLocalizations.of(context).translate("redo"),
          icon: const Icon(MaterialCommunityIcons.redo_variant,),
          breakpoints: {
            ScaffoldFromZero.screenSizeSmall: ActionState.overflow,
            ScaffoldFromZero.screenSizeMedium: ActionState.icon,
          },
          onTap: _redoRecord.isEmpty ? null : (context) {
            redo();
          },
        ),
    ];
  }

  Future<ModelType?> maybeEdit(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) async {
    for (final e in props.values) {
      e.passedFirstEdit = false;
      e.userInteracted = false;
      e.validationErrors = [];
    }
    ModelType? confirm = await showModalFromZero(
      context: context,
      builder: (modalContext) {
        return Consumer(
          builder: (context, ref, child) {
            _contextForValidation = context;
            return buildEditModalWidget(context,
              showDefaultSnackBars: showDefaultSnackBars,
              showRevertChanges: showRevertChanges,
              askForSaveConfirmation: askForSaveConfirmation,
              showUndoRedo: showUndoRedo,
            );
          },
        );
      },
    );
    return confirm;
  }


  Future<dynamic> pushViewDialog(BuildContext mainContext, {
    bool? showEditButton,
    bool? showDeleteButton,
    bool? useIntrinsicWidth,
    bool showDefaultSnackBars = true,
  }) {
    if (useIntrinsicWidth==null && props.values.where((e) => e is ListField && !e.hiddenInView && (e.buildViewWidgetAsTable || e.objects.length>50)).isNotEmpty) {
      useIntrinsicWidth = false;
    }
    return showModalFromZero(context: mainContext,
      builder: (context) {
        return AnimatedBuilder(
          animation: this,
          builder: (context, child) {
            final scrollController = ScrollController();
            Widget result = SingleChildScrollView(
              controller: scrollController,
              child: buildViewWidget(mainContext,
                mainScrollController: scrollController,
              ),
            );
            if (useIntrinsicWidth ?? true) {
              result = IntrinsicWidth(child: result,);
            }
            return DialogFromZero(
              contentPadding: EdgeInsets.zero,
              scrollController: scrollController,
              content: result,
              maxWidth: viewDialogWidth * ((useIntrinsicWidth ?? true) ? 1.5 : 1),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(uiName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (uiName!=classUiName)
                    SelectableText(classUiName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                ],
              ),
              dialogActions: [
                DialogButton.cancel(
                  child: Text(FromZeroLocalizations.of(context).translate("close_caps")),
                ),
              ],
              appBarActions: [
                ...buildViewDialogDefaultActions(context,
                  showEditButton: showEditButton,
                  showDeleteButton: showDeleteButton,
                  showDefaultSnackBars: showDefaultSnackBars,
                ),
                ...(viewDialogExtraActions?.call(mainContext, this) ?? []),
              ],
            );
          },
        );
      },
    );
  }
  Widget buildViewWidget(BuildContext context, {
    List<FieldGroup>? fieldGroups,
    ScrollController? mainScrollController,
    bool? useIntrinsicWidth,
    int titleFlex = 1000000,
    int valueFlex = 1618034,
    double? titleMaxWidth,
    bool applyAlternateBackground = true,
    bool initialAlternateBackground = false,
  }) {
    if (viewWidgetBuilder!=null) {
      return viewWidgetBuilder!(context, this);
    } else {
      return defaultBuildViewWidget(context, this,
        fieldGroups: fieldGroups,
        mainScrollController: mainScrollController,
        useIntrinsicWidth: useIntrinsicWidth,
        titleFlex: titleFlex,
        valueFlex: valueFlex,
        titleMaxWidth: titleMaxWidth,
        applyAlternateBackground: applyAlternateBackground,
        initialAlternateBackground: initialAlternateBackground,
      );
    }
  }
  static Widget defaultBuildViewWidget<T>(BuildContext context, DAO<T> dao, {
    List<FieldGroup>? fieldGroups,
    ScrollController? mainScrollController,
    bool? useIntrinsicWidth,
    int titleFlex = 1000000,
    int valueFlex = 1618034,
    double? titleMaxWidth,
    bool applyAlternateBackground = true,
    bool initialAlternateBackground = false,
  }) {
    if (!context.mounted) return const SizedBox.shrink(); // hack to prevent error when getting Theme from a dirty context
    if (useIntrinsicWidth==null && (titleMaxWidth!=null
        || dao.props.values.where((e) => e is ListField && e.buildViewWidgetAsTable).isNotEmpty)) {
      useIntrinsicWidth ??= false;
    }
    fieldGroups ??= dao.fieldGroups;
    bool clear = initialAlternateBackground;
    bool first = true;
    Widget result = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fieldGroups.map((group) {
        if (!context.mounted) return const SizedBox.shrink(); // hack to prevent error when getting Theme from a dirty context
        final fields = group.props.values.where((e) => !e.hiddenInView);
        Widget result;
        if (fields.isEmpty) {
          return const SizedBox.shrink();
        }
        result = Column(
          mainAxisSize: MainAxisSize.min,
          children: fields.map((e) {
            if (!context.mounted) return const SizedBox.shrink(); // hack to prevent error when getting Theme from a dirty context
            clear = !clear;
            if (e is ListField && e.buildViewWidgetAsTable) {
              clear = false;
              return ListField.tableAsViewBuilder(dao, e, context, mainScrollController);
            } else {
              final title = Container(
                padding: const EdgeInsets.only(bottom: 6, top: 8, left: 12, right: 12,),
                // alignment: Alignment.centerRight,
                child: SelectableText(e.uiName,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge!.color!
                        .withOpacity(Theme.of(context).brightness==Brightness.light ? 0.7 : 0.8),
                    wordSpacing: 0.4, // hack to fix soft-wrap bug with intrinsicHeight
                    height: 1.1,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
              final value = Container(
                alignment: Alignment.centerLeft,
                child: e.buildViewWidget(context,
                  linkToInnerDAOs: dao.viewDialogLinksToInnerDAOs,
                  showViewButtons: dao.viewDialogShowsViewButtons,
                ),
              );
              Widget layout;
              if (titleMaxWidth==null) {
                layout = IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: titleFlex,
                        child: title,
                      ),
                      const SizedBox(
                        height: 24,
                        child: VerticalDivider(width: 0,),
                      ),
                      Expanded(
                        flex: valueFlex,
                        child: value,
                      ),
                    ],
                  ),
                );
              } else {
                layout = FlexibleLayoutFromZero(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  applyIntrinsicCrossAxis: true,
                  children: [
                    FlexibleLayoutItemFromZero(
                      flex: titleFlex.toDouble(),
                      maxSize: titleMaxWidth,
                      child: title,
                    ),
                    const FlexibleLayoutItemFromZero(
                      minSize: 1, maxSize: 1,
                      child: SizedBox(
                        height: 24,
                        child: VerticalDivider(width: 0,),
                      ),
                    ),
                    FlexibleLayoutItemFromZero(
                      flex: valueFlex.toDouble(),
                      child: value,
                    ),
                  ],
                );
              }
              return Material(
                color: !applyAlternateBackground ? Colors.transparent
                    : clear ? Theme.of(context).cardColor
                    : Color.alphaBlend(Theme.of(context).cardColor.withOpacity(0.965), Colors.black),
                child: layout,
              );
            }
          }).toList(),
        );
        if (!first || group.name!=null) {
          result = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!first)
                DAOViewDividerWidget(
                  titleFlex: titleFlex,
                  valueFlex: valueFlex,
                  titleMaxWidth: titleMaxWidth,
                  goBelow: false,
                ),
              if (group.name!=null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                  child: Text(group.name!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
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
    );
    if (useIntrinsicWidth??true) {
      result = IntrinsicWidth(child: result,);
    }
    return result;
  }

  Widget buildGroupWidget({
    required BuildContext context,
    required FieldGroup group,
    ScrollController? mainScrollController,
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
    final childGroups = group.visibleChildGroups;
    final fields = group.visibleFields;
    if (childGroups.isEmpty && fields.isEmpty) {
      return const SizedBox.shrink();
    }
    bool verticalLayout = firstIteration || group.primary;
    bool addBorder = group.name!=null && group.props.length>1;
    groupBorderNestingCount += (addBorder ? 1 : 0);
    List<Widget> getChildren({bool useLayoutFromZero = false}) => [
      ...buildFormWidgets(context,
        props: fields,
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
      ...childGroups.map((e) {
        return buildGroupWidget(
          context: context,
          group: e,
          showCancelActionToPop: true,
          mainScrollController: mainScrollController,
          expandToFillContainer: verticalLayout && expandToFillContainer,
          focusNode: focusNode,
          showDefaultSnackBars: showDefaultSnackBars,
          showRevertChanges: showRevertChanges,
          askForSaveConfirmation: askForSaveConfirmation,
          showActionButtons: false,
          popAfterSuccessfulSave: popAfterSuccessfulSave,
          firstIteration: false,
          wrapInLayoutFromZeroItem: useLayoutFromZero,
          groupBorderNestingCount: groupBorderNestingCount,
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
          crossAxisAlignment: group.primary ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: getChildren(useLayoutFromZero: true)
              .cast<FlexibleLayoutItemFromZero>(),
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
    if (addBorder) {
      result = Padding(
        padding: EdgeInsets.only(
          top: 3 + (group.name!.isNotEmpty ? 4 : 0),
          bottom: 3,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 12, top: 20,
              left: 2, right: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0, left: 18,
              child: Text(group.name!),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 18, left: 8, right: 8,),
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
        maxSize: group.maxWidth + (addBorder ? 16 : 0),
        minSize: group.minWidth + (addBorder ? 16 : 0),
        child: result,
      );
    }
    return result;
  }

  List<Widget> buildFormWidgets(BuildContext context, {
    Map<String, Field>? props,
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
    props ??= this.props;
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
        final hidden = e.hiddenInForm;
        const fieldVerticalPadding = 3.0;
        if (asSlivers) {
          result = result.mapIndexed((i, w) {
            return hidden
                ? const SizedBox.shrink()
                : SliverPadding(
                    padding: EdgeInsets.only(
                      top: i == 0 ? fieldVerticalPadding : 0,
                      bottom: i == result.lastIndex ? fieldVerticalPadding : 0,
                    ),
                    sliver: w,
                  );
          }).toList();
        } else {
          result = result.mapIndexed((i, w) {
            return hidden
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(
                      top: i==0 ? fieldVerticalPadding : 0,
                      bottom: i==result.lastIndex ? fieldVerticalPadding : 0,
                    ),
                    child: w,
                  );
              }).toList();
          if (wrapInLayoutFromZeroItem) {
            result = [
              FlexibleLayoutItemFromZero(
                maxSize: hidden ? 0 : e.maxWidth,
                minSize: hidden ? 0 : e.minWidth,
                flex: hidden ? 0 : e.flex,
                child: hidden ? const SizedBox.shrink() : AnimatedSwitcher(
                  duration: 300.milliseconds,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: e.hiddenInForm
                      ? const SizedBox.shrink()
                      : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: result,
                  ),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.vertical,
                      axisAlignment: -1,
                      child: Center(child: child),
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    // only allow 2 widgets to be here, to avoid building the widet
                    // for the same Field twice, which causes duplicate GlobalKey assertion
                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (previousChildren.isNotEmpty) previousChildren.last,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                ),
              ),
            ];
          }
        }
        return result;
      }).flatten(),
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
    double topSpace = 6,
    double bottomSpace = 24,
  }) {
    return [
      SizedBox(height: topSpace,),
      Center(
        child: WillPopScope(
          onWillPop: () async {
            if (!userInteracted || !isEdited) return true;
            bool? pop = (await showModalFromZero(
              context: context,
              builder: (modalContext) {
                return DialogFromZero(
                  title: Text(FromZeroLocalizations.of(context).translate("confirm_close_title")),
                  content: Text(FromZeroLocalizations.of(context).translate("confirm_close_desc")),
                  dialogActions: [
                    const DialogButton.cancel(),
                    DialogButton(
                      color: Colors.red,
                      onPressed: () {
                        Navigator.of(modalContext).pop(true); // Dismiss alert dialog
                      },
                      child: Text(FromZeroLocalizations.of(context).translate("close_caps")),
                    ),
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
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).disabledColor,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(FromZeroLocalizations.of(context).translate("cancel_caps"),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.8),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).maybePop(null);
                        },
                      ),
                    ),
                  if (showCancelActionToPop)
                    const SizedBox(width: 12,),
                  if (showRevertChanges)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: isEdited && userInteracted ? () {
                          maybeRevertChanges(context);
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(FromZeroLocalizations.of(context).translate("reverse_changes_caps"),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
                          ),
                        ),
                      ),
                    ),
                  if (showRevertChanges)
                    const SizedBox(width: 12,),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userInteracted
                            ? Color.alphaBlend(Theme.of(context).colorScheme.secondary.withOpacity(0.2), Theme.of(context).cardColor)
                            : Theme.of(context).canvasColor,
                        foregroundColor: userInteracted
                            ? Theme.of(context).textTheme.bodyLarge!.color
                            : Theme.of(context).disabledColor,
                      ),
                      onPressed: isEdited ? () async {
                        ModelType? result = await maybeSave(context,
                          showDefaultSnackBars: showDefaultSnackBars,
                          askForSaveConfirmation: askForSaveConfirmation,
                        );
                        if (result!=null) {
                          if (popAfterSuccessfulSave) {
                            Navigator.of(context).pop(result);
                          }
                        }
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text((saveButtonTitle?.call(this).toUpperCase() ?? FromZeroLocalizations.of(context).translate("save_caps")),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,),
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
      SizedBox(height: bottomSpace,),
    ];
  }

  /// should be overriden by children to provide retry functionalities for errors that occur during validation
  Widget buildValidationInternalErrorRetryButton(InternalError e) => const SizedBox.shrink();
  
}





class DAOViewDividerWidget extends StatelessWidget {
  final int titleFlex;
  final double? titleMaxWidth;
  final int valueFlex;
  final double height;
  final bool goBelow;
  const DAOViewDividerWidget({
    this.titleFlex = 1000000,
    this.valueFlex = 1618034,
    this.titleMaxWidth,
    this.height = 16,
    this.goBelow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (titleMaxWidth==null) {
      return IntrinsicHeight(
        child: Stack(
          children: [
            Divider(height: height),
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: titleFlex,
                    child: const SizedBox.expand(),
                  ),
                  SizedBox(
                    height: goBelow ? height : height/2,
                    child: const VerticalDivider(width: 0,),
                  ),
                  Expanded(
                    flex: valueFlex,
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Stack(
        children: [
          Divider(height: height),
          Positioned.fill(
            child: FlexibleLayoutFromZero(
              crossAxisAlignment: CrossAxisAlignment.start,
              applyIntrinsicCrossAxis: true,
              children: [
                FlexibleLayoutItemFromZero(
                  flex: titleFlex.toDouble(),
                  maxSize: titleMaxWidth ?? double.infinity,
                  child: const SizedBox.expand(),
                ),
                FlexibleLayoutItemFromZero(
                  minSize: 1, maxSize: 1,
                  child: SizedBox(
                    height: goBelow ? height : height/2,
                    child: const VerticalDivider(width: 0,),
                  ),
                ),
                FlexibleLayoutItemFromZero(
                  flex: valueFlex.toDouble(),
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

