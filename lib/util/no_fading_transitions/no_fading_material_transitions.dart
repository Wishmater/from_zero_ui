
import 'package:flutter/material.dart';

class FadeUpwardsSlideTransition extends StatelessWidget {
  final bool upwards;
  final Tween<Offset>? movementTween;
  FadeUpwardsSlideTransition({
    required Animation<double> routeAnimation,
    required this.child,
    this.movementTween,
    this.upwards = true,
    super.key,
  }) : _positionAnimation = routeAnimation
          .drive((movementTween ?? (upwards ? _bottomUpTween : _topDownTween))
              .chain(_fastOutSlowInTween),);

  // Fractional offset from 1/4 screen below the top to fully on screen.
  static final Tween<Offset> _bottomUpTween = Tween<Offset>(
    begin: const Offset(0.0, 0.25),
    end: Offset.zero,
  );
  // Fractional offset from 1/4 screen aboce the top to fully on screen.
  static final Tween<Offset> _topDownTween = Tween<Offset>(
    begin: const Offset(0.0, -0.25),
    end: Offset.zero,
  );
  static final Animatable<double> _fastOutSlowInTween = CurveTween(curve: Curves.fastOutSlowIn);

  final Animation<Offset> _positionAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _positionAnimation,
      child: child,
    );
  }
}

class FadeUpwardsFadeTransition extends StatelessWidget {
  FadeUpwardsFadeTransition({
    required Animation<double> routeAnimation,
    required this.child,
    super.key,
  }) : _opacityAnimation = routeAnimation.drive(_easeInTween);

  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);

  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: child,
    );
  }
}