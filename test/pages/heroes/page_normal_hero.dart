import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageNormalHero extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageNormalHero(Animation<double> animation, Animation<double> secondaryAnimation)
      : super(animation, secondaryAnimation);

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageNormalHero> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(
        tabs: List.generate(PageHome.tabs.length, (index) {
          if (PageHome.tabs[index].title=="Heroes") {
            return PageHome.tabs[index].copyWith(selectedChild: 0);
          }
          return PageHome.tabs[index];
        })
        , compact: compact,
        selected: -1,
      ),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage(context){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Center(
          child: Hero(
            tag: "hero_test",
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
      ),
    );
  }

}