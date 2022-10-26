import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


/// receives a model and a function to turn it into a DAO, only calls said function when necessary
abstract class LazyDAO<ModelType> implements DAO<ModelType> {

  static bool logDaoBuild = !kReleaseMode;

  ModelType? originalModel;
  DAO<ModelType>? _dao;
  DAO<ModelType> get dao  {
    if (_dao==null) {
      if (logDaoBuild) {
        log('Building dao: $classUiName -- $uiName', stackTrace: StackTrace.current);
      }
      _dao = buildDAO();
    }
    return _dao!;
  }
  bool get isDaoBuilt => _dao!=null;

  LazyDAO(this.originalModel);


  // functions required to be overriden
  //
  DAO<ModelType> buildDAO();


  // DAO methods that should be overriden, to delay build as much as possible
  //
  /// @mustOverride
  String get classUiName;
  /// @mustOverride
  String get uiName;
  /// @mustOverride ???
  bool get canSave => dao.canSave;
  /// @mustOverride ???
  bool get canDelete => dao.canDelete;

  // DAO methods that should be overriden if also changed in dao
  //
  /// @mustOverride
  String get classUiNamePlural => dao.classUiNamePlural;
  /// @mustOverride
  String get searchName => dao.searchName;


  // DAO methods that were modified, but don't need to be overridden
  //
  int compareTo(other) => other is LazyDAO
      ? _dao!=null && other._dao!=null
        ? dao.compareTo(other.dao)
        : uiName.compareTo(other.uiName)
      : other is DAO
        ? dao.compareTo(other)
        : -1;

  @override
  String toString() => _dao!=null ? dao.uiName : uiName;

  @override
  bool operator == (dynamic other) => (other is DAO)
      && (id==null
          ? hashCode==other.hashCode
          : (this.runtimeType==other.runtimeType && this.id==other.id));

  @override
  int get hashCode => _dao!=null ? dao.hashCode
      : originalModel==null ? identityHashCode(this) : (runtimeType.hashCode+originalModel.hashCode).hashCode;

  Future<ModelType?> save(context, {
    bool updateDbValuesAfterSuccessfulSave = true,
    bool showDefaultSnackBar = true,
    bool skipValidation = false,
  }) async {
    final result = await dao.save(context,
      updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
      showDefaultSnackBar: showDefaultSnackBar,
      skipValidation: skipValidation,
    );
    if (updateDbValuesAfterSuccessfulSave && result!=null) {
      originalModel = result;
    }
    return result;
  }

  void copyDaoWith({
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
    List<Widget> Function(BuildContext context, DAO dao)? viewDialogExtraActions,
    List<Widget> Function(BuildContext context, DAO dao)? formDialogExtraActions,
    bool? useIntrinsicHeightForViewDialog,
    bool? wantsLinkToSelfFromOtherDAOs,
    double? viewDialogWidth,
    double? formDialogWidth,
    bool? viewDialogLinksToInnerDAOs,
    bool? viewDialogShowsViewButtons,
    bool? viewDialogShowsEditButton,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    bool? showConfirmDialogWithBlockingErrors,
    DAO? parentDAO,
    DAOValueGetter<bool, ModelType>? enableDoubleColumnLayout,
    DAOValueGetter<String, ModelType>? searchNameGetter,
    DAOValueGetter<String, ModelType>? editDialogTitle,
    DAOValueGetter<String, ModelType>? saveConfirmationDialogTitle,
    DAOValueGetter<String, ModelType>? saveButtonTitle,
    DAOValueGetter<String, ModelType>? saveConfirmationDialogDescription,
  }) {
    _dao = dao.copyWith(
      id: id,
      classUiNameGetter: classUiNameGetter,
      fieldGroups: fieldGroups,
      classUiNamePluralGetter: classUiNamePluralGetter,
      uiNameGetter: uiNameGetter,
      onSave: onSave,
      onSaveAPI: onSaveAPI,
      onDidSave: onDidSave,
      onDelete: onDelete,
      onDeleteAPI: onDeleteAPI,
      onDidDelete: onDidDelete,
      viewWidgetBuilder: viewWidgetBuilder,
      viewDialogExtraActions: viewDialogExtraActions,
      formDialogExtraActions: formDialogExtraActions,
      useIntrinsicHeightForViewDialog: useIntrinsicHeightForViewDialog,
      viewDialogWidth: viewDialogWidth,
      formDialogWidth: formDialogWidth,
      viewDialogLinksToInnerDAOs: viewDialogLinksToInnerDAOs,
      viewDialogShowsViewButtons: viewDialogShowsViewButtons,
      viewDialogShowsEditButton: viewDialogShowsEditButton,
      wantsLinkToSelfFromOtherDAOs: wantsLinkToSelfFromOtherDAOs,
      undoRecord: undoRecord,
      redoRecord: redoRecord,
      showConfirmDialogWithBlockingErrors: showConfirmDialogWithBlockingErrors,
      parentDAO: parentDAO,
      enableDoubleColumnLayout: enableDoubleColumnLayout,
      searchNameGetter: searchNameGetter,
      editDialogTitle: editDialogTitle,
      saveConfirmationDialogTitle: saveConfirmationDialogTitle,
      saveButtonTitle: saveButtonTitle,
      saveConfirmationDialogDescription: saveConfirmationDialogDescription,
    );
  }


  // DAO fields, forwarded to it
  //
  bool get blockNotifyListeners => dao.blockNotifyListeners;
  set blockNotifyListeners(bool value) {
    dao.blockNotifyListeners = value;
  }
  DAOValueGetter<String, ModelType> get classUiNameGetter => dao.classUiNameGetter;
  set classUiNameGetter(DAOValueGetter<String, ModelType> value) {
    dao.classUiNameGetter = value;
  }
  DAOValueGetter<String, ModelType> get classUiNamePluralGetter => dao.classUiNamePluralGetter;
  set classUiNamePluralGetter(DAOValueGetter<String, ModelType> value) {
    dao.classUiNamePluralGetter = value;
  }
  BuildContext? get contextForValidation => dao.contextForValidation;
  set contextForValidation(BuildContext? value) {
    dao.contextForValidation = value;
  }
  DAOValueGetter<String, ModelType>? get editDialogTitle => dao.editDialogTitle;
  set editDialogTitle(DAOValueGetter<String, ModelType>? value) {
    dao.editDialogTitle = value;
  }
  DAOValueGetter<bool, ModelType>? get enableDoubleColumnLayout => dao.enableDoubleColumnLayout;
  set enableDoubleColumnLayout(DAOValueGetter<bool, ModelType>? value) {
    dao.enableDoubleColumnLayout = value;
  }
  bool get enableUndoRedoMechanism => dao.enableUndoRedoMechanism;
  set enableUndoRedoMechanism(bool value) {
    dao.enableUndoRedoMechanism = value;
  }
  List<FieldGroup> get fieldGroups => dao.fieldGroups;
  set fieldGroups(List<FieldGroup> value) {
    dao.fieldGroups = value;
  }
  List<Widget> Function(BuildContext context, DAO dao)? get formDialogExtraActions => dao.formDialogExtraActions;
  set formDialogExtraActions(List<Widget> Function(BuildContext context, DAO dao)? value) {
    dao.formDialogExtraActions = value;
  }
  double get formDialogWidth => dao.formDialogWidth;
  set formDialogWidth(double value) {
    dao.formDialogWidth = value;
  }
  dynamic get id => dao.id;
  set id(dynamic value) {
    dao.id = value;
  }
  OnDeleteCallback<ModelType>? get onDelete => dao.onDelete;
  set onDelete(OnDeleteCallback<ModelType>? value) {
    dao.onDelete = value;
  }
  OnDeleteAPICallback<ModelType>? get onDeleteAPI => dao.onDeleteAPI;
  set onDeleteAPI(OnDeleteAPICallback<ModelType>? value) {
    dao.onDeleteAPI = value;
  }
  OnDidDeleteCallback<ModelType>? get onDidDelete => dao.onDidDelete;
  set onDidDelete(OnDidDeleteCallback<ModelType>? value) {
    dao.onDidDelete = value;
  }
  OnDidSaveCallback<ModelType>? get onDidSave => dao.onDidSave;
  set onDidSave(OnDidSaveCallback<ModelType>? value) {
    dao.onDidSave = value;
  }
  OnSaveCallback<ModelType>? get onSave => dao.onSave;
  set onSave(OnSaveCallback<ModelType>? value) {
    dao.onSave = value;
  }
  OnSaveAPICallback<ModelType>? get onSaveAPI => dao.onSaveAPI;
  set onSaveAPI(OnSaveAPICallback<ModelType>? value) {
    dao.onSaveAPI = value;
  }
  DAO? get parentDAO => dao.parentDAO;
  set parentDAO(DAO? value) {
    dao.parentDAO = value;
  }
  DAOValueGetter<String, ModelType>? get saveButtonTitle => dao.saveButtonTitle;
  set saveButtonTitle(DAOValueGetter<String, ModelType>? value) {
    dao.saveButtonTitle = value;
  }
  DAOValueGetter<String, ModelType>? get saveConfirmationDialogDescription => dao.saveConfirmationDialogDescription;
  set saveConfirmationDialogDescription(DAOValueGetter<String, ModelType>? value) {
    dao.saveConfirmationDialogDescription = value;
  }
  DAOValueGetter<String, ModelType>? get saveConfirmationDialogTitle => dao.saveConfirmationDialogTitle;
  set saveConfirmationDialogTitle(DAOValueGetter<String, ModelType>? value) {
    dao.saveConfirmationDialogTitle = value;
  }
  DAOValueGetter<String, ModelType>? get searchNameGetter => dao.searchNameGetter;
  set searchNameGetter(DAOValueGetter<String, ModelType>? value) {
    dao.searchNameGetter = value;
  }
  bool get showConfirmDialogWithBlockingErrors => dao.showConfirmDialogWithBlockingErrors;
  set showConfirmDialogWithBlockingErrors(bool value) {
    dao.showConfirmDialogWithBlockingErrors = value;
  }
  DAOValueGetter<String, ModelType> get uiNameGetter => dao.uiNameGetter;
  set uiNameGetter(DAOValueGetter<String, ModelType> value) {
    dao.uiNameGetter = value;
  }
  bool get useIntrinsicHeightForViewDialog => dao.useIntrinsicHeightForViewDialog;
  set useIntrinsicHeightForViewDialog(bool value) {
    dao.useIntrinsicHeightForViewDialog = value;
  }
  int get validationCallCount => dao.validationCallCount;
  set validationCallCount(int value) {
    dao.validationCallCount = value;
  }
  List<Widget> Function(BuildContext context, DAO dao)? get viewDialogExtraActions => dao.viewDialogExtraActions;
  set viewDialogExtraActions(List<Widget> Function(BuildContext context, DAO dao)? value) {
    dao.viewDialogExtraActions = value;
  }
  bool get viewDialogLinksToInnerDAOs => dao.viewDialogLinksToInnerDAOs;
  set viewDialogLinksToInnerDAOs(bool value) {
    dao.viewDialogLinksToInnerDAOs = value;
  }
  bool? get viewDialogShowsEditButton => dao.viewDialogShowsEditButton;
  set viewDialogShowsEditButton(bool? value) {
    dao.viewDialogShowsEditButton = value;
  }
  bool get viewDialogShowsViewButtons => dao.viewDialogShowsViewButtons;
  set viewDialogShowsViewButtons(bool value) {
    dao.viewDialogShowsViewButtons = value;
  }
  double get viewDialogWidth => dao.viewDialogWidth;
  set viewDialogWidth(double value) {
    dao.viewDialogWidth = value;
  }
  DAOWidgetBuilder<ModelType>? get viewWidgetBuilder => dao.viewWidgetBuilder;
  set viewWidgetBuilder(DAOWidgetBuilder<ModelType>? value) {
    dao.viewWidgetBuilder = value;
  }
  bool get wantsLinkToSelfFromOtherDAOs => dao.wantsLinkToSelfFromOtherDAOs;
  set wantsLinkToSelfFromOtherDAOs(bool value) {
    dao.wantsLinkToSelfFromOtherDAOs = value;
  }


  // DAO methods, forwarded to it
  //
  bool get hasListeners => dao.hasListeners;
  bool get isEdited => dao.isEdited;
  bool get isNew => dao.isNew;
  Map<String, Field<Comparable>> get props => dao.props;
  List<ValidationError> get validationErrors => dao.validationErrors;
  void addListener(VoidCallback listener) => dao.addListener(listener);
  void addOnUpdate(ValueChanged<DAO> o) => dao.addOnUpdate(o);
  void addRedoEntry(Field<Comparable> field) => dao.addRedoEntry(field);
  void addUndoEntry(Field<Comparable> field, {bool clearRedo = true}) => dao.addUndoEntry(field, clearRedo: clearRedo);
  void applyDefaultValues(List<InvalidatingError<Comparable>> invalidatingErrors) => dao.applyDefaultValues(invalidatingErrors);
  void beginRedoTransaction() => dao.beginRedoTransaction();
  void beginUndoTransaction() => dao.beginUndoTransaction();
  void commitRedoTransaction() => dao.commitRedoTransaction();
  void commitUndoTransaction({bool clearRedo = true})  => dao.commitUndoTransaction();
  Future<bool> delete(context, {bool? showDefaultSnackBar}) => dao.delete(context, showDefaultSnackBar: showDefaultSnackBar);
  void dispose() => dao.dispose();
  void focusError(ValidationError error) => dao.focusError(error);
  void focusFirstBlockingError() => dao.focusFirstBlockingError();
  void fuseLastTwoUndoRecords() => dao.fuseLastTwoUndoRecords();
  Future<bool> maybeDelete(BuildContext context, {bool? showDefaultSnackBars}) => dao.maybeDelete(context, showDefaultSnackBars: showDefaultSnackBars);
  void maybeRevertChanges(BuildContext context)  => dao.maybeRevertChanges(context);
  void notifyListeners()  => dao.notifyListeners();
  void redo() => dao.redo();
  void removeAllRedoEntries(Field<Comparable> field) => dao.removeAllRedoEntries(field);
  void removeAllUndoEntries(Field<Comparable> field) => dao.removeAllUndoEntries(field);
  void removeLastRedoEntry(Field<Comparable> field) => dao.removeLastRedoEntry(field);
  void removeLastUndoEntry(Field<Comparable> field) => dao.removeLastUndoEntry(field);
  void removeListener(VoidCallback listener) => dao.removeListener(listener);
  bool removeOnUpdate(ValueChanged<DAO> o) => dao.removeOnUpdate(o);
  void revertChanges() => dao.revertChanges();
  void undo() => dao.undo();
  Future<bool> validate(context, {bool validateNonEditedFields = true}) => dao.validate(context, validateNonEditedFields: validateNonEditedFields);
  List<Widget> buildFormDialogDefaultActions(BuildContext context, {bool showUndoRedo = true,}) => dao.buildFormDialogDefaultActions(context, showUndoRedo: showUndoRedo);
  List<Widget> buildActionButtons(BuildContext context, {
    bool showRevertChanges = false,
    bool popAfterSuccessfulSave = true,
    bool showCancelActionToPop = false,
    bool showDefaultSnackBars = true,
    bool askForSaveConfirmation = true,
  }) {
    return dao.buildActionButtons(context,
      showRevertChanges: showRevertChanges,
      popAfterSuccessfulSave: popAfterSuccessfulSave,
      showCancelActionToPop: showCancelActionToPop,
      showDefaultSnackBars: showDefaultSnackBars,
      askForSaveConfirmation: askForSaveConfirmation,
    );
  }
  Widget buildEditModalWidget(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) {
    return dao.buildEditModalWidget(context,
      showDefaultSnackBars: showDefaultSnackBars,
      showRevertChanges: showRevertChanges,
      askForSaveConfirmation: askForSaveConfirmation,
      showUndoRedo: showUndoRedo,
    );
  }
  List<Widget> buildFormWidgets(BuildContext context, {
    Map<String, Field<Comparable>>? props,
    ScrollController? mainScrollController,
    bool asSlivers = true,
    bool showActionButtons = true,
    bool showRevertChanges = false,
    bool popAfterSuccessfulSave = true,
    bool showCancelActionToPop = false,
    bool expandToFillContainer = true,
    bool showDefaultSnackBars = true,
    bool askForSaveConfirmation = true,
    bool wrapInLayoutFromZeroItem = false,
    FocusNode? focusNode,
  }) {
    return dao.buildFormWidgets(context,
      props: props,
      mainScrollController: mainScrollController,
      asSlivers: asSlivers,
      showActionButtons: showActionButtons,
      showRevertChanges: showRevertChanges,
      popAfterSuccessfulSave: popAfterSuccessfulSave,
      showCancelActionToPop: showCancelActionToPop,
      expandToFillContainer: expandToFillContainer,
      showDefaultSnackBars: showDefaultSnackBars,
      askForSaveConfirmation: askForSaveConfirmation,
      wrapInLayoutFromZeroItem: wrapInLayoutFromZeroItem,
      focusNode: focusNode,
    );
  }
  Widget buildGroupWidget({
    required BuildContext context,
    required FieldGroup group,
    ScrollController? mainScrollController,
    bool showActionButtons = true,
    bool showRevertChanges = false,
    bool popAfterSuccessfulSave = true,
    bool showCancelActionToPop = false,
    bool expandToFillContainer = true,
    bool showDefaultSnackBars = true,
    bool askForSaveConfirmation = true,
    bool firstIteration = true,
    bool wrapInLayoutFromZeroItem = false,
    FocusNode? focusNode,
    int groupBorderNestingCount = 0,
  }) {
    return dao.buildGroupWidget(
      context: context,
      group: group,
      showDefaultSnackBars: showDefaultSnackBars,
      askForSaveConfirmation: askForSaveConfirmation,
      focusNode: focusNode,
      expandToFillContainer: expandToFillContainer,
      firstIteration: firstIteration,
      groupBorderNestingCount: groupBorderNestingCount,
      mainScrollController: mainScrollController,
      popAfterSuccessfulSave: popAfterSuccessfulSave,
      showActionButtons: showActionButtons,
      showCancelActionToPop: showCancelActionToPop,
      showRevertChanges: showRevertChanges,
      wrapInLayoutFromZeroItem: wrapInLayoutFromZeroItem,
    );
  }
  Widget buildViewWidget(BuildContext context, {
    List<FieldGroup>? fieldGroups,
    ScrollController? mainScrollController,
    bool? useIntrinsicWidth,
    bool? useIntrinsicHeight,
    int titleFlex = 1000000,
    int valueFlex = 1618034,
    double? titleMaxWidth,
    bool applyAlternateBackground = true,
  }) {
    return dao.buildViewWidget(context,
      mainScrollController: mainScrollController,
      applyAlternateBackground: applyAlternateBackground,
      fieldGroups: fieldGroups,
      titleFlex: titleFlex,
      titleMaxWidth: titleMaxWidth,
      useIntrinsicHeight: useIntrinsicHeight,
      useIntrinsicWidth: useIntrinsicWidth,
      valueFlex: valueFlex,
    );
  }
  Future<ModelType?> maybeEdit(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) {
    return dao.maybeEdit(context,
      showRevertChanges: showRevertChanges,
      askForSaveConfirmation: askForSaveConfirmation,
      showDefaultSnackBars: showDefaultSnackBars,
      showUndoRedo: showUndoRedo,
    );
  }
  Future pushViewDialog(BuildContext mainContext, {
    bool? showEditButton,
    bool? useIntrinsicWidth,
    bool? useIntrinsicHeight,
    bool showDefaultSnackBars = true,
  }) {
    return pushViewDialog(mainContext,
      showDefaultSnackBars: showDefaultSnackBars,
      useIntrinsicWidth: useIntrinsicWidth,
      useIntrinsicHeight: useIntrinsicHeight,
      showEditButton: showEditButton,
    );
  }
  Future<ModelType?> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave = true,
    bool showDefaultSnackBars = true,
    bool askForSaveConfirmation = true,
  }) {
    return dao.maybeSave(context,
      showDefaultSnackBars: showDefaultSnackBars,
      askForSaveConfirmation: askForSaveConfirmation,
      updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
    );
  }


}

