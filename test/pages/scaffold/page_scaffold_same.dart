import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';

import '../home/page_home.dart';

class PageScaffoldSame extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageScaffoldSame(Animation<double> animation, Animation<double> secondaryAnimation)
      : super(animation, secondaryAnimation);

  @override
  _PageScaffoldInnerState createState() => _PageScaffoldInnerState();

}

class _PageScaffoldInnerState extends State<PageScaffoldSame> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Inner Page"),
      body: Center(
        child: Card(child: FlutterLogo(size: 512,)),
      ),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, -1],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

}
