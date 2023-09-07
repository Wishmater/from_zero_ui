import 'dart:io';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/ui_utility/from_zero_logo.dart';
import 'package:go_router/go_router.dart';

import '../../router.dart';

class PageHome extends StatefulWidget {

  const PageHome({super.key});

  @override
  PageHomeState createState() => PageHomeState();

}

class PageHomeState extends State<PageHome> {

  ScrollController controller = ScrollController();
  late DAO testDao;

  @override
  void initState() {
    testDao = DAO(
      uiNameGetter: (dao) => 'Test DAO',
      classUiNameGetter: (dao) => 'Test DAO',
      fieldGroups: [
        FieldGroup(
          fields: {
            'test_text': StringField(
              uiNameGetter: (field, dao) => 'TextField Test',
            ),
            'test_combo': ComboField(
              uiNameGetter: (field, dao) => 'Combo Test',
              possibleValuesGetter: (context, field, dao) => List.generate(40, (index) {
                return DAO(
                  uiNameGetter: (dao) => 'Item $index',
                  classUiNameGetter: (dao) => 'Item',
                );
              }),
            ),
          },
        ),
      ],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      mainScrollController: controller,
      scrollbarType: ScaffoldFromZero.scrollbarTypeOverAppbar,
      appbarType: ScaffoldFromZero.appbarTypeQuickReturn,
      title: const Row(
        children: [
          Text("FromZero playground"),
          Hero(
            tag: 'title-hero',
            child: Icon(Icons.ac_unit, color: Colors.white,),
          ),
        ],
      ),
      body: _getPage(context),
      drawerContentBuilder: (context, compact) {
        return DrawerMenuFromZero(
          tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: mainRoutes),
          compact: compact,
        );
      },
      drawerFooterBuilder: (context, compact) => DrawerMenuFromZero(
        tabs: ResponsiveDrawerMenuItem.fromGoRoutes(routes: settingsRoutes),
        compact: compact,
      ),
    );
  }

  Widget _getPage (BuildContext context){
    return SingleChildScrollView(
      controller: controller,
      child: ResponsiveHorizontalInsets(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppbarFiller(),
              const SizedBox(height: 12,),
              AspectRatio(
                aspectRatio: 4,
                child: ContextMenuFromZero(
                  actions: List.generate(3, (index) {
                    return ActionFromZero(
                      title: 'Kappa $index',
                      icon: const Icon(Icons.translate),
                    );
                  }),
                  child: const FromZeroBanner(logoSizePercentage: 0.8,),
                ),
              ),
              const SizedBox(height: 12,),
              const SizedBox(height: 12,),
              Card(
                clipBehavior: Clip.hardEdge,
                child: Container(height: 1200, width: 600, color: Colors.red,
                  child: Column(
                    children: [
                      const SizedBox(height: 16,),
                      Text(Platform.script.toString()),
                      const SizedBox(height: 16,),
                      const AspectRatio(
                        aspectRatio: 4,
                        child: FromZeroBanner(logoSizePercentage: 0.8,),
                      ),
                      const SizedBox(height: 32,),
                      ContextMenuFromZero(
                        actions: [
                          ...List.generate(3, (index) {
                            return ActionFromZero(
                              title: 'Kappa $index',
                              icon: const Icon(Icons.translate),
                            );
                          }),
                          ActionFromZero.divider(),
                          ...List.generate(3, (index) {
                            return ActionFromZero(
                              title: 'Krappa $index',
                              icon: const Icon(Icons.send),
                              enabled: false,
                            );
                          }),
                        ],
                        child: ElevatedButton(
                          child: const Text("SCAFFOLD"),
                          onPressed: () {
                            GoRouter.of(context).goNamed("scaffold");
                          },
                        ),
                      ),
                      const SizedBox(height: 32,),
                      ...testDao.buildFormWidgets(context,
                        asSlivers: false,
                        expandToFillContainer: false,
                        showActionButtons: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12,),
            ],
          ),
        ),
      ),
    );
  }

}
