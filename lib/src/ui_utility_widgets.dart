import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/src/scaffold_from_zero.dart';

class ResponsiveHorizontalInsets extends StatelessWidget {

  final Widget child;

  ResponsiveHorizontalInsets({this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < ScaffoldFromZero.medium ? 0 : 12),
      child: child,
    );
  }

}


class LoadingCheckbox extends StatelessWidget{

  final bool value;
  final ValueChanged<bool> onChanged;
  final MouseCursor mouseCursor;
  final Color activeColor;
  final Color checkColor;
  final MaterialTapTargetSize materialTapTargetSize;
  final VisualDensity visualDensity;
  final Color focusColor;
  final Color hoverColor;
  final FocusNode focusNode;
  final bool autofocus;
  final Widget loadingWidget;
  final Duration transitionDuration;
  final Key key;
  PageTransitionSwitcherTransitionBuilder pageTransitionBuilder;
  AnimatedSwitcherTransitionBuilder transitionBuilder;

  LoadingCheckbox({
    @required this.value,
    @required this.onChanged,
    this.mouseCursor,
    this.activeColor, this.checkColor, this.materialTapTargetSize,
    this.visualDensity, this.focusColor, this.hoverColor, this.focusNode,
    this.autofocus = false,
    this.loadingWidget = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3,),),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionBuilder,
    this.transitionBuilder,
    this.key,
  }) {
    if (transitionBuilder==null && pageTransitionBuilder==null)
      transitionBuilder = _defaultTransitionBuilder;
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    if (value==null){
      result = Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        child: loadingWidget,
      );
    } else{
      result = Checkbox(
        key: key,
        value: value,
        onChanged: onChanged,
        mouseCursor: mouseCursor,
        activeColor: activeColor,
        checkColor: checkColor,
        focusColor: focusColor,
        hoverColor: hoverColor,
        materialTapTargetSize: materialTapTargetSize,
        visualDensity: visualDensity,
        focusNode: focusNode,
        autofocus: autofocus,
      );
    }
    if (pageTransitionBuilder!=null)
      return PageTransitionSwitcher(
        transitionBuilder: pageTransitionBuilder,
        duration: transitionDuration,
        child: result,
      );
    else
      return AnimatedSwitcher(
        transitionBuilder: transitionBuilder,
        duration: transitionDuration,
        child: result,
      );
  }

  AnimatedSwitcherTransitionBuilder _defaultTransitionBuilder
      = (Widget child, Animation<double> animation)
    => ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic), child: child,);


  PageTransitionSwitcherTransitionBuilder _defaultPageTransitionBuilder
      = (child, primaryAnimation, secondaryAnimation) {
    return FadeThroughTransition(
      animation: primaryAnimation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Colors.transparent,
      child: child,
    );
  };

}

class AnimatedEntryWidget extends StatefulWidget {

  Widget child;
  AnimatedSwitcherTransitionBuilder transitionBuilder;
  Duration duration;
  Curve curve;

  AnimatedEntryWidget({
    @required this.child,
    this.transitionBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
  }) {
    if (transitionBuilder==null) transitionBuilder = (child, animation){
      return FadeTransition(opacity: animation, child: child,);
    };
  }

  @override
  _AnimatedEntryWidgetState createState() => _AnimatedEntryWidgetState();

}

class _AnimatedEntryWidgetState extends State<AnimatedEntryWidget> with SingleTickerProviderStateMixin{

  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    controller.forward(from: 0);
    animation = CurvedAnimation(
      parent: controller,
      curve: widget.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.transitionBuilder(widget.child, animation);
  }

}

//TODO 3 move more stuff here
//TODO 3 move logic that restricts screen usage on xLarge screens here