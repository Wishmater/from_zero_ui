import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class PageHome extends StatelessWidget {

  static List<List<ResponsiveDrawerMenuItem>> tabs = [
    [
      ResponsiveDrawerMenuItem(
        title: "Home",
        icon: Icons.home,
        route: "/",
      ),
      ResponsiveDrawerMenuItem(
        title: "Scaffold FromZero",
        icon: Icons.subtitles,
        route: "/scaffold",
      ),
      ResponsiveDrawerMenuItem(
        title: "Lightweight Table",
        icon: Icons.table_chart,
        route: "/lightweight_table",
      ),
      ResponsiveDrawerMenuItem(
        title: "Future Handling",
        icon: Icons.refresh,
        route: "/future_handling",
      ),
      ResponsiveDrawerMenuItem(
        title: "Heroes",
        icon: Icons.person_pin_circle,
        route: "/heroes",
      ),
    ],
  ];

  static List<List<ResponsiveDrawerMenuItem>> footerTabs = [
    [
      ResponsiveDrawerMenuItem(
        title: "Settings",
        icon: Icons.settings,
        route: "/settings",
      )
    ]
  ];

  final animation;
  final secondaryAnimation;


  PageHome({this.animation, this.secondaryAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      title: Text("FromZero playground"),
      body: Container(),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 0],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

}
