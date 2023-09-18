import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';


import '../../router.dart';

class PageScaffold extends StatefulWidget {

  const PageScaffold({super.key});

  @override
  PageScaffoldState createState() => PageScaffoldState();

}

class PageScaffoldState extends State<PageScaffold> {

  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Row(
        children: [
          Text("Scaffold FromZero"),
          Hero(
            tag: 'title-hero',
            child: Icon(Icons.ac_unit, color: Colors.white,),
          ),
        ],
      ),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
        compact: compact,
      ),
      actions: [
        Builder(
          builder: (context) {
            return ActionFromZero(
              title: "Action 1",
              icon: const Icon(Icons.looks_one),
              onTap: (appbarContext){
                SnackBarFromZero(
                  context: context,
                  type: SnackBarFromZero.info,
                  title: const Text("Title"),
                  message: const Text("Pog message..."),
                  duration: const Duration(seconds: 10),
                  actions: [
                    SnackBarAction(
                      label: "Action",
                      onPressed: (){
                        SnackBarFromZero(
                          context: context,
                          type: SnackBarFromZero.info,
                          title: const Text("Action Pressed"),
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
          },
        ),
        Builder(builder: (context) => ActionFromZero(
          title: "Action 2",
          breakpoints: {
            ScaffoldFromZero.screenSizeMedium: ActionState.button,
          },
          onTap: (appbarContext){

          },
        ),),

        ActionFromZero(
          title: "Search",
          icon: const Icon(Icons.search),
          expandedBuilder: ({required context, required title, enabled=true, icon, onTap, color}) {
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
                const SizedBox(height: 12,),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Page Transitions", style: Theme.of(context).textTheme.headlineMedium,),
                        const SizedBox(height: 32,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ElevatedButton(
                            child: const Text("Page With Same ID and Same Depth"),
                            onPressed: () => GoRouter.of(context).pushNamed("scaffold_same"),
                          ),
                        ),
                        const SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ElevatedButton(
                            child: const Text("Page With Same ID and Higher Depth"),
                            onPressed: () => GoRouter.of(context).pushNamed("scaffold_inner"),
                          ),
                        ),
                        const SizedBox(height: 16,),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ElevatedButton(
                            child: const Text("Page With Different ID"),
                            onPressed: () => GoRouter.of(context).pushNamed("scaffold_other"),
                          ),
                        ),
                        const SizedBox(height: 8,),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
