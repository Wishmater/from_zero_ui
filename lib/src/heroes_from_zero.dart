import 'package:flutter/material.dart';

abstract class HeroesFromZero{

  static HeroFlightShuttleBuilder fadeThroughFlightShuttleBuilder =
      (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        final Hero newHero =
        (flightDirection == HeroFlightDirection.pop
            ? fromHeroContext.widget
            : toHeroContext.widget) as Hero;
        final Hero oldHero =
        (flightDirection == HeroFlightDirection.push
            ? fromHeroContext.widget
            : toHeroContext.widget) as Hero;
        Animation<double> newAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return LayoutBuilder(
          builder: (context, constraints) => OverflowBox(
            minHeight: constraints.minHeight,
            maxHeight: constraints.maxHeight,
            minWidth: constraints.minWidth,
            maxWidth: constraints.maxWidth,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.contain,
                  child: ConstrainedBox(
                    constraints: BoxConstraints.loose(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    child: oldHero.child,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.contain,
                  child: FadeTransition(
                    opacity: newAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints.loose(
                        Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      child: newHero.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  };

}