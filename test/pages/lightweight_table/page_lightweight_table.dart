import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import '../home/page_home.dart';

class PageLightweightTable extends StatelessWidget {
  final animation;
  final secondaryAnimation;

  ScrollController scrollController = ScrollController();

  PageLightweightTable({this.animation, this.secondaryAnimation});

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      title: Text("Lightweight Table"),
      body: _getPage(context),
      drawerContentBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.tabs, compact: compact, selected: [0, 2],),
      drawerFooterBuilder: (compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: [-1, -1], replaceInsteadOfPuhsing: DrawerMenuFromZero.neverReplaceInsteadOfPuhsing,),
    );
  }

  Widget _getPage(context){
    return ScrollbarFromZero(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: ResponsiveHorizontalInsets(
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
