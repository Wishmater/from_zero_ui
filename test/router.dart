
import 'package:fluro/fluro.dart';
import 'package:from_zero_ui/src/custom_fluro_router.dart' as my_fluro_router;

import 'pages/future_handling/page_future_handling.dart';
import 'pages/heroes/page_heroes.dart';
import 'pages/home/page_home.dart';
import 'pages/lightweight_table/page_lightweight_table.dart';
import 'pages/scaffold/page_scaffold.dart';
import 'pages/settings/page_settings.dart';


class FluroRouter{

  static my_fluro_router.Router router = my_fluro_router.Router();
  static final defaultTransitionType = TransitionType.custom;
//  static final defaultTransitionType = TransitionType.material;
//  static final defaultTransitionType = kIsWeb ? TransitionType.fadeIn : TransitionType.material;

  static var cache;
  static String addonHeroTag = '';
  static String lastPageID;



  static void setupRouter() {

    router.define(
      '/settings',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageSettings();
        },
      ),
      transitionType: TransitionType.materialFullScreenDialog,
    );

    router.define(
      '/',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageHome(animation: animation, secondaryAnimation: secondaryAnimation,);
        },
      ),
    );

    router.define(
      '/scaffold',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageScaffold(animation: animation, secondaryAnimation: secondaryAnimation,);
        },
      ),
    );

    router.define(
      '/lightweight_table',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageLightweightTable(animation: animation, secondaryAnimation: secondaryAnimation,);
        },
      ),
    );

    router.define(
      '/future_handling',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageFutureHandling(animation: animation, secondaryAnimation: secondaryAnimation,);
        },
      ),
    );

    router.define(
      '/heroes',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageHeroes(animation: animation, secondaryAnimation: secondaryAnimation,);
        },
      ),
    );

  }

}