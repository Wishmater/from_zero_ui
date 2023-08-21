import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:dartx/dartx.dart';

typedef Widget ButtonChildBuilder<T>(BuildContext context, String? title, String? hint, T? value, bool enabled, bool clearable, {bool showDropdownIcon});
/// returns true if navigator should pop after (default true)
typedef bool? OnPopupItemSelected<T>(T? value);
typedef Widget ExtraWidgetBuilder<T>(BuildContext context, OnPopupItemSelected<T>? onSelected,);

class ComboFromZero<T> extends StatefulWidget {

  final T? value;
  final List<T>? possibleValues;
  final AsyncValue<List<T>>? possibleValuesAsync;
  final Future<List<T>>? possibleValuesFuture;
  final AutoDisposeStateNotifierProvider<ApiState<List<T>>, AsyncValue<List<T>>>? possibleValuesProvider;
  final VoidCallback? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool? showSearchBox;
  final String? title;
  final String? hint;
  final bool enabled;
  final bool clearable;
  final bool sort;
  final bool showViewActionOnDAOs;
  final bool showDropdownIcon;
  final bool blockComboWhilePossibleValuesLoad;
  final ButtonChildBuilder<T>? buttonChildBuilder;
  final double? popupWidth;
  final ExtraWidgetBuilder<T>? extraWidget;
  final FocusNode? focusNode;
  final Widget Function(T value)? popupWidgetBuilder;
  final ButtonStyle? buttonStyle;
  final double popupRowHeight;
  final bool useFixedPopupRowHeight;
  final bool showNullInSelection;
  final bool showHintAsNullInSelection;

  ComboFromZero({
    this.value,
    this.possibleValues,
    this.possibleValuesAsync,
    this.possibleValuesFuture,
    this.possibleValuesProvider,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox,
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
    this.popupRowHeight = 38,
    this.useFixedPopupRowHeight = true,
    this.blockComboWhilePossibleValuesLoad = false,
    this.showNullInSelection = false,
    this.showHintAsNullInSelection = true,
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
                    ? Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: enabled ? Theme.of(context).textTheme.bodySmall!.color : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.75),
                    ),)
                    : MaterialKeyValuePair(
                      title: title,
                      value: value==null ? (hint ?? '') : value.toString(),
                      valueStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                        height: 1,
                        color: value==null ? Theme.of(context).textTheme.bodySmall!.color!
                            : Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(enabled ? 1 : 0.75),
                      ),
                    ),
              ),
              SizedBox(width: 4,),
              if (showDropdownIcon && enabled && !clearable)
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyLarge!.color,),
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
    if (widget.blockComboWhilePossibleValuesLoad) {
      if (widget.possibleValuesProvider!=null) {
        result = ApiProviderBuilder<List<T>>(
          provider: widget.possibleValuesProvider!,
          dataBuilder: _buildCombo,
          loadingBuilder: _buildComboLoading,
          errorBuilder: _buildComboError,
        );
      } else if (widget.possibleValuesFuture!=null) {
        result = FutureBuilderFromZero<List<T>>(
          future: widget.possibleValuesFuture!,
          successBuilder: _buildCombo,
          loadingBuilder: _buildComboLoading,
          errorBuilder: (context, error, stackTrace) => _buildComboError(context, error, stackTrace is StackTrace ? stackTrace : null),
        );
      } else if (widget.possibleValuesAsync!=null) {
        result = AsyncValueBuilder<List<T>>(
          asyncValue: widget.possibleValuesAsync!,
          dataBuilder: _buildCombo,
          loadingBuilder: _buildComboLoading,
          errorBuilder: _buildComboError,
        );
      } else {
        result = _buildCombo(context, widget.possibleValues!);
      }
    } else {
      result = _buildCombo(context, null);
    }
    return result;
  }

  Widget _buildComboError(BuildContext context, Object? error, StackTrace? stackTrace, [VoidCallback? onRetry]) {
    return LimitedBox(
      maxWidth: 256,
      maxHeight: 64,
      child: ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace, onRetry),
    );
  }

  Widget _buildComboLoading(BuildContext context, [ValueListenable<double?>? progress]) {
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
    return LimitedBox(
      maxWidth: 256,
      maxHeight: 64,
      child: Stack(
        children: [
          Padding(
            padding: widget.buttonStyle?.padding?.resolve({})
                ?? EdgeInsets.symmetric(horizontal: 8),
            child: result,
          ),
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              color: Theme.of(context).disabledColor,
              child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombo(BuildContext context, List<T>? possibleValues,) {
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
              autoscrollSpeed: null,
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
                Widget result;
                if (possibleValues!=null) {
                  result = _buildPopup(context, possibleValues);
                } else {
                  if (widget.possibleValuesProvider!=null) {
                    result = ApiProviderBuilder<List<T>>(
                      provider: widget.possibleValuesProvider!,
                      dataBuilder: _buildPopup,
                      loadingBuilder: _buildPopupLoading,
                      errorBuilder: _buildPopupError,
                    );
                  } else if (widget.possibleValuesFuture!=null) {
                    result = FutureBuilderFromZero<List<T>>(
                      future: widget.possibleValuesFuture!,
                      successBuilder: _buildPopup,
                      loadingBuilder: _buildPopupLoading,
                      errorBuilder: (context, error, stackTrace) => _buildPopupError(context, error, stackTrace is StackTrace ? stackTrace : null),
                    );
                  } else if (widget.possibleValuesAsync!=null) {
                    result = AsyncValueBuilder<List<T>>(
                      asyncValue: widget.possibleValuesAsync!,
                      dataBuilder: _buildPopup,
                      loadingBuilder: _buildPopupLoading,
                      errorBuilder: _buildPopupError,
                    );
                  } else {
                    result = _buildPopup(context, widget.possibleValues!);
                  }
                }
                return result;
              },
            );
            if (selected==null) {
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
                  child: widget.value!=null ? TooltipFromZero(
                    message: FromZeroLocalizations.of(context).translate('clear'),
                    child: IconButton(
                      icon: Icon(Icons.close),
                      splashRadius: 20,
                      onPressed: () {
                        widget.onSelected?.call(null);
                      },
                    ),
                  ) : SizedBox.shrink(),
                ),
              ),
            ),
          ),
      ],
    );
    return result;
  }

  Widget _buildPopup(BuildContext context, List<T> possibleValues,) {
    return ComboFromZeroPopup<T>(
      possibleValues: possibleValues,
      onSelected: widget.onSelected,
      onCanceled: widget.onCanceled,
      value: widget.value,
      sort: widget.sort,
      showSearchBox: widget.showSearchBox,
      showViewActionOnDAOs: widget.showViewActionOnDAOs,
      title: widget.title,
      extraWidget: widget.extraWidget,
      popupWidgetBuilder: widget.popupWidgetBuilder,
      rowHeight: widget.popupRowHeight,
      useFixedRowHeight: widget.useFixedPopupRowHeight,
      showNullInSelection: widget.showNullInSelection,
      showHintAsNullInSelection: widget.showHintAsNullInSelection,
      hint: widget.hint,
    );
  }

  Widget _buildPopupError(BuildContext context, Object? error, StackTrace? stackTrace, [VoidCallback? onRetry]) {
    return IntrinsicHeight(
      child: ApiProviderBuilder.defaultErrorBuilder(context, error, stackTrace, onRetry),
    );
  }

  Widget _buildPopupLoading(BuildContext context, [ValueListenable<double?>? progress]) {
    return SizedBox(
      height: 128,
      child: ApiProviderBuilder.defaultLoadingBuilder(context, progress),
    );
  }

}



class ComboFromZeroPopup<T> extends StatefulWidget {

  final T? value;
  final List<T> possibleValues;
  final VoidCallback? onCanceled;
  final OnPopupItemSelected<T>? onSelected;
  final bool? showSearchBox;
  final bool showViewActionOnDAOs;
  final bool sort;
  final String? title;
  final ExtraWidgetBuilder<T>? extraWidget;
  final Widget Function(T value)? popupWidgetBuilder;
  final double rowHeight;
  final bool useFixedRowHeight;
  final bool showNullInSelection;
  final bool showHintAsNullInSelection;
  final String? hint;

  ComboFromZeroPopup({
    required this.possibleValues,
    this.value,
    this.onSelected,
    this.onCanceled,
    this.showSearchBox,
    this.showViewActionOnDAOs = true,
    this.sort = true,
    this.title,
    this.extraWidget,
    this.popupWidgetBuilder,
    this.rowHeight = 38,
    this.useFixedRowHeight = true,
    this.showNullInSelection = false,
    this.showHintAsNullInSelection = true,
    this.hint,
  });

  @override
  _ComboFromZeroPopupState<T> createState() => _ComboFromZeroPopupState<T>();

}

class _ComboFromZeroPopupState<T> extends State<ComboFromZeroPopup<T>> {

  final ScrollController popupScrollController = ScrollController();
  String? searchQuery;
  TableController<T?> tableController = TableController();
  FocusNode initialFocus = FocusNode();

  bool get showSearchBox => widget.showSearchBox ?? widget.possibleValues.length > 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (showSearchBox) {
        initialFocus.requestFocus();
      } else {
        // FocusScope.of(context).nextFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.possibleValues.map((e) {
      return SimpleRowModel<T?>(
        id: e,
        values: {0: e.toString()},
        height: widget.useFixedRowHeight ? widget.rowHeight : null,
        onRowTap: (value) {
          _select(e);
        },
      );
    }).toList();
    if (widget.showNullInSelection) {
      rows.add(SimpleRowModel<T?>(
        id: null,
        values: {0: (widget.showHintAsNullInSelection ? widget.hint : null) ?? '< Vacío >'}, // TODO 3 internationalize
        height: widget.useFixedRowHeight ? widget.rowHeight : null,
        alwaysOnTop: true,
        onRowTap: (value) {
          _select(null);
        },
      ));
    }
    return ScrollbarFromZero(
      controller: popupScrollController,
      child: CustomScrollView(
        controller: popupScrollController,
        shrinkWrap: true,
        slivers: [
          if (!showSearchBox)
            SliverToBoxAdapter(child: SizedBox(height: 12,),),
          TableFromZero<T?>(
            tableController: tableController,
            tableHorizontalPadding: 8,
            initialSortedColumn: widget.sort ? 0 : -1,
            enableFixedHeightForListRows: widget.useFixedRowHeight,
            cellBuilder: widget.popupWidgetBuilder==null ? null
                : (context, row, colKey) => widget.popupWidgetBuilder!(row.id!),
            rows: rows,
            onFilter: (filtered) {
              List<RowModel<T?>> starts = [];
              List<RowModel<T?>> contains = [];
              if (searchQuery==null || searchQuery!.isEmpty) {
                contains = filtered;
              } else {
                final q = searchQuery!.trim().toUpperCase();
                for (final e in filtered) {
                  final value = (e.id is DAO)
                      ? (e.id as DAO).searchName.toUpperCase()
                      : e.id==null ? e.values[0]
                      : e.id.toString().toUpperCase();
                  if (value.contains(q)) {
                    if (value.startsWith(q)) {
                      starts.add(e);
                    } else {
                      contains.add(e);
                    }
                  }
                }
              }
              return [...starts, ...contains];
            },
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
              rowAddon: Container(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    if (widget.title!=null)
                      Container(
                        padding: EdgeInsets.only(
                          top: showSearchBox ? 8.0 : 0,
                          bottom: widget.extraWidget!=null ? 4 : !showSearchBox ? 12 : 0,
                          left: 8, right: 8,
                        ),
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(0, widget.extraWidget==null&&showSearchBox ? 4 : 0),
                          child: Text(widget.title!,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    if (widget.extraWidget!=null)
                      widget.extraWidget!(context, widget.onSelected,),
                    if (showSearchBox)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12,),
                        child: KeyboardListener(
                          includeSemantics: false,
                          focusNode: FocusNode(),
                          onKeyEvent: (value) {
                            if (value is KeyDownEvent) {
                              if (value.logicalKey==LogicalKeyboardKey.arrowDown) {
                                FocusScope.of(context).focusInDirection(TraversalDirection.down);
                              } else if (value.logicalKey==LogicalKeyboardKey.arrowUp) {
                                FocusScope.of(context).focusInDirection(TraversalDirection.up);
                              }
                            }
                          },
                          child: TextFormField(
                            initialValue: searchQuery,
                            focusNode: initialFocus,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(left: 8, right: 80, bottom: 4, top: 8,),
                              labelText: FromZeroLocalizations.of(context).translate('search...'),
                              labelStyle: TextStyle(height: 1.5),
                              suffixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall!.color!,),
                            ),
                            onChanged: (value) {
                              searchQuery = value;
                              tableController.filter();
                            },
                            onFieldSubmitted: (value) {
                              final filtered = tableController.filtered;
                              if (filtered.length==1) {
                                _select(filtered.first.id);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12,),),
        ],
      ),
    );
  }

  void _select(T? e) {
    bool? pop = widget.onSelected?.call(e);
    if (pop??true) {
      Navigator.of(context).pop(e);
    }
  }

}


