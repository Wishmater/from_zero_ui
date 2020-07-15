import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageScaffold extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageScaffold();

  @override
  _PageScaffoldState createState() => _PageScaffoldState();

}

class _PageScaffoldState extends State<PageScaffold> {

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Scaffold FromZero"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(
        compact: compact,
        selected: 1,
        tabs: PageHome.tabs,
      ),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage(BuildContext context){
    return ScrollbarFromZero(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: ResponsiveHorizontalInsets(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 12,),
                Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Page Transitions", style: Theme.of(context).textTheme.headline4,),
                        SizedBox(height: 32,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Same ID and Same Depth"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/same"),
                          ),
                        ),
                        SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Same ID and Higher Depth"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/inner"),
                          ),
                        ),
                        SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Different ID"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/other"),
                          ),
                        ),
                        SizedBox(height: 8,),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
