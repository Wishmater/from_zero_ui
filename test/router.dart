import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'main.dart';
import 'pages/future_handling/page_future_handling.dart';
import 'pages/heroes/page_cross_fade_hero.dart';
import 'pages/heroes/page_custom_hero.dart';
import 'pages/heroes/page_heroes.dart';
import 'pages/heroes/page_inner_hero.dart';
import 'pages/heroes/page_normal_hero.dart';
import 'pages/home/page_home.dart';
import 'pages/lightweight_table/page_lightweight_table.dart';
import 'pages/scaffold/page_scaffold.dart';
import 'pages/scaffold/page_scaffold_inner.dart';
import 'pages/scaffold/page_scaffold_other.dart';
import 'pages/scaffold/page_scaffold_same.dart';
import 'pages/settings/page_settings.dart';



final mainRoutes = [
  GoRouteGroupFromZero(
    routes: [
      GoRouteFromZero(
        path: '/',
        name: 'home',
        title: 'Home',
        icon: Icon(Icons.home),
        childrenAsDropdownInDrawerNavigation: false,
        builder: (context, state) => PageHome(),
        routes: [
          GoRouteFromZero(
            path: 'scaffold',
            name: 'scaffold',
            title: 'Scaffold FromZero',
            icon: Icon(Icons.subtitles),
            builder: (context, state) => PageScaffold(),
            routes: [
              GoRouteFromZero(
                path: 'same',
                name: 'scaffold_same',
                builder: (context, state) => PageScaffoldSame(),
              ),
              GoRouteFromZero(
                path: 'inner',
                name: 'scaffold_inner',
                builder: (context, state) => PageScaffoldInner(),
                pageScaffoldDepth: 1,
              ),
              GoRouteFromZero(
                path: 'other',
                name: 'scaffold_other',
                builder: (context, state) => PageScaffoldOther(),
                pageScaffoldId: 'other',
              ),
            ],
          ),
          GoRouteFromZero(
            path: 'lightweight_table',
            name: 'lightweight_table',
            title: 'Lightweight Table',
            icon: Icon(Icons.table_chart),
            builder: (context, state) => PageLightweightTable(),
          ),
          GoRouteGroupFromZero(
            title: 'Heroes',
            routes: [
              GoRouteFromZero(
                path: 'heroes',
                name: 'heroes',
                title: 'Heroes',
                icon: Icon(Icons.person_pin_circle),
                builder: (context, state) => PageHeroes(),
                routes: heroesRoutes,
              ),
            ],
          ),
          GoRouteFromZero(
            path: 'future_handling',
            name: 'future_handling',
            title: 'Future Handling',
            icon: Icon(Icons.refresh),
            builder: (context, state) => PageFutureHandling(),
          ),
          ...settingsRoutes,
        ],
      ),
    ],
  ),
];

final heroesRoutes = [
  GoRouteFromZero(
    path: 'normal',
    name: 'heroes_normal',
    title: 'Normal Hero',
    icon: Icon(Icons.looks_one),
    builder: (context, state) => PageNormalHero(),
  ),
  GoRouteFromZero(
    path: 'fade',
    name: 'heroes_fade',
    title: 'CrossFade Hero',
    icon: Icon(Icons.looks_two),
    builder: (context, state) => PageCrossFadeHero(),
  ),
  GoRouteFromZero(
    path: 'custom',
    name: 'heroes_custom',
    title: 'Custom transionBuilder Hero',
    icon: Icon(Icons.looks_3),
    builder: (context, state) => PageCustomHero(),
  ),
  GoRouteFromZero(
    path: 'inner',
    name: 'heroes_inner',
    title: 'CrossFade Higher Depth',
    icon: Icon(Icons.looks_4),
    pageScaffoldDepth: 1,
    builder: (context, state) => PageInnerHero(),
  ),
];

final settingsRoutes = [
  GoRouteFromZero(
    path: 'settings',
    name: 'settings',
    title: 'Settings',
    icon: Icon(Icons.settings),
    builder: (context, state) => PageSettings(),
    pageScaffoldId: 'settings',
  ),
];

final initRoute = GoRouteFromZero(
  path: '/login',
  name: 'login',
  builder: (context, state) => PageSplash(),
  pageScaffoldId: 'login',
);





class PageSplash extends StatefulWidget {

  const PageSplash({Key? key}) : super(key: key);

  @override
  _PageSplashState createState() => _PageSplashState();

}

class _PageSplashState extends State<PageSplash> {

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      initChangeNotifier.initialized = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).canvasColor,);
  }

}

