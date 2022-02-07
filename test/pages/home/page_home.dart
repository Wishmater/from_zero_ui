import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/app_update.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/ui_components/context_menu.dart';
import 'package:from_zero_ui/src/ui_utility/from_zero_logo.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:go_router/go_router.dart';

import '../../change_notifiers/theme_parameters.dart';
import '../../et_test.dart';
import '../../router.dart';

class PageHome extends StatefulWidget {

  PageHome();

  @override
  _PageHomeState createState() => _PageHomeState();

}

class _PageHomeState extends State<PageHome> {

  ScrollController controller = ScrollController();
  late DAO testDao;

  static bool updateCalled = false;
  @override
  void initState() {
//    if (!updateCalled){
//      UpdateFromZero(
//        1,
//        'http://190.92.122.228:8080/update/cutrans_crm_ver.json',
//        'http://190.92.122.228:8080/update/cutrans_crm.zip',
//      ).checkUpdate().then((value) => value.promptUpdate(context));
//    }
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
          }
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
      title: Row(
        children: [
          Text("FromZero playground"),
          Hero(
            tag: 'title-hero',
            child: Icon(Icons.ac_unit, color: Colors.white,),
          )
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
      actions: [
        ActionFromZero(title: "Test Action", onTap: (appbarContext){
          getEtDao().maybeEdit(context);
        },),
        ActionFromZero(title: "Test Action", onTap: (appbarContext){
          getEtDao().maybeEdit(context);
        },
          icon: Icon(Icons.call),
          breakpoints: {0: ActionState.icon},
        ),
        ActionFromZero(title: "Test Action", onTap: (appbarContext){
          getEtDao().maybeEdit(context);
        },
          icon: Icon(Icons.call),
          breakpoints: {0: ActionState.icon},),
        ActionFromZero(title: "Test Action", onTap: (appbarContext){
          getEtDao().maybeEdit(context);
        },
          icon: Icon(Icons.call),
          breakpoints: {0: ActionState.icon},),
      ],
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
              AppbarFiller(),
              SizedBox(height: 12,),
              AspectRatio(
                aspectRatio: 4,
                child: ContextMenuFromZero(
                  actions: List.generate(3, (index) {
                    return ActionFromZero(
                      title: 'Kappa $index',
                      icon: Icon(Icons.translate),
                    );
                  }),
                  child: FromZeroBanner(logoSizePercentage: 0.8,),
                ),
              ),
              SizedBox(height: 12,),
              SizedBox(height: 12,),
              Card(
                clipBehavior: Clip.hardEdge,
                child: Container(height: 1200, width: 600, color: Colors.red,
                  child: Column(
                    children: [
                      SizedBox(height: 16,),
                      Text(Platform.script.toString()),
                      SizedBox(height: 16,),
                      AspectRatio(
                        aspectRatio: 4,
                        child: FromZeroBanner(logoSizePercentage: 0.8,),
                      ),
                      SizedBox(height: 32,),
                      ContextMenuFromZero(
                        actions: [
                          ...List.generate(3, (index) {
                            return ActionFromZero(
                              title: 'Kappa $index',
                              icon: Icon(Icons.translate),
                            );
                          }),
                          ActionFromZero.divider(),
                          ...List.generate(3, (index) {
                            return ActionFromZero(
                              title: 'Krappa $index',
                              icon: Icon(Icons.send),
                              enabled: false,
                            );
                          }),
                        ],
                        child: RaisedButton(
                          child: Text("SCAFFOLD"),
                          onPressed: () {
                            Navigator.of(context).pushNamed("/scaffold");
                          },
                        ),
                      ),
                      SizedBox(height: 32,),
                      ...testDao.buildFormWidgets(context,
                        asSlivers: false,
                        expandToFillContainer: false,
                        showActionButtons: false,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12,),
            ],
          ),
        ),
      ),
    );
  }

}
