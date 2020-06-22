
import 'package:fluro/fluro.dart';
import 'package:from_zero_ui/src/custom_fluro_router.dart' as my_fluro_router;
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';

import 'pages/future_handling/page_future_handling.dart';
import 'pages/heroes/page_heroes.dart';
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

    router.defineRouteFromZero('/settings', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageSettings(previousPage, animation, secondaryAnimation));

    router.defineRouteFromZero('/', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageHome(previousPage, animation, secondaryAnimation));

    router.defineRouteFromZero('/scaffold', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageScaffold(previousPage, animation, secondaryAnimation));
    router.defineRouteFromZero('/scaffold/same', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageScaffoldSame(previousPage, animation, secondaryAnimation));
    router.defineRouteFromZero('/scaffold/inner', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageScaffoldInner(previousPage, animation, secondaryAnimation));
    router.defineRouteFromZero('/scaffold/other', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageScaffoldOther(previousPage, animation, secondaryAnimation));

    router.defineRouteFromZero('/lightweight_table', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageLightweightTable(previousPage, animation, secondaryAnimation));

    router.defineRouteFromZero('/future_handling', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageFutureHandling(previousPage, animation, secondaryAnimation));

    router.defineRouteFromZero('/heroes', (context, parameters, animation, secondaryAnimation, previousPage)
        => PageHeroes(previousPage, animation, secondaryAnimation));


  }

}