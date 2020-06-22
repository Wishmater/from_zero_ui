import 'package:flutter/material.dart';

abstract class HeroesFromZero{

  static HeroFlightShuttleBuilder fadeThroughFlightShuttleBuilder =
      (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        final Hero newHero =
        flightDirection == HeroFlightDirection.pop
            ? fromHeroContext.widget
            : toHeroContext.widget;
        final Hero oldHero =
        flightDirection == HeroFlightDirection.push
            ? fromHeroContext.widget
            : toHeroContext.widget;
        Animation<double> newAnimation = CurvedAnimation(parent: animation, curve: Curves.linear); // TODO ??? maybe use easeOut curve
        return Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: oldHero.child,
            ),
            FittedBox(
              fit: BoxFit.contain,
              child: FadeTransition(
                opacity: newAnimation,
                child: newHero.child,
              ),
            ),
          ],
        );
  };

}