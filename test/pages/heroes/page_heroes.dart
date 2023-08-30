
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


import '../../router.dart';


class PageHeroes extends StatefulWidget {

  const PageHeroes({super.key});

  @override
  PageHeroesState createState() => PageHeroesState();

}

class PageHeroesState extends State<PageHeroes> {

  late Widget widgetToExport;
  HeroFlightShuttleBuilder? shuttleBuilder;

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Text("Heroes"),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
      drawerFooterBuilder: (context, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar",
          //   icon: Icon(Icons.file_download),
          //   onTap: () {
          //     showModalFromZero(
          //       context: context,
          //       builder: (scaffoldContext) => Export(
          //         scaffoldContext: scaffoldContext,
          //         childBuilder: (context, i, currentSize, portrait, scale, format) => widgetToExport,
          //         childrenCount: (currentSize, portrait, scale, format) => 1,
          //         themeParameters: (context as WidgetRef).read(fromZeroThemeParametersProvider),
          //         title: DateTime.now().millisecondsSinceEpoch.toString() + " Heroes",
          //         path: getApplicationDocumentsDirectory().then((value) => value.absolute.path+"/Playground From Zero/"),
          //       ),
          //     );
          //   },
          // ),
          DrawerMenuFromZero(
            tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: settingsRoutes),
            compact: compact,
          )
        ],
      ),
    );
  }

  Widget _getPage(context){
    widgetToExport = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: 8,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                    child: const Text("Normal Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = null;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/normal");
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                    child: const Text("CrossFade Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = HeroesFromZero.fadeThroughFlightShuttleBuilder;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/fade");
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton( //TODO 3- implement custom trransitionBuilderHero
                    child: const Text("Custom transionBuilder Hero"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = null;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/custom");
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                    child: const Text("CrossFade in a Page with Higher Depth"),
                    onPressed: () {
                      setState(() {
                        shuttleBuilder = HeroesFromZero.fadeThroughFlightShuttleBuilder;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        Navigator.pushNamed(context, "/heroes/inner");
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8,),
              ],
            ),
            const SizedBox(width: 32,),
            Hero(
              tag: "hero_test",
              flightShuttleBuilder: shuttleBuilder,
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text("Heroes Test", style: Theme.of(context).textTheme.titleMedium,),
                    ),
                    const FlutterLogo(size: 192,),
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
