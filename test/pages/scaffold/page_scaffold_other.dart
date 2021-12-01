import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageScaffoldOther extends PageFromZero {

  @override
  int get pageScaffoldDepth => -1;
  @override
  String get pageScaffoldId => "Other 1234";

  PageScaffoldOther();

  @override
  _PageScaffoldInnerState createState() => _PageScaffoldInnerState();

}

class _PageScaffoldInnerState extends State<PageScaffoldOther> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Inner Page"),
      body: Center(
        child: Card(child: FlutterLogo(size: 512,)),
      ),
      useCompactDrawerInsteadOfClose: false,
      drawerWidth: 512,
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(tabs: [
        ResponsiveDrawerMenuItem(
          title: "Home",
          icon: Icon(Icons.home),
          route: "/home",
        ),
        ResponsiveDrawerMenuDivider(),
        ResponsiveDrawerMenuItem(
          title: "Scaffold FromZero",
          icon: Icon(Icons.subtitles),
          route: "/scaffold",
        ),
        ResponsiveDrawerMenuItem(
          title: "Lightweight Table",
          icon: Icon(Icons.table_chart),
          route: "/lightweight_table",
        ),
        ResponsiveDrawerMenuDivider(
          title: "Group 2",
        ),
        ResponsiveDrawerMenuItem(
            title: "Heroes",
            icon: Icon(Icons.person_pin_circle),
            route: "/heroes",
            children: [
              ResponsiveDrawerMenuItem(
                title: "Normal Hero",
                icon: Icon(Icons.looks_one),
                route: "/heroes/normal",
              ),
              ResponsiveDrawerMenuItem(
                title: "CrossFade Hero",
                icon: Icon(Icons.looks_two),
                route: "/heroes/fade",
              ),
              ResponsiveDrawerMenuItem(
                title: "Custom transionBuilder Hero",
                subtitle: 'SUB',
                icon: Icon(Icons.looks_3),
                route: "/heroes/custom",
              ),
              ResponsiveDrawerMenuItem(
                title: "CrossFade Higher Depth",
                icon: Icon(MaterialCommunityIcons.table_large),
                  subtitle: 'SUB',
                route: "/heroes/inner",
                children: [
                  ResponsiveDrawerMenuItem(
                    title: "Normal Hero",
                    icon: Icon(Icons.looks_one),
                    route: "/heroes/normal",
                  ),
                  ResponsiveDrawerMenuItem(
                    title: "REALLY LONG TITLE SO IT OVERFLOWS AND I CAN CHECK DIFFERENT HEIGHT BEHAVIOUR. even more text goggammit",
                    icon: Icon(Icons.looks_one),
                    route: "/heroes/normal",
                  ),
                  ResponsiveDrawerMenuItem(
                    title: "Normal Hero",
                    icon: Icon(Icons.looks_one),
                    subtitle: 'asdjgbasdkjfbsjdf',
                    route: "/heroes/normal",
                  ),
                  ResponsiveDrawerMenuItem(
                    title: "Normal Hero",
                    icon: Icon(Icons.looks_one),
                    route: "/heroes/normal",
                    children: [
                      ResponsiveDrawerMenuItem(
                        title: "Normal Hero",
                        icon: Icon(Icons.looks_one),
                        route: "/heroes/normal",
                      ),
                      ResponsiveDrawerMenuItem(
                        title: "Normal Hero",
                        icon: Icon(Icons.looks_one),
                        route: "/heroes/normal",
                      ),
                    ]
                  ),
                ]
              ),
              ResponsiveDrawerMenuItem(
                  title: "CrossFade Higher Depth",
                  icon: Icon(MaterialCommunityIcons.table_large),
                  subtitle: 'SUB',
                  route: "/heroes/inner",
                  children: [
                    ResponsiveDrawerMenuItem(
                      title: "Normal Hero",
                      icon: Icon(Icons.looks_one),
                      route: "/heroes/normal",
                    ),
                    ResponsiveDrawerMenuItem(
                      title: "REALLY LONG TITLE SO IT OVERFLOWS AND I CAN CHECK DIFFERENT HEIGHT BEHAVIOUR. even more text goggammit",
                      icon: Icon(Icons.looks_one),
                      route: "/heroes/normal",
                    ),
                    ResponsiveDrawerMenuItem(
                      title: "Normal Hero",
                      icon: Icon(Icons.looks_one),
                      subtitle: 'asdjgbasdkjfbsjdf',
                      route: "/heroes/normal",
                    ),
                    ResponsiveDrawerMenuItem(
                        title: "Normal Hero",
                        icon: Icon(Icons.looks_one),
                        route: "/heroes/normal",
                        children: [
                          ResponsiveDrawerMenuItem(
                            title: "Normal Hero",
                            icon: Icon(Icons.looks_one),
                            route: "/heroes/normal",
                          ),
                          ResponsiveDrawerMenuItem(
                            title: "Normal Hero",
                            icon: Icon(Icons.looks_one),
                            route: "/heroes/normal",
                          ),
                        ]
                    ),
                  ]
              ),
            ]
        ),
        ResponsiveDrawerMenuItem(
          title: "Future Handling",
          icon: Icon(Icons.refresh),
          route: "/future_handling",
        ),
        ResponsiveDrawerMenuItem(
          title: "Future Handling",
          icon: Icon(Icons.refresh),
          route: "/future_handling",
          children: [
            ResponsiveDrawerMenuItem(
              title: "Future Handling",
              icon: Icon(Icons.refresh),
              route: "/future_handling",
            ),
            ResponsiveDrawerMenuItem(
              title: "Future Handling",
              icon: Icon(Icons.refresh),
              route: "/future_handling",
            ),
            ResponsiveDrawerMenuItem(
              title: "Future Handling",
              icon: Icon(Icons.refresh),
              route: "/future_handling",
            ),
          ]
        ),
      ],
        compact: compact, selected: -1, style: DrawerMenuFromZero.styleTree,),
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
    );
  }

}
