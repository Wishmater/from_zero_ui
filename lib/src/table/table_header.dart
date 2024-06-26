import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


class TableHeaderFromZero<T> extends StatefulWidget {

  final TableController<T> controller;
  final Widget? title;
  final List<ActionFromZero>? actions;
  final Widget? leading;
  final VoidCallback? onShowAppbarContextMenu;
  final bool showElementCount;
  final FutureOr<String>? exportPathForExcel;
  final bool addSearchAction;
  final bool searchActionExpandedByDefault;
  final bool? showColumnMetadata; /// defaults to Table.showHeaders
  final Color? defaultActionsColor;
  final Color? backgroundColor;
  final double titleLeftPadding;

  const TableHeaderFromZero({
    required this.controller,
    required this.title,
    this.actions,
    this.leading,
    this.onShowAppbarContextMenu,
    this.showElementCount = true,
    this.exportPathForExcel,
    this.addSearchAction = false,
    this.searchActionExpandedByDefault = true,
    this.defaultActionsColor,
    this.backgroundColor,
    this.showColumnMetadata,
    this.titleLeftPadding = 18,
    super.key,
  });

  @override
  TableHeaderFromZeroState<T> createState() => TableHeaderFromZeroState();

}

class TableHeaderFromZeroState<T> extends State<TableHeaderFromZero<T>> {

  bool autofocusSearchOnNextBuild = false;
  String? searchQuery;
  late final FocusNode searchTextfieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (PlatformExtended.isDesktop) {
      autofocusSearchOnNextBuild = true;
    }
    if (!widget.controller.extraFilters.contains(defaultOnFilter)) {
      widget.controller.extraFilters.add(defaultOnFilter);
    }
  }

  @override
  void dispose() {
    widget.controller.extraFilters.remove(defaultOnFilter);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        List<ActionFromZero> actions = widget.actions ?? [];
        if (widget.controller.currentState?.widget.allowCustomization??false) {
          actions = TableFromZeroState.addManageActions(context,
            actions: actions,
            controller: widget.controller,
          );
        }
        final exportPathForExcel = widget.exportPathForExcel ?? widget.controller.currentState?.widget.exportPathForExcel;
        if (exportPathForExcel!=null) {
          actions = TableFromZeroState.addExportExcelAction(context,
            actions: actions,
            tableController: widget.controller,
            exportPathForExcel: exportPathForExcel,
          );
        }
        if (widget.addSearchAction) {
          actions.insert(0, buildSearchAction());
        }
        List<RowModel<T>>? filtered;
        try {
          filtered = widget.controller.filtered;
        } catch (_) {}
        int selectedCount = filtered==null ? 0
            : filtered.where((e) => e.onCheckBoxSelected!=null && e.selected==true).length;
        Widget subtitle;
        if (selectedCount==0) {
          if (filtered!=null && widget.showElementCount) {
            final column = widget.controller.columns?[widget.controller.sortedColumn];
            String subtitleText;
            if (column!=null) {
              subtitleText = column.getSubtitleText(context, filtered, widget.controller.sortedColumn,
                addMetadata: widget.showColumnMetadata ?? widget.controller.currentState!.widget.showHeaders,
              );
            } else {
              final count = filtered.length;
              subtitleText = count==0 ? FromZeroLocalizations.of(context).translate('no_elements')
                  : '$count ${count>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                  : FromZeroLocalizations.of(context).translate('element_sing')}';
            }
            subtitle = Text(subtitleText,
              // key: ValueKey('normal'),
              style: Theme.of(context).textTheme.bodySmall,
            );
          } else {
            subtitle = const SizedBox.shrink();
          }
        } else {
          final count = filtered!.where((e) => e.onCheckBoxSelected!=null).length;
          subtitle = Text('$selectedCount/$count ${selectedCount>1 ? FromZeroLocalizations.of(context).translate('selected_plur')
              : FromZeroLocalizations.of(context).translate('selected_sing')}',
            // key: ValueKey('selected'),
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        subtitle = AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          child: subtitle,
          transitionBuilder: (child, animation) {
            return SizeTransition(
              axisAlignment: -1,
              sizeFactor: animation,
              child: child,
            );
          },
        );
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              color: widget.backgroundColor ?? Material.of(context).color ?? Theme.of(context).cardColor, // Colors.transparent
              iconTheme: Theme.of(context).iconTheme,
              actionsIconTheme: widget.defaultActionsColor==null
                  ? Theme.of(context).iconTheme
                  : Theme.of(context).iconTheme.copyWith(color: widget.defaultActionsColor),
              titleTextStyle: Theme.of(context).textTheme.titleMedium,
              toolbarTextStyle: widget.defaultActionsColor==null
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.titleMedium!.copyWith(color: widget.defaultActionsColor),
            ),
          ),
          child: AppbarFromZero(
            titleSpacing: 0,
            onShowContextMenu: widget.onShowAppbarContextMenu,
            title: Row(
              children: [
                if (widget.leading==null)
                  SizedBox(width: 4 + widget.titleLeftPadding,),
                if (widget.leading!=null)
                  ... [
                    SizedBox(width: widget.titleLeftPadding,),
                    widget.leading!,
                    const SizedBox(width: 9,),
                  ],
                Expanded(
                  child: OverflowScroll(
                    autoscrollSpeed: null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.title!=null)
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontSize: Theme.of(context).textTheme.titleLarge!.fontSize!*0.85,
                            ),
                            child: widget.title!,
                          ),
                        if (filtered!=null)
                          subtitle,
                      ],
                    ),
                  ),
                ),
              ],
            ),
            elevation: 0,
            actions: actions,
            initialExpandedAction: widget.addSearchAction && widget.searchActionExpandedByDefault
                ? (actions.first as ActionFromZero) : null,
            onExpanded: (_) {
              autofocusSearchOnNextBuild = true;
            },
          ),
        );
      },
    );
    return result;
  }

  ActionFromZero buildSearchAction() {
    return ActionFromZero(
      title: 'Buscar...',
      icon: const Icon(Icons.search),
      breakpoints: {0: ActionState.expanded},
      centerExpanded: false,
      expandedBuilder: ({
        required BuildContext context,
        required String title,
        Widget? icon,
        ContextCallback? onTap,
        String? disablingError,
        Color? color,
      }) {
        if (autofocusSearchOnNextBuild) {
          autofocusSearchOnNextBuild = false;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            searchTextfieldFocusNode.requestFocus();
          });
        }
        return Container(
          width: 224,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            children: [
              TextFormField(
                initialValue: searchQuery,
                focusNode: searchTextfieldFocusNode,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(left: 8, right: 8+28, bottom: 12,),
                  labelText: "Buscar...",
                ),
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  searchQuery = value;
                  widget.controller.filter();
                },
                onFieldSubmitted: (value) {
                  final filtered = widget.controller.filtered;
                  if (filtered.isNotEmpty){
                    submitSearch();
                  }
                },
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1, right: 4),
                    child: IconButton(
                      icon: const Icon(Icons.search),
                      color: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Colors.white,
                      onPressed: submitSearch,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void submitSearch() {
    final filtered = widget.controller.filtered;
    searchTextfieldFocusNode.unfocus();
    if (searchQuery.isNotNullOrBlank && filtered.length==1) {
      filtered.first.onRowTap?.call(filtered.first);
    }
  }

  List<RowModel<T>> defaultOnFilter(List<RowModel<T>> rows) {
    List<RowModel<T>> starts = [];
    List<RowModel<T>> contains = [];
    if (searchQuery==null || searchQuery!.isEmpty) {
      return rows;
    } else {
      final q = this.searchQuery!.trim().toUpperCase();
      for (final e in rows) {
        if (e.id is DAO) {
          final value = (e.id as DAO).searchName.toUpperCase();
          if (value.contains(q)) {
            if (value.startsWith(q)) {
              starts.add(e);
            } else {
              contains.add(e);
            }
          }
        } else {
          for (final v in e.values.values) {
            final value = v.toString().toUpperCase();
            if (value.contains(q)) {
              if (value.startsWith(q)) {
                starts.add(e);
              } else {
                contains.add(e);
              }
              break;
            }
          }
        }
      }
      return [...starts, ...contains];
    }

  }

}
