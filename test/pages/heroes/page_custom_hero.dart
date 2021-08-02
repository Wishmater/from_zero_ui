import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageCustomHero extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageCustomHero();

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageCustomHero> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: List.generate(PageHome.tabs.length, (index) {
          if (PageHome.tabs[index].title=="Heroes") {
            return PageHome.tabs[index].copyWith(selectedChild: 2);
          }
          return PageHome.tabs[index];
        })
        , compact: compact,
        selected: -1,
      ),
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
    );
  }

  Widget _getPage(context){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Center(
          child: Container(
            color: Theme.of(context).accentColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text("Heroes Test", style: Theme.of(context).textTheme.headline3,),
                ),
                FlutterLogo(size: 512,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
