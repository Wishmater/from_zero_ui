import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/src/field.dart';
import 'package:from_zero_ui/src/field_validators.dart';
import 'field_one_to_many.dart';


typedef Future<DAO?> OnSaveCallback(BuildContext context, DAO e);
typedef Widget DAOWidgetBuilder(BuildContext context, DAO dao);
typedef T DAOValueGetter<T>(DAO dao);

class DAO extends ChangeNotifier implements Comparable {

  dynamic id;
  DAOValueGetter<String> classUiNameGetter;
  String get classUiName => classUiNameGetter(this);
  DAOValueGetter<String> classUiNamePluralGetter;
  String get classUiNamePlural => classUiNamePluralGetter(this);
  DAOValueGetter<String> uiNameGetter;
  String get uiName => uiNameGetter(this);
  /// props shouldn't be added or removed manually, only changes at construction and on load()
  List<FieldGroup> fieldGroups;
  Map<String, Field> get props {
    return {
      if (fieldGroups.isNotEmpty)
        ...fieldGroups.map((e) => e.props).reduce((value, element) => {...value, ...element}),
    };
  }
  List<Field> undoRecord;
  List<Field> redoRecord;
  OnSaveCallback? onSave;
  OnSaveCallback? onDelete;
  List<ValueChanged<DAO>> _selfUpdateListeners = [];

  DAOWidgetBuilder? viewWidgetBuilder;
  bool useIntrinsicHeightForViewDialog;
  double viewDialogWidth;
  double formDialogWidth;
  bool viewDialogLinksToInnerDAOs;
  bool viewDialogShowsViewButtons;
  bool? viewDialogShowsEditButton;

  DAO({
    required this.classUiNameGetter,
    DAOValueGetter<String>? classUiNamePluralGetter,
    required this.uiNameGetter,
    this.id,
    this.fieldGroups = const [],
    this.onSave,
    this.onDelete,
    this.viewWidgetBuilder,
    this.useIntrinsicHeightForViewDialog = true,
    this.viewDialogWidth = 512,
    this.formDialogWidth = 512,
    this.viewDialogLinksToInnerDAOs = true,
    this.viewDialogShowsViewButtons = true,
    this.viewDialogShowsEditButton,
    List<Field>? undoRecord,
    List<Field>? redoRecord,
  }) :  this.undoRecord = undoRecord ?? [],
        this.redoRecord = redoRecord ?? [],
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
  DAO copyWith({
    DAOValueGetter<String>? classUiNameGetter,
    DAOValueGetter<String>? classUiNamePluralGetter,
    DAOValueGetter<String>? uiNameGetter,
    dynamic id,
    List<FieldGroup>? fieldGroups,
    OnSaveCallback? onSave,
    OnSaveCallback? onDelete,
    DAOWidgetBuilder? viewWidgetBuilder,
    bool? useIntrinsicHeightForViewDialog,
    double? viewDialogWidth,
    double? formDialogWidth,
    bool? viewDialogLinksToInnerDAOs,
    bool? viewDialogShowsViewButtons,
    bool? viewDialogShowsEditButton,
    List<Field>? undoRecord,
    List<Field>? redoRecord,
  }) {
    final result = DAO(
      id: id??this.id,
      classUiNameGetter: classUiNameGetter??this.classUiNameGetter,
      fieldGroups: fieldGroups??this.fieldGroups.map((e) => e.copyWith()).toList(),
      classUiNamePluralGetter: classUiNamePluralGetter??this.classUiNamePluralGetter,
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      onSave: onSave??this.onSave,
      onDelete: onDelete??this.onDelete,
      viewWidgetBuilder: viewWidgetBuilder??this.viewWidgetBuilder,
      useIntrinsicHeightForViewDialog: useIntrinsicHeightForViewDialog??this.useIntrinsicHeightForViewDialog,
      viewDialogWidth: viewDialogWidth??this.viewDialogWidth,
      formDialogWidth: formDialogWidth??this.formDialogWidth,
      viewDialogLinksToInnerDAOs: viewDialogLinksToInnerDAOs??this.viewDialogLinksToInnerDAOs,
      viewDialogShowsViewButtons: viewDialogShowsViewButtons??this.viewDialogShowsViewButtons,
      viewDialogShowsEditButton: viewDialogShowsEditButton??this.viewDialogShowsEditButton,
      undoRecord: undoRecord??this.undoRecord,
      redoRecord: redoRecord??this.redoRecord,
    );
    result._selfUpdateListeners = _selfUpdateListeners;
    return result;
  }

  bool get isNew => id==null;
  bool get isEdited => props.values.any((element) => element.isEdited);
  List<ValidationError> get validationErrors => props.values.map((e) => e.validationErrors).flatten().toList();

  @override
  int compareTo(other) => (other is DAO) ? uiName.compareTo(other.uiName) : -1;

  @override
  String toString() => uiName;

  @override
  bool operator == (dynamic other) => (other is DAO) && (id==null ? super.hashCode==other.hashCode : (this.classUiName==other.classUiName && this.id==other.id));

  @override
  int get hashCode => id==null ? super.hashCode : (classUiName+id.toString()).hashCode;


  BuildContext? contextForValidation;
  Map<String, dynamic> lastValidatedValues = {}; // kept to only run validation if values have changed
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (contextForValidation!=null) {
      bool editedSinceLastValidation = false;
      final props = this.props;
      for (final key in props.keys) {
        if (!lastValidatedValues.containsKey(key) || lastValidatedValues[key]!=props[key]!.value) {
          editedSinceLastValidation = true;
          break;
        }
      }
      if (editedSinceLastValidation) {
        for (final key in props.keys) {
          lastValidatedValues[key] = props[key]!.value;
        }
        validate(contextForValidation,
          validateNonEditedFields: false,
        );
      }
    }
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

  void undo() {
    assert(undoRecord.isNotEmpty);
    undoRecord.last.undo();
  }

  void redo() {
    assert(redoRecord.isNotEmpty);
    redoRecord.last.redo();
  }

  Future<bool> validate(context, {
    bool validateNonEditedFields = true,
    bool scrollToBlockingFields = false,
  }) async {
    bool success = true;
    List<Future<bool>> results = [];
    for (final e in props.values) {
      results.add(e.validate(context, this, validateIfNotEdited: validateNonEditedFields)..then((v) => notifyListeners()));
    }
    for (final e in results) {
      success = await e;
      if (!success) {
        break;
      }
    }
    if (scrollToBlockingFields && !success) {
      try {
        Scrollable.ensureVisible(props.values.firstWhere((e) => e.validationErrors.where((e) => e.isBlocking).isNotEmpty).fieldGlobalKey.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      } catch(_) {}
    }
    return success;
  }

  Future<bool> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
  }) async {
    bool validation = await validate(context,
      validateNonEditedFields: true,
      scrollToBlockingFields: true,
    );
    if (!validation) {
      return false;
    }
    bool? confirm = true;
    if (askForSaveConfirmation) {
      confirm = await showModal(
        context: context,
        builder: (context) {
          final allErrors = validationErrors;
          List<ValidationError> warnings = [];
          List<ValidationError> errors = [];
          for (final e in allErrors) {
            if (e.isVisibleAsHintMessage) {
              if (e.isBlocking) {
                errors.add(e);
              } else {
                warnings.add(e);
              }
            }
          }
          return SizedBox(
            width: formDialogWidth-32,
            child: AlertDialog(
              title: Text(FromZeroLocalizations.of(context).translate("confirm_save_title")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FromZeroLocalizations.of(context).translate("confirm_save_desc")),
                  if (errors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12,),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                            size: 38,
                            color: ValidationMessage.severityColors[Theme.of(context).brightness]![ValidationErrorSeverity.error]!,
                          ),
                          SizedBox(width: 6,),
                          Expanded(
                            child: Text(FromZeroLocalizations.of(context).translate("errors") + ':',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...errors.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 15,),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                            size: 10,
                            color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!,
                          ),
                          SizedBox(width: 8,),
                          Expanded(
                            child: Text(e.error,
                              // style: Theme.of(context).textTheme.bodyText1!.copyWith(color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (warnings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12,),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                            size: 38,
                            color: ValidationMessage.severityColors[Theme.of(context).brightness]![ValidationErrorSeverity.warning]!,
                          ),
                          SizedBox(width: 6,),
                          Expanded(
                            child: Text(FromZeroLocalizations.of(context).translate("warnings") + ':',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ...warnings.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 15,),
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                            size: 10,
                            color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!,
                          ),
                          SizedBox(width: 8,),
                          Expanded(
                            child: Text(e.error,
                              // style: Theme.of(context).textTheme.bodyText1!.copyWith(color: ValidationMessage.severityColors[Theme.of(context).brightness]![e.severity]!),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
      return false;
    }
  }

  Future<bool> save(context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBar=true,
    bool skipValidation=false,
  }) async {
    if (!skipValidation) {
      bool validation = await validate(context,
        validateNonEditedFields: true,
        scrollToBlockingFields: true,
      );
      if (!validation) {
        return false;
      }
    }
    bool newInstance = id==null || id==-1;
    bool success = false;
    try {
      success = onSave==null || (await onSave!.call(context, this))!=null;
    } catch (e, st) {
      success = false;
      print(e); print(st);
    }
    if (updateDbValuesAfterSuccessfulSave && success) {
      props.forEach((key, value) {
        value.dbValue = value.value;
      });
    }
    if (showDefaultSnackBar) {
      SnackBarFromZero(
        context: context,
        type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
        title: Text(success
            ? '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
            : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
            : FromZeroLocalizations.of(context).translate("connection_error_long")),
      ).show(context);
    }
    return success;
  }

  Future<bool> delete(context, {bool? showDefaultSnackBar,}) async {
    bool success = false;
    showDefaultSnackBar = showDefaultSnackBar ?? onDelete!=null;
    try {
      success = onDelete==null || await onDelete!.call(context, this)!=null;
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
            : FromZeroLocalizations.of(context).translate("connection_error_long")),
      ).show(context);
    }
    return success;
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

  Future<bool> maybeEdit(BuildContext context, {
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
    lastValidatedValues = {};
    contextForValidation = context;
    final focusNode = FocusNode();
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        double widescreenDialogWidth = formDialogWidth*2+32+24+16+32+16+38;
        bool widescreen = constraints.maxWidth>=widescreenDialogWidth;
        Widget result = AnimatedBuilder(
          animation: this,
          builder: (context, child) {
            bool expandToFillContainer = false;
            if (props.values.where((e) => !e.hiddenInForm && (e is OneToManyRelationField)).isNotEmpty) {
              expandToFillContainer = true;
            } else if (widescreen && fieldGroups.where((e) => !e.primary && e.props.values.where((e) => !e.hiddenInForm).isNotEmpty).isNotEmpty) {
              expandToFillContainer = true;
            }
            List<Widget> primaryFormWidgets = [];
            int i = 1;
            Map<String, Widget> secondaryFormWidgets = {};
            for (final e in fieldGroups) {
              if (e.props.values.where((e) => !e.hiddenInForm).isNotEmpty) {
                Widget groupWidget = buildGroupWidget(
                  context: context,
                  group: e,
                  showCancelActionToPop: true,
                  expandToFillContainer: expandToFillContainer,
                  asSlivers: false,
                  focusNode: focusNode,
                  showDefaultSnackBars: showDefaultSnackBars,
                  showRevertChanges: showRevertChanges,
                  askForSaveConfirmation: askForSaveConfirmation,
                  showActionButtons: false,
                );
                if (!widescreen || e.primary) {
                  primaryFormWidgets.add(groupWidget);
                } else {
                  secondaryFormWidgets[e.name ?? 'Grupo $i'] = groupWidget; // TODO declare buildForm field and call it here reccurisvely
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
            ScrollController primaryScrollController = ScrollController();
            ScrollController tabBarScrollController = ScrollController();
            Map<String, ScrollController> secondaryScrollControllers = Map.fromIterable(secondaryFormWidgets.keys,
              value: (element) => ScrollController(),
            );
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
                          onPressed: undoRecord.isEmpty ? null : () {
                            undo(); // TODO 3 add shortcut support (ctrl+z, ctrl+shift+z)
                          },
                        ),
                      if (showUndoRedo)
                        IconButton(
                          tooltip: FromZeroLocalizations.of(context).translate("redo"),
                          icon: Icon(MaterialCommunityIcons.redo_variant,),
                          onPressed: redoRecord.isEmpty ? null : () {
                            redo();
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
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
                                child: FocusTraversalGroup(
                                  policy: WidgetOrderTraversalPolicy(),
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
                      if (secondaryFormWidgets.keys.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(right: 24),
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: formDialogWidth+12+16,
                              child: DefaultTabController(
                                length: secondaryFormWidgets.keys.length,
                                child: Column(
                                  children: [
                                    ScrollbarFromZero(
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
                                              child: TabBar(
                                                isScrollable: true,
                                                indicatorWeight: 3,
                                                tabs: secondaryFormWidgets.keys.map((e) {
                                                  return Container(
                                                    height: 32,
                                                    alignment: Alignment.center,
                                                    child: Text(e, style: Theme.of(context).textTheme.subtitle1,),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: secondaryFormWidgets.keys.map((e) {
                                          return ScrollbarFromZero(
                                            controller: secondaryScrollControllers[e],
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: SingleChildScrollView(
                                                controller: secondaryScrollControllers[e],
                                                child: FocusTraversalGroup(
                                                  policy: WidgetOrderTraversalPolicy(),
                                                  child: secondaryFormWidgets[e]!,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
            bool allowSetInvalidatingFieldsToDefaultValues = true;
            bool allowUndoInvalidatingChanges = undoRecord.isNotEmpty;
            for (Field e in props.values) {
              final errors = e.validationErrors.where((error) => error.severity==ValidationErrorSeverity.invalidating);
              errors.forEach((err) {
                final error = err as InvalidatingError;
                allowSetInvalidatingFieldsToDefaultValues = allowSetInvalidatingFieldsToDefaultValues && error.allowSetThisFieldToDefaultValue;
                allowUndoInvalidatingChanges = allowUndoInvalidatingChanges && error.allowUndoInvalidatingChange;
                if (error.showVisualConfirmation) {
                  invalidatingErrors[error] = e;
                } else {
                  WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                    e.value = error.defaultValue;
                  });
                }
              });
            }
            if (!allowSetInvalidatingFieldsToDefaultValues && !allowUndoInvalidatingChanges) {
              if (undoRecord.isEmpty) {
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
                                            if (undoRecord.isEmpty)
                                              Text(FromZeroLocalizations.of(context).translate("confirm_invalidating_no_undo_record")),
                                            if (undoRecord.isNotEmpty)
                                              FieldDiffMessage(
                                                field: undoRecord.last,
                                                oldValue: undoRecord.last.undoValues.last,
                                                newValue: undoRecord.last.value,
                                              ), // TODO accomodate for multi-step undo's
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
                                                print (key.defaultValue);
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
                                            undo();
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
                                            invalidatingErrors.forEach((key, value) {
                                              value.value = key.defaultValue;
                                            });
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
        return result;
      },
    );
    // Future.delayed(Duration(milliseconds: 200)).then((value) => focusNode.requestFocus());
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
    bool? confirm = await showModal(
      context: context,
      builder: (modalContext) {
        return content;
      },
    );
    contextForValidation = null;
    return confirm??false;
  }


  Future<dynamic> pushViewDialog(BuildContext context, {
    bool? showEditButton,
  }) {
    Widget content = AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        return Column(
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
                        Text(uiName,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        if (uiName.isNotEmpty)
                          Text(classUiName,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                      ],
                    ),
                  ),
                  if (showEditButton ?? viewDialogShowsEditButton ?? onSave!=null)
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
              child: buildViewWidget(context),
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
    ScrollController scrollController = ScrollController();
    bool clear = false;
    return ScrollbarFromZero(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: props.values.where((e) => !e.hiddenInView).map((e) {
            clear = !clear;
            return Material(
              color: clear ? Theme.of(context).cardColor
                  : Color.alphaBlend(Theme.of(context).cardColor.withOpacity(0.965), Colors.black),
              child: e.buildViewWidget(context,
                linkToInnerDAOs: this.viewDialogLinksToInnerDAOs,
                showViewButtons: this.viewDialogShowsViewButtons,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildGroupWidget({
    required BuildContext context,
    required FieldGroup group,
    bool asSlivers=true,
    bool showActionButtons=true,
    bool showRevertChanges=false,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
    bool firstIteration=true,
    FocusNode? focusNode,
  }) {
    if (group.props.values.where((e) => !e.hiddenInForm).isEmpty) {
      return SizedBox.shrink();
    }
    bool verticalLayout = firstIteration || group.primary;
    List<Widget> children = [
      ...buildFormWidgets(context,
        group: group,
        showCancelActionToPop: true,
        expandToFillContainer: verticalLayout && expandToFillContainer,
        asSlivers: false,
        focusNode: firstIteration && group.primary ? focusNode : null,
        showDefaultSnackBars: showDefaultSnackBars,
        showRevertChanges: showRevertChanges,
        askForSaveConfirmation: askForSaveConfirmation,
        showActionButtons: false,
      ),
      ...group.childGroups.map((e) {
        return buildGroupWidget(
          context: context,
          group: e,
          showCancelActionToPop: true,
          expandToFillContainer: verticalLayout && expandToFillContainer,
          asSlivers: false,
          focusNode: focusNode,
          showDefaultSnackBars: showDefaultSnackBars,
          showRevertChanges: showRevertChanges,
          askForSaveConfirmation: askForSaveConfirmation,
          showActionButtons: false,
          popAfterSuccessfulSave: popAfterSuccessfulSave,
          firstIteration: false,
        );
      }),
    ];
    Widget result;
    if (verticalLayout) {
      result = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
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
            children: children,
          ),
        ),
      );
    }
    result = SizedBox(
      width: formDialogWidth,
      child: result,
    );
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
    return result;
  }

  List<Widget> buildFormWidgets(BuildContext context, {
    FieldGroup? group,
    bool asSlivers=true,
    bool showActionButtons=true,
    bool showRevertChanges=false,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool showDefaultSnackBars=true,
    bool askForSaveConfirmation=true,
    FocusNode? focusNode,
  }) {
    final props = group?.fields ?? this.props;
    bool first = true;
    List<Widget> result = [
      ...props.values.map((e) {
        List<Widget> result = e.buildFieldEditorWidgets(context,
          addCard: true,
          asSliver: asSlivers,
          expandToFillContainer: expandToFillContainer,
          focusNode: first ? focusNode : null,
        );
        first = false;
        result = result.map((w) {
          if (asSlivers) {
            return e.hiddenInForm
                ? SliverToBoxAdapter(child: SizedBox.shrink(),)
                : SliverPadding(
                  padding: EdgeInsets.only(top: 6, bottom: 6,),
                  sliver: w,
                );
          } else {
            return AnimatedSwitcher(
              duration: 300.milliseconds,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: e.hiddenInForm
                  ? SizedBox.shrink()
                  : Padding(
                    padding: EdgeInsets.only(top: 6, bottom: 6,),
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
                          Navigator.of(context).maybePop(false); // Dismiss alert dialog
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
                        if (onSave!=null) {
                          showModal(
                            context: context,
                            configuration: const FadeScaleTransitionConfiguration(barrierDismissible: false,),
                            builder: (context) {
                              return LoadingSign();
                            },
                          );
                        }
                        bool success = await maybeSave(context,
                          showDefaultSnackBars: showDefaultSnackBars,
                          askForSaveConfirmation: askForSaveConfirmation,
                        );
                        if (onSave!=null) {
                          Navigator.of(context).pop();
                        }
                        if (success) {
                          if (popAfterSuccessfulSave) {
                            Navigator.of(context).pop(true);
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






