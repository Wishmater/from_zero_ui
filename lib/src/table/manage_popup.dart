import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


abstract class TableFromZeroManagePopup {

  static Future<ManagePopupResult> showDefaultManagePopup<T>({
    required BuildContext context,
    required TableController<T> controller,
  }) async {
    final columns = controller.columns!;
    final columnKeys = List.from(controller.columnKeys!);
    final columnVisibility = {
      for (final e in columnKeys)
        e: controller.currentColumnKeys!.contains(e),
    };
    final filterButtonGlobalKeys = {
      for (final e in columnKeys)
        e: GlobalKey(),
    };
    bool modified = false;
    bool modifiedFilters = false;
    final confirm = await showModalFromZero(
      context: context,
      builder: (context) {
        ScrollController scrollController = ScrollController();
        return ResponsiveInsetsDialog(
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 128*3,
            child: ScrollbarFromZero(
              controller: scrollController,
              child: StatefulBuilder(
                builder: (context, setState) {
                  final visibleColumns = columnKeys.where((e) => columnVisibility[e]!);
                  final isAnyColHidden = columnVisibility.any((key, value) => !value);
                  final clearFiltersAction = TableFromZeroState.getClearAllFiltersAction(
                    controller: controller,
                    skipConditions: true,
                    updateStateIfModified: false,
                    onDidTap: () {
                      modifiedFilters = true;
                      setState(() {});
                    },
                  )?.copyWith(
                    breakpoints: {
                      0: ActionState.icon,
                      ScaffoldFromZero.screenSizeLarge: ActionState.button,
                    },
                  );
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: scrollController,
                        shrinkWrap: true,
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 64+12),),
                          SliverReorderableList(
                            proxyDecorator: (child, index, animation) {
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: ColoredBox(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                    ),
                                  ),
                                  child,
                                ],
                              );
                            },
                            itemCount: columnKeys.length,
                            onReorder: (int oldIndex, int newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = columnKeys.removeAt(oldIndex);
                                columnKeys.insert(newIndex, item);
                                modified = true;
                              });
                            },
                            itemBuilder: (context, index) {
                              final key = columnKeys[index];
                              final col = columns[key]!;
                              bool isDesktop = PlatformExtended.isDesktop;
                              Widget result = StatefulBuilder(
                                builder: (context, itemSetState) {
                                  Widget? leading;
                                  if (isDesktop) {
                                    leading = ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.reorder),
                                    );
                                  }
                                  final subtitleText = col.getMetadataText(context, controller.filtered, key);
                                  final dividerColor = Color.alphaBlend(Theme.of(context).dividerColor, Theme.of(context).cardColor);
                                  final dividerIndent = isDesktop ? 48.0 : 0.0;
                                  Widget result = Column(
                                    children: [
                                      if (index==0)
                                        Divider(height: 1, color: dividerColor, indent: dividerIndent),
                                      Divider(height: 0, color: dividerColor, indent: dividerIndent),
                                      ListTile(
                                        title: Text(col.name),
                                        subtitle: subtitleText.isBlank ? null
                                            : Text(subtitleText),
                                        leading: leading,
                                        trailing: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              StatefulBuilder(
                                                builder: (context, actionSetState) {
                                                  final visible = columnVisibility[key]!;
                                                  return ActionFromZero(
                                                    title: visible ? 'Ocultar Columna' : 'Mostrar Columna', // TODO 3 internationalize
                                                    icon: SelectableIcon(
                                                      selected: visible,
                                                      selectedIcon: Icons.visibility,
                                                      icon: Icons.visibility_off,
                                                      selectedColor: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
                                                      unselectedOffset: 0,
                                                      selectedOffset: 0,
                                                    ),
                                                    onTap: (context) {
                                                      modified = true;
                                                      setState(() {
                                                        columnVisibility[key] = !visible;
                                                      });
                                                    },
                                                  ).buildIcon(context);
                                                },
                                              ),
                                              AnimatedBuilder(
                                                animation: controller,
                                                builder: (context, child) {
                                                  return Container(
                                                    key: filterButtonGlobalKeys[key],
                                                    child: TableFromZeroState.getOpenFilterPopupAction(context,
                                                      controller: controller,
                                                      col: col,
                                                      colKey: key,
                                                      globalKey: filterButtonGlobalKeys[key],
                                                      updateStateIfModified: false,
                                                      onPopupResult: (value) {
                                                        modifiedFilters = modifiedFilters || value;
                                                        if (value) {
                                                          // itemSetState(() {});
                                                          setState(() {}); // need to setState for the whole widget to update clearAllFilters button
                                                        }
                                                      },
                                                    ).buildIcon(context,),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Divider(height: 0, color: dividerColor, indent: dividerIndent),
                                      if (index==columnKeys.lastIndex)
                                        Divider(height: 1, color: dividerColor, indent: dividerIndent),
                                    ],
                                  );
                                  if (!isDesktop) {
                                    result = ReorderableDelayedDragStartListener(
                                      index: index,
                                      child: result,
                                    );
                                  }
                                  return result;
                                },
                              );
                              result = Material(
                                type: MaterialType.transparency,
                                key: ValueKey(key),
                                child: result,
                              );
                              return result;
                            },
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24+42,),),
                        ],
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: AppbarFromZero(
                          title: Text('Personalizar Tabla',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          backgroundColor: Theme.of(context).cardColor,
                          surfaceTintColor: Theme.of(context).cardColor,
                          elevation: 6,
                          toolbarHeight: 64,
                          actions: [
                            ActionFromZero(
                              title: isAnyColHidden ? 'Mostrar todas las columnas' : 'Ocultar todas las columnas',
                              icon: SelectableIcon(
                                selected: isAnyColHidden,
                                selectedIcon: Icons.visibility,
                                icon: Icons.visibility_off,
                                selectedColor: Theme.of(context).brightness==Brightness.light ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
                                unselectedColor: Theme.of(context).textTheme.bodyLarge!.color,
                                unselectedOffset: 0,
                                selectedOffset: 0,
                              ),
                              onTap: (context) {
                                modified = true;
                                setState(() {
                                  for (final key in columnVisibility.keys) {
                                    columnVisibility[key] = isAnyColHidden;
                                  }
                                });
                              },
                            ),
                            if (clearFiltersAction!=null)
                              clearFiltersAction,
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Theme.of(context).cardColor.withOpacity(0),
                                    Theme.of(context).cardColor,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(bottom: 8, right: 16,),
                              color: Theme.of(context).cardColor,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const DialogButton.cancel(),
                                  DialogButton.accept(
                                    tooltip: visibleColumns.isEmpty
                                        ? 'Debe haber al menos 1 columna visible'
                                        : null,
                                    onPressed: visibleColumns.isEmpty ? null : () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    if (confirm ?? false) {
      controller.columnKeys = columnKeys;
      controller.currentColumnKeys = columnKeys.where((e) => columnVisibility[e]!).toList();
    }
    return ManagePopupResult(modified||modifiedFilters, modifiedFilters);
  }

}

class ManagePopupResult{
  final bool modified;
  final bool filtersModified;
  ManagePopupResult(this.modified, this.filtersModified);
}