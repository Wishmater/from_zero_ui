import 'dart:math';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';


import '../../router.dart';

class PageScaffoldInner extends StatefulWidget {

  const PageScaffoldInner({super.key});

  @override
  PageScaffoldInnerState createState() => PageScaffoldInnerState();

}

class PageScaffoldInnerState extends State<PageScaffoldInner> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Text("Inner Page"),
      body: Center(
        child: Card(child: InkWell(
          onTap: () {
            GoRouter.of(context).pushNamed('scaffold_inner', queryParameters: {
              'rand': Random().nextDouble().toString(),
            });
          },
          child: const FlutterLogo(size: 512,),
        )),
      ),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
    );
  }

}
