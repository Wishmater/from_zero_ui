import 'dart:math';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:go_router/go_router.dart';


import '../../change_notifiers/theme_parameters.dart';
import '../../router.dart';
import '../home/page_home.dart';

class PageScaffoldInner extends StatefulWidget {

  PageScaffoldInner();

  @override
  _PageScaffoldInnerState createState() => _PageScaffoldInnerState();

}

class _PageScaffoldInnerState extends State<PageScaffoldInner> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: Text("Inner Page"),
      body: Center(
        child: Card(child: InkWell(
          onTap: () {
            GoRouter.of(context).pushNamed('scaffold_inner', queryParameters: {
              'rand': Random().nextDouble().toString(),
            });
          },
          child: FlutterLogo(size: 512,),
        )),
      ),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
    );
  }

}
