import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';



bool skipFirstRenderWhenPushing = false; // disabled because it breaks heroes, and the actual performance gain is doubtful


extension Replace on GoRouter {

  void removeLast() {
    // routerDelegate.currentConfiguration.remove(routerDelegate.currentConfiguration.last); // removeLast()
    routerDelegate.pop(); // removeLast()
  }

  void pushReplacementNamed(String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) async {
    removeLast();
    pushNamed(name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void pushNamedAndRemoveUntil(String name,
      bool Function(RouteMatch match) stop, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    popUntil(stop);
    pushNamed(name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// This causes routes to first be popped, and then new one pushed, which might bring some visual issues
  void pushNamedAndMaybeRemoveUntil(
      BuildContext context,
      String name,
      bool Function(RouteMatch match) stop, {
        Map<String, String> pathParameters = const {},
        Map<String, String> queryParameters = const {},
        Object? extra,
      }) {
    maybePopUntil(context, stop);
    pushNamed(name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void popUntil(bool Function(RouteMatch match) stop) {
    bool shouldRemove;
    do {
      final last = routerDelegate.currentConfiguration.last;
      shouldRemove = routerDelegate.canPop() && !stop(last);
      if (shouldRemove) {
        removeLast();
      }
    } while (shouldRemove);
    _safeNotifyListeners();
  }

  /// returns true if successfully popped until wanted
  Future<bool> maybePopUntil(context, bool Function(RouteMatch match) stop) async {
    bool shouldRemove;
    bool blocked = false;
    do {
      final last = routerDelegate.currentConfiguration.last;
      shouldRemove = routerDelegate.canPop() && !stop(last);
      if (shouldRemove) {
        blocked = !(await Navigator.of(context).maybePop());
      }
    } while (shouldRemove && !blocked);
    _safeNotifyListeners();
    return !blocked;
  }

  void _safeNotifyListeners() {
    scheduleMicrotask(routerDelegate.notifyListeners);
  }

}


class GoRouteFromZero extends GoRoute {

  /// Name shown in the UI
  final String? title;
  /// Subtitle shown in the UI
  final String? subtitle;
  /// Icon shown in drawer menu, etc
  final Widget icon;
  /// Different page IDs will perform an animation in the whole Scaffold, instead of just the body
  final String pageScaffoldId;
  /// Scaffold will perform a SharedZAxisTransition if the depth is different (and not -1)
  final int pageScaffoldDepth;
  /// If false will draw children in DrawerMenu in the same depth as this route, instead of the default expansion tile
  final bool childrenAsDropdownInDrawerNavigation;
  /// used in DrawerFromZero
  final Widget Function(String title)? titleBuilder;


  GoRouteFromZero({
    required String path,
    String? name,
    this.title,
    this.subtitle,
    this.icon = const SizedBox.shrink(),
    GoRouterWidgetBuilder? builder,
    GoRouterRedirect? redirect,
    Widget Function(BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child)? transitionBuilder,
    List<GoRouteFromZero> routes = const [],
    this.pageScaffoldId = 'main',
    this.pageScaffoldDepth = 0,
    this.childrenAsDropdownInDrawerNavigation = true,
    GoRouterPageBuilder? pageBuilder,
    LocalKey Function(BuildContext context, GoRouterState state,)? pageKeyGetter,
    this.titleBuilder,
  }) :  assert((builder==null && transitionBuilder==null) || pageBuilder==null,
            'If specifying pageBuilder; builder and transitionBuilder will be overriden, so they should be null'),
        super(
          path: path,
          name: name ?? path,
          builder: null,
          redirect: redirect,
          routes: routes,
          pageBuilder: pageBuilder ?? (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              // key: (pageKeyGetter?.call(context, state)) ?? ValueKey(state.uri.toString()),
              child: OnlyOnActiveBuilder(builder: builder!, state: state,),
              transitionsBuilder: transitionBuilder
                  ?? (context, animation, secondaryAnimation, child) => child,
            );
          },
        ) {
    assert(this is GoRouteGroupFromZero || builder!=null || pageBuilder!=null,
        'One of builder or pageBuilder must be specified');
  }

  GoRouteFromZero copyWith({
    String? path,
    String? name,
    String? title,
    String? subtitle,
    Widget? icon,
    GoRouterRedirect? redirect,
    List<GoRouteFromZero>? routes,
    String? pageScaffoldId,
    int? pageScaffoldDepth,
    bool? childrenAsDropdownInDrawerNavigation,
    GoRouterWidgetBuilder? builder,
    GoRouterPageBuilder? pageBuilder,
  }) {
    return GoRouteFromZero(
      path: path ?? this.path,
      name: name ?? this.name!,
      title: title ?? this.title,
      subtitle: subtitle,
      icon: icon ?? this.icon,
      redirect: redirect ?? this.redirect,
      routes: routes ?? this.routes,
      pageScaffoldId: pageScaffoldId ?? this.pageScaffoldId,
      pageScaffoldDepth: pageScaffoldDepth ?? this.pageScaffoldDepth,
      childrenAsDropdownInDrawerNavigation: childrenAsDropdownInDrawerNavigation ?? this.childrenAsDropdownInDrawerNavigation,
      builder: builder ?? this.builder,
      pageBuilder: pageBuilder ?? this.pageBuilder,
    );
  }

  @override
  List<GoRouteFromZero> get routes => super.routes.cast<GoRouteFromZero>();

  static GoRouteFromZero of(BuildContext context) {
    return GoRouter.of(context).routerDelegate.currentConfiguration.last.route as GoRouteFromZero;
  }

  void go(BuildContext context, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    GoRouter.of(context).goNamed(name!,
      pathParameters: getPathParameters(pathParameters),
      queryParameters: getQueryParameters(queryParameters),
      extra: getExtra(extra),
    );
  }

  void push(BuildContext context, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    GoRouter.of(context).pushNamed(name!,
      pathParameters: getPathParameters(pathParameters),
      queryParameters: getQueryParameters(queryParameters),
      extra: getExtra(extra),
    );
  }

  void pushReplacement(BuildContext context, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    GoRouter.of(context).pushReplacementNamed(name!,
      pathParameters: getPathParameters(pathParameters),
      queryParameters: getQueryParameters(queryParameters),
      extra: getExtra(extra),
    );
  }

  Map<String, String> getPathParameters(Map<String, String> pathParameters)
      => {...defaultPathParameters, ...pathParameters};
  Map<String, String> getQueryParameters(Map<String, String> queryParameters)
      => {...defaultQueryParameters, ...queryParameters};
  Object? getExtra(Object? extra) {
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
  // these can be overriden to add default pathParameters to route pushes
  Map<String, String> get defaultPathParameters => {};
  Map<String, String> get defaultQueryParameters => {};
  Object? get defaultExtra => null;


  static List<GoRouteFromZero> getCleanRoutes(List<GoRouteFromZero> routes, {
    bool addStartingSlash = true,
  }) {
    final result = <GoRouteFromZero>[];
    for (final e in routes) {
      if (e is GoRouteGroupFromZero) {
        result.addAll(getCleanRoutes(e.routes,
          addStartingSlash: addStartingSlash,
        ));
      } else {
        result.add(e.copyWith(
          path: addStartingSlash && !e.path.startsWith('/')
              ? '/${e.path}' : e.path,
          routes: getCleanRoutes(e.routes,
            addStartingSlash: false,
          ),
        ));
      }
    }
    return result;
  }

  // taken from go_router
  static String addQueryParameters(String loc, Map<String, String> queryParameters) {
    final uri = Uri.parse(loc);
    assert(uri.queryParameters.isEmpty);
    return _canonicalUri(
        Uri(path: uri.path, queryParameters: queryParameters).toString());
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

  final bool showInDrawerNavigation;
  final bool showAsDropdown;

  GoRouteGroupFromZero({
    String? title,
    String? subtitle,
    Widget? icon,
    required List<GoRouteFromZero> routes,
    this.showInDrawerNavigation = true,
    this.showAsDropdown = true,
  }) : super(
    path: 'null',
    title: title,
    subtitle: subtitle,
    icon: icon ?? const SizedBox.shrink(),
    routes: routes,
  );

  @override
  GoRouteGroupFromZero copyWith({
    String? path,
    String? name,
    String? title,
    String? subtitle,
    Widget? icon,
    GoRouterRedirect? redirect,
    List<GoRouteFromZero>? routes,
    String? pageScaffoldId,
    int? pageScaffoldDepth,
    bool? childrenAsDropdownInDrawerNavigation,
    GoRouterWidgetBuilder? builder,
    GoRouterPageBuilder? pageBuilder,
  }) {
    return GoRouteGroupFromZero(
      title: title ?? this.title,
      subtitle: subtitle,
      icon: icon ?? this.icon,
      routes: routes ?? this.routes,
      showInDrawerNavigation: showInDrawerNavigation,
      showAsDropdown: showAsDropdown,
    );
  }

}

class GoRouterStateFromZero extends GoRouterState {

  final GoRouteFromZero route;
  final int pageScaffoldDepth;
  String get pageScaffoldId => route.pageScaffoldId;

  const GoRouterStateFromZero(super._configuration, {
    required this.route,
    required this.pageScaffoldDepth,
    required super.uri,
    required super.matchedLocation,
    super.name,
    super.path,
    required super.fullPath,
    required super.pathParameters,
    super.extra,
    super.error,
    required super.pageKey,
  });

}




class OnlyOnActiveBuilder extends ConsumerStatefulWidget {

  final GoRouterState state;
  final GoRouterWidgetBuilder builder;
  final GoRouteFromZero? route; /// used for forcing the route, useful for RouteNotFound

  const OnlyOnActiveBuilder({
    required this.state,
    required this.builder,
    this.route,
    Key? key,
  }) : super(key: key);

  @override
  OnlyOnActiveBuilderState createState() => OnlyOnActiveBuilderState();

}

class OnlyOnActiveBuilderState extends ConsumerState<OnlyOnActiveBuilder> {

  bool built = false;
  GoRouterStateFromZero? state;
  GoRouterStateFromZero? previousState;
  late final ScaffoldFromZeroChangeNotifier scaffoldChangeNotifier;

  @override
  void initState() {
    super.initState();
    scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
    // for some reason, GoRouter doesn't allow of(context, listen: false) ...
    final inherited = context.getElementForInheritedWidgetOfExactType<InheritedGoRouter>();
    assert(inherited != null, 'No GoRouter found in context');
    final router = (inherited!.widget as InheritedGoRouter).goRouter;
    final matches = router.routerDelegate.currentConfiguration.matches;
    late GoRouteFromZero currentRoute;
    // int currentDepth = 0;
    // int accumulatedDepth = 0;
    for (int i=0; i<matches.length; i++) {
      final match = matches[i];
      final route = widget.route ?? (match.route as GoRouteFromZero);
      // accumulatedDepth += route.pageScaffoldDepth;
      if (match.pageKey.value == widget.state.pageKey.value) {
        currentRoute = route;
        // currentDepth = accumulatedDepth;
      }
    }
    state = GoRouterStateFromZero(router.configuration,
      route: currentRoute,
      pageScaffoldDepth: currentRoute.pageScaffoldDepth, // accumulatedDepth disabled, because most of the time it doesn't make sense
      fullPath: widget.state.fullPath,
      name: widget.state.name,
      path: widget.state.path,
      error: widget.state.error,
      extra: widget.state.extra,
      pageKey: widget.state.pageKey,
      pathParameters: widget.state.pathParameters,
      matchedLocation: widget.state.matchedLocation,
      uri: widget.state.uri,
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (previousState!=null && scaffoldChangeNotifier.currentRouteState!=state!) {
      scaffoldChangeNotifier.setCurrentRouteState(previousState!);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (built || isActiveRoute(context)) {

      if (isActiveRoute(context) && scaffoldChangeNotifier.currentRouteState!=state!) {
        previousState = scaffoldChangeNotifier.currentRouteState;
        scaffoldChangeNotifier.setCurrentRouteState(state!);
      }

      if (built || !skipFirstRenderWhenPushing) {

        built = true;
        return widget.builder(context, state!);

      } else {

        built = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {});
        });
        return Container(color: Theme.of(context).canvasColor,);

      }

    } else {

      return Container();

    }

  }

  bool isActiveRoute(context) => widget.state.pageKey.value==GoRouterState.of(context).pageKey.value;

}





class DefaultInitChangeNotifier extends ChangeNotifier {

  bool _initialized = false;
  bool get initialized => _initialized;
  set initialized(bool value) {
    _initialized = value;
    notifyListeners();
  }

}