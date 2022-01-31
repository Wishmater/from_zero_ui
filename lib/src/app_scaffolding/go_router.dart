import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/src/go_router_delegate.dart';
import 'package:go_router/src/typedefs.dart';
import 'package:go_router/src/inherited_go_router.dart';



bool skipFirstRenderWhenPushing = true;


class GoRouteFromZero extends GoRoute {

  /// Name shown in the UI
  String? title;
  /// Subtitle shown in the UI
  String? subtitle;
  /// Icon shown in drawer menu, etc
  Widget icon;
  /// Different page IDs will perform an animation in the whole Scaffold, instead of just the body
  String pageScaffoldId;
  /// Scaffold will perform a SharedZAxisTransition if the depth is different (and not -1)
  int pageScaffoldDepth;
  /// If false, won't be shown when building DrawerMenu from routes, default true
  bool showInDrawerNavigation;
  /// If false will draw children in DrawerMenu in the same depth as this route, instead of the default expansion tile
  bool childrenAsDropdownInDrawerNavigation;

  GoRouteFromZero({
    required String path,
    String? name,
    this.title,
    this.subtitle,
    this.icon = const SizedBox.shrink(),
    GoRouterWidgetBuilder builder = emptyBuilder,
    GoRouterRedirect redirect = emptyRedirect,
    List<GoRouteFromZero> routes = const [],
    this.pageScaffoldId = 'main',
    this.pageScaffoldDepth = 0,
    this.showInDrawerNavigation = true,
    this.childrenAsDropdownInDrawerNavigation = true,
  }) : super(
    path: path,
    name: name ?? path,
    builder: builder,
    redirect: redirect,
    routes: routes,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: OnlyOnActiveBuilder(builder: builder, state: state,),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
    ),
  );

  GoRouteFromZero copyWith({
    String? path,
    String? name,
    String? title,
    String? subtitle,
    Widget? icon,
    GoRouterWidgetBuilder? builder,
    GoRouterRedirect? redirect,
    List<GoRouteFromZero>? routes,
    String? pageScaffoldId,
    int? pageScaffoldDepth,
    bool? showInDrawerNavigation,
    bool? childrenAsDropdownInDrawerNavigation,
  }) {
    return GoRouteFromZero(
      path: path ?? this.path,
      name: name ?? this.name!,
      title: title ?? this.title,
      subtitle: subtitle,
      icon: icon ?? this.icon,
      builder: builder ?? this.builder,
      redirect: redirect ?? this.redirect,
      routes: routes ?? this.routes,
      pageScaffoldId: pageScaffoldId ?? this.pageScaffoldId,
      pageScaffoldDepth: pageScaffoldDepth ?? this.pageScaffoldDepth,
      showInDrawerNavigation: showInDrawerNavigation ?? this.showInDrawerNavigation,
      childrenAsDropdownInDrawerNavigation: childrenAsDropdownInDrawerNavigation ?? this.childrenAsDropdownInDrawerNavigation,
    );
  }

  @override
  List<GoRouteFromZero> get routes => super.routes.cast<GoRouteFromZero>();

  void go(BuildContext context, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    GoRouter.of(context).goNamed(name!,
      params: _getParams(params),
      queryParams: _getQueryParams(queryParams),
      extra: _getExtra(extra),
    );
  }

  void push(BuildContext context, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    GoRouter.of(context).pushNamed(name!,
      params: _getParams(params),
      queryParams: _getQueryParams(queryParams),
      extra: _getExtra(extra),
    );
  }

  void pushReplacement(BuildContext context, {
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    GoRouter.of(context).pop(context);
    push(context,
      params: params,
      queryParams: queryParams,
      extra: extra,
    );
  }

  Map<String, String> _getParams(Map<String, String> params)
      => {...defaultParams, ...params};
  Map<String, String> _getQueryParams(Map<String, String> queryParams)
      => {...defaultQueryParams, ...queryParams};
  Object? _getExtra(Object? extra) {
    if ((extra==null || extra is Map) && defaultExtra is Map ) {
      return {
        if (extra!=null)
          ...(extra as Map),
        ...(defaultExtra as Map),
      };
    } else {
      return extra;
    }
  }
  // these can be overriden to add default params to route pushes
  Map<String, String> get defaultParams => {};
  Map<String, String> get defaultQueryParams => {};
  Object? get defaultExtra => null;


  static List<GoRouteFromZero> getCleanRoutes(List<GoRouteFromZero> routes) {
    final result = <GoRouteFromZero>[];
    for (final e in routes) {
      if (e is GoRouteGroupFromZero) {
        result.addAll(getCleanRoutes(e.routes));
      } else {
        result.add(e.copyWith(
          routes: getCleanRoutes(e.routes),
        ));
      }
    }
    return result;
  }

  static String? emptyRedirect(GoRouterState state) => null;

  static Widget emptyBuilder(BuildContext context, GoRouterState state) =>
      throw Exception('GoRoute builder parameter not set\n'
          'See gorouter.dev/redirection#considerations for details');

  // taken from go_router
  static String addQueryParams(String loc, Map<String, String> queryParams) {
    final uri = Uri.parse(loc);
    assert(uri.queryParameters.isEmpty);
    return _canonicalUri(
        Uri(path: uri.path, queryParameters: queryParams).toString());
  }
  static String _canonicalUri(String loc) {
    var canon = Uri.parse(loc).toString();
    canon = canon.endsWith('?') ? canon.substring(0, canon.length - 1) : canon;

    // remove trailing slash except for when you shouldn't, e.g.
    // /profile/ => /profile
    // / => /
    // /login?from=/ => login?from=/
    canon = canon.endsWith('/') && canon != '/' && !canon.contains('?')
        ? canon.substring(0, canon.length - 1)
        : canon;

    // /login/?from=/ => /login?from=/
    // /?from=/ => /?from=/
    canon = canon.replaceFirst('/?', '?', 1);

    return canon;
  }

}

class GoRouteGroupFromZero extends GoRouteFromZero {

  GoRouteGroupFromZero({
    String? title,
    String? subtitle,
    Widget? icon,
    required List<GoRouteFromZero> routes,
    bool showInDrawerNavigation = true,
  }) : super(
    path: 'null',
    name: title ?? '',
    subtitle: subtitle,
    icon: icon ?? const SizedBox.shrink(),
    routes: routes,
    showInDrawerNavigation: showInDrawerNavigation,
  );

}

class GoRouterStateFromZero extends GoRouterState {

  GoRouteFromZero route;
  int pageScaffoldDepth;
  String get pageScaffoldId => route.pageScaffoldId;

  GoRouterStateFromZero(GoRouterDelegate delegate, {
    required this.route,
    required this.pageScaffoldDepth,
    required String location,
    required String subloc,
    required String? name,
    String? path,
    String? fullpath,
    Map<String, String> params = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
    Exception? error,
    ValueKey<String>? pageKey,
  }) :  super(delegate,
          location: location,
          subloc: subloc,
          name: name,
          path: path,
          fullpath: fullpath,
          params: params,
          queryParams: queryParams,
          extra: extra,
          error: error,
          pageKey: pageKey,
        );

}




class OnlyOnActiveBuilder extends ConsumerStatefulWidget {

  final GoRouterState state;
  final GoRouterWidgetBuilder builder;

  const OnlyOnActiveBuilder({
    required this.state,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  OnlyOnActiveBuilderState createState() => OnlyOnActiveBuilderState();

}

class OnlyOnActiveBuilderState extends ConsumerState<OnlyOnActiveBuilder> {

  bool built = false;
  late GoRouterStateFromZero state;

  @override
  void initState() {
    super.initState();
    // for some reason, GoRouter doesn't allow of(context, listen: false) ...
    final inherited = context.getElementForInheritedWidgetOfExactType<InheritedGoRouter>();
    assert(inherited != null, 'No GoRouter found in context');
    final router = (inherited!.widget as InheritedGoRouter).goRouter;
    final location = GoRouteFromZero.addQueryParams(widget.state.subloc, widget.state.queryParams);
    // route = router.routerDelegate.matches.lastWhere((e) {
    //   return GoRouteFromZero.addQueryParams(e.subloc, e.queryParams) == location;
    // }).route as GoRouteFromZero;
    final matches = router.routerDelegate.matches;
    late GoRouteFromZero currentRoute;
    int currentDepth = 0;
    int accumulatedDepth = 0;
    for (int i=0; i<matches.length; i++) {
      final match = matches[i];
      final route = match.route as GoRouteFromZero;
      accumulatedDepth += route.pageScaffoldDepth;
      if (GoRouteFromZero.addQueryParams(match.subloc, match.queryParams) == location) {
        currentRoute = route;
        currentDepth = accumulatedDepth;
      }
    }
    state = GoRouterStateFromZero(router.routerDelegate,
      route: currentRoute,
      pageScaffoldDepth: currentDepth,
      subloc: widget.state.subloc,
      location: widget.state.location,
      name: widget.state.name,
      queryParams: widget.state.queryParams,
      path: widget.state.path,
      error: widget.state.error,
      extra: widget.state.extra,
      fullpath: widget.state.fullpath,
      pageKey: widget.state.pageKey,
      params: widget.state.params,
    );
  }

  @override
  Widget build(BuildContext context) {

    if (built || isActiveRoute(context)) {

      final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
      if (isActiveRoute(context) && scaffoldChangeNotifier.currentRouteState!=state) {
        scaffoldChangeNotifier.setCurrentRouteState(state);
      }

      if (built || !skipFirstRenderWhenPushing) {

        return widget.builder(context, widget.state);

      } else {

        built = true;
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          setState(() {});
        });
        return Container(color: Theme.of(context).canvasColor,);

      }

    } else {

      return Container();

    }

  }

  bool isActiveRoute(context) =>
      GoRouteFromZero.addQueryParams(widget.state.subloc, widget.state.queryParams)
          == GoRouter.of(context).location;

}





class DefaultInitChangeNotifier extends ChangeNotifier {

  bool _initialized = false;
  bool get initialized => _initialized;
  set initialized(bool value) {
    _initialized = value;
    notifyListeners();
  }

}