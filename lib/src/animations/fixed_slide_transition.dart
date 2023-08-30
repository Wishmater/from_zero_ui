import 'package:flutter/material.dart';


class FixedSlideTransition extends AnimatedWidget {

  final Widget? child;
  final Animation<Offset> position;
  final bool transformHitTests;
  final FilterQuality? filterQuality;


  const FixedSlideTransition({
    required this.child,
    required this.position,
    this.transformHitTests = true,
    this.filterQuality,
    super.key,
  }) : super(listenable: position);

  @override
  Widget build(BuildContext context) {
    Offset offset = position.value;
    return Transform.translate(
      offset: offset,
      transformHitTests: transformHitTests,
      filterQuality: filterQuality,
      child: child,
    );
  }

}
