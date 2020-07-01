import 'dart:math';

import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';
import '../util/custom_fluro_router.dart' as my_fluro_router;


typedef PageFromZero PageFromZeroCallback(
    BuildContext context, Map<String, List<String>> parameters,
    Animation<double> animation, Animation<double> secondaryAnimation,
//    PageFromZero previousPage,
);

typedef Widget HandlerFunc(
    BuildContext context, Map<String, List<String>> parameters,
    Animation<double> animation, Animation<double> secondaryAnimation);

class Handler {
  Handler({this.type = HandlerType.route, this.handlerFunc});
  final HandlerType type;
  final HandlerFunc handlerFunc;
}

class FluroRouterFromZero extends my_fluro_router.Router{

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
  String get pageScaffoldId;
  /// Scaffold will perform a SharedZAxisTransition if the depth is different (and not -1)
  int get pageScaffoldDepth;
  /// PageTransition animation
  final Animation<double> animation;
  /// PageTransition secondaryAnimation
  final Animation<double> secondaryAnimation;

  int randomId = 0;


  PageFromZero(this.animation, this.secondaryAnimation) : super();

}