import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:from_zero_ui/src/table/table_from_zero.dart';
import 'package:from_zero_ui/src/table/table_from_zero_models.dart';


class TableHeaderFromZero extends StatelessWidget {

  final TableController controller;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onShowAppbarContextMenu;
  final bool showElementCount;

  const TableHeaderFromZero({
    required this.controller,
    required this.title,
    this.actions,
    this.leading,
    this.onShowAppbarContextMenu,
    this.showElementCount = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        List<RowModel>? filtered;
        try {
          filtered = controller.filtered;
        } catch (_) {}
        int selectedCount = filtered==null ? 0
            : filtered.where((e) => e.selected==true).length;
        Widget subtitle;
        if (selectedCount==0) {
          if (filtered!=null && showElementCount) {
            subtitle = Text(filtered.length==0 ? FromZeroLocalizations.of(context).translate('no_elements')
                : '${filtered.length} ${filtered.length>1 ? FromZeroLocalizations.of(context).translate('element_plur')
                : FromZeroLocalizations.of(context).translate('element_sing')}',
              // key: ValueKey('normal'),
              style: Theme.of(context).textTheme.caption,
            );
          } else {
            subtitle = SizedBox.shrink();
          }
        } else {
          subtitle = Text('$selectedCount/${filtered!.length} ${selectedCount>1 ? FromZeroLocalizations.of(context).translate('selected_plur')
              : FromZeroLocalizations.of(context).translate('selected_sing')}',
            // key: ValueKey('selected'),
            style: Theme.of(context).textTheme.caption,
          );
        }
        subtitle = AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
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
            appBarTheme: AppBarTheme(
              color: Material.of(context)!.color ?? Theme.of(context).cardColor, // Colors.transparent
              iconTheme: Theme.of(context).iconTheme,
              titleTextStyle: Theme.of(context).textTheme.subtitle1,
              toolbarTextStyle: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          child: AppbarFromZero(
            titleSpacing: 0,
            onShowContextMenu: onShowAppbarContextMenu,
            title: Row(
              children: [
                if (leading==null)
                  SizedBox(width: 24,),
                if (leading!=null)
                  ... [
                    SizedBox(width: 20,),
                    leading!,
                    SizedBox(width: 9,),
                  ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (title!=null)
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.headline6!,
                        child: title!,
                      ),
                    if (filtered!=null)
                      subtitle,
                  ],
                ),
              ],
            ),
            elevation: 0,
            actions: actions,
          ),
        );
      },
    );
  }

}
