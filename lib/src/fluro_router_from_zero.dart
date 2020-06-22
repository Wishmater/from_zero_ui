import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'file:///C:/Workspaces/Flutter/from_zero_ui/lib/util/custom_fluro_router.dart' as my_fluro_router;


typedef PageFromZero PageFromZeroCallback(
    BuildContext context, Map<String, List<String>> parameters,
    Animation<double> animation, Animation<double> secondaryAnimation,
    PageFromZero lastPage,
);

class FluroRouterFromZero extends my_fluro_router.Router{

  static PageFromZero previousPage;

  void defineRouteFromZero(String routePath, PageFromZeroCallback pageFromZeroCallback){
    define(
      routePath,
      handler: my_fluro_router.Handler(
        handlerFunc: (context, params, animation, secondaryAnimation) {
          PageFromZero newPage = pageFromZeroCallback(context, params, animation, secondaryAnimation, previousPage);
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

  final PageFromZero previousPage;

  final int randomId = DateTime.now().millisecondsSinceEpoch;


  PageFromZero(this.previousPage, this.animation, this.secondaryAnimation);


//  @override
//  bool operator == (dynamic other) => other is PageFromZero && this.randomId==other.randomId;
//  @override
//  int get hashCode => this.randomId;

}