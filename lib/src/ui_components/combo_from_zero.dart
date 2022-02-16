import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';

typedef Widget ButtonChildBuilder<T>(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable, {bool showDropdownIcon});
/// returns true if navigator should pop after (default true)
typedef bool? OnPopupItemSelected<T>(T? value);
typedef Widget ExtraWidgetBuilder<T>(BuildContext context, OnPopupItemSelected<T>? onSelected,);

class ComboFromZero<T> extends StatefulWidget {

  final T? value;
  final List<T>? possibleValues;
  final AsyncValue<List<T>>? possibleValuesAsync;
  final Future<List<T>>? possibleValuesFuture;
  final ApiProvider<List<T>>? possibleValuesProvider;
  final VoidCallback? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool showSearchBox;
  final String? title;
  final String? hint;
  final bool enabled;
  final bool clearable;
  final bool sort;
  final bool showViewActionOnDAOs;
  final bool showDropdownIcon;
  final ButtonChildBuilder<T>? buttonChildBuilder;
  final double? popupWidth;
  final ExtraWidgetBuilder<T>? extraWidget;
  final FocusNode? focusNode;
  final Widget Function(T value)? popupWidgetBuilder;
  final ButtonStyle? buttonStyle;

  ComboFromZero({
    this.value,
    this.possibleValues,
    this.possibleValuesAsync,
    this.possibleValuesFuture,
    this.possibleValuesProvider,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox=true,
    this.title,
    this.hint,
    this.buttonChildBuilder,
    this.enabled = true,
    this.clearable = true,
    this.sort = true,
    this.showViewActionOnDAOs = true,
    this.showDropdownIcon = false,
    this.popupWidth,
    this.extraWidget,
    this.focusNode,
    this.popupWidgetBuilder,
    this.buttonStyle,
  }) :  assert(possibleValues!=null
              || possibleValuesFuture!=null
              || possibleValuesProvider!=null);

  @override
  _ComboFromZeroState<T> createState() => _ComboFromZeroState<T>();

  static Widget defaultButtonChildBuilder(BuildContext context, String? title, String? hint, dynamic value, bool enabled, bool clearable, {bool showDropdownIcon=true}) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 38, minWidth: 192,
        ),
        child: Padding(
          padding: EdgeInsets.only(right: enabled&&clearable ? 32 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 8,),
              Expanded(
                child: value==null&&hint==null&&title!=null
                    ? Text(title, style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: enabled ? Theme.of(context).textTheme.caption!.color : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.75),
                    ),)
                    : MaterialKeyValuePair(
                      title: title,
                      value: value==null ? (hint ?? '') : value.toString(),
                      valueStyle: Theme.of(context).textTheme.subtitle1!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.caption!.color!
                            : Theme.of(context).textTheme.bodyText1!.color!.withOpacity(enabled ? 1 : 0.75),
                      ),
                    ),
              ),
              SizedBox(width: 4,),
              if (showDropdownIcon && enabled && !clearable)
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyText1!.color,),
              SizedBox(width: 4,),
            ],
          ),
        ),
      ),
    );
  }

}

class _ComboFromZeroState<T> extends State<ComboFromZero<T>> {

  GlobalKey buttonKey = GlobalKey();

  late final buttonFocusNode = widget.focusNode ?? FocusNode();
  @override
  Widget build(BuildContext context) {
    Widget result;
    if (widget.possibleValuesProvider!=null) {
      result = ApiProviderBuilder<List<T>>(
        provider: widget.possibleValuesProvider!,
        dataBuilder: _build,
        loadingBuilder: _buildLoading,
        errorBuilder: _buildError,
      );
    } else if (widget.possibleValuesFuture!=null) {
      result = FutureBuilderFromZero<List<T>>(
        future: widget.possibleValuesFuture!,
        successBuilder: _build,
        loadingBuilder: _buildLoading,
        errorBuilder: (context, error, stackTrace) => _buildError(context, error, stackTrace is StackTrace ? stackTrace : null),
      );
    } else if (widget.possibleValuesAsync!=null) {
      result = AsyncValueBuilder<List<T>>(
        asyncValue: widget.possibleValuesAsync!,
        dataBuilder: _build,
        loadingBuilder: _buildLoading,
        errorBuilder: _buildError,
      );
    } else {
      return _build(context, widget.possibleValues!);
    }
    return result;
  }

  Widget _buildError(BuildContext context, Object? error, StackTrace? stackTrace, [VoidCallback? onRetry]) {
    return SizedBox(
      width: 64,
      height: 38,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace, onRetry), // TODO 1 implement compact errorBuilder, this will overflow
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, [double? progress]) {
    return SizedBox(
      width: 64,
      height: 38,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, List<T>? possibleValues,) {
    Widget result;
    if (widget.buttonChildBuilder==null) {
      result = ComboFromZero.defaultButtonChildBuilder(context, widget.title, widget.hint, widget.value, widget.enabled, widget.clearable,
        showDropdownIcon: widget.showDropdownIcon,
      );
    } else {
      result = widget.buttonChildBuilder!(context, widget.title, widget.hint, widget.value, widget.enabled, widget.clearable,
        showDropdownIcon: widget.showDropdownIcon,
      );
    }
    result = Stack(
      children: [
        TextButton(
          key: buttonKey,
          style: widget.buttonStyle,
          child: Center(
            child: OverflowScroll(
              child: result,
              scrollDirection: Axis.vertical,
            ),
          ),
          focusNode: buttonFocusNode,
          onPressed: widget.enabled ? () async {
            buttonFocusNode.requestFocus();
            T? selected = await showPopupFromZero<T>(
              context: context,
              anchorKey: buttonKey,
              width: widget.popupWidth,
              builder: (context) {
                return ComboFromZeroPopup<T>(
                  possibleValues: possibleValues!,
                  onSelected: widget.onSelected,
                  onCanceled: widget.onCanceled,
                  value: widget.value,
                  sort: widget.sort,
                  showSearchBox: widget.showSearchBox,
                  showViewActionOnDAOs: widget.showViewActionOnDAOs,
                  title: widget.title,
                  extraWidget: widget.extraWidget,
                  popupWidgetBuilder: widget.popupWidgetBuilder,
                );
              },
            );
            if (selected!=null) {
              widget.onCanceled?.call();
            }
          } : null,
        ),
        if (widget.enabled && widget.clearable)
          Positioned(
            right: 8, top: 0, bottom: 0,
            child: ExcludeFocus(
              child: Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: widget.value!=null ? IconButton(
                    icon: Icon(Icons.close),
                    tooltip: FromZeroLocalizations.of(context).translate('clear'),
                    splashRadius: 20,
                    onPressed: () {
                      widget.onSelected?.call(null);
                    },
                  ) : SizedBox.shrink(),
                ),
              ),
            ),
          ),
      ],
    );
    return result;
  }

}



class ComboFromZeroPopup<T> extends StatefulWidget {

  final T? value;
  final List<T> possibleValues;
  final VoidCallback? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool showSearchBox;
  final bool showViewActionOnDAOs;
  final bool sort;
  final String? title;
  final ExtraWidgetBuilder<T>? extraWidget;
  final Widget Function(T value)? popupWidgetBuilder;

  ComboFromZeroPopup({
    required this.possibleValues,
    this.value,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox = true,
    this.showViewActionOnDAOs = true,
    this.sort = true,
    this.title,
    this.extraWidget,
    this.popupWidgetBuilder,
  });

  @override
  _ComboFromZeroPopupState<T> createState() => _ComboFromZeroPopupState<T>();

}

class _ComboFromZeroPopupState<T> extends State<ComboFromZeroPopup<T>> {

  final ScrollController popupScrollController = ScrollController();
  String? searchQuery;
  TableController tableController = TableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarFromZero(
      controller: popupScrollController,
      child: CustomScrollView(
        controller: popupScrollController,
        shrinkWrap: true,
        slivers: [
          if (!widget.showSearchBox)
            SliverToBoxAdapter(child: SizedBox(height: 12,),),
          TableFromZero<T>(
            tableController: tableController,
            tableHorizontalPadding: 8,
            initialSortedColumn: widget.sort ? 0 : -1,
            cellBuilder: widget.popupWidgetBuilder==null ? null
                : (context, row, colKey) => widget.popupWidgetBuilder!(row.id),
            onFilter: (filtered) {
              if (searchQuery!=null && searchQuery!.isNotEmpty) {
                return filtered.where((e) => e.id.toString().toUpperCase().contains(searchQuery!.toUpperCase())).toList();
              }
              return filtered;
            },
            rows: widget.possibleValues.map((e) {
              return SimpleRowModel(
                id: e,
                values: {0: e.toString()},
                backgroundColor: widget.value==e ? Theme.of(context).toggleableActiveColor.withOpacity(0.1) : null,
                onRowTap: (value) {
                  _select(e);
                },
              );
            }).toList(),
            rowActions: widget.showViewActionOnDAOs && T is DAO
                ? [
                    RowAction<T>(
                      title: FromZeroLocalizations.of(context).translate('view'),
                      icon: Icon(Icons.info_outline),
                      onRowTap: (context, row) {
                        (row.id as DAO).pushViewDialog(context);
                      },
                    )
                  ]
                : [],
            headerRowModel: SimpleRowModel(
              id: 'header', values: {},
              rowAddon: widget.showSearchBox ? Container(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    if (widget.title!=null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Center(
                          child: Transform.translate(
                            offset: Offset(0, 4),
                            child: Text(widget.title!,
                              style: Theme.of(context).textTheme.subtitle1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    if (widget.extraWidget!=null)
                      widget.extraWidget!(context, widget.onSelected,),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12,),
                      child: TextFormField(
                        initialValue: searchQuery,
                        autofocus: PlatformExtended.isDesktop,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 8, right: 80, bottom: 4, top: 8,),
                          labelText: FromZeroLocalizations.of(context).translate('search...'),
                          labelStyle: TextStyle(height: 1.5),
                          suffixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.caption!.color!,),
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                          tableController.filter();
                        },
                        onFieldSubmitted: (value) {
                          final filtered = tableController.filtered!;
                          if (filtered.length==1) {
                            _select(filtered.first.id);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ) : null,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12,),),
        ],
      ),
    );
  }

  void _select(T e) {
    bool? pop = widget.onSelected?.call(e);
    if (pop??true) {
      Navigator.of(context).pop(e);
    }
  }

}


