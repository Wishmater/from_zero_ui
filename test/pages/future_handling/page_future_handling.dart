import 'dart:io';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageFutureHandling extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageFutureHandling();

  @override
  _PageFutureHandlingState createState() => _PageFutureHandlingState();

}

class _PageFutureHandlingState extends State<PageFutureHandling> {

  late Widget widgetToExport;
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      mainScrollController: scrollController,
      appbarType: ScaffoldFromZero.appbarTypeCollapse,
      currentPage: widget,
      title: Container(
        height: 56,
        width: 256,
        color: Colors.red,
        alignment: Alignment.center,
        child: Text("Future Handling"),
      ),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: 4,),
      drawerFooterBuilder: (scaffoldContext, compact) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DrawerMenuButtonFromZero(
          //   selected: false,
          //   compact: compact,
          //   title: "Exportar",
          //   icon: Icon(Icons.file_download),
          //   onTap: () {
          //     showModal(
          //       context: scaffoldContext,
          //       // builder: (context) => Export(
          //       //   scaffoldContext: scaffoldContext,
          //       //   childBuilder: (context, i, currentSize, portrait, scale, format) => widgetToExport,
          //       //   childrenCount: (currentSize, portrait, scale, format) => 1,
          //       //   themeParameters: Provider.of<ThemeParameters>(context, listen: false),
          //       //   title: DateTime.now().millisecondsSinceEpoch.toString() + " Future Handling",
          //       //   path: Export.getDefaultDirectoryPath('Playground From Zero'),
          //       // ),
          //     );
          //   },
          // ),
          DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
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
        SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(Duration(seconds: 2)).then((value) => "Kappa"),
              successBuilder: (context, result) {
                return Center(child: Text("Succes :)\r\nValue: $result"));
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(Duration(seconds: 3)).then((value) => throw Exception()),
              successBuilder: (context, result) {
                return Center(child: Text("Succes :)\r\nValue: $result"));
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        SizedBox(height: 12,),
        Card(
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilderFromZero(
              future: Future.delayed(Duration(milliseconds: 10)).then((value) => "instant"),
              successBuilder: (context, result) {
                return FlutterLogo(size: 600,);
              },
              applyAnimatedContainerFromChildSize: true,
            ),
          ),
        ),
        SizedBox(height: 500,),
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
