import 'dart:math';

import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import '../util/custom_fluro_router.dart' as my_fluro_router;


@deprecated
typedef PageFromZero PageFromZeroCallback(
    BuildContext context, Map<String, List<String>> parameters,
    Animation<double> animation, Animation<double> secondaryAnimation,
//    PageFromZero previousPage,
);

@deprecated
typedef Widget HandlerFunc(
    BuildContext context, Map<String, List<String>> parameters,
    Animation<double> animation, Animation<double> secondaryAnimation);

@deprecated
class Handler {
  Handler({this.type = HandlerType.route, this.handlerFunc});
  final HandlerType type;
  final HandlerFunc handlerFunc;
}

@deprecated
class FluroRouterFromZero extends my_fluro_router.Router{
  //TODO 1 remove this at some point and if needed, define it as an extension method to FluroRouter, also move everything in this file to ScaffoldFromZero
  @deprecated
  void defineRouteFromZero(String routePath, PageFromZeroCallback pageFromZeroCallback){
    define(
      routePath,
      handler: Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          PageFromZero newPage = pageFromZeroCallback(context, params, animation, secondaryAnimation);
          return newPage;
        },
      ),
      transitionType: TransitionType.custom,
    );
  }

}


abstract class PageFromZero extends StatefulWidget{

  /// Use this to separate pages. Different page IDs will perform an animation in the whole Scaffold, instead of just the body
  String get pageScaffoldId; // TODO 1 ????? maybe find a way to define this in pageRoute or something to deprecate PageFromZero and its whole mechanism
  /// Scaffold will perform a SharedZAxisTransition if the depth is different (and not -1)
  int get pageScaffoldDepth;


  int randomId = 0;


  PageFromZero() : super();

}