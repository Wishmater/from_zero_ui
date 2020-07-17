import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageScaffoldInner extends PageFromZero {

  @override
  int get pageScaffoldDepth => 2;
  @override
  String get pageScaffoldId => "Home";

  PageScaffoldInner();

  @override
  _PageScaffoldInnerState createState() => _PageScaffoldInnerState();

}

class _PageScaffoldInnerState extends State<PageScaffoldInner> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Inner Page"),
      body: Center(
        child: Card(child: FlutterLogo(size: 512,)),
      ),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: -1,),
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

}
