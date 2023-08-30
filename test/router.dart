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
    showAsDropdown: false,
    routes: [
      GoRouteFromZero(
        path: '/',
        name: 'home',
        title: 'Home',
        icon: const Icon(Icons.home),
        childrenAsDropdownInDrawerNavigation: false,
        builder: (context, state) => const PageHome(),
        routes: [
          GoRouteFromZero(
            path: 'scaffold',
            name: 'scaffold',
            title: 'Scaffold FromZero',
            icon: const Icon(Icons.subtitles),
            builder: (context, state) => const PageScaffold(),
            routes: [
              GoRouteGroupFromZero(
                showInDrawerNavigation: false,
                routes: [
                  GoRouteFromZero(
                    path: 'same',
                    name: 'scaffold_same',
                    builder: (context, state) => const PageScaffoldSame(),
                  ),
                  GoRouteFromZero(
                    path: 'inner',
                    name: 'scaffold_inner',
                    builder: (context, state) => const PageScaffoldInner(),
                    pageScaffoldDepth: 1,
                  ),
                  GoRouteFromZero(
                    path: 'other',
                    name: 'scaffold_other',
                    builder: (context, state) => const PageScaffoldOther(),
                    pageScaffoldId: 'other',
                  ),
                ],
              ),
            ],
          ),
          GoRouteFromZero(
            path: 'lightweight_table',
            name: 'lightweight_table',
            title: 'Lightweight Table',
            icon: const Icon(Icons.table_chart),
            builder: (context, state) => const PageLightweightTable(),
          ),
          GoRouteGroupFromZero(
            title: 'Heroes',
            showAsDropdown: false,
            routes: [
              GoRouteFromZero(
                path: 'heroes',
                name: 'heroes',
                title: 'Heroes',
                icon: const Icon(Icons.person_pin_circle),
                builder: (context, state) => const PageHeroes(),
                routes: heroesRoutes,
              ),
            ],
          ),
          GoRouteFromZero(
            path: 'future_handling',
            name: 'future_handling',
            title: 'Future Handling',
            icon: const Icon(Icons.refresh),
            builder: (context, state) => const PageFutureHandling(),
          ),
          GoRouteGroupFromZero(
            showInDrawerNavigation: false,
            routes: settingsRoutes,
          ),
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
    icon: const Icon(Icons.looks_one),
    builder: (context, state) => const PageNormalHero(),
  ),
  GoRouteFromZero(
    path: 'fade',
    name: 'heroes_fade',
    title: 'CrossFade Hero',
    icon: const Icon(Icons.looks_two),
    builder: (context, state) => const PageCrossFadeHero(),
  ),
  GoRouteFromZero(
    path: 'custom',
    name: 'heroes_custom',
    title: 'Custom transionBuilder Hero',
    icon: const Icon(Icons.looks_3),
    builder: (context, state) => const PageCustomHero(),
  ),
  GoRouteFromZero(
    path: 'inner',
    name: 'heroes_inner',
    title: 'CrossFade Higher Depth',
    icon: const Icon(Icons.looks_4),
    pageScaffoldDepth: 1,
    builder: (context, state) => const PageInnerHero(),
  ),
];

final settingsRoutes = [
  GoRouteFromZero(
    path: 'settings',
    name: 'settings',
    title: 'Settings',
    icon: const Icon(Icons.settings),
    builder: (context, state) => const PageSettings(),
    pageScaffoldId: 'settings',
  ),
];

final initRoute = GoRouteFromZero(
  path: '/login',
  name: 'login',
  builder: (context, state) => const PageSplash(),
  pageScaffoldId: 'login',
);





class PageSplash extends StatefulWidget {

  const PageSplash({Key? key}) : super(key: key);

  @override
  PageSplashState createState() => PageSplashState();

}

class PageSplashState extends State<PageSplash> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initChangeNotifier.initialized = true;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).canvasColor,);
  }

}

