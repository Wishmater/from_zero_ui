
import 'package:from_zero_ui/from_zero_ui.dart';

import 'pages/future_handling/page_future_handling.dart';
import 'pages/heroes/page_cross_fade_hero.dart';
import 'pages/heroes/page_custom_hero.dart';
import 'pages/heroes/page_heroes.dart';
import 'pages/heroes/page_inner_hero.dart';
import 'pages/heroes/page_normal_hero.dart';
import 'pages/home/page_home.dart';
import 'pages/lightweight_table/page_lightweight_table.dart';
import 'pages/scaffold/page_scaffold.dart';
import 'pages/scaffold/page_scaffold_inner.dart';
import 'pages/scaffold/page_scaffold_other.dart';
import 'pages/scaffold/page_scaffold_same.dart';
import 'pages/settings/page_settings.dart';

import 'package:fluro/fluro.dart';


class MyFluroRouter{

  static FluroRouter router = FluroRouter();

  static var cache;


  static void setupRouter() {

    router.define('/',
      handler: Handler(
        handlerFunc: (context, params){
          return SplashPage((_) async => '/home');
        },
      ),
    );


    router.define('/settings',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageSettings();
        },
      ),
    );


    router.define('/home',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageHome();
        },
      ),
    );


    router.define('/scaffold',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageScaffold();
        },
      ),
    );
    router.define('/scaffold/same',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageScaffoldSame();
        },
      ),
    );
    router.define('/scaffold/inner',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageScaffoldInner();
        },
      ),
    );
    router.define('/scaffold/other',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageScaffoldOther();
        },
      ),
    );


    router.define('/lightweight_table',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageLightweightTable();
        },
      ),
    );


    router.define('/future_handling',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageFutureHandling();
        },
      ),
    );


    router.define('/heroes',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageHeroes();
        },
      ),
    );
    router.define('/heroes/normal',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageNormalHero();
        },
      ),
    );
    router.define('/heroes/fade',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageCrossFadeHero();
        },
      ),
    );
    router.define('/heroes/custom',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageCustomHero();
        },
      ),
    );
    router.define('/heroes/inner',
      transitionType: TransitionType.custom,
      transitionDuration: Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) => child,
      handler: Handler(
        handlerFunc: (context, params){
          return PageInnerHero();
        },
      ),
    );

  }

}