import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';

import '../home/page_home.dart';

class PageFutureHandling extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageFutureHandling(PageFromZero previousPage, Animation<double> animation, Animation<double> secondaryAnimation)
      : super(previousPage, animation, secondaryAnimation);

  @override
  _PageFutureHandlingState createState() => _PageFutureHandlingState();

}

class _PageFutureHandlingState extends State<PageFutureHandling> {

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Future Handling"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 3],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage(context){
    return ScrollbarFromZero(
      controller: scrollController,
      child: ResponsiveHorizontalInsets(
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
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
                  ),
                ),
              ),
              SizedBox(height: 12,),

              SizedBox(height: 12,),
            ],
          ),
        ),
      ),
    );
  }

}
