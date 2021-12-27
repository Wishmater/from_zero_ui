import 'package:flutter/material.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/expansion_tile_from_zero.dart';
import 'package:from_zero_ui/util/my_popup_menu.dart' as my_popup_menu_button;
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/src/go_route_match.dart';


class ResponsiveDrawerMenuDivider extends ResponsiveDrawerMenuItem{

  Widget? widget;
  ResponsiveDrawerMenuDivider({String? title, this.widget}) : super(
    title: title ?? '',
  );

}

class ResponsiveDrawerMenuItem{

  final String title;
  final String? subtitle;
  final String? subtitleRight;
  final String? route;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? queryParams;
  final Widget? icon;
  final List<ResponsiveDrawerMenuItem>? children;
  final int selectedChild;
  final bool Function()? onTap;
  final bool executeBothOnTapAndDefaultOnTap;
  final bool forcePopup;
  final bool defaultExpanded;
  final Widget? customExpansionTileTrailing;
  final bool dense;
  final double titleHorizontalOffset;
  final Key? itemKey;

  ResponsiveDrawerMenuItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.params,
    this.queryParams,
    this.children,
    this.selectedChild = -1,
    this.onTap,
    this.forcePopup = false,
    this.executeBothOnTapAndDefaultOnTap = false,
    this.defaultExpanded = false,
    this.customExpansionTileTrailing,
    this.dense = false,
    this.titleHorizontalOffset = 0,
    this.subtitleRight,
    this.itemKey,
  });

  static List<ResponsiveDrawerMenuItem> fromGoRoutes({
    required List<GoRouteFromZero> routes,
    bool excludeRoutesThatDontWantToShow = false,
    Map<String, dynamic>? params,
    Map<String, dynamic>? queryParams,
    bool dense = false,
    bool forcePopup = false,
    double titleHorizontalOffset = 0,
  }) {
    if (excludeRoutesThatDontWantToShow) {
      routes = routes.where((e) => e.showInDrawerNavigation).toList();
    }
    return routes.mapIndexed((i, e) {
      final children = fromGoRoutes(
        routes: e.routes,
        params: params,
        queryParams: queryParams,
        dense: dense,
        forcePopup: forcePopup,
        titleHorizontalOffset: titleHorizontalOffset,
        excludeRoutesThatDontWantToShow: true,
      );
      if (e is GoRouteGroupFromZero) {
        return <ResponsiveDrawerMenuItem>[
          if (i>0)
            ResponsiveDrawerMenuDivider(title: e.title),
          ...children,
          if (i<routes.lastIndex)
            ResponsiveDrawerMenuDivider(),
        ];
      } else {
        return [
          ResponsiveDrawerMenuItem(
            title: e.title ?? '',
            icon: e.icon,
            route: e.name,
            children: e.childrenAsDropdownInDrawerNavigation ? children : [],
            params: params,
            queryParams: queryParams,
            dense: dense,
            forcePopup: forcePopup,
            titleHorizontalOffset: titleHorizontalOffset,
          ),
          if (!e.childrenAsDropdownInDrawerNavigation)
            ...children,
        ];
      }
    }).expand((e) => e).toList();
  }

  ResponsiveDrawerMenuItem copyWith({
    String? title,
    String? subtitle,
    String? subtitleRight,
    String? route,
    Map<String, dynamic>? arguments,
    Widget? icon,
    List<ResponsiveDrawerMenuItem>? children,
    int? selectedChild,
    bool Function()? onTap,
    bool? executeBothOnTapAndDefaultOnTap,
    bool? forcePopup,
    bool? defaultExpanded,
    Widget? customExpansionTileTrailing,
    bool? dense,
    double? titleHorizontalOffset,
    Key? itemKey,
  }){
    return ResponsiveDrawerMenuItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      subtitleRight: subtitleRight ?? this.subtitleRight,
      route: route ?? this.route,
      params: arguments ?? this.params,
      icon: icon ?? this.icon,
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      onTap: onTap ?? this.onTap,
      executeBothOnTapAndDefaultOnTap: executeBothOnTapAndDefaultOnTap ?? this.executeBothOnTapAndDefaultOnTap,
      forcePopup: forcePopup ?? this.forcePopup,
      defaultExpanded: defaultExpanded ?? this.defaultExpanded,
      customExpansionTileTrailing: customExpansionTileTrailing ?? this.customExpansionTileTrailing,
      dense: dense ?? this.dense,
      titleHorizontalOffset: titleHorizontalOffset ?? this.titleHorizontalOffset,
      itemKey: itemKey ?? this.itemKey,
    );
  }

  String get uniqueId => title.toString()+subtitle.toString()+(icon?.toStringShort()).toString()+route.toString();

}

class DrawerMenuFromZero extends ConsumerStatefulWidget {

  static const int goRouter = 10;
  @deprecated
  static const int alwaysReplaceInsteadOfPushing = 1;
  @deprecated
  static const int neverReplaceInsteadOfPushing = 2;
  @deprecated
  static const int exceptRootReplaceInsteadOfPushing = 0;

  static const int styleDrawerMenu = 0;
  static const int styleTree = 1;

  final List<ResponsiveDrawerMenuItem>? parentTabs; /// Only used for smart pushing algorithm
  final List<ResponsiveDrawerMenuItem> tabs;
  final int selected;
  final bool compact;
  final int replaceInsteadOfPushing; // TODO refactor to
  final int depth;
  final double paddingRight;
  final bool popup;
  final String? homeRoute;
  final int style;
  final List<bool> paintPreviousTreeLines;
  final bool inferSelected;

  DrawerMenuFromZero({
    required this.tabs,
    this.parentTabs,
    @deprecated
    this.selected = -1,
    this.compact = false,
    @deprecated
    this.replaceInsteadOfPushing = goRouter,
    this.depth = 0,
    this.paddingRight = 0,
    this.popup = false,
    this.style = styleDrawerMenu,
    this.paintPreviousTreeLines = const[],
    this.inferSelected = true,
    String? homeRoute,
  }) : this.homeRoute = homeRoute ?? tabs[0].route;

  @override
  _DrawerMenuFromZeroState createState() => _DrawerMenuFromZeroState();

  @deprecated
  static double calculateHeight(List<ResponsiveDrawerMenuItem> tabs){
    double sum = 0;
    tabs.forEach((element) {
      if (element is ResponsiveDrawerMenuDivider){
        sum += element.title.isEmpty ? 13 : 32;
      } else{
        sum += 49;
      }
    });
    return sum;
  }

}

class _DrawerMenuFromZeroState extends ConsumerState<DrawerMenuFromZero> {

  Map<int, GlobalKey> _menuButtonKeys = {};
  late List<ResponsiveDrawerMenuItem> _tabs;
  late int _selected;
  bool pendingUpdate = false;

  @override
  void initState() {
    super.initState();
    pendingUpdate = true;
  }

  @override
  void didUpdateWidget(covariant DrawerMenuFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.tabs.contentEquals(oldWidget.tabs, (a, b)=>a.route==b.route)) {
      pendingUpdate = true;
    }
  }

  void _updateTabs() {
    pendingUpdate = false;
    _tabs = List.from(widget.tabs);
    _selected = widget.selected;
    if (widget.selected<0 && widget.inferSelected) {

      if (widget.replaceInsteadOfPushing == DrawerMenuFromZero.goRouter) {
        final goRouter = GoRouter.of(context);
        final location = goRouter.location;
        final matches = goRouter.routerDelegate.matches;
        final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
        Map<ResponsiveDrawerMenuItem, String> computedNames = {};
        int Function(List<ResponsiveDrawerMenuItem>, GoRouteMatch)? getSelectedIndex;
        getSelectedIndex = (tabs, match) {
          for (int i=0; i<tabs.length; i++) {
            final e = tabs[i];
            if (e.route!=null) {
              if (!computedNames.containsKey(e)) {
                computedNames[e] = goRouter.namedLocation(e.route!);
              }
              final computedName = computedNames[e]!;
              if (e.children!=null) {
                int innerIndex = getSelectedIndex!(e.children!, match);
                if (innerIndex>=0) {
                  tabs[i] = e.copyWith(
                    selectedChild: innerIndex,
                  );
                  scaffoldChangeNotifier.isTreeNodeExpanded[e.uniqueId] = true;
                  return i;
                }
              }
              if (computedName == location) {
                return i;
              }
            }
          }
          return -1;
        };
        for (int i=matches.lastIndex; i>=0 && _selected<0; i--) {
          _selected = getSelectedIndex(_tabs, matches[i]);
        }

      } else {

        // old deprecated way of inferring the selected route
        try {
          String location = widget.replaceInsteadOfPushing == DrawerMenuFromZero.goRouter
              ? GoRouter.of(context).location
              : ModalRoute.of(context)!.settings.name!;
          List<String> paths = location.split('/')..removeWhere((e) => e.isEmpty);
          String cumulativePath = '';
          if (widget.homeRoute!=null) {
            List<String> homeRoutePaths = widget.homeRoute!.split('/')..removeWhere((e) => e.isEmpty);
            if (homeRoutePaths.isNotEmpty) {
              homeRoutePaths.removeLast();
              while (homeRoutePaths.isNotEmpty && homeRoutePaths[0]==paths[0]) {
                cumulativePath += '/${paths[0]}';
                homeRoutePaths.removeAt(0);
                paths.removeAt(0);
              }
            }
          }
          for (var i = 0; i < paths.length; ++i) {
            cumulativePath += '/${paths[i]}';
            if (i==0) {
              _selected = _tabs.indexWhere((e) => e.route==cumulativePath);
            } else {
              if (_selected<0) {
                break;
              }
              ResponsiveDrawerMenuItem item = _tabs[_selected];
              for (var j = 0; j < i-1; ++j) {
                item = item.children![item.selectedChild];
              }
              if (item.selectedChild>=0) break;
              _tabs[_selected] = item.copyWith(
                selectedChild: item.children?.indexWhere((e) => e.route==cumulativePath) ?? -1,
              );
            }
          }
        } catch (e, st) {
          // print(e);
          // print(st);
        }

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pendingUpdate) {
      _updateTabs();
    }
    return Column(
      children: _getWidgets(context, _tabs, _selected),
    );
  }

  List<Widget> _getWidgets(BuildContext context, List<ResponsiveDrawerMenuItem> tabs, int selected){
    List<Widget> result = List.generate(tabs.length, (i) {
      if (tabs[i] is ResponsiveDrawerMenuDivider){

        ResponsiveDrawerMenuDivider divider = tabs[i] as ResponsiveDrawerMenuDivider;
        if (divider.widget!=null){
          return divider.widget!;
        } else{
          double height = widget.compact||tabs[i].title.isNullOrEmpty ? 13 : 32;
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
                    SizedBox(height: 6,),
                    Divider(height: 1,),
                    tabs[i].title.isEmpty ? SizedBox(height: 6,) : Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Text(tabs[i].title, style: Theme.of(context).textTheme.caption,),
                    )
                  ],
                ),
              ),
            ),
          );
        }

      } else{

        Future<bool> Function() onTap;
        if (widget.replaceInsteadOfPushing==DrawerMenuFromZero.goRouter) {

          onTap = (tabs[i].onTap!=null && !tabs[i].executeBothOnTapAndDefaultOnTap)
              ? () async {
                return tabs[i].onTap?.call() ?? false;
              }
              : () async {
                bool result;
                result = tabs[i].onTap?.call() ?? false;
                if (i!=selected && tabs[i].route!=null) {
                  GoRouter.of(context).goNamed(
                    tabs[i].route!,
                    params: (tabs[i].params??{}).map((key, value) => MapEntry(key, value.toString())),
                    queryParams: (tabs[i].queryParams??{}).map((key, value) => MapEntry(key, value.toString())),
                  );
                }
                return result;
              };

        } else {

          // old deprecated method of smartly pushing
          onTap = (tabs[i].onTap!=null && !tabs[i].executeBothOnTapAndDefaultOnTap)
              ? () async {
            // if (widget.popup) Navigator.of(context).pop();
            return tabs[i].onTap?.call() ?? false;
          }
              : () async {
            bool result;
            result = tabs[i].onTap?.call() ?? false;
            if (i!=selected && tabs[i].route!=null) {
              var navigator = Navigator.of(context);
              try{
                var scaffold = Scaffold.of(context);
                if (scaffold.hasDrawer && scaffold.isDrawerOpen)
                  navigator.pop();
              } catch(_, __){}
              if (widget.replaceInsteadOfPushing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPushing){
                // ! this will break if the homeRoute is NOT in the stack
                if (selected>=0 && tabs[selected].route==widget.homeRoute){
                  navigator.pushNamed(
                    tabs[i].route!,
                    arguments: {...(tabs[i].params??{}), ...(tabs[i].queryParams??{})},
                  );
                } else{
                  if (tabs[i].route==widget.homeRoute){
                    if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                      navigator.popUntil(ModalRoute.withName(widget.homeRoute!));
                    }
                  } else{
                    if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                      navigator.pushNamedAndRemoveUntil(
                        tabs[i].route!,
                        ModalRoute.withName(widget.homeRoute!),
                        arguments: {...(tabs[i].params??{}), ...(tabs[i].queryParams??{})},
                      );
                    }
                  }
                }
              } else if (widget.replaceInsteadOfPushing == DrawerMenuFromZero.neverReplaceInsteadOfPushing){
                navigator.pushNamed(
                  tabs[i].route!,
                  arguments: {...(tabs[i].params??{}), ...(tabs[i].queryParams??{})},
                );
              } else if (widget.replaceInsteadOfPushing == DrawerMenuFromZero.alwaysReplaceInsteadOfPushing){
                if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                  List<String> routes = [];
                  if (widget.homeRoute!=null) {
                    routes.add(widget.homeRoute!);
                  }
                  Function(List<ResponsiveDrawerMenuItem>)? addRoutes;
                  addRoutes = (List<ResponsiveDrawerMenuItem> items) {
                    items.forEach((e) {
                      if (e.route!=null) {
                        routes.add(e.route!);
                      }
                      addRoutes!(e.children ?? []);
                    });
                  };
                  addRoutes(widget.parentTabs ?? _tabs);
                  bool passed = false;
                  navigator.pushNamedAndRemoveUntil(
                    tabs[i].route!,
                        (Route<dynamic> route) {
                      if (passed || route.isFirst) return true;
                      if (routes.contains(route.settings.name)){
                        passed = true;
                      }
                      return false;
                    },
                    arguments: {...(tabs[i].params??{}), ...(tabs[i].queryParams??{})},
                  );
                }
              }
              result = true;
            }
            return result; //false
          };

        }

        Widget result;

        if (tabs[i].children!=null && (tabs[i].children?.isNotEmpty??false)){

          if (!_menuButtonKeys.containsKey(i)) _menuButtonKeys[i] = GlobalKey();
          final scaffoldChangeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
          result = my_popup_menu_button.PopupMenuButton(
            enabled: false,
            child: ExpansionTileFromZero(
              initiallyExpanded: selected==i || tabs[i].selectedChild>=0,
              expanded: widget.compact||tabs[i].forcePopup ? false
                  : scaffoldChangeNotifier.isTreeNodeExpanded[tabs[i].uniqueId] ?? tabs[i].defaultExpanded,
              expandedAlignment: Alignment.topCenter,
              style: widget.style,
              actionPadding: EdgeInsets.only(
                left: widget.style==DrawerMenuFromZero.styleTree ? widget.depth*20.0 : 0,
              ),
              title: getTreeOverlay(
                DrawerMenuButtonFromZero(
                  key: tabs[i].itemKey,
                  title: tabs[i].title,
                  subtitle: tabs[i].subtitle,
                  subtitleRight: tabs[i].subtitleRight,
                  selected: selected==i,
                  compact: widget.compact,
                  dense: tabs[i].dense,
                  titleHorizontalOffset: tabs[i].titleHorizontalOffset,
                  icon: tabs[i].icon ?? SizedBox.shrink(),
                  contentPadding: EdgeInsets.only(
                    left: widget.depth*20.0 + (widget.style==DrawerMenuFromZero.styleTree ? 16 : 0),
                    right: widget.paddingRight + (widget.style==DrawerMenuFromZero.styleDrawerMenu ? 42 : 0),
                  ),
                ), tabs, i,
              ),
              trailing: tabs[i].customExpansionTileTrailing ?? (tabs[i].forcePopup ? SizedBox.shrink() : null),
              children: [
                Stack(
                  overflow: Overflow.visible,
                  children: [
                    if (widget.style==DrawerMenuFromZero.styleDrawerMenu)
                      Positioned.fill(
                        child: Container(
                          padding: EdgeInsets.only(left: widget.depth*20.0),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 20.0, //(widget.depth+1)*20.0
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                      ),
                    DrawerMenuFromZero(
                      tabs: tabs[i].children!,
                      compact: widget.compact,
                      selected: tabs[i].selectedChild,
                      inferSelected: false,
                      depth: widget.depth+1,
                      replaceInsteadOfPushing: widget.replaceInsteadOfPushing == DrawerMenuFromZero.exceptRootReplaceInsteadOfPushing
                          ? (selected==0 ? DrawerMenuFromZero.neverReplaceInsteadOfPushing : DrawerMenuFromZero.alwaysReplaceInsteadOfPushing)
                          : widget.replaceInsteadOfPushing,
                      style: widget.style,
                      homeRoute: widget.homeRoute,
                      parentTabs: widget.parentTabs ?? _tabs,
                      paintPreviousTreeLines: [...widget.paintPreviousTreeLines, i!=tabs.length-1,],
                    ),
                  ],
                ),
              ],
              onExpansionChanged: (value) async {
                if (widget.compact||tabs[i].forcePopup){
                  if (!await onTap()){
                    (_menuButtonKeys[i]!.currentState as my_popup_menu_button.PopupMenuButtonState).showButtonMenu();
                  }
                  return false;
                } else{
                  if ((await onTap()) && value){
                    return false;
                  }
                  return true;
                }
              },
              onPostExpansionChanged: (value) {
                scaffoldChangeNotifier.isTreeNodeExpanded[tabs[i].uniqueId] = value;
              },
            ),
            key: _menuButtonKeys[i],
            tooltip: "",
            menuHorizontalPadding: 0, // TODO 1 refactor this to use ContextMenuFromZero, maybe delete my_popup_menu_button
//            menuVerticalPadding: 0,
            itemBuilder: (context) => List.generate(widget.compact||tabs[i].forcePopup ? 1 : 0,
                    (index) => my_popup_menu_button.PopupMenuItem(
              enabled: false,
              child: DrawerMenuFromZero(
                popup: true,
                tabs: tabs[i].children!,
                compact: false,
                selected: tabs[i].selectedChild,
                inferSelected: false,
                paddingRight: 16,
                replaceInsteadOfPushing: widget.replaceInsteadOfPushing,
                homeRoute: widget.homeRoute,
                parentTabs: widget.parentTabs ?? _tabs,
                style: widget.style,
              ),
            )),
          );

        } else{

          result = getTreeOverlay(
            DrawerMenuButtonFromZero(
              key: tabs[i].itemKey,
              title: tabs[i].title,
              subtitle: tabs[i].subtitle,
              subtitleRight: tabs[i].subtitleRight,
              selected: selected==i,
              compact: widget.compact,
              icon: tabs[i].icon ?? SizedBox.shrink(),
              onTap: onTap,
              dense: tabs[i].dense,
              titleHorizontalOffset: tabs[i].titleHorizontalOffset,
              contentPadding: EdgeInsets.only(
                left: widget.depth*20.0 + (widget.style==DrawerMenuFromZero.styleTree ? 16 : 0),
                right: widget.paddingRight,
              ),
            ), tabs, i,
          );

        }

        return result;

      }
    });
    return result;
  }

  Widget getTreeOverlay(Widget child, List<ResponsiveDrawerMenuItem> tabs, int i,){
    if (widget.style==DrawerMenuFromZero.styleTree){
      return Stack(
        overflow: Overflow.visible,
        children: [
          child,
          if (widget.depth>0)
            Positioned(
              left: 11, right: 0, bottom: -1, top: -1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.depth, (index) {
                  if (index!=widget.depth-1 && widget.paintPreviousTreeLines[index+1]==false){
                    return SizedBox(width: 20,);
                  }
                  return FractionallySizedBox(
                    heightFactor: index==widget.depth-1 && i==tabs.length-1 ? 0.5 : 1,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 20, height: double.infinity,
                      child: VerticalDivider(
                        thickness: 2, width: 2,
                        color: Color.alphaBlend(Theme.of(context).dividerColor.withOpacity(Theme.of(context).dividerColor.opacity*3), Material.of(context)!.color!),
                      ),
                    ),
                  );
                }),
              ),
            ),
          if (widget.depth>0)
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.only(left: 20.0*widget.depth,),
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: (tabs[i].children==null || tabs[i].children!.isEmpty) ? 24: 12,
                  child: Divider(
                    thickness: 2, height: 2,
                    color: Color.alphaBlend(Theme.of(context).dividerColor.withOpacity(Theme.of(context).dividerColor.opacity*3), Material.of(context)!.color!),
                  ),
                ),
              ),
            ),
        ],
      );
    } else{
      return child;
    }
  }

}


class DrawerMenuButtonFromZero extends StatefulWidget {

  final bool selected;
  final bool compact;
  final String title;
  final String? subtitle;
  final String? subtitleRight;
  final Widget? icon;
  final GestureTapCallback? onTap;
  final Color? selectedColor;
  final EdgeInsets contentPadding;
  final bool dense;
  final double titleHorizontalOffset;

  DrawerMenuButtonFromZero({Key? key, this.selected=false, this.compact=false, required this.title,
      this.subtitle, this.icon, this.onTap, this.selectedColor, this.dense=false,
      this.contentPadding = const EdgeInsets.only(left: 0), this.titleHorizontalOffset=0,
      this.subtitleRight}) : super(key: key);

  @override
  _DrawerMenuButtonFromZeroState createState() => _DrawerMenuButtonFromZeroState(selectedColor);

}

class _DrawerMenuButtonFromZeroState extends State<DrawerMenuButtonFromZero> {

  Color? selectedColor;

  _DrawerMenuButtonFromZeroState(this.selectedColor);

  @override
  Widget build(BuildContext context) {
    if (widget.selectedColor==null){
      selectedColor = Theme.of(context).brightness==Brightness.dark
          ? Theme.of(context).accentColor
          : Theme.of(context).primaryColor;
    }
    return Container(
      color: widget.selected
          ? selectedColor!.withOpacity(0.05)
          : Colors.transparent,
      child: ListTile(
        selected: widget.selected,
        title: Transform.translate(
          offset: Offset(widget.titleHorizontalOffset, 0),
          child: Text(widget.title, style: TextStyle(
              fontSize: 16,
              color: widget.selected ? selectedColor : Theme.of(context).textTheme.bodyText1!.color
          ),),
        ),
        subtitle: widget.subtitle==null||widget.compact ? null
            : Transform.translate(
              offset: Offset(widget.titleHorizontalOffset, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.subtitle!, style: TextStyle(
                        color: widget.selected ? selectedColor!.withOpacity(0.75)
                            : Theme.of(context).textTheme.caption!.color
                    ),),
                  ),
                  if (widget.subtitleRight!=null)
                    Text(widget.subtitleRight!, style: TextStyle(
                        color: widget.selected ? selectedColor!.withOpacity(0.75)
                            : Theme.of(context).textTheme.caption!.color
                      ),
                      textAlign: TextAlign.right,
                    ),
                ],
              ),
            ),
        contentPadding: widget.contentPadding,
        dense: widget.dense,
        mouseCursor: SystemMouseCursors.click,
        leading: Padding(
          padding: EdgeInsets.only(left: widget.dense ? 4 : 0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Builder(
              builder: (context) {
                Widget result = SizedBox.expand(
                  child: widget.compact ? TooltipFromZero(
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
//      leading: SizedBox(width: 1, height: 1,),
        onTap: widget.onTap,
      ),
    );
  }

}
