import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageScaffoldSame extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageScaffoldSame();

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
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: -1,),
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
    );
  }

}
