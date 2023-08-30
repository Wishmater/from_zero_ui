
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


import '../../router.dart';

class PageFutureHandling extends StatefulWidget {

  const PageFutureHandling({super.key});

  @override
  PageFutureHandlingState createState() => PageFutureHandlingState();

}

class PageFutureHandlingState extends State<PageFutureHandling> {

  late Widget widgetToExport;
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      mainScrollController: scrollController,
      appbarType: ScaffoldFromZero.appbarTypeCollapse,
      title: Container(
        height: 56,
        width: 256,
        color: Colors.red,
        alignment: Alignment.center,
        child: const Text("Future Handling"),
      ),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
      drawerFooterBuilder: (scaffoldContext, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar",
          //   icon: Icon(Icons.file_download),
          //   onTap: () {
          //     showModalFromZero(
          //       context: scaffoldContext,
          //       // builder: (context) => Export(
          //       //   scaffoldContext: scaffoldContext,
          //       //   childBuilder: (context, i, currentSize, portrait, scale, format) => widgetToExport,
          //       //   childrenCount: (currentSize, portrait, scale, format) => 1,
          //       //   themeParameters: (context as WidgetRef).read(fromZeroThemeParametersProvider),
          //       //   title: DateTime.now().millisecondsSinceEpoch.toString() + " Future Handling",
          //       //   path: Export.getDefaultDirectoryPath('Playground From Zero'),
          //       // ),
          //     );
          //   },
          // ),
          DrawerMenuFromZero(
            tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: settingsRoutes),
            compact: compact,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: (){},
      ),
    );
  }

  // GlobalKey widgetToExportKey;
  Widget _getPage(context){
    widgetToExport = Column(
      // key: widgetToExportKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(const Duration(seconds: 2)).then((value) => "Kappa"),
              successBuilder: (context, result) {
                return Center(child: Text("Succes :)\r\nValue: $result"));
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        const SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(const Duration(seconds: 3)).then((value) => throw Exception()),
              successBuilder: (context, result) {
                return Center(child: Text("Succes :)\r\nValue: $result"));
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        const SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(const Duration(milliseconds: 10)).then((value) => "instant"),
              successBuilder: (context, result) {
                return const FlutterLogo(size: 600,);
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        const SizedBox(height: 500,),
      ],
    );
    return SingleChildScrollView(
      controller: scrollController,
      child: ResponsiveHorizontalInsets(
        child: widgetToExport,
      ),
    );
  }

}
