import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/animations/heroes_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../../router.dart';
import '../home/page_home.dart';

class PageCrossFadeHero extends StatefulWidget {

  PageCrossFadeHero();

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageCrossFadeHero> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: heroesRoutes),
        compact: compact,
      ),
    );
  }

  Widget _getPage(context){
    return WillPopScope(
      onWillPop: () async => await showModalFromZero(context: context, builder: (context) {
        return DialogFromZero(
          title: Text("Sure?"),
          dialogActions: [
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            SimpleDialogOption(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Center(
            child: Hero(
              tag: "hero_test",
              flightShuttleBuilder: HeroesFromZero.fadeThroughFlightShuttleBuilder,
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
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
