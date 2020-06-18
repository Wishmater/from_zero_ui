import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

import '../home/page_home.dart';

class PageScaffold extends StatelessWidget {
  final animation;
  final secondaryAnimation;


  PageScaffold({this.animation, this.secondaryAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      title: Text("Scaffold FromZero"),
      body: Container(),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 1],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }
}
