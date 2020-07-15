
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';

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


class FluroRouter{

  static FluroRouterFromZero router = FluroRouterFromZero();

  static var cache;


  static void setupRouter() {

    router.define(
      '/',
      handler: Handler(
        handlerFunc: (context, params, animation, secondaryAnimation){
          return SplashPage(() async => '/home');
        },
      ),
    );


    router.defineRouteFromZero('/settings', (context, parameters, animation, secondaryAnimation,)
        => PageSettings());


    router.defineRouteFromZero('/home', (context, parameters, animation, secondaryAnimation,)
        => PageHome());


    router.defineRouteFromZero('/scaffold', (context, parameters, animation, secondaryAnimation,)
        => PageScaffold());
    router.defineRouteFromZero('/scaffold/same', (context, parameters, animation, secondaryAnimation,)
        => PageScaffoldSame());
    router.defineRouteFromZero('/scaffold/inner', (context, parameters, animation, secondaryAnimation,)
        => PageScaffoldInner());
    router.defineRouteFromZero('/scaffold/other', (context, parameters, animation, secondaryAnimation,)
        => PageScaffoldOther());


    router.defineRouteFromZero('/lightweight_table', (context, parameters, animation, secondaryAnimation,)
        => PageLightweightTable());


    router.defineRouteFromZero('/future_handling', (context, parameters, animation, secondaryAnimation,)
        => PageFutureHandling());


    router.defineRouteFromZero('/heroes', (context, parameters, animation, secondaryAnimation,)
        => PageHeroes());
    router.defineRouteFromZero('/heroes/normal', (context, parameters, animation, secondaryAnimation,)
        => PageNormalHero());
    router.defineRouteFromZero('/heroes/fade', (context, parameters, animation, secondaryAnimation,)
        => PageCrossFadeHero());
    router.defineRouteFromZero('/heroes/custom', (context, parameters, animation, secondaryAnimation,)
        => PageCustomHero());
    router.defineRouteFromZero('/heroes/inner', (context, parameters, animation, secondaryAnimation,)
        => PageInnerHero());


  }

}