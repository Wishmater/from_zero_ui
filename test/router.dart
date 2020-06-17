
import 'package:fluro/fluro.dart';
import 'package:from_zero_ui/src/custom_fluro_router.dart' as my_fluro_router;

import 'pages/home/page_home.dart';


class FluroRouter{

  static my_fluro_router.Router router = my_fluro_router.Router();
  static final defaultTransitionType = TransitionType.custom;
//  static final defaultTransitionType = TransitionType.material;
//  static final defaultTransitionType = kIsWeb ? TransitionType.fadeIn : TransitionType.material;

  static var cache;
  static String addonHeroTag = '';



  static void setupRouter() {

    router.define(
      '/',
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          return PageHome();
        },
      ),
    );

  }

}