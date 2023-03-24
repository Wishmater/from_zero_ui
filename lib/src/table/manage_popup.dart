import 'package:animations/animations.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';


abstract class TableFromZeroManagePopup {

  static Future<ManagePopupResult> showDefaultManagePopup<T>({
    required BuildContext context,
    required TableController<T> controller,
  }) async {
    final columns = controller.columns!;
    final columnKeys = controller.columnKeys!;
    final columnVisibility = {
      for (final e in columnKeys)
        e: controller.currentColumnKeys!.contains(e)
    };
    final filterButtonGlobalKeys = {
      for (final e in columnKeys)
        e: GlobalKey(),
    };
    bool modified = false;
    bool modifiedFilters = false;
    await showModal(
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
                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: scrollController,
                        shrinkWrap: true,
                        slivers: [
                          SliverToBoxAdapter(child: SizedBox(height: 16),),
                          SliverReorderableList(
                            proxyDecorator: (child, index, animation) {
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: ColoredBox(color: Colors.blue.withOpacity(0.33)),
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
                                      child: Icon(Icons.reorder),
                                    );
                                  }
                                  final subtitleText = col.getMetadataText(context, controller.filtered, key);
                                  final dividerColor = Color.alphaBlend(Theme.of(context).dividerColor, Theme.of(context).cardColor);
                                  final dividerIndent = isDesktop ? 50.0 : 0.0;
                                  Widget result = Column(
                                    children: [
                                      if (index==0)
                                        Divider(height: 1, color: dividerColor, indent: dividerIndent),
                                      Divider(height: 0, color: dividerColor, indent: dividerIndent),
                                      ListTile(
                                        horizontalTitleGap: 8,
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
                                                    icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
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
                                                  return TableFromZeroState.getOpenFilterPopupAction(context,
                                                    controller: controller,
                                                    col: col,
                                                    colKey: key,
                                                    globalKey: filterButtonGlobalKeys[key],
                                                    updateStateIfModified: false,
                                                    onPopupResult: (value) {
                                                      modifiedFilters = modifiedFilters || value;
                                                      if (value) {
                                                        itemSetState(() {});
                                                      }
                                                    },
                                                  ).buildIcon(context);
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
                          SliverToBoxAdapter(child: SizedBox(height: 16+42,),),
                        ],
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
                              padding: EdgeInsets.only(bottom: 8, right: 16,),
                              color: Theme.of(context).cardColor,
                              child: TooltipFromZero(
                                message: visibleColumns.isEmpty
                                    ? 'Debe haber al menos 1 columna visible'
                                    : null,
                                child: FlatButton(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(FromZeroLocalizations.of(context).translate('accept_caps'),
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  textColor: Colors.blue,
                                  onPressed: visibleColumns.isEmpty ? null : () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ),
        );
      },
    );
    controller.currentColumnKeys = columnKeys.where((e) => columnVisibility[e]!).toList();
    return ManagePopupResult(modified, modifiedFilters);
  }

}

class ManagePopupResult{
  final bool modified;
  final bool filtersModified;
  ManagePopupResult(this.modified, this.filtersModified);
}