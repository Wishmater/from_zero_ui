import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'field_one_to_many.dart';


typedef Future<DAO?> OnSaveCallback(BuildContext context, DAO e);

typedef Widget DAOWidgetBuilder(BuildContext context, DAO dao);

class DAO extends ChangeNotifier implements Comparable {

  dynamic? id;
  String classUiName;
  String classUiNamePlural;
  String uiName;
  /// props shouldn't be added or removed manually, only changes at construction and on load()
  Map<String, Field> props;
  OnSaveCallback? onSave;
  OnSaveCallback? onDelete;
  List<ValueChanged<DAO>> _selfUpdateListeners = [];

  DAOWidgetBuilder? viewWidgetBuilder;
  bool useIntrinsicHeightForViewDialog;
  double viewDialogWidth;
  double formDialogWidth;

  DAO({
    required this.classUiName,
    String? classUiNamePlural,
    required this.uiName,
    this.id,
    Map<String, Field>? props,
    this.onSave,
    this.onDelete,
    this.viewWidgetBuilder,
    this.useIntrinsicHeightForViewDialog = true,
    this.viewDialogWidth = 512,
    this.formDialogWidth = 640,
  }) :  this.classUiNamePlural = classUiNamePlural ?? classUiName,
        props = props ?? const {} {
        this.props.forEach((key, value) {
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
    String? classUiName,
    String? classUiNamePlural,
    String? uiName,
    dynamic? id,
    Map<String, Field>? props,
    OnSaveCallback? onSave,
    OnSaveCallback? onDelete,
    DAOWidgetBuilder? viewWidgetBuilder,
    bool? useIntrinsicHeightForViewDialog,
    double? viewDialogWidth,
    double? formDialogWidth,
  }) {
    final result = DAO(
      id: id??this.id,
      classUiName: classUiName??this.classUiName,
      props: props??this.props.map((key, value) => MapEntry(key, value.copyWith())),
      classUiNamePlural: classUiNamePlural??this.classUiNamePlural,
      uiName: uiName??this.uiName,
      onSave: onSave??this.onSave,
      onDelete: onDelete??this.onDelete,
      viewWidgetBuilder: viewWidgetBuilder??this.viewWidgetBuilder,
      useIntrinsicHeightForViewDialog: useIntrinsicHeightForViewDialog??this.useIntrinsicHeightForViewDialog,
      viewDialogWidth: viewDialogWidth??this.viewDialogWidth,
      formDialogWidth: formDialogWidth??this.formDialogWidth,
    );
    result._selfUpdateListeners = _selfUpdateListeners;
    return result;
  }

  bool get isNew => id==null;
  bool get isEdited => props.values.any((element) => element.isEditted);

  @override
  int compareTo(other) => (other is DAO) ? uiName.compareTo(other.uiName) : -1;

  @override
  String toString() => uiName;

  @override
  bool operator == (dynamic other) => (other is DAO) && (id==null ? super.hashCode==other.hashCode : (this.classUiName==other.classUiName && this.id==other.id));

  @override
  int get hashCode => id==null ? super.hashCode : (classUiName+id.toString()).hashCode;


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

  Future<bool> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
    bool showDefaultSnackBars=true,
  }) async {
    assert(onSave!=null);
    bool? confirm = await showModal(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(FromZeroLocalizations.of(context).translate("confirm_save_title")),
          content: Text(FromZeroLocalizations.of(context).translate("confirm_save_desc")),
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
        );
      },
    );
    if (confirm??false) {
      return save(context,
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
  }) async {
    bool newInstance = id==null || id==-1;
    bool success = false;
    try {
      success = (await onSave?.call(context, this))!=null;
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

  Future<bool> delete(context, {bool showDefaultSnackBar=true,}) async {
    bool success = false;
    try {
      success = (await onDelete?.call(context, this))!=null;
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

  Future<bool> maybeEdit(BuildContext context, {bool showDefaultSnackBars=true}) async {
    bool expandToFillContainer = false;
    if (props.values.where((e) => e is OneToManyRelationField).isNotEmpty) {
      expandToFillContainer = true;
    }
    final focusNode = FocusNode();
    Widget content = ChangeNotifierBuilder(
      changeNotifier: this,
      builder: (context, value, child) {
        List<Widget> formWidgets = buildFormWidgets(context,
          showCancelActionToPop: true,
          expandToFillContainer: expandToFillContainer,
          asSlivers: false,
          focusNode: focusNode,
          showDefaultSnackBars: showDefaultSnackBars,
        );
        List<Widget> formFields = formWidgets.sublist(0, formWidgets.length-2);
        List<Widget> formActions = formWidgets.sublist(formWidgets.length-2);
        ScrollController scrollController = ScrollController();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
              child: Text('${id==null ? FromZeroLocalizations.of(context).translate("add")
                  : FromZeroLocalizations.of(context).translate("edit")} $classUiName',
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
                      child: FocusTraversalGroup(
                        policy: WidgetOrderTraversalPolicy(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: formFields,
                        ),
                      ),
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
      },
    );
    if (!expandToFillContainer) {
      content = IntrinsicHeight(
        child: content,
      );
    }
    // Future.delayed(Duration(milliseconds: 200)).then((value) => focusNode.requestFocus());
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      focusNode.requestFocus();
    });
    bool? confirm = await showModal(
      context: context,
      builder: (modalContext) {
        return Center(
          child: SizedBox(
            width: formDialogWidth,
            child: Dialog(
              clipBehavior: Clip.hardEdge,
              child: Container(
                color: Theme.of(context).canvasColor,
                child: content,
              ),
            ),
          ),
        );
      },
    );
    return confirm??false;
  }


  Future<dynamic> pushViewDialog(BuildContext context, {
    bool? showEditButton,
  }) {
    Widget content = ChangeNotifierBuilder(
      changeNotifier: this,
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 8,),
              child: Row(
                children: [
                  Expanded(
                    child: Text(uiName,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ),
                  if (showEditButton ?? onSave!=null)
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
          child: SizedBox(
            width: viewDialogWidth,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Dialog(
                backgroundColor: Theme.of(context).cardColor,
                child: content,
              ),
            ),
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
            return Container(
              color: clear ? Theme.of(context).cardColor
                  : Color.alphaBlend(Theme.of(context).cardColor.withOpacity(0.965), Colors.black),
              child: e.buildViewWidget(context),
            );
          }).toList(),
        ),
      ),
    );
  }


  List<Widget> buildFormWidgets(BuildContext context, {
    bool asSlivers=true,
    bool showActionButtons=true,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool showDefaultSnackBars=true,
    FocusNode? focusNode,
  }) {
    bool first = true;
    List<Widget> result = [
      SizedBox(height: 12,),
      ...props.values.where((e) => !e.hiddenInForm).map((e) {
        final result = e.buildFieldEditorWidgets(context,
          addCard: true,
          asSliver: asSlivers,
          expandToFillContainer: expandToFillContainer,
          focusNode: first ? focusNode : null,
        );
        first = false;
        return result;
      }).flatten().map((e) {
        if (asSlivers) {
          return SliverPadding(
            padding: EdgeInsets.only(top: 6, bottom: 6,),
            sliver: e,
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(top: 6, bottom: 6,),
            child: e,
          );
        }
      }).toList(),
      SizedBox(height: 12,),
      if (showActionButtons)
        SizedBox(height: 6,),
      if (showActionButtons)
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
                          showModal(
                            context: context,
                            configuration: const FadeScaleTransitionConfiguration(barrierDismissible: false,),
                            builder: (context) {
                              return LoadingSign();
                            },
                          );
                          bool success = await maybeSave(context,
                            showDefaultSnackBars: showDefaultSnackBars,
                          );
                          Navigator.of(context).pop();
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
      if (showActionButtons)
        SizedBox(height: 24,),
    ];
    if (asSlivers) {
      result = result.map((e) => (e is SliverPadding) ? e : SliverToBoxAdapter(child: e)).toList();
    }
    return result;
  }
  
}



class Field<T extends Comparable> extends ChangeNotifier implements Comparable, ContainsValue {

  String uiName;
  String? hint;
  T? dbValue;
  bool clearable;
  bool enabled;
  bool hiddenInTable;
  bool hiddenInView;
  bool hiddenInForm;
  double maxWidth;
  FocusNode? focusNode;
  double? tableColumnWidth;

  T? _value;
  T? get value => _value;
  set value(T? value) {
    if (_value!=value) {
      _value = value;
      notifyListeners();
    }
  }

  Field({
    required this.uiName,
    T? value,
    T? dbValue,
    this.enabled = true,
    this.clearable = true,
    this.maxWidth = 512,
    this.hint,
    this.focusNode,
    this.tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
  }) :  _value = value,
        dbValue = dbValue ?? value,
        this.hiddenInTable = hiddenInTable ?? hidden ?? false,
        this.hiddenInView = hiddenInView ?? hidden ?? false,
        this.hiddenInForm = hiddenInForm ?? hidden ?? false;


  Field copyWith({
    String? uiName,
    T? value,
    T? dbValue,
    bool? enabled,
    bool? clearable,
    double? maxWidth,
    String? hint,
    double? tableColumnWidth,
    bool? hidden,
    bool? hiddenInTable,
    bool? hiddenInView,
    bool? hiddenInForm,
  }) {
    return Field(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabled: enabled??this.enabled,
      clearable: clearable??this.clearable,
      maxWidth: maxWidth??this.maxWidth,
      hint: hint??this.hint,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
      hiddenInTable: hiddenInTable ?? hidden ?? this.hiddenInTable,
      hiddenInView: hiddenInView ?? hidden ?? this.hiddenInView,
      hiddenInForm: hiddenInForm ?? hidden ?? this.hiddenInForm,
    );
  }

  @override
  String toString() => value==null ? '' : value.toString();

  @override
  bool operator == (dynamic other) => other is Field<T> && this.value==other.value;

  @override
  int get hashCode => value.hashCode;

  bool get isEditted => value!=dbValue;

  @override
  int compareTo(other) => other is Field ? value==null||(value is String && (value as String).isEmpty) ? 1 : value!.compareTo(other.value) : 1;

  List<Widget> buildFieldEditorWidgets(BuildContext context, {
    bool addCard = false,
    bool asSliver = true,
    bool expandToFillContainer = true,
    FocusNode? focusNode,
  }) {
    Widget result;
    if (hiddenInForm) {
      result = SizedBox.shrink();
      if (asSliver) {
        result = SliverToBoxAdapter(child: result,);
      }
      return [result];
    }
    result = ListTile(
      leading: Icon(Icons.error_outline),
      title: Text('Unimplemented Widget for type: ${T.toString()}'),
    );
    if (addCard) {
      result = Card(
        child: Padding(
          padding: EdgeInsets.only(left: 12, right: 12,),
          child: result,
        ),
      );
    }
    result = ResponsiveHorizontalInsets(
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: result,
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

  Widget buildViewWidget(BuildContext context) {
    if (hiddenInView) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          // TODO this probably wont do well on a mobile layout
          Expanded(
            flex: 1000000,
            child: Text(uiName,
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Container(
            height: 24,
            child: VerticalDivider(width: 16,),
          ),
          Expanded(
            flex: 1618034,
            child: Text(toString(),
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
        ],
      ),
    );
  }

  void revertChanges() {
    value = dbValue;
    notifyListeners();
  }

  SimpleColModel getColModel() {
    return SimpleColModel(
      name: uiName,
      filterEnabled: true,
      width: tableColumnWidth,
    );
  }

}


