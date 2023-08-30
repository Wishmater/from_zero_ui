import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


import '../../router.dart';

class PageScaffoldOther extends StatefulWidget {

  const PageScaffoldOther({super.key});

  @override
  PageScaffoldInnerState createState() => PageScaffoldInnerState();

}

class PageScaffoldInnerState extends State<PageScaffoldOther> {

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Text("Inner Page"),
      body: const Center(
        child: Card(child: FlutterLogo(size: 512,)),
      ),
      useCompactDrawerInsteadOfClose: false,
      drawerWidth: 512,
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
    );
  }

}
