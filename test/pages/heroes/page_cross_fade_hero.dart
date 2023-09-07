import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


import '../../router.dart';

class PageCrossFadeHero extends StatefulWidget {

  const PageCrossFadeHero({super.key});

  @override
  PageHeroesState createState() => PageHeroesState();

}

class PageHeroesState extends State<PageCrossFadeHero> {

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
    return WillPopScope(
      onWillPop: () async => await showModalFromZero(context: context, builder: (context) {
        return DialogFromZero(
          title: const Text("Sure?"),
          dialogActions: [
            SimpleDialogOption(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            SimpleDialogOption(
              child: const Text("OK"),
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
        ),
      ),
    );
  }

}
