import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../../router.dart';
import '../home/page_home.dart';

class PageNormalHero extends StatefulWidget {

  PageNormalHero();

  @override
  _PageHeroesState createState() => _PageHeroesState();

}

class _PageHeroesState extends State<PageNormalHero> {

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
