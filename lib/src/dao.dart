import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'field_one_to_many.dart';


typedef Future<bool?> OnSaveCallback(BuildContext context, DAO e);


class DAO extends ChangeNotifier implements Comparable {

  dynamic? id;
  String classUiName;
  String uiName;
  /// props shouldn't be added or removed manually, only changes at construction and on load()
  Map<String, Field> props;
  OnSaveCallback? onSave;
  OnSaveCallback? onDelete;

  DAO({
    required this.classUiName,
    required this.uiName,
    this.id,
    Map<String, Field>? props,
    this.onSave,
    this.onDelete,
  }) : props = props ?? const {} {
    this.props.forEach((key, value) {
      value.addListener(() {
        notifyListeners();
      });
    });
  }

  DAO.dummy({
    required this.uiName,
    required this.classUiName,
    this.id,
    Map<String, Field>? props,
  }) :  props = props ?? const {} {
    this.props.forEach((key, value) {
      value.addListener(() {
        notifyListeners();
      });
    });
  }

  /// @mustOverride
  DAO copyWith({
    String? classUiName,
    String? uiName,
    dynamic? id,
    Map<String, Field>? props,
    OnSaveCallback? onSave,
    OnSaveCallback? onDelete,
  }) {
    return DAO(
      id: id??this.id,
      classUiName: classUiName??this.classUiName,
      props: props??this.props.map((key, value) => MapEntry(key, value.copyWith())),
      uiName: uiName??this.uiName,
      onSave: onSave??this.onSave,
      onDelete: onDelete??this.onDelete,
    );
  }

  bool get isNew => id==null;
  bool get isEditted => props.values.any((element) => element.isEditted);

  // TODO ? implement equals and hashCode (here and in field) ?? do I need this

  @override
  int compareTo(other) => (other is DAO) ? uiName.compareTo(other.uiName) : -1;

  @override
  String toString() => uiName;

  @override
  bool operator == (dynamic other) => (other is DAO) && (id==null ? super.hashCode==other.hashCode : (this.classUiName==other.classUiName && this.id==other.id));

  @override
  int get hashCode => id==null ? super.hashCode : (classUiName+id.toString()).hashCode;


  void revertChanges() {
    props.forEach((key, value) {
      value.revertChanges();
    });
    notifyListeners();
  }

  Future<bool> maybeSave(BuildContext context, {
    bool updateDbValuesAfterSuccessfulSave=true,
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
      );
    } else {
      return false;
    }
  }

  Future<bool> save(context, {
    bool updateDbValuesAfterSuccessfulSave=true,
  }) async {
    bool newInstance = id==null;
    bool success = false;
    try {
      success = (await onSave?.call(context, this)) ?? true;
    } catch (e, st) {
      success = false;
      print(e); print(st);
    }
    if (updateDbValuesAfterSuccessfulSave && success) {
      props.forEach((key, value) {
        value.dbValue = value.value;
      });
    }
    SnackBarFromZero(
      context: context,
      type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
      title: Text(success
          ? '$classUiName ${newInstance ? FromZeroLocalizations.of(context).translate("added")
                                        : FromZeroLocalizations.of(context).translate("edited")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
          : FromZeroLocalizations.of(context).translate("connection_error_long")),
    ).show(context);
    return success;
  }

  Future<bool> delete(context) async {
    bool success = false;
    try {
      success = (await onDelete?.call(context, this)) ?? true;
    } catch (e, st) {
      success = false;
      print(e); print(st);
    }
    SnackBarFromZero(
      context: context,
      type: success ? SnackBarFromZero.success : SnackBarFromZero.error,
      title: Text(success
          ? '$classUiName ${FromZeroLocalizations.of(context).translate("deleted")} ${FromZeroLocalizations.of(context).translate("successfully")}.'
          : FromZeroLocalizations.of(context).translate("connection_error_long")),
    ).show(context);
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

  Future<bool> maybeEdit(BuildContext context) async {
    bool expandToFillContainer = false;
    if (props.values.where((e) => e is OneToManyRelationField).isNotEmpty) {
      expandToFillContainer = true;
    }
    Widget content = ChangeNotifierBuilder(
      changeNotifier: this,
      builder: (context, value, child) {
        List<Widget> formWidgets = buildFormWidgets(context,
          showCancelActionToPop: true,
          expandToFillContainer: expandToFillContainer,
          asSlivers: false,
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
    bool? confirm = await showModal(
      context: context,
      builder: (modalContext) {
        return Center(
          child: SizedBox(
            width: 512+128,
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


  List<Widget> buildFormWidgets(BuildContext context, {
    bool asSlivers=true,
    bool showActionButtons=true,
    bool popAfterSuccessfulSave=true,
    bool showCancelActionToPop=false,
    bool expandToFillContainer=true,
    bool autofocus = true,
  }) {
    bool first = true;
    List<Widget> result = [
      SizedBox(height: 12,),
      ...props.values.map((e) {
        final result = e.buildFieldEditorWidgets(context,
          addCard: true,
          asSliver: asSlivers,
          expandToFillContainer: expandToFillContainer,
          autofocus: autofocus&&first,
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
              if (!isEditted) return true;
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
                        onPressed: isEditted ? () {
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
                        onPressed: isEditted ? () async {
                          showModal(
                            context: context,
                            configuration: const FadeScaleTransitionConfiguration(barrierDismissible: false,),
                            builder: (context) {
                              return LoadingSign();
                            },
                          );
                          bool success = await maybeSave(context);
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
  bool hidden;
  double maxWidth;
  FocusNode? focusNode;
  double? tableColumnWidth;

  T? _value;
  T? get value => _value;
  set value(T? value) {
    _value = value;
    notifyListeners();
  }

  Field({
    required this.uiName,
    T? value,
    T? dbValue,
    this.enabled = true,
    this.clearable = true,
    this.hidden = false,
    this.maxWidth = 512,
    this.hint,
    this.focusNode,
    this.tableColumnWidth,
  }) :  _value = value,
        dbValue = dbValue??value;

  Field.dummy({
    required this.uiName,
    this.enabled = true,
    this.hidden = false,
    this.clearable = true,
  }) :  _value = null,
        dbValue = null,
        maxWidth = 512;

  Field copyWith({
    String? uiName,
    T? value,
    T? dbValue,
    bool? enabled,
    bool? clearable,
    bool? hidden,
    double? maxWidth,
    String? hint,
    double? tableColumnWidth,
  }) {
    return Field(
      uiName: uiName??this.uiName,
      value: value??this.value,
      dbValue: dbValue??this.dbValue,
      enabled: enabled??this.enabled,
      clearable: clearable??this.clearable,
      hidden: hidden??this.hidden,
      maxWidth: maxWidth??this.maxWidth,
      hint: hint??this.hint,
      tableColumnWidth: tableColumnWidth??this.tableColumnWidth,
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
    bool autofocus = false,
  }) {
    Widget result;
    if (hidden) {
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


