import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/export.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';

class PageHome extends PageFromZero {

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

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageHome(Animation<double> animation, Animation<double> secondaryAnimation)
      : super(animation, secondaryAnimation);

  @override
  _PageHomeState createState() => _PageHomeState();

}

class _PageHomeState extends State<PageHome> {

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
//      mainScrollController: controller,
      scrollbarType: ScaffoldFromZero.scrollbarTypeOverAppbar,
      appbarType: ScaffoldFromZero.appbarTypeQuickReturn,
      currentPage: widget,
      title: Text("FromZero playground"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 0],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage (BuildContext context){
    return SingleChildScrollView(
      controller: controller,
      child: ResponsiveHorizontalInsets(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppbarFiller(),
              SizedBox(height: 12,),
              Card(
                clipBehavior: Clip.hardEdge,
                child: Container(height: 1200, width: 600, color: Colors.red,),
              ),
              SizedBox(height: 12,),
            ],
          ),
        ),
      ),
    );
  }

}
