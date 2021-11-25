import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/animations/heroes_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';


class PageHeroes extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageHeroes();

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageHeroes> {

  late Widget widgetToExport;
  HeroFlightShuttleBuilder? shuttleBuilder;

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: 3,),
      drawerFooterBuilder: (context, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar",
          //   icon: Icon(Icons.file_download),
          //   onTap: () {
          //     showModal(
          //       context: context,
          //       builder: (scaffoldContext) => Export(
          //         scaffoldContext: scaffoldContext,
          //         childBuilder: (context, i, currentSize, portrait, scale, format) => widgetToExport,
          //         childrenCount: (currentSize, portrait, scale, format) => 1,
          //         themeParameters: Provider.of<ThemeParameters>(context, listen: false),
          //         title: DateTime.now().millisecondsSinceEpoch.toString() + " Heroes",
          //         path: getApplicationDocumentsDirectory().then((value) => value.absolute.path+"/Playground From Zero/"),
          //       ),
          //     );
          //   },
          // ),
          DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
        ],
      ),
    );
  }

  Widget _getPage(context){
    widgetToExport = Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                SizedBox(height: 8,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RaisedButton(
                    child: Text("Normal Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = null;
                      });
                      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/normal");
                      });
                    },
                  ),
                ),
                SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RaisedButton(
                    child: Text("CrossFade Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = HeroesFromZero.fadeThroughFlightShuttleBuilder;
                      });
                      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/fade");
                      });
                    },
                  ),
                ),
                SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RaisedButton( //TODO 3- implement custom trransitionBuilderHero
                    child: Text("Custom transionBuilder Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = null;
                      });
                      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/custom");
                      });
                    },
                  ),
                ),
                SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RaisedButton(
                    child: Text("CrossFade in a Page with Higher Depth"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = HeroesFromZero.fadeThroughFlightShuttleBuilder;
                      });
                      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/inner");
                      });
                    },
                  ),
                ),
                SizedBox(height: 8,),
              ],
            ),
            SizedBox(width: 32,),
            Hero(
              tag: "hero_test",
              flightShuttleBuilder: shuttleBuilder,
              child: Container(
                color: Theme.of(context).accentColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text("Heroes Test", style: Theme.of(context).textTheme.subtitle1,),
                    ),
                    FlutterLogo(size: 192,),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: widgetToExport
    );
  }

}
