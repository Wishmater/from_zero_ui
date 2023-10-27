import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';


class ResponsiveDrawerMenuDivider extends ResponsiveDrawerMenuItem{

  Widget? widget;
  ResponsiveDrawerMenuDivider({String? title, this.widget}) : super(
    title: title ?? '',
  );

}

class ResponsiveDrawerMenuItem{

  final String title;
  final String? denseTitle;
  final String? subtitle;
  final String? subtitleRight;
  final String? route;
  final Map<String, String>? pathParameters;
  final Map<String, String>? queryParameters;
  final Object? extra;
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
  final List<ActionFromZero> contextMenuActions;
  final Widget Function(String title)? titleBuilder;

  ResponsiveDrawerMenuItem({
    required this.title,
    this.denseTitle,
    this.subtitle,
    this.icon,
    this.route,
    this.pathParameters,
    this.queryParameters,
    this.extra,
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
    this.contextMenuActions = const [],
    this.titleBuilder,
  });

  static List<ResponsiveDrawerMenuItem> fromGoRoutes({
    required List<GoRouteFromZero> routes,
    bool excludeRoutesThatDontWantToShow = false,
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
    bool dense = false,
    bool forcePopup = false,
    double titleHorizontalOffset = 0,
  }) {
    return routes.mapIndexed((i, e) {
      final children = fromGoRoutes(
        routes: e.routes,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
        dense: dense,
        forcePopup: forcePopup,
        titleHorizontalOffset: titleHorizontalOffset,
        excludeRoutesThatDontWantToShow: true,
      );
      if (e is GoRouteGroupFromZero) {
        if (!e.showInDrawerNavigation) {
          return <ResponsiveDrawerMenuItem>[];
        } else if (e.showAsDropdown) {
          return [
            if (i>0 && routes[i-1] is! GoRouteGroupFromZero)
              ResponsiveDrawerMenuDivider(
                widget: const Divider(height: 1,),
              ),
            ResponsiveDrawerMenuItem(
              title: e.title ?? e.path,
              titleBuilder: e.titleBuilder,
              icon: e.icon,
              children: children,
            ),
            ResponsiveDrawerMenuDivider(
              widget: const Divider(height: 1,),
            ),
          ];
        } else {
          return <ResponsiveDrawerMenuItem>[
            if ((i>0 && routes[i-1] is! GoRouteGroupFromZero) || e.title!=null)
              ResponsiveDrawerMenuDivider(title: e.title),
            ...children,
            if (i<routes.lastIndex || e.title!=null)
              ResponsiveDrawerMenuDivider(),
          ];
        }
      } else {
        return [
          ResponsiveDrawerMenuItem(
            title: e.title ?? '',
            titleBuilder: e.titleBuilder,
            subtitle: e.subtitle,
            icon: e.icon,
            route: e.name,
            children: e.childrenAsDropdownInDrawerNavigation ? children : [],
            pathParameters: e.getPathParameters(pathParameters),
            queryParameters: e.getQueryParameters(queryParameters),
            extra: e.getExtra(extra),
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
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Object? extra,
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
    List<ActionFromZero>? contextMenuActions,
    Widget Function(String title)? titleBuilder,
    String? denseTitle,
  }){
    return ResponsiveDrawerMenuItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      subtitleRight: subtitleRight ?? this.subtitleRight,
      route: route ?? this.route,
      pathParameters: params ?? pathParameters,
      queryParameters: queryParams ?? queryParameters,
      extra: extra ?? this.extra,
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
      contextMenuActions: contextMenuActions ?? this.contextMenuActions,
      titleBuilder: titleBuilder ?? this.titleBuilder,
      denseTitle: denseTitle ?? this.denseTitle,
    );
  }

  int get uniqueId => Object.hashAll([title, subtitle, icon?.toStringShort(), route.toString()]);

  BottomNavigationBarItem asBottomNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: icon ?? const Icon(Icons.pages),
      label: title,
      tooltip: subtitle,
    );
  }

}

class DrawerMenuFromZero extends ConsumerStatefulWidget {

  static const int go = 10;
  static const int replace = 1;
  static const int push = 2;
  @deprecated
  static const int keepRootAlive = 0;

  static const int styleDrawerMenu = 0;
  static const int styleTree = 1;

  final List<ResponsiveDrawerMenuItem>? parentTabs; /// Only used for smart pushing algorithm
  final List<ResponsiveDrawerMenuItem> tabs;
  final int selected;
  final bool compact;
  final int pushType;
  final bool useGoRouter;
  final int depth;
  final double paddingRight;
  final bool popup;
  final String? homeRoute;
  final int style;
  final List<bool> paintPreviousTreeLines;
  final bool inferSelected;
  final bool allowCollapseRoot;
  final Map<int, GlobalKey<ExpansionTileFromZeroState>>? expansionTileKeys;

  DrawerMenuFromZero({
    required this.tabs,
    this.parentTabs,
    @deprecated
    this.selected = -1,
    this.compact = false,
    this.pushType = go,
    this.useGoRouter = true,
    this.depth = 0,
    this.paddingRight = 0,
    this.popup = false,
    this.style = styleDrawerMenu,
    this.paintPreviousTreeLines = const[],
    this.inferSelected = true,
    this.allowCollapseRoot = true,
    String? homeRoute,
    this.expansionTileKeys,
    super.key,
  })  : homeRoute = homeRoute ?? tabs[0].route;

  @override
  DrawerMenuFromZeroState createState() => DrawerMenuFromZeroState();

  // static double calculateHeight(List<ResponsiveDrawerMenuItem> tabs){
  //   double sum = 0;
  //   for (var element in tabs) {
  //     if (element is ResponsiveDrawerMenuDivider){
  //       sum += element.title.isEmpty ? 13 : 32;
  //     } else{
  //       sum += 49;
  //     }
  //   }
  //   return sum;
  // }

}

class DrawerMenuFromZeroState extends ConsumerState<DrawerMenuFromZero> {

  final Map<int, GlobalKey<ContextMenuFromZeroState>> _menuButtonKeys = {};
  late List<ResponsiveDrawerMenuItem> _tabs;
  late int _selected;
  bool pendingUpdate = false;
  GoRouteFromZero? route;
  final Map<int, Map<int, GlobalKey<ExpansionTileFromZeroState>>> childKeys = {};

  @override
  void initState() {
    super.initState();
    try {
      route = GoRouteFromZero.of(context);
    } catch(_) {}
    pendingUpdate = true;
  }

  @override
  void didUpdateWidget(covariant DrawerMenuFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.tabs.contentEquals(oldWidget.tabs, (a, b)=>a.route==b.route)) {
      pendingUpdate = true;
    }
  }

  static bool useNamesToUpdateTabsWithGoRouter = true;
  void _updateTabs() {
    pendingUpdate = false;
    _tabs = List.from(widget.tabs);
    _selected = widget.selected;
    if (widget.selected<0 && widget.inferSelected) {

      if (widget.useGoRouter) {

        if (useNamesToUpdateTabsWithGoRouter) {

          final goRouter = GoRouter.of(context);
          final matches = goRouter.routerDelegate.currentConfiguration;
          final currentRouteName = (matches.last.route as GoRoute).name?.replaceAll('_', '');
          final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
          int Function(List<ResponsiveDrawerMenuItem>, RouteMatch)? getSelectedIndex;
          getSelectedIndex = (tabs, match) {
            for (int i=0; i<tabs.length; i++) {
              final e = tabs[i];
              if (e.route!=null) {
                final name = e.route?.replaceAll('_', ''); // hack to allow duplicated routes to triger properly
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
                // log("$name -- $currentRouteName");
                if (name == currentRouteName) {
                  return i;
                }
              } else if (e.children!=null) {
                int innerIndex = getSelectedIndex!(e.children!, match);
                if (innerIndex>=0) {
                  tabs[i] = e.copyWith(
                    selectedChild: innerIndex,
                  );
                  scaffoldChangeNotifier.isTreeNodeExpanded[e.uniqueId] = true;
                  return i;
                }
              }
            }
            return -1;
          };
          for (int i=matches.matches.lastIndex; i>=0 && _selected<0; i--) {
            _selected = getSelectedIndex(_tabs, matches.matches[i]);
          }

        } else {

          // old deprecated method of comparing using computed paths
          final goRouter = GoRouter.of(context);
          final goRouterState = GoRouterState.of(context);
          String location = goRouterState.uri.toString();
          int queryParamsIndex = location.indexOf('?');
          if (queryParamsIndex>=0) {
            location = location.substring(0, queryParamsIndex);
          }
          final matches = goRouter.routerDelegate.currentConfiguration;
          final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
          Map<ResponsiveDrawerMenuItem, String> computedNames = {};
          int Function(List<ResponsiveDrawerMenuItem>, RouteMatch)? getSelectedIndex;
          getSelectedIndex = (tabs, match) {
            for (int i=0; i<tabs.length; i++) {
              final e = tabs[i];
              if (e.route!=null) {
                if (!computedNames.containsKey(e)) {
                  computedNames[e] = goRouter.namedLocation(e.route!,
                    pathParameters: e.pathParameters ?? {},
                  );
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
                // log("$location -- $computedName");
                if (computedName == location) {
                  return i;
                }
              } else if (e.children!=null) {
                int innerIndex = getSelectedIndex!(e.children!, match);
                if (innerIndex>=0) {
                  tabs[i] = e.copyWith(
                    selectedChild: innerIndex,
                  );
                  scaffoldChangeNotifier.isTreeNodeExpanded[e.uniqueId] = true;
                  return i;
                }
              }
            }
            return -1;
          };
          for (int i=matches.matches.lastIndex; i>=0 && _selected<0; i--) {
            _selected = getSelectedIndex(_tabs, matches.matches[i]);
          }

        }

      } else {

        // old deprecated way of inferring the selected route
        try {
          String location = widget.pushType == DrawerMenuFromZero.go
              ? GoRouterState.of(context).uri.toString()
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
        } catch (_) {}

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pendingUpdate) {
      _updateTabs();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _getWidgets(context, _tabs, _selected),
    );
  }

  List<Widget> _getWidgets(BuildContext context, List<ResponsiveDrawerMenuItem> tabs, int selected){
    final theme = Theme.of(context);
    List<Widget> result = List.generate(tabs.length, (i) {
      if (tabs[i] is ResponsiveDrawerMenuDivider){

        ResponsiveDrawerMenuDivider divider = tabs[i] as ResponsiveDrawerMenuDivider;
        if (divider.widget!=null){
          return Padding(
            padding: EdgeInsets.only(left: widget.depth==0 ? 0 : 26 + (widget.depth-1)*21.0),
            child: divider.widget,
          );
        } else{
          double height = widget.compact||tabs[i].title.isNullOrEmpty ? 9 : 32;
          return Padding(
            padding: EdgeInsets.only(left: widget.depth==0 ? 0 : 26 + (widget.depth-1)*21.0),
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
                    const SizedBox(height: 4,),
                    const Divider(height: 1,),
                    tabs[i].title.isEmpty ? const SizedBox(height: 4,) : Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Text(tabs[i].title, style: theme.textTheme.bodySmall,),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

      } else{

        Future<bool> Function() onTap;
        if (widget.pushType==DrawerMenuFromZero.go) {

          onTap = (tabs[i].onTap!=null && !tabs[i].executeBothOnTapAndDefaultOnTap)
              ? () async {
                return tabs[i].onTap?.call() ?? false;
              }
              : () async {
                bool result;
                result = tabs[i].onTap?.call() ?? false;
                if (tabs[i].route!=null) {
                  ScaffoldState? scaffold;
                  try { scaffold = Scaffold.of(context); } catch(_) {}
                  if (scaffold!=null) {
                    if (scaffold.isDrawerOpen) {
                      scaffold.closeDrawer();
                    }
                    if (scaffold.isEndDrawerOpen) {
                      scaffold.closeEndDrawer();
                    }
                  }
                  GoRouter.of(context).goNamed(
                    tabs[i].route!,
                    pathParameters: (tabs[i].pathParameters??{}).map(MapEntry.new),
                    queryParameters: (tabs[i].queryParameters??{}).map(MapEntry.new),
                    extra: tabs[i].extra,
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
              var goRouter = widget.useGoRouter ? GoRouter.of(context) : null;
              try{
                var scaffold = Scaffold.of(context);
                if (scaffold.hasDrawer && scaffold.isDrawerOpen) {
                  navigator.pop();
                }
              } catch(_, __){}
              if (widget.pushType == DrawerMenuFromZero.keepRootAlive){
                // ! this will break if the homeRoute is NOT in the stack
                if (selected>=0 && tabs[selected].route==widget.homeRoute){
                  if (goRouter==null) {
                    navigator.pushNamed(
                      tabs[i].route!,
                      arguments: {...(tabs[i].pathParameters??{}), ...(tabs[i].queryParameters??{})},
                    );
                  } else {
                    goRouter.pushNamed(
                      tabs[i].route!,
                      pathParameters: (tabs[i].pathParameters??{}).map(MapEntry.new),
                      queryParameters: (tabs[i].queryParameters??{}).map(MapEntry.new),
                      extra: tabs[i].extra,
                    );
                  }
                } else{
                  if (tabs[i].route==widget.homeRoute){
                    if (goRouter==null) {
                      if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                        navigator.popUntil(ModalRoute.withName(widget.homeRoute!));
                      }
                    } else {
                      goRouter.maybePopUntil(context, (match) => (match.route as GoRoute).name==widget.homeRoute);
                    }
                  } else{
                    if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                      if (goRouter==null) {
                        navigator.pushNamedAndRemoveUntil(
                          tabs[i].route!,
                          ModalRoute.withName(widget.homeRoute!),
                          arguments: {...(tabs[i].pathParameters??{}), ...(tabs[i].queryParameters??{})},
                        );
                      } else {
                        navigator.popUntil(ModalRoute.withName(widget.homeRoute!));
                        goRouter.pushNamedAndRemoveUntil(
                          tabs[i].route!,
                          (match) => (match.route as GoRoute).name==widget.homeRoute,
                          pathParameters: (tabs[i].pathParameters??{}).map(MapEntry.new),
                          queryParameters: (tabs[i].queryParameters??{}).map(MapEntry.new),
                          extra: tabs[i].extra,
                        );
                      }
                    }
                  }
                }
              } else if (widget.pushType == DrawerMenuFromZero.push){
                if (goRouter==null) {
                  navigator.pushNamed(
                    tabs[i].route!,
                    arguments: {...(tabs[i].pathParameters??{}), ...(tabs[i].queryParameters??{})},
                  );
                } else {
                  goRouter.pushNamed(
                    tabs[i].route!,
                    pathParameters: (tabs[i].pathParameters??{}).map(MapEntry.new),
                    queryParameters: (tabs[i].queryParameters??{}).map(MapEntry.new),
                    extra: tabs[i].extra,
                  );
                }
              } else if (widget.pushType == DrawerMenuFromZero.replace){
                if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                  List<String> routes = [];
                  if (widget.homeRoute!=null) {
                    routes.add(widget.homeRoute!);
                  }
                  void Function(List<ResponsiveDrawerMenuItem>)? addRoutes;
                  addRoutes = (List<ResponsiveDrawerMenuItem> items) {
                    for (final e in items) {
                      if (e.route!=null) {
                        routes.add(e.route!);
                      }
                      addRoutes!(e.children ?? []);
                    }
                  };
                  addRoutes(widget.parentTabs ?? _tabs);
                  bool passed = false;
                  if (goRouter==null) {
                    navigator.pushNamedAndRemoveUntil(
                      tabs[i].route!,
                      (Route<dynamic> route) {
                        if (passed || route.isFirst) return true;
                        if (routes.contains(route.settings.name)){
                          passed = true;
                        }
                        return false;
                      },
                      arguments: {...(tabs[i].pathParameters??{}), ...(tabs[i].queryParameters??{})},
                    );
                  } else {
                    // TODO 3 can I make this a maybe pop
                    goRouter.pushNamedAndRemoveUntil(
                      tabs[i].route!,
                      (match) {
                        if (passed) return true;
                        if (routes.contains((match.route as GoRoute).name)){
                          passed = true;
                        }
                        return false;
                      },
                      pathParameters: (tabs[i].pathParameters??{}).map(MapEntry.new),
                      queryParameters: (tabs[i].queryParameters??{}).map(MapEntry.new),
                      extra: tabs[i].extra,
                    );
                  }
                }
              }
              result = true;
            }
            return result; //false
          };

        }

        final addedPaddingLeft = MediaQuery.paddingOf(context).left;
        Widget result;

        if (tabs[i].children?.isNotEmpty??false){

          if (!_menuButtonKeys.containsKey(i)) _menuButtonKeys[i] = GlobalKey();
          for (int j=0; j<tabs[i].children!.length; j++) {
            final e = tabs[i].children![j];
            if (e.children?.isNotEmpty ?? false) {
              childKeys[i] ??= {};
              childKeys[i]![j] ??= GlobalKey();
            }
          }
          final scaffoldChangeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
          final expanded = widget.compact||tabs[i].forcePopup ? false
              : scaffoldChangeNotifier.isTreeNodeExpanded[tabs[i].uniqueId] ?? tabs[i].defaultExpanded;
          result = ContextMenuFromZero(
            addGestureDetector: false,
            key: _menuButtonKeys[i],
            anchorAlignment: Alignment.topLeft,
            popupAlignment: Alignment.bottomRight,
            useCursorLocation: false,
            contextMenuWidth: 304,
            offsetCorrection: Offset(
              scaffoldChangeNotifier.collapsedDrawerWidths[route?.pageScaffoldId] ?? 0,
              -2,
            ),
            contextMenuWidget: Builder(
              builder: (context) {
                final scrollController = ScrollController();
                return ScrollbarTheme(
                  data: Theme.of(Navigator.of(context).context).scrollbarTheme,
                  child: ScrollbarFromZero(
                    controller: scrollController,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: DrawerMenuFromZero(
                          popup: true,
                          tabs: tabs[i].children!,
                          // tabs: [tabs[i].children!.first],
                          compact: false,
                          selected: tabs[i].selectedChild,
                          inferSelected: false,
                          paddingRight: 16,
                          pushType: widget.pushType == DrawerMenuFromZero.keepRootAlive
                              ? (selected==0 ? DrawerMenuFromZero.push : DrawerMenuFromZero.replace)
                              : widget.pushType,
                          homeRoute: widget.homeRoute,
                          parentTabs: widget.parentTabs ?? _tabs,
                          style: widget.style,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            child: ExpansionTileFromZero(
              key: widget.expansionTileKeys?[i],
              initiallyExpanded: selected==i || tabs[i].selectedChild>=0,
              expanded: expanded,
              expandedAlignment: Alignment.topCenter,
              contextMenuActions: tabs[i].contextMenuActions,
              addExpandCollapseContextMenuAction: !widget.compact,
              childrenKeysForExpandCollapse: childKeys[i]?.values.toList(),
              style: widget.style,
              leading: widget.depth!=0 || widget.allowCollapseRoot ? null : const SizedBox.shrink(),
              actionPadding: EdgeInsets.only(
                left: addedPaddingLeft + (widget.style==DrawerMenuFromZero.styleTree ? widget.depth*20.0 : 0),
              ),
              trailing: widget.depth==0 && !widget.allowCollapseRoot
                  ? const SizedBox.shrink()
                  : tabs[i].customExpansionTileTrailing ?? (tabs[i].forcePopup ? const SizedBox.shrink() : null),
              titleBuilder: (context, expanded) {
                return Padding (
                  padding: expanded
                      ? EdgeInsets.only(top: widget.style==DrawerMenuFromZero.styleTree ? 4 : 6)
                      : EdgeInsets.symmetric(vertical: widget.style==DrawerMenuFromZero.styleTree ? 4 : 6),
                  child: getTreeOverlay(
                    DrawerMenuButtonFromZero(
                      key: tabs[i].itemKey,
                      title: tabs[i].title,
                      denseTitle: tabs[i].denseTitle,
                      titleWidget: tabs[i].titleBuilder?.call(tabs[i].title),
                      subtitle: tabs[i].subtitle,
                      subtitleRight: tabs[i].subtitleRight,
                      selected: selected==i && (tabs[i].selectedChild<0 || !expanded),
                      compact: widget.compact,
                      dense: tabs[i].dense,
                      titleHorizontalOffset: tabs[i].titleHorizontalOffset,
                      icon: tabs[i].icon ?? const SizedBox.shrink(),
                      softWrap: widget.style!=DrawerMenuFromZero.styleTree,
                      contentPadding: EdgeInsets.only(
                        left: addedPaddingLeft + widget.depth*20.0 + (widget.style==DrawerMenuFromZero.styleTree ? 16 : 0),
                        right: widget.paddingRight + (widget.style==DrawerMenuFromZero.styleDrawerMenu ? 42 : 0),
                        top: widget.style!=DrawerMenuFromZero.styleTree ? 2 : 0,
                        bottom: widget.style!=DrawerMenuFromZero.styleTree ? 2 : 0,
                      ),
                    ), tabs, i,
                    addedPaddingLeft: addedPaddingLeft,
                  ),
                );
              },
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (widget.style==DrawerMenuFromZero.styleDrawerMenu)
                      Positioned(
                        left: 0, right: 0, bottom: 0, top: 0, // -8
                        child: IgnorePointer(
                          child: Container(
                            padding: EdgeInsets.only(left: widget.depth*21.0),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 26.0, //(widget.depth+1)*20.0
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
                                color: Color.alphaBlend(theme.dividerColor.withOpacity(theme.dividerColor.opacity*0.5), Material.maybeOf(context)?.color ?? theme.cardColor),
                                // color: Color.alphaBlend(
                                //   selected!=i
                                //       ? theme.dividerColor
                                //       : Color.lerp(theme.indicatorColor, Colors.white, 0.33)!,
                                //   Material.of(context)?.color ?? theme.cardColor,
                                // ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    DrawerMenuFromZero(
                      tabs: tabs[i].children!,
                      expansionTileKeys: childKeys[i],
                      compact: widget.compact,
                      selected: tabs[i].selectedChild,
                      inferSelected: false,
                      depth: widget.depth+1,
                      pushType: widget.pushType == DrawerMenuFromZero.keepRootAlive
                          ? (selected==0 ? DrawerMenuFromZero.push : DrawerMenuFromZero.replace)
                          : widget.pushType,
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
                  if (!(await onTap())) {
                    _menuButtonKeys[i]!.currentState!.showContextMenu();
                  }
                  return false;
                } else if (widget.depth==0 && !widget.allowCollapseRoot) {
                  await onTap();
                  return false;
                } else {
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
          );

        } else{

          result = getTreeOverlay(
            DrawerMenuButtonFromZero(
              key: tabs[i].itemKey,
              title: tabs[i].title,
              denseTitle: tabs[i].denseTitle,
              titleWidget: tabs[i].titleBuilder?.call(tabs[i].title),
              subtitle: tabs[i].subtitle,
              subtitleRight: tabs[i].subtitleRight,
              selected: selected==i,
              compact: widget.compact,
              icon: tabs[i].icon ?? const SizedBox.shrink(),
              onTap: onTap,
              dense: tabs[i].dense,
              titleHorizontalOffset: tabs[i].titleHorizontalOffset,
              softWrap: widget.style!=DrawerMenuFromZero.styleTree,
              contentPadding: EdgeInsets.only(
                left: addedPaddingLeft + widget.depth*20.0 + (widget.style==DrawerMenuFromZero.styleTree ? 16 : 0),
                right: widget.paddingRight,
                top: widget.style!=DrawerMenuFromZero.styleTree ? 2 : 0,
                bottom: widget.style!=DrawerMenuFromZero.styleTree ? 2 : 0,
              ),
            ), tabs, i,
            addedPaddingLeft: addedPaddingLeft,
          );
          if (tabs[i].contextMenuActions.isNotEmpty) {
            result = ContextMenuFromZero(
              actions: tabs[i].contextMenuActions,
              child: result,
            );
          }

        }

        return result;

      }
    });
    return result;
  }

  Widget getTreeOverlay(Widget child, List<ResponsiveDrawerMenuItem> tabs, int i, {
    double addedPaddingLeft = 0,
  }){
    if (widget.style==DrawerMenuFromZero.styleTree){
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (widget.depth>0)
            Positioned(
              left: 11, right: 0, bottom: -12, top: -12,
              child: Padding(
                padding: EdgeInsets.only(
                  left: addedPaddingLeft,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(widget.depth, (index) {
                    if (index!=widget.depth-1 && widget.paintPreviousTreeLines[index+1]==false){
                      return const SizedBox(width: 20,);
                    }
                    return FractionallySizedBox(
                      heightFactor: index==widget.depth-1 && i==tabs.length-1 ? 0.5 : 1,
                      alignment: Alignment.topCenter,
                      child: const SizedBox(
                        width: 20, height: double.infinity,
                        child: VerticalDivider(
                          thickness: 2, width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          if (widget.depth>0)
            Positioned.fill(
              child: Container(
                padding: EdgeInsets.only(left: addedPaddingLeft + 20.0*widget.depth,),
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: (tabs[i].children==null || tabs[i].children!.isEmpty) ? 24: 12,
                  child: const Divider(
                    thickness: 2, height: 2,
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
  final String? denseTitle;
  final Widget? titleWidget;
  final String? subtitle;
  final String? subtitleRight;
  final Widget? icon;
  final GestureTapCallback? onTap;
  final Color? selectedColor;
  final EdgeInsets contentPadding;
  final bool dense;
  final double titleHorizontalOffset;
  final MouseCursor? mouseCursor;
  final bool showAnimatedShadowIfSelected;
  final bool softWrap;

  const DrawerMenuButtonFromZero({
    required this.title,
    this.selected=false,
    this.compact=false,
    this.denseTitle,
    this.titleWidget,
    this.subtitle,
    this.icon,
    this.onTap,
    this.selectedColor,
    this.dense=false,
    this.contentPadding = const EdgeInsets.only(left: 0, top: 3, bottom: 3),
    this.titleHorizontalOffset = 0,
    this.subtitleRight,
    this.mouseCursor = SystemMouseCursors.click,
    this.showAnimatedShadowIfSelected = true,
    this.softWrap = true,
    super.key,
  });

  @override
  DrawerMenuButtonFromZeroState createState() => DrawerMenuButtonFromZeroState();

}

class DrawerMenuButtonFromZeroState extends State<DrawerMenuButtonFromZero> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = !widget.selected ? Colors.transparent
        : Color.lerp((widget.selectedColor ?? theme.indicatorColor), theme.cardColor, 0.77);
    final selectedTextColor = !widget.selected ? Colors.transparent
        : widget.selectedColor ?? Color.lerp(theme.textTheme.bodyLarge!.color, theme.indicatorColor, 0.7)!;
    final dense = widget.dense && !widget.selected;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        selected: widget.selected,
        contentPadding: widget.contentPadding,
        dense: dense,
        mouseCursor: widget.mouseCursor,
        minVerticalPadding: 3, // default is 4
        visualDensity: const VisualDensity(horizontal: -2, vertical: -4), // compact is -2
        horizontalTitleGap: 16 + widget.titleHorizontalOffset + (widget.dense ? 5 : 2),
        onTap: widget.onTap,
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 100),
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontSize: dense
                ? widget.selected ? 17 : 14
                : widget.selected ? 17 : 16,
            color: dense
                ? widget.selected ? selectedTextColor.withOpacity(0.75) : theme.textTheme.bodySmall!.color
                : widget.selected ? selectedTextColor : theme.textTheme.bodyLarge!.color,
            fontWeight: widget.selected ? FontWeight.w700 : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: widget.titleWidget ?? Text(dense ? (widget.denseTitle??widget.title) : widget.title,
                  maxLines: dense ? 1 : null,
                  softWrap: !dense&&widget.softWrap,
                  overflow: TextOverflow.fade,
                ),
              ),
              if (dense && widget.subtitleRight!=null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(widget.subtitleRight!,
                    textAlign: TextAlign.right,
                    maxLines: dense ? 1 : null,
                    softWrap: !dense&&widget.softWrap,
                    overflow: TextOverflow.fade,
                  ),
                ),
              const SizedBox(width: 12,),
            ],
          ),
        ),
        subtitle: dense||widget.subtitle==null||widget.compact ? null
            : AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 100),
              style: TextStyle(
                color: widget.selected ? selectedTextColor.withOpacity(0.75) : theme.textTheme.bodySmall!.color,
                fontWeight: widget.selected ? FontWeight.w600 : null,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.subtitle!,
                        softWrap: widget.softWrap,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    if (widget.subtitleRight!=null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(widget.subtitleRight!,
                          textAlign: TextAlign.right,
                          softWrap: widget.softWrap,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    const SizedBox(width: 12,),
                  ],
                ),
              ),
            ),
        leading: SizedBox(
          height: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.selected && widget.showAnimatedShadowIfSelected)
                InitiallyAnimatedWidget(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  builder: (animation, child) {
                    return Positioned(
                      top: 2, bottom: 2,
                      right: -4 + 96*(1 - animation.value) - (widget.titleHorizontalOffset/2),
                      left: -widget.contentPadding.left - MediaQuery.sizeOf(context).width,
                      child: Opacity(
                        opacity: (animation.value*2).coerceIn(0, 1),
                        child: child,
                      ),
                    );
                  },
                ),
              Padding(
                padding: EdgeInsets.only(left: dense ? 9 : 4),
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
                        data: theme.iconTheme.copyWith(
                          color: widget.selected ? selectedTextColor
                              : theme.brightness==Brightness.light? Colors.black45 : null,
                          size: dense ? 18 : null,
                        ),
                        child: result,
                      );
                      return result;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
