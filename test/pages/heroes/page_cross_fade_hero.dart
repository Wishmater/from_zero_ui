import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/animations/heroes_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageCrossFadeHero extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageCrossFadeHero();

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageCrossFadeHero> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: List.generate(PageHome.tabs.length, (index) {
          if (PageHome.tabs[index].title=="Heroes") {
            return PageHome.tabs[index].copyWith(selectedChild: 1);
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
    return WillPopScope(
      onWillPop: () async => await showModal(context: context, builder: (context) => AlertDialog(
        title: Text("Sure?"),
        actions: [
          SimpleDialogOption(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          SimpleDialogOption(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Center(
            child: Hero(
              tag: "hero_test",
              flightShuttleBuilder: HeroesFromZero.fadeThroughFlightShuttleBuilder,
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
      ),
    );
  }

}
