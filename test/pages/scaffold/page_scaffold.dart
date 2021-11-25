import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:provider/provider.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../home/page_home.dart';

class PageScaffold extends PageFromZero {

  @override
  int get pageScaffoldDepth => 1;
  @override
  String get pageScaffoldId => "Home";

  PageScaffold();

  @override
  _PageScaffoldState createState() => _PageScaffoldState();

}

class _PageScaffoldState extends State<PageScaffold> {

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Row(
        children: [
          Text("Scaffold FromZero"),
          Hero(
            tag: 'title-hero',
            child: Icon(Icons.ac_unit, color: Colors.white,),
          )
        ],
      ),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        compact: compact,
        selected: 1,
        tabs: PageHome.tabs,
      ),
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(tabs: PageHome.footerTabs, compact: compact, selected: -1, replaceInsteadOfPushing: DrawerMenuFromZero.neverReplaceInsteadOfPushing,),
      actions: [
        Builder(
          builder: (context) {
            return ActionFromZero(
              title: "Action 1",
              icon: Icon(Icons.looks_one),
              onTap: (appbarContext){
                SnackBarFromZero(
                  context: context,
                  type: SnackBarFromZero.info,
                  title: Text("Title"),
                  message: Text("Pog message..."),
                  duration: Duration(seconds: 10),
                  actions: [
                    SnackBarAction(
                      label: "Action",
                      onPressed: (){
                        SnackBarFromZero(
                          context: context,
                          type: SnackBarFromZero.info,
                          title: Text("Action Pressed"),
                        ).show(context);
                      },
                    ),
//                    SnackBarAction(
//                      label: "Action",
//                      onPressed: (){
//                        SnackBarFromZero(
//                          context: context,
//                          type: SnackBarFromZero.info,
//                          title: Text("Action Pressed"),
//                        ).show(context);
//                      },
//                    ),
//                    SnackBarAction(
//                      label: "Action",
//                      onPressed: (){
//                        SnackBarFromZero(
//                          context: context,
//                          type: SnackBarFromZero.info,
//                          title: Text("Action Pressed"),
//                        ).show(context);
//                      },
//                    ),
                  ],
                ).show(context);
              },
            );
          }
        ),
        Builder(builder: (context) => ActionFromZero(
          title: "Action 2",
          breakpoints: {
            ScaffoldFromZero.screenSizeMedium: ActionState.button,
          },
          onTap: (appbarContext){
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text("pepeg"),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
              width: 512,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: "Do something", onPressed: (){},),
//              margin: EdgeInsets.all(0),
              padding: EdgeInsets.all(0),

            ));
          },
        ),),

        ActionFromZero(
          title: "Search",
          icon: Icon(Icons.search),
          expandedBuilder: ({required context, enabled=true, icon, onTap, required title}) {
            return Container(
              width: 256,
              color: Colors.green,
            );
          },
        ),
      ],
    );
  }

  Widget _getPage(BuildContext context){
    return ScrollbarFromZero(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        child: ResponsiveHorizontalInsets(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 12,),
                Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Page Transitions", style: Theme.of(context).textTheme.headline4,),
                        SizedBox(height: 32,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Same ID and Same Depth"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/same"),
                          ),
                        ),
                        SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Same ID and Higher Depth"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/inner"),
                          ),
                        ),
                        SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: RaisedButton(
                            child: Text("Page With Different ID"),
                            onPressed: () => Navigator.pushNamed(context, "/scaffold/other"),
                          ),
                        ),
                        SizedBox(height: 8,),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
