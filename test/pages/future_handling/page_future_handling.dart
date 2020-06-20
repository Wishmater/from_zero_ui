import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

import '../home/page_home.dart';

class PageFutureHandling extends StatelessWidget {

  final animation;
  final secondaryAnimation;
  final scrollController = ScrollController();

  PageFutureHandling({this.animation, this.secondaryAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
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
            children: [
              SizedBox(height: 12,),
              Card(
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
