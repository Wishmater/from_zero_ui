import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


import '../../router.dart';

class PageCustomHero extends StatefulWidget {

  const PageCustomHero({super.key});

  @override
  PageHeroesState createState() => PageHeroesState();

}

class PageHeroesState extends State<PageCustomHero> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: heroesRoutes),
        compact: compact,
      ),
    );
  }

  Widget _getPage(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Center(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.secondary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text("Heroes Test", style: Theme.of(context).textTheme.displaySmall,),
                ),
                const FlutterLogo(size: 512,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
