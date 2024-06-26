part of 'dao.dart';


enum DAOBuildLogType {
  none,
  simple,
  fullStackTrace,
}

/// receives a model and a function to turn it into a DAO, only calls said function when necessary
abstract class LazyDAO<ModelType> extends DAO<ModelType> {

  ModelType? originalModel;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  void ensureInitialized()  {
    if (!isInitialized) {
      buildDAO();
      try {
        log(LgLvl.finer, 'Building dao $runtimeType: $classUiName -- $uiName', type: FzLgType.dao);
      } catch(e, st) {
        log(LgLvl.finer, 'Building dao: Error logging name $runtimeType', e: e, st: st, type: FzLgType.dao);
      }
    }
  }

  @override
  dynamic get id => isInitialized ? super.id :
      originalModel==null ? null
          : originalModel is int ? originalModel
          : (originalModel as dynamic).id;


  LazyDAO(this.originalModel) : super._uninitialized();
  
  void initialize({
    required DAOValueGetter<String, ModelType> classUiNameGetter,
    required DAOValueGetter<String, ModelType> uiNameGetter,
    DAOValueGetter<String, ModelType>? classUiNamePluralGetter,
    DAOValueGetter<String, ModelType>? uiNameDenseGetter,
    dynamic id,
    List<FieldGroup> fieldGroups = const [],
    OnSaveCallback<ModelType>? onSave,
    OnSaveAPICallback<ModelType>? onSaveAPI,
    OnDidSaveCallback<ModelType>? onDidSave,
    OnDeleteCallback<ModelType>? onDelete,
    OnDeleteAPICallback<ModelType>? onDeleteAPI,
    OnDidDeleteCallback<ModelType>? onDidDelete,
    DAOWidgetBuilder<ModelType>? viewWidgetBuilder,
    List<Widget> Function(BuildContext context, DAO dao)? viewDialogExtraActions,
    List<Widget> Function(BuildContext context, DAO dao)? formDialogExtraActions,
    bool useIntrinsicHeightForViewDialog = true,
    double viewDialogWidth = 512,
    double formDialogWidth = 512,
    bool viewDialogLinksToInnerDAOs = true,
    bool viewDialogShowsViewButtons = false,
    bool? viewDialogShowsEditButton,
    bool? viewDialogShowsDeleteButton,
    bool wantsLinkToSelfFromOtherDAOs = true,
    List<List<Field>>? undoRecord,
    List<List<Field>>? redoRecord,
    bool enableUndoRedoMechanism = true,
    bool showConfirmDialogWithBlockingErrors = true,
    // DAO? parentDAO,  // i don't see the case where .initialize() will need to set parrent DAO, and removing it allows for better performance, by not having to force initialization when parentDAO set
    DAOValueGetter<DoubleColumnLayoutType, ModelType>? enableDoubleColumnLayout,
    DAOValueGetter<String, ModelType>? searchNameGetter,
    DAOValueGetter<String, ModelType>?  editDialogTitle,
    DAOValueGetter<String, ModelType>?  saveConfirmationDialogTitle,
    DAOValueGetter<String, ModelType>?  saveButtonTitle,
    DAOValueGetter<Widget, ModelType>?  saveConfirmationDialogDescription,
  }) {
    // assert(!_isInitialized, 'Attempted to initialize DAO twice: ${this.runtimeType}: ${this.classUiName}');
    _isInitialized = true;
    this.classUiNameGetter = classUiNameGetter;
    this.uiNameGetter = uiNameGetter;
    this.uiNameDenseGetter = uiNameDenseGetter;
    this.id = id;
    this.fieldGroups = fieldGroups;
    this.onSave = onSave;
    this.onSaveAPI = onSaveAPI;
    this.onDidSave = onDidSave;
    this.onDelete = onDelete;
    this.onDeleteAPI = onDeleteAPI;
    this.onDidDelete = onDidDelete;
    this.viewWidgetBuilder = viewWidgetBuilder;
    this.viewDialogExtraActions = viewDialogExtraActions;
    this.formDialogExtraActions = formDialogExtraActions;
    this.viewDialogWidth = viewDialogWidth;
    this.formDialogWidth = formDialogWidth;
    this.viewDialogLinksToInnerDAOs = viewDialogLinksToInnerDAOs;
    this.viewDialogShowsViewButtons = viewDialogShowsViewButtons;
    this.viewDialogShowsEditButton = viewDialogShowsEditButton;
    this.viewDialogShowsDeleteButton = viewDialogShowsDeleteButton;
    this.wantsLinkToSelfFromOtherDAOs = wantsLinkToSelfFromOtherDAOs;
    this.enableUndoRedoMechanism = enableUndoRedoMechanism;
    this.showConfirmDialogWithBlockingErrors = showConfirmDialogWithBlockingErrors;
    // this.parentDAO = parentDAO;
    doubleColumnLayoutType = enableDoubleColumnLayout;
    this.searchNameGetter = searchNameGetter;
    this.editDialogTitle = editDialogTitle;
    this.saveConfirmationDialogTitle = saveConfirmationDialogTitle;
    this.saveButtonTitle = saveButtonTitle;
    this.saveConfirmationDialogDescription = saveConfirmationDialogDescription;
    _undoRecord = undoRecord ?? [];
    _redoRecord = redoRecord ?? [];
    this.classUiNamePluralGetter = classUiNamePluralGetter ?? classUiNameGetter;
    props.forEach((key, value) {
      value.dao = this;
      value.addListener(notifyListeners);
    });
    addListener(() {
      for (final element in _selfUpdateListeners) {
        element(this);
      }
    });
  }


  // functions required to be overriden
  //
  void buildDAO();

  @override
  LazyDAO<ModelType> copyWith({ // force child classes to override copyWith
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
    bool? useIntrinsicHeightForViewDialog,
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
    final result = copyWithLazyData();
    if (id!=null
        || classUiNameGetter!=null
        || classUiNamePluralGetter!=null
        || uiNameGetter!=null
        || uiNameDenseGetter!=null
        || fieldGroups!=null
        || onSave!=null
        || onSaveAPI!=null
        || onDidSave!=null
        || onDelete!=null
        || onDeleteAPI!=null
        || onDidDelete!=null
        || viewWidgetBuilder!=null
        || viewDialogExtraActions!=null
        || formDialogExtraActions!=null
        || useIntrinsicHeightForViewDialog!=null
        || wantsLinkToSelfFromOtherDAOs!=null
        || viewDialogWidth!=null
        || formDialogWidth!=null
        || viewDialogLinksToInnerDAOs!=null
        || viewDialogShowsViewButtons!=null
        || viewDialogShowsEditButton!=null
        || viewDialogShowsDeleteButton!=null
        || undoRecord!=null
        || redoRecord!=null
        || showConfirmDialogWithBlockingErrors!=null
        || parentDAO!=null
        || enableDoubleColumnLayout!=null
        || searchNameGetter!=null
        || editDialogTitle!=null
        || saveConfirmationDialogTitle!=null
        || saveButtonTitle!=null
        || saveConfirmationDialogDescription!=null) {
      ensureInitialized();
    }
    if (isInitialized) {
      result.initialize(
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
        // undoRecord: undoRecord??this._undoRecord, // cannot reach _undoRecord and _redoRecord since they're private, surely its fine :)
        // redoRecord: redoRecord??this._redoRecord,
        showConfirmDialogWithBlockingErrors: showConfirmDialogWithBlockingErrors??this.showConfirmDialogWithBlockingErrors,
        // parentDAO: parentDAO??this.parentDAO,
        enableDoubleColumnLayout: enableDoubleColumnLayout??doubleColumnLayoutType,
        searchNameGetter: searchNameGetter ?? this.searchNameGetter,
        editDialogTitle: editDialogTitle ?? this.editDialogTitle,
        saveConfirmationDialogTitle: saveConfirmationDialogTitle ?? this.saveConfirmationDialogTitle,
        saveButtonTitle: saveButtonTitle ?? this.saveButtonTitle,
        saveConfirmationDialogDescription: saveConfirmationDialogDescription ?? this.saveConfirmationDialogDescription,
      );
    }
    return result;
  }
  LazyDAO<ModelType> copyWithLazyData();


  // DAO methods that should be overriden, to delay build as much as possible
  //
  /// @mustOverride
  @override
  String get classUiName;
  /// @mustOverride
  @override
  String get uiName;
  /// @mustOverride
  @override
  bool get wantsLinkToSelfFromOtherDAOs {
    ensureInitialized();
    return super.wantsLinkToSelfFromOtherDAOs;
  }
  @override
  set wantsLinkToSelfFromOtherDAOs(bool value) {
    ensureInitialized();
    super.wantsLinkToSelfFromOtherDAOs = value;
  }
  /// @mustOverride ???
  @override
  bool get canSave {
    ensureInitialized();
    return super.canSave;
  }
  /// @mustOverride ???
  @override
  bool get canDelete {
    ensureInitialized();
    return super.canDelete;
  }


  // DAO methods that should be overriden if also changed in dao
  //
  /// @mustOverride
  @override
  String get classUiNamePlural {
    try {
      return super.classUiNamePlural;
    } catch (e) {
      assert(isInitialized, 'classUiNamePlural called without initializing DAO: $runtimeType: ${this.classUiName}');
      rethrow;
    }
  }
  /// @mustOverride
  @override
  String get searchName {
    try {
      return super.searchName;
    } catch (e) {
      assert(isInitialized, 'searchName called without initializing DAO: $runtimeType: ${this.classUiName}');
      rethrow;
    }
  }


  // DAO methods that were modified, but don't need to be overridden
  //
  @override
  Future<ModelType?> save(context, {
    bool updateDbValuesAfterSuccessfulSave = true,
    bool showDefaultSnackBar = true,
    bool? snackBarCancellable,
    bool skipValidation = false,
  }) async {
    ensureInitialized();
    final result = await super.save(context,
      updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
      showDefaultSnackBar: showDefaultSnackBar,
      snackBarCancellable: snackBarCancellable,
      skipValidation: skipValidation,
    );
    if (updateDbValuesAfterSuccessfulSave && result!=null) {
      originalModel = result;
    }
    return result;
  }


  // DAO fields, forwarded to it
  //
  // bool get blockNotifyListeners => super.blockNotifyListeners;
  // set blockNotifyListeners(bool value) {
  //   super.blockNotifyListeners = value;
  // }
  // DAOValueGetter<String, ModelType> get classUiNameGetter => super.classUiNameGetter;
  // set classUiNameGetter(DAOValueGetter<String, ModelType> value) {
  //   super.classUiNameGetter = value;
  // }
  // DAOValueGetter<String, ModelType> get classUiNamePluralGetter => super.classUiNamePluralGetter;
  // set classUiNamePluralGetter(DAOValueGetter<String, ModelType> value) {
  //   super.classUiNamePluralGetter = value;
  // }
  // BuildContext? get contextForValidation => super.contextForValidation;
  // set contextForValidation(BuildContext? value) {
  //   super.contextForValidation = value;
  // }
  // DAOValueGetter<String, ModelType>? get editDialogTitle => super.editDialogTitle;
  // set editDialogTitle(DAOValueGetter<String, ModelType>? value) {
  //   super.editDialogTitle = value;
  // }
  // DAOValueGetter<DoubleColumnLayout, ModelType>? get enableDoubleColumnLayout => super.enableDoubleColumnLayout;
  // set enableDoubleColumnLayout(DAOValueGetter<DoubleColumnLayout, ModelType>? value) {
  //   super.enableDoubleColumnLayout = value;
  // }
  // bool get enableUndoRedoMechanism => super.enableUndoRedoMechanism;
  // set enableUndoRedoMechanism(bool value) {
  //   super.enableUndoRedoMechanism = value;
  // }
  @override
  List<FieldGroup> get fieldGroups {
    ensureInitialized();
    return super.fieldGroups;
  }
  @override
  set fieldGroups(List<FieldGroup> value) {
    ensureInitialized();
    super.fieldGroups = value;
  }
  // List<Widget> Function(BuildContext context, DAO dao)? get formDialogExtraActions => super.formDialogExtraActions;
  // set formDialogExtraActions(List<Widget> Function(BuildContext context, DAO dao)? value) {
  //   super.formDialogExtraActions = value;
  // }
  // double get formDialogWidth => super.formDialogWidth;
  // set formDialogWidth(double value) {
  //   super.formDialogWidth = value;
  // }
  // dynamic get id => super.id;
  // set id(dynamic value) {
  //   super.id = value;
  // }
  // OnDeleteCallback<ModelType>? get onDelete => super.onDelete;
  // set onDelete(OnDeleteCallback<ModelType>? value) {
  //   super.onDelete = value;
  // }
  // OnDeleteAPICallback<ModelType>? get onDeleteAPI => super.onDeleteAPI;
  // set onDeleteAPI(OnDeleteAPICallback<ModelType>? value) {
  //   super.onDeleteAPI = value;
  // }
  // OnDidDeleteCallback<ModelType>? get onDidDelete => super.onDidDelete;
  // set onDidDelete(OnDidDeleteCallback<ModelType>? value) {
  //   super.onDidDelete = value;
  // }
  // OnDidSaveCallback<ModelType>? get onDidSave => super.onDidSave;
  // set onDidSave(OnDidSaveCallback<ModelType>? value) {
  //   super.onDidSave = value;
  // }
  // OnSaveCallback<ModelType>? get onSave => super.onSave;
  // set onSave(OnSaveCallback<ModelType>? value) {
  //   super.onSave = value;
  // }
  // OnSaveAPICallback<ModelType>? get onSaveAPI => super.onSaveAPI;
  // set onSaveAPI(OnSaveAPICallback<ModelType>? value) {
  //   super.onSaveAPI = value;
  // }
  // DAO? get parentDAO {
  //   ensureInitialized();
  //   return super.parentDAO;
  // }
  // set parentDAO(DAO? value) {
  //   ensureInitialized();  // we dont need to ensure initialization when parentDAO is set, because the argument was removed from initialize(), so it won't be overriden
  //   super.parentDAO = value;
  // }
  // DAOValueGetter<String, ModelType>? get saveButtonTitle => super.saveButtonTitle;
  // set saveButtonTitle(DAOValueGetter<String, ModelType>? value) {
  //   super.saveButtonTitle = value;
  // }
  // DAOValueGetter<String, ModelType>? get saveConfirmationDialogDescription => super.saveConfirmationDialogDescription;
  // set saveConfirmationDialogDescription(DAOValueGetter<String, ModelType>? value) {
  //   super.saveConfirmationDialogDescription = value;
  // }
  // DAOValueGetter<String, ModelType>? get saveConfirmationDialogTitle => super.saveConfirmationDialogTitle;
  // set saveConfirmationDialogTitle(DAOValueGetter<String, ModelType>? value) {
  //   super.saveConfirmationDialogTitle = value;
  // }
  // DAOValueGetter<String, ModelType>? get searchNameGetter => super.searchNameGetter;
  // set searchNameGetter(DAOValueGetter<String, ModelType>? value) {
  //   super.searchNameGetter = value;
  // }
  // bool get showConfirmDialogWithBlockingErrors => super.showConfirmDialogWithBlockingErrors;
  // set showConfirmDialogWithBlockingErrors(bool value) {
  //   super.showConfirmDialogWithBlockingErrors = value;
  // }
  // DAOValueGetter<String, ModelType> get uiNameGetter => super.uiNameGetter;
  // set uiNameGetter(DAOValueGetter<String, ModelType> value) {
  //   super.uiNameGetter = value;
  // }
  // bool get useIntrinsicHeightForViewDialog => super.useIntrinsicHeightForViewDialog;
  // set useIntrinsicHeightForViewDialog(bool value) {
  //   super.useIntrinsicHeightForViewDialog = value;
  // }
  // int get validationCallCount => super.validationCallCount;
  // set validationCallCount(int value) {
  //   super.validationCallCount = value;
  // }
  // List<Widget> Function(BuildContext context, DAO dao)? get viewDialogExtraActions => super.viewDialogExtraActions;
  // set viewDialogExtraActions(List<Widget> Function(BuildContext context, DAO dao)? value) {
  //   super.viewDialogExtraActions = value;
  // }
  // bool get viewDialogLinksToInnerDAOs => super.viewDialogLinksToInnerDAOs;
  // set viewDialogLinksToInnerDAOs(bool value) {
  //   super.viewDialogLinksToInnerDAOs = value;
  // }
  // bool? get viewDialogShowsEditButton => super.viewDialogShowsEditButton;
  // set viewDialogShowsEditButton(bool? value) {
  //   super.viewDialogShowsEditButton = value;
  // }
  // bool get viewDialogShowsViewButtons => super.viewDialogShowsViewButtons;
  // set viewDialogShowsViewButtons(bool value) {
  //   super.viewDialogShowsViewButtons = value;
  // }
  // double get viewDialogWidth => super.viewDialogWidth;
  // set viewDialogWidth(double value) {
  //   super.viewDialogWidth = value;
  // }
  // DAOWidgetBuilder<ModelType>? get viewWidgetBuilder => super.viewWidgetBuilder;
  // set viewWidgetBuilder(DAOWidgetBuilder<ModelType>? value) {
  //   super.viewWidgetBuilder = value;
  // }


  // DAO methods, forwarded to it
  //
  // bool get hasListeners => super.hasListeners;
  // bool get isEdited => super.isEdited;
  // bool get isNew => super.isNew;
  // Map<String, Field<Comparable>> get props => super.props;
  // List<ValidationError> get validationErrors => super.validationErrors;
  // void addListener(VoidCallback listener) => super.addListener(listener);
  // void addOnUpdate(ValueChanged<DAO> o) => super.addOnUpdate(o);
  // void addRedoEntry(Field<Comparable> field) => super.addRedoEntry(field);
  // void addUndoEntry(Field<Comparable> field, {bool clearRedo = true}) => super.addUndoEntry(field, clearRedo: clearRedo);
  // void applyDefaultValues(List<InvalidatingError<Comparable>> invalidatingErrors) => super.applyDefaultValues(invalidatingErrors);
  // void beginRedoTransaction() => super.beginRedoTransaction();
  // void beginUndoTransaction() => super.beginUndoTransaction();
  // void commitRedoTransaction() => super.commitRedoTransaction();
  // void commitUndoTransaction({bool clearRedo = true})  => super.commitUndoTransaction();
  @override
  Future<bool> delete(context, {bool? showDefaultSnackBar}) {
    ensureInitialized();
    return super.delete(context, showDefaultSnackBar: showDefaultSnackBar);
  }
  // void dispose() => super.dispose();
  // void focusError(ValidationError error) => super.focusError(error);
  // void focusFirstBlockingError() => super.focusFirstBlockingError();
  // void fuseLastTwoUndoRecords() => super.fuseLastTwoUndoRecords();
  @override
  Future<bool> maybeDelete(BuildContext context, {bool? showDefaultSnackBars}) {
    ensureInitialized();
    return super.maybeDelete(context, showDefaultSnackBars: showDefaultSnackBars);
  }
  // void maybeRevertChanges(BuildContext context)  => super.maybeRevertChanges(context);
  // void notifyListeners()  => super.notifyListeners();
  // void redo() => super.redo();
  // void removeAllRedoEntries(Field<Comparable> field) => super.removeAllRedoEntries(field);
  // void removeAllUndoEntries(Field<Comparable> field) => super.removeAllUndoEntries(field);
  // void removeLastRedoEntry(Field<Comparable> field) => super.removeLastRedoEntry(field);
  // void removeLastUndoEntry(Field<Comparable> field) => super.removeLastUndoEntry(field);
  // void removeListener(VoidCallback listener) => super.removeListener(listener);
  // bool removeOnUpdate(ValueChanged<DAO> o) => super.removeOnUpdate(o);
  // void revertChanges() => super.revertChanges();
  // void undo() => super.undo();
  // Future<bool> validate(context, {bool validateNonEditedFields = true}) => super.validate(context, validateNonEditedFields: validateNonEditedFields);
  // List<Widget> buildFormDialogDefaultActions(BuildContext context, {bool showUndoRedo = true,}) => super.buildFormDialogDefaultActions(context, showUndoRedo: showUndoRedo);
  // List<Widget> buildActionButtons(BuildContext context, {
  //   bool showRevertChanges = false,
  //   bool popAfterSuccessfulSave = true,
  //   bool showCancelActionToPop = false,
  //   bool showDefaultSnackBars = true,
  //   bool askForSaveConfirmation = true,
  // }) {
  //   ensureInitialized();
  //   return super.buildActionButtons(context,
  //     showRevertChanges: showRevertChanges,
  //     popAfterSuccessfulSave: popAfterSuccessfulSave,
  //     showCancelActionToPop: showCancelActionToPop,
  //     showDefaultSnackBars: showDefaultSnackBars,
  //     askForSaveConfirmation: askForSaveConfirmation,
  //   );
  // }
  @override
  Widget buildEditModalWidget(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) {
    ensureInitialized();
    return super.buildEditModalWidget(context,
      showDefaultSnackBars: showDefaultSnackBars,
      showRevertChanges: showRevertChanges,
      askForSaveConfirmation: askForSaveConfirmation,
      showUndoRedo: showUndoRedo,
    );
  }
  @override
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
    ensureInitialized();
    return super.buildFormWidgets(context,
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
  @override
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
    ensureInitialized();
    return super.buildGroupWidget(
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
  @override
  Widget buildViewWidget(BuildContext context, {
    List<FieldGroup>? fieldGroups,
    ScrollController? mainScrollController,
    bool? useIntrinsicWidth,
    bool? useIntrinsicHeight,
    int titleFlex = 1000000,
    int valueFlex = 1618034,
    double? titleMaxWidth,
    bool applyAlternateBackground = true,
    bool initialAlternateBackground = false,
  }) {
    ensureInitialized();
    return super.buildViewWidget(context,
      mainScrollController: mainScrollController,
      applyAlternateBackground: applyAlternateBackground,
      initialAlternateBackground: initialAlternateBackground,
      fieldGroups: fieldGroups,
      titleFlex: titleFlex,
      titleMaxWidth: titleMaxWidth,
      useIntrinsicWidth: useIntrinsicWidth,
      valueFlex: valueFlex,
    );
  }
  @override
  Future<ModelType?> maybeEdit(BuildContext context, {
    bool showDefaultSnackBars = true,
    bool showRevertChanges = false,
    bool? askForSaveConfirmation,
    bool showUndoRedo = true,
  }) {
    ensureInitialized();
    return super.maybeEdit(context,
      showRevertChanges: showRevertChanges,
      askForSaveConfirmation: askForSaveConfirmation,
      showDefaultSnackBars: showDefaultSnackBars,
      showUndoRedo: showUndoRedo,
    );
  }
  @override
  Future pushViewDialog(BuildContext mainContext, {
    bool? showEditButton,
    bool? showDeleteButton,
    bool? useIntrinsicWidth,
    bool? useIntrinsicHeight,
    bool showDefaultSnackBars = true,
  }) {
    ensureInitialized();
    return super.pushViewDialog(mainContext,
      showDefaultSnackBars: showDefaultSnackBars,
      useIntrinsicWidth: useIntrinsicWidth,
      showEditButton: showEditButton,
      showDeleteButton: showDeleteButton,
    );
  }
  @override
  Future<ModelType?> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave = true,
    bool showDefaultSnackBars = true,
    bool? snackBarCancellable,
    bool askForSaveConfirmation = true,
    bool skipValidation = false,
  }) {
    ensureInitialized();
    return super.maybeSave(context,
      showDefaultSnackBars: showDefaultSnackBars,
      snackBarCancellable: snackBarCancellable,
      askForSaveConfirmation: askForSaveConfirmation,
      updateDbValuesAfterSuccessfulSave: updateDbValuesAfterSuccessfulSave,
      skipValidation: skipValidation,
    );
  }


}

