import 'package:flutter/material.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/expansion_tile_from_zero.dart';
import 'package:from_zero_ui/util/my_popup_menu.dart' as my_popup_menu_button;
import 'package:flutter/rendering.dart';

class ResponsiveDrawerMenuDivider extends ResponsiveDrawerMenuItem{

  ResponsiveDrawerMenuDivider({String title}) : super(
    title: title,
  );

}

class ResponsiveDrawerMenuItem{

  final String title;
  final String subtitle;
  final String route;
  final Widget icon;
  final List<ResponsiveDrawerMenuItem> children; //TODO 2 implement multilevel / children
  final int selectedChild;
  final bool Function() onTap;
  final bool forcePopup;

  ResponsiveDrawerMenuItem({
    @required this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.children,
    this.selectedChild = -1,
    this.onTap,
    this.forcePopup = false,
  });

  ResponsiveDrawerMenuItem copyWith({
    title,
    icon,
    route,
    children,
    selectedChild,
    subtitle,
    onTap,
    forcePopup,
  }){
    return ResponsiveDrawerMenuItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      onTap: onTap ?? this.onTap,
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      forcePopup: forcePopup ?? this.forcePopup,
    );
  }

}

class DrawerMenuFromZero extends StatefulWidget {

  static const int alwaysReplaceInsteadOfPuhsing = 1;
  static const int neverReplaceInsteadOfPuhsing = 2;
  static const int exceptRootReplaceInsteadOfPuhsing = 0;

  final List<ResponsiveDrawerMenuItem> tabs;
  int selected;
  final bool compact;
  final int replaceInsteadOfPuhsing;
  final int depth;
  final double paddingRight;

  DrawerMenuFromZero({
    @required this.tabs,
    int selected = 0,
    this.compact = false,
    this.replaceInsteadOfPuhsing = exceptRootReplaceInsteadOfPuhsing,
    this.depth = 0,
    this.paddingRight = 0,
  }){
    for (int i=0; i<=selected && i<tabs.length; i++){
      if (tabs[i] is ResponsiveDrawerMenuDivider){
        selected++;
      }
    }
    this.selected = selected;
  }

  @override
  _DrawerMenuFromZeroState createState() => _DrawerMenuFromZeroState();

}

class _DrawerMenuFromZeroState extends State<DrawerMenuFromZero> {

  List<GlobalKey> _menuButtonKeys = [];

  @override
  void initState() {
    super.initState();
    widget.tabs.forEach((element) {
      _menuButtonKeys.add(element.children==null ? null : GlobalKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _getWidgets(context, widget.tabs, widget.selected),
    );
  }

  List<Widget> _getWidgets(BuildContext context, List<ResponsiveDrawerMenuItem> tabs, int selected){
    List<Widget> result = List.generate(tabs.length, (i) {
      if (tabs[i] is ResponsiveDrawerMenuDivider){

        double height = widget.compact||tabs[i].title==null ? 17 : 32;
        return Padding(
          padding: EdgeInsets.only(left: widget.depth*20.0),
          child: AnimatedContainer(
            duration: 300.milliseconds,
            height: height,
            curve: Curves.easeOut,
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8,),
                  Divider(height: 1,),
                  tabs[i].title==null ? SizedBox(height: 8,) : Padding(
                    padding: const EdgeInsets.only(left: 64),
                    child: Text(tabs[i].title, style: Theme.of(context).textTheme.caption,),
                  )
                ],
              ),
            ),
          ),
        );

      } else{

        final onTap = tabs[i].onTap ?? () async {
          if (i!=selected && tabs[i].route!=null) {
            var navigator = Navigator.of(context);
            try{
              var scaffold = Scaffold.of(context);
              if (scaffold.hasDrawer && scaffold.isDrawerOpen)
                navigator.pop();
            } catch(_, __){}
            if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPuhsing){
              if (selected==0){
                navigator.pushNamed(tabs[i].route);
              } else{
                if (i==0){
                  if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                    navigator.pop();
                  }
                } else{
                  if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                    navigator.pushReplacementNamed(tabs[i].route);
                  }
                }
              }
            } else if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.neverReplaceInsteadOfPuhsing){
              navigator.pushNamed(tabs[i].route);
            } else if (widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.alwaysReplaceInsteadOfPuhsing){
              if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                navigator.pushReplacementNamed(tabs[i].route);
              }
            }
            return true;
          }
          return false;
        };
        if (tabs[i].children!=null && tabs[i].children.isNotEmpty){

          return my_popup_menu_button.PopupMenuButton(
            enabled: false,
            child: ExpansionTileFromZero(
              initiallyExpanded: selected==i || tabs[i].selectedChild!=null&&tabs[i].selectedChild>=0,
              expanded: widget.compact||tabs[i].forcePopup ? false : null,
              expandedAlignment: Alignment.topCenter,
              title: DrawerMenuButtonFromZero(
                title: tabs[i].title,
                subtitle: tabs[i].subtitle,
                selected: selected==i,
                compact: widget.compact,
                icon: tabs[i].icon ?? SizedBox.shrink(),
                contentPadding: EdgeInsets.only(left: widget.depth*20.0, right: widget.paddingRight),
              ),
              children: [
                Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        padding: EdgeInsets.only(left: widget.depth*20.0),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: (widget.depth+1)*20.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(topRight: Radius.circular(999999)),
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),
                    DrawerMenuFromZero(
                      tabs: tabs[i].children,
                      compact: widget.compact,
                      selected: tabs[i].selectedChild,
                      depth: widget.depth+1,
                      replaceInsteadOfPuhsing: widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPuhsing
                          ? (selected==0 ? DrawerMenuFromZero.neverReplaceInsteadOfPuhsing : DrawerMenuFromZero.alwaysReplaceInsteadOfPuhsing)
                          : widget.replaceInsteadOfPuhsing,
                    ),
                  ],
                ),
              ],
              onExpansionChanged: (value) async {
                if (widget.compact||tabs[i].forcePopup){
                  if (!await onTap()){
                    (_menuButtonKeys[i].currentState as my_popup_menu_button.PopupMenuButtonState).showButtonMenu();
                  }
                  return false;
                } else{
                  if ((await onTap()) && value){
                    return false;
                  }
                  return true;
                }
              },
            ),
            key: _menuButtonKeys[i],
            tooltip: "",
            offset: Offset(widget.compact ? 56 : 304, -7),
            menuHorizontalPadding: 0,
//            menuVerticalPadding: 0,
            itemBuilder: (context) => List.generate(widget.compact||tabs[i].forcePopup ? 1 : 0,
                    (index) => my_popup_menu_button.PopupMenuItem(
              enabled: false,
              child: DrawerMenuFromZero(
                tabs: tabs[i].children,
                compact: false,
                selected: tabs[i].selectedChild,
                paddingRight: 16,
                replaceInsteadOfPuhsing: widget.replaceInsteadOfPuhsing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPuhsing
                    ? (selected==0 ? DrawerMenuFromZero.neverReplaceInsteadOfPuhsing : DrawerMenuFromZero.alwaysReplaceInsteadOfPuhsing)
                    : widget.replaceInsteadOfPuhsing,
              ),
            )),
          );

        } else{

          return DrawerMenuButtonFromZero(
            title: tabs[i].title,
            subtitle: tabs[i].subtitle,
            selected: selected==i,
            compact: widget.compact,
            icon: tabs[i].icon ?? SizedBox.shrink(),
            contentPadding: EdgeInsets.only(left: widget.depth*20.0, right: widget.paddingRight),
            onTap: onTap,
          );

        }

      }
    });
    return result;
  }

}


class DrawerMenuButtonFromZero extends StatefulWidget {

  final bool selected;
  final bool compact;
  final String title;
  final String subtitle;
  final Widget icon;
  final GestureTapCallback onTap;
  final Color selectedColor;
  final EdgeInsets contentPadding;
  bool dense;

  DrawerMenuButtonFromZero({this.selected=false, this.compact=false, this.title,
      this.subtitle, this.icon, this.onTap, this.selectedColor, this.dense=false,
    this.contentPadding = const EdgeInsets.only(left: 0)});

  @override
  _DrawerMenuButtonFromZeroState createState() => _DrawerMenuButtonFromZeroState(selectedColor);

}

class _DrawerMenuButtonFromZeroState extends State<DrawerMenuButtonFromZero> {

  Color selectedColor;

  _DrawerMenuButtonFromZeroState(this.selectedColor);

  @override
  Widget build(BuildContext context) {
    if (widget.selectedColor==null){
      selectedColor = Theme.of(context).brightness==Brightness.dark
          ? Theme.of(context).accentColor
          : Theme.of(context).primaryColor;
    }
    return Container(
      color: widget.selected&&!widget.dense
          ? selectedColor.withOpacity(0.05)
          : Colors.transparent,
      child: ListTile(
        selected: widget.selected,
        title: Text(widget.title, style: TextStyle(
          fontSize: 16,
          color: widget.selected ? selectedColor : Theme.of(context).textTheme.bodyText1.color
        ),),
        subtitle: widget.subtitle==null||widget.compact ? null
            : Text(widget.subtitle, style: TextStyle(
              color: widget.selected ? selectedColor.withOpacity(0.75)
                : Theme.of(context).textTheme.caption.color
        ),),
        contentPadding: widget.contentPadding,
        dense: widget.dense,
        mouseCursor: SystemMouseCursors.click,
        leading: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.dense ? 4 : 0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Builder(
              builder: (context) {
                Widget result = SizedBox.expand(
                  child: widget.compact ? Tooltip(
                    message: widget.title,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: widget.icon,
                    ),
                  ) : Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: widget.icon,
                  ),
                );
                result = IconTheme(
                  data: Theme.of(context).iconTheme.copyWith(
                    color: widget.selected ? selectedColor
                        : Theme.of(context).brightness==Brightness.light? Colors.black45 : null,
                  ),
                  child: result,
                );
                return result;
              }
            ),
          ),
        ),
        onTap: widget.onTap,
      ),
    );
  }

}
