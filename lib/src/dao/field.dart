part of 'dao.dart';


typedef FutureOr<ValidationError?> FieldValidator<T extends Comparable>(BuildContext context, DAO dao, Field<T> field);
typedef T FieldValueGetter<T, R extends Field>(R field, DAO dao);
typedef T ContextFulFieldValueGetter<T, R extends Field>(BuildContext context, R field, DAO dao);
typedef void OnFieldValueChanged<T>(DAO dao, Field field, T value);
typedef Widget ViewWidgetBuilder<T extends Comparable>(BuildContext context, Field<T> field, {bool linkToInnerDAOs, bool showViewButtons, bool dense, bool? hidden});
bool trueFieldGetter(_, __) => true;
bool falseFieldGetter(_, __) => false;
List defaultValidatorsGetter(_, __) => [];

class Field<T extends Comparable> extends ChangeNotifier implements Comparable, ContainsValue<T> {

  late DAO dao;
  FieldValueGetter<String, Field> uiNameGetter;
  String get uiName => uiNameGetter(this, dao);
  FieldValueGetter<String?, Field>? hintGetter;
  String? get hint => hintGetter?.call(this, dao);
  FieldValueGetter<String?, Field>? tooltipGetter;
  String? get tooltip => tooltipGetter?.call(this, dao);
  T? dbValue;
  T? defaultValue; /// used for reversing the field to default state when hidden, noly if invalidateNonEmptyValuesIfHiddenInForm==true, default null
  FieldValueGetter<bool, Field> clearableGetter;
  bool get clearable => clearableGetter(this, dao);
  bool get enabled => DAO.ignoreBlockingErrors
      ? true
      : validationErrors.where((e) => e.severity==ValidationErrorSeverity.disabling || e.severity==ValidationErrorSeverity.invalidating).isEmpty;
  FieldValueGetter<bool, Field> hiddenInTableGetter;
  bool get hiddenInTable => hiddenInTableGetter(this, dao);
  FieldValueGetter<bool, Field> hiddenInViewGetter;
  bool get hiddenInView => hiddenInViewGetter(this, dao);
  FieldValueGetter<bool, Field> hiddenInFormGetter;
  bool get hiddenInForm => hiddenInFormGetter(this, dao);
  double maxWidth;
  double minWidth;
  /// only used when using FlexibleLayoutFromZero for FieldGroup
  double flex;
  double? tableColumnWidth;
  FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter;
  List<FieldValidator<T>> get validators => validatorsGetter?.call(this, dao) ?? [];
  bool validateOnlyOnConfirm;
  bool passedFirstEdit = false;
  bool userInteracted = false;
  bool isRequired = false;
  List<ValidationError> validationErrors = [];
  FieldValueGetter<SimpleColModel, Field> colModelBuilder;
  bool invalidateNonEmptyValuesIfHiddenInForm;
  ContextFulFieldValueGetter<Color?, Field>? backgroundColor;
  ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter;
  List<ActionFromZero> buildActions(BuildContext context, FocusNode? focusNode) {
    return actionsGetter?.call(dao.contextForValidation ?? context, this, dao).map((e) {
      return e.copyWith(
        onTap: e.onTap==null ? null : (context) {
          userInteracted = true;
          focusNode?.requestFocus();
          e.onTap!(context);
        },
      );
    }).toList() ?? [];
  }
  ViewWidgetBuilder<T> viewWidgetBuilder;
  OnFieldValueChanged<T?>? onValueChanged;
  FocusNode? _focusNode;
  FocusNode get focusNode {
    _focusNode ??= FocusNode();
    return _focusNode!;
  }
  GlobalKey? _fieldGlobalKey;
  GlobalKey get fieldGlobalKey {
    _fieldGlobalKey ??= GlobalKey();
    return _fieldGlobalKey!;
  }

  T? _value;
  T? get value => _value;
  @mustCallSuper
  set value(T? value) {
    if (_value!=value) {
      passedFirstEdit = true;
      addUndoEntry(_value);
      _value = value;
      if (dao.contextForValidation!=null) {
        dao.validate(dao.contextForValidation!,
          validateNonEditedFields: false,
        );
      }
      onValueChanged?.call(dao, this, _value);
      notifyListeners();
    }
  }
  void addUndoEntry(T? value) {
    if (undoValues.isEmpty || undoValues.last!=value) {
      undoValues.add(value);
      dao.addUndoEntry(this);
      redoValues = [];
    }
  }
  List<T?> undoValues;
  List<T?> redoValues;

  Field({
    required this.uiNameGetter,
    T? value,
    T? dbValue,
    this.clearableGetter = Field.defaultClearableGetter,
    this.maxWidth = 512,
    this.minWidth = 128,
    this.flex = 0,
    this.hintGetter,
    this.tooltipGetter,
    this.tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    this.validatorsGetter,
    this.validateOnlyOnConfirm = false,
    GlobalKey? fieldGlobalKey,
    FocusNode? focusNode,
    this.colModelBuilder = fieldDefaultGetColumn,
    List<T?>? undoValues,
    List<T?>? redoValues,
    this.invalidateNonEmptyValuesIfHiddenInForm = true,
    this.defaultValue,
    this.backgroundColor,
    this.actionsGetter,
    this.viewWidgetBuilder = Field.defaultViewWidgetBuilder,
    this.onValueChanged,
  }) :  this._value = value,
        this.dbValue = dbValue ?? value,
        this.undoValues = undoValues ?? [],
        this.redoValues = redoValues ?? [],
        this._fieldGlobalKey = fieldGlobalKey,
        this._focusNode = focusNode,
        this.hiddenInTableGetter = hiddenInTableGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInViewGetter = hiddenInViewGetter ?? hiddenGetter ?? falseFieldGetter,
        this.hiddenInFormGetter = hiddenInFormGetter ?? hiddenGetter ?? falseFieldGetter;

  Field<T> copyWith({
    FieldValueGetter<String, Field>? uiNameGetter,
    T? value,
    T? dbValue,
    FieldValueGetter<bool, Field>? clearableGetter,
    double? maxWidth,
    double? minWidth,
    double? flex,
    FieldValueGetter<String?, Field>? hintGetter,
    FieldValueGetter<String?, Field>? tooltipGetter,
    double? tableColumnWidth,
    FieldValueGetter<bool, Field>? hiddenGetter,
    FieldValueGetter<bool, Field>? hiddenInTableGetter,
    FieldValueGetter<bool, Field>? hiddenInViewGetter,
    FieldValueGetter<bool, Field>? hiddenInFormGetter,
    FieldValueGetter<List<FieldValidator<T>>, Field>? validatorsGetter,
    bool? validateOnlyOnConfirm,
    FieldValueGetter<SimpleColModel, Field>? colModelBuilder,
    List<T?>? undoValues,
    List<T?>? redoValues,
    bool? invalidateNonEmptyValuesIfHiddenInForm,
    T? defaultValue,
    ContextFulFieldValueGetter<Color?, Field>? backgroundColor,
    ContextFulFieldValueGetter<List<ActionFromZero>, Field>? actionsGetter,
    ViewWidgetBuilder<T>? viewWidgetBuilder,
    OnFieldValueChanged<T?>? onValueChanged,
  }) {
    return Field<T>(
      uiNameGetter: uiNameGetter??this.uiNameGetter,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      clearableGetter: clearableGetter??this.clearableGetter,
      maxWidth: maxWidth??this.maxWidth,
      minWidth: minWidth??this.minWidth,
      flex: flex??this.flex,
      hintGetter: hintGetter??this.hintGetter,
      tooltipGetter: tooltipGetter??this.tooltipGetter,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTableGetter: hiddenInTableGetter ?? hiddenGetter ?? this.hiddenInTableGetter,
      hiddenInViewGetter: hiddenInViewGetter ?? hiddenGetter ?? this.hiddenInViewGetter,
      hiddenInFormGetter: hiddenInFormGetter ?? hiddenGetter ?? this.hiddenInFormGetter,
      validatorsGetter: validatorsGetter ?? this.validatorsGetter,
      validateOnlyOnConfirm: validateOnlyOnConfirm ?? this.validateOnlyOnConfirm,
      colModelBuilder: colModelBuilder ?? this.colModelBuilder,
      undoValues: undoValues ?? List.from(this.undoValues),
      redoValues: redoValues ?? List.from(this.redoValues),
      invalidateNonEmptyValuesIfHiddenInForm: invalidateNonEmptyValuesIfHiddenInForm ?? this.invalidateNonEmptyValuesIfHiddenInForm,
      defaultValue: defaultValue ?? this.defaultValue,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actionsGetter: actionsGetter ?? this.actionsGetter,
      viewWidgetBuilder: viewWidgetBuilder ?? this.viewWidgetBuilder,
      onValueChanged: onValueChanged ?? this.onValueChanged,
    );
  }

  @override
  String toString() => value==null ? '' : value.toString();

  @override
  bool operator == (dynamic other) => other is Field<T> && this.value==other.value;

  @override
  int get hashCode => value.hashCode;

  bool get isEdited => value!=dbValue;

  @override
  int compareTo(other) => other is Field ? value==null||(value is String && (value as String).isEmpty) ? 1 : other.value==null ? -1 : value!.compareTo(other.value) : 1;

  void revertChanges() {
    _value = dbValue;
    undoValues.clear();
    dao.removeAllUndoEntries(this);
    redoValues.clear();
    dao.removeAllRedoEntries(this);
    notifyListeners();
  }

  void undo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    commitUndo(value,
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
  }
  void commitUndo(T? currentValue, {
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    assert(undoValues.isNotEmpty);
    redoValues.add(currentValue);
    dao.addRedoEntry(this);
    _value = undoValues.removeLast();
    if (removeEntryFromDAO) {
      dao.removeLastUndoEntry(this);
    }
    if (requestFocus) {
      this.requestFocus();
    }
    notifyListeners();
  }

  void redo({
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    commitRedo(value,
      removeEntryFromDAO: removeEntryFromDAO,
      requestFocus: requestFocus,
    );
  }
  void commitRedo(T? currentValue, {
    bool removeEntryFromDAO = false,
    bool requestFocus = true,
  }) {
    assert(redoValues.isNotEmpty);
    undoValues.add(currentValue);
    dao.addUndoEntry(this);
    _value = redoValues.removeLast();
    if (removeEntryFromDAO) {
      dao.removeLastRedoEntry(this);
    }
    if (requestFocus) {
      this.requestFocus();
    }
    notifyListeners();
  }

  Future<bool> validate(BuildContext context, DAO dao, int currentValidationId, {
    bool validateIfNotEdited=false,
    bool validateIfHidden=false,
  }) async {
    validationErrors = [];
    if (dao.parentDAO==null ? hiddenInForm : hiddenInTable) {
      if (invalidateNonEmptyValuesIfHiddenInForm && value!=defaultValue) {
        validationErrors.add(InvalidatingError(
          field: this,
          error: uiName + ' ' + FromZeroLocalizations.of(context).translate("validation_combo_hidden_with_value"),
          defaultValue: defaultValue,
        ));
      }
      if (!validateIfHidden) {
        return validationErrors.where((e) => e.isBlocking).isEmpty;
      }
    }
    if (validateIfNotEdited) {
      passedFirstEdit = true;
    }
    validationErrors = await _getValidationErrors<T>(context, dao, this, currentValidationId);
    if (currentValidationId!=dao.validationCallCount) return false;
    validationErrors.sort((a, b) => a.severity.weight.compareTo(b.severity.weight));
    final result = validationErrors.where((e) => e.isBlocking).isEmpty;
    await validateRequired(context, dao, currentValidationId, result);
    return result;
  }
  Future<bool> validateRequired(BuildContext context, DAO dao, int currentValidationId, bool normalValidationResult, {
    T? emptyValue,
  }) async {
    bool isRequired = false;
    if (value==null || (value is String && (value as String).isBlank) || (value is ComparableList && (value as ComparableList).isEmpty)) {
      isRequired = !normalValidationResult;
    } else {
      try {
        final emptyField = this.copyWith().._value = emptyValue;
        emptyField.dao = dao;
        final emptyValidationErrors = await _getValidationErrors<T>(context, dao, emptyField, currentValidationId);
        isRequired = emptyValidationErrors.where((e) => e.isBlocking).isNotEmpty;
      } catch (e, st) {
        isRequired = false;
        log ('Error while trying to evaluate if field is required: ${dao.classUiName} - ${dao.uiName}  --  $uiName');
        log(e, stackTrace: st);
      }
    }
    this.isRequired = isRequired;
    return isRequired;
  }
  static Future<List<ValidationError>> _getValidationErrors<T extends Comparable>
      (BuildContext context, DAO dao, Field<T> field, int currentValidationId) async {
    final List<FutureOr<ValidationError?>> futureErrors = [];
    for (final e in field.validators) {
      futureErrors.add(e(context, dao, field));
    }
    final result = <ValidationError>[];
    for (final e in futureErrors) {
      ValidationError? error;
      try {
        error = await e;
      } catch (e, st) {
        log (e, stackTrace: st);
        result.add(ValidationError(field: field,
          error: 'Error al ejecutar validación: ${ApiProviderBuilder.getErrorTitle(context, e, st)}\n${ApiProviderBuilder.getErrorSubtitle(context, error, st)}',
        ));
      }
      if (currentValidationId!=dao.validationCallCount) return [];
      if (error!=null) {
        result.add(error);
      }
    }
    return result;
  }

  void requestFocus() {
    focusNode.requestFocus();
    // try { // no need to do this anymore, since EnsureVisibleWhenFocused will work automatically
    //   Scrollable.ensureVisible(fieldGlobalKey.currentContext!,
    //     duration: Duration(milliseconds: 500),
    //     curve: Curves.easeOutCubic,
    //     alignment: 0.5,
    //   );
    // } catch(_) {}
  }

  SimpleColModel getColModel() => colModelBuilder(this, dao);
  static SimpleColModel fieldDefaultGetColumn(Field field, DAO dao) {
    return SimpleColModel(
      name: field.uiName,
      filterEnabled: true,
      flex: field.tableColumnWidth?.round() ?? 192,
    );
  }

  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard = false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    bool dense = false,
    bool ignoreHidden = false,
    FocusNode? focusNode,
    ScrollController? mainScrollController,
  }) {
    Widget result;
    if (hiddenInForm && !ignoreHidden) {
      result = SizedBox.shrink();
      if (asSliver) {
        result = SliverToBoxAdapter(child: result,);
      }
      return [result];
    }
    if (false) {
      result = ListTile(
        leading: Icon(Icons.error_outline),
        title: Text('Unimplemented Widget for type: ${T.toString()}'),
      );
    } else {
      result = Container();
    }
    if (addCard) {
      result = Card(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12,),
          child: result,
        ),
      );
    }
    result = ResponsiveHorizontalInsets(
      child: SizedBox(
        width: maxWidth,
        child: result,
      ),
    );
    if (asSliver) {
      result = SliverToBoxAdapter(
        child: result,
      );
    }
    return [result];
  }

  Widget buildViewWidget(BuildContext context, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=false,
    bool dense = false,
    bool? hidden,
  }) {
    return viewWidgetBuilder(context, this,
      linkToInnerDAOs: linkToInnerDAOs,
      showViewButtons: showViewButtons,
      dense: dense,
      hidden: hidden,
    );
  }
  static Widget defaultViewWidgetBuilder<T extends Comparable>
  (BuildContext context, Field field, {
    bool linkToInnerDAOs=true,
    bool showViewButtons=false,
    bool dense = false,
    bool? hidden,
    String? subtitle,
  }) {
    if (hidden ?? field.hiddenInView) {
      return SizedBox.shrink();
    }
    linkToInnerDAOs = linkToInnerDAOs && (field.value is DAO)
        && (field.value as DAO).wantsLinkToSelfFromOtherDAOs;
    final onTap = linkToInnerDAOs
        ? ()=>(field.value as DAO).pushViewDialog(context)
        : null;
    String message;
    if (field.value is DAO) {
      message = dense ? (field.value as DAO).uiNameDense : (field.value as DAO).uiName;
    } else if (field is DateField) {
      message = field.value==null ? ''
          : dense
              ? field.formatterDense.format(field.value!)
              : field.formatter.format(field.value!);
    } else {
      message = field.toString();
    }
    return Stack(
      children: [
        Padding(
          padding: dense
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: dense
                    ? AutoSizeText(message,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: field.getColModel().alignment,
                        maxLines: 1,
                        minFontSize: 14,
                        overflowReplacement: TooltipFromZero(
                          message: message,
                          waitDuration: Duration(milliseconds: 0),
                          verticalOffset: -16,
                          child: AutoSizeText(message,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: field.getColModel().alignment,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(message,
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              wordSpacing: 0.4, // hack to fix soft-wrap bug with intrinsicHeight
                            ),
                          ),
                          if (subtitle!=null)
                            Text(subtitle,
                              style: Theme.of(context).textTheme.caption!.copyWith(
                                wordSpacing: 0.4, // hack to fix soft-wrap bug with intrinsicHeight
                              ),
                            ),
                        ],
                      ),
              ),
              if (linkToInnerDAOs && showViewButtons)
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: IconButton(
                    icon: Icon(Icons.info_outline),
                    padding: EdgeInsets.all(0),
                    constraints: BoxConstraints(maxHeight: 32),
                    onPressed: () => (field.value as DAO).pushViewDialog(context),
                  ),
                ),
            ],
          ),
        ),
        if (onTap!=null)
          Positioned.fill(
            child: translucent.InkWell(
              onTap: onTap,
              // mouseCursor: SystemMouseCursors.text,
            ),
          ),
      ],
    );
  }

  List<ActionFromZero> buildDefaultActions(BuildContext context, {FocusNode? focusNode}) {
    return [
      if (dao.enableUndoRedoMechanism)
        ActionFromZero(
          title: 'Deshacer', // TODO 3 internationalize
          icon: Icon(MaterialCommunityIcons.undo_variant),
          onTap: (context) {
            userInteracted = true;
            focusNode?.requestFocus();
            undo(removeEntryFromDAO: true);
          },
          breakpoints: {0: ActionState.popup},
          enabled: undoValues.isNotEmpty,
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
          breakpoints: {0: ActionState.popup},
          enabled: redoValues.isNotEmpty,
        ),
      if (clearable)
        ActionFromZero(
          title: 'Limpiar', // TODO 3 internationalize
          icon: Icon(Icons.clear),
          onTap: (context) {
            userInteracted = true;
            value = defaultValue;
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              (focusNode??_focusNode)?.requestFocus();
            });
          },
          breakpoints: {0: enabled&&value!=defaultValue ? ActionState.icon : ActionState.popup},
          enabled: clearable && value!=defaultValue,
        ),
    ];
  }

  static bool defaultClearableGetter<T extends Comparable>(Field field, DAO dao) {
    return trueFieldGetter(field, dao);
    //return !field.validators.contains(fieldValidatorRequired<T>);
  }

}



class FieldGroup {

  final String? name;
  final bool primary;
  final Map<String, Field> fields;
  final List<FieldGroup> childGroups;
  Map<String, Field> get props {
    return {
      ...fields,
      if (childGroups.isNotEmpty)
        ...childGroups.map((e) => e.props).reduce((value, element) => {...value, ...element}),
    };
  }
  final bool useLayoutFromZero;
  /// only used when building FlexibleLayoutFromZero
  double get maxWidth => max(fields.values.maxBy((e) => e.maxWidth)?.maxWidth ?? 0,
                              childGroups.maxBy((e) => e.maxWidth)?.maxWidth ?? 0);
  /// only used when building FlexibleLayoutFromZero
  double get minWidth => max(fields.values.maxBy((e) => e.minWidth)?.minWidth ?? 0,
                              childGroups.maxBy((e) => e.minWidth)?.minWidth ?? 0);

  const FieldGroup({
    this.fields = const {},
    this.name,
    this.primary = true,
    this.childGroups = const [],
    this.useLayoutFromZero = true,
  });

  FieldGroup copyWith({
    String? name,
    bool? primary,
    Map<String, Field>? fields,
    List<FieldGroup>? childGroups,
  }) {
    final result = FieldGroup(
      name: name??this.name,
      primary: primary??this.primary,
      fields: fields??this.fields.map((key, value) => MapEntry(key, value.copyWith())),
      childGroups: childGroups??this.childGroups.map((e) => e.copyWith()).toList(),
    );
    return result;
  }

  bool get isVisible => visibleFields.isNotEmpty || visibleChildGroups.isNotEmpty;
  Map<String, Field> get visibleFields => Map<String, Field>.from(fields)
    ..removeWhere((key, value) => value.hiddenInForm);
  List<FieldGroup> get visibleChildGroups => childGroups.where((e) => e.isVisible).toList();

}



class HiddenValueField<T> extends Field<BoolComparable> {
  T hiddenValue;
  HiddenValueField(this.hiddenValue) : super(
    uiNameGetter: (field, dao) => '',
    hiddenGetter: (field, dao) => true,
  );
  @override
  Field<BoolComparable> copyWith({FieldValueGetter<String, Field<Comparable>>? uiNameGetter, BoolComparable? value, BoolComparable? dbValue, FieldValueGetter<bool, Field<Comparable>>? clearableGetter, double? maxWidth, double? minWidth, double? flex, FieldValueGetter<String?, Field<Comparable>>? hintGetter, FieldValueGetter<String?, Field<Comparable>>? tooltipGetter, double? tableColumnWidth, FieldValueGetter<bool, Field<Comparable>>? hiddenGetter, FieldValueGetter<bool, Field<Comparable>>? hiddenInTableGetter, FieldValueGetter<bool, Field<Comparable>>? hiddenInViewGetter, FieldValueGetter<bool, Field<Comparable>>? hiddenInFormGetter, FieldValueGetter<List<FieldValidator<BoolComparable>>, Field<Comparable>>? validatorsGetter, bool? validateOnlyOnConfirm, FieldValueGetter<SimpleColModel, Field<Comparable>>? colModelBuilder, List<BoolComparable?>? undoValues, List<BoolComparable?>? redoValues, bool? invalidateNonEmptyValuesIfHiddenInForm, BoolComparable? defaultValue, ContextFulFieldValueGetter<Color?, Field<Comparable>>? backgroundColor, ContextFulFieldValueGetter<List<ActionFromZero>, Field<Comparable>>? actionsGetter, ViewWidgetBuilder<BoolComparable>? viewWidgetBuilder, OnFieldValueChanged<BoolComparable>? onValueChanged}) {
    return HiddenValueField(hiddenValue);
  }
}




