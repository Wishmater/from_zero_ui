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
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < ScaffoldFromZero.screenSizeMedium ? 0 : 12),
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

class MaterialKeyValuePair extends StatelessWidget {

  String title;
  String value;
  bool frame;


  MaterialKeyValuePair({@required this.title, @required this.value, this.frame=false});

  @override
  Widget build(BuildContext context) {
    if (frame){
      return Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.caption,),
              Stack(
                fit: StackFit.passthrough,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 1),
                    child: Text(value,),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: Divider(
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: VerticalDivider(
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title!=null)
          Text(
            title,
            style: Theme.of(context).textTheme.caption,
          ),
        if (value!=null)
          Text(
            value,
          ),
      ],
    );
  }

}

class AppbarFiller extends StatelessWidget {

  final height;

  AppbarFiller({this.height=56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height+MediaQuery.of(context).padding.top,
//      color: Theme.of(context).appBarTheme.color??Theme.of(context).primaryColor,
    );
  }
}

class OpacityGradient extends StatelessWidget {

  static const left = 0;
  static const right = 1;
  static const top = 2;
  static const bottom = 3;
  static const horizontal = 4;
  static const vertical = 5;
  //TODO 3 implement all

  final Widget child;
  final int direction;
  final double size;
  final double percentage;


  OpacityGradient({
    @required this.child,
    this.direction = vertical,
    double size,
    this.percentage,
  }) :
    assert(size==null || percentage==null, "Can't set both a hard size and a percentage."),
    size = size==null&&percentage==null ? 16 : size
  ;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: direction==top || direction==bottom || direction==vertical
            ? Alignment.topCenter : Alignment.centerLeft,
        end: direction==top || direction==bottom || direction==vertical
            ? Alignment.bottomCenter : Alignment.centerRight,
        stops: [
          0,
          direction==bottom || direction==right ? 0
              : size==null ? percentage
              : size/(direction==top || direction==bottom || direction==vertical ? bounds.height : bounds.width),
          direction==top || direction==left ? 1
              : size==null ? 1-percentage
              : 1-size/(direction==top || direction==bottom || direction==vertical ? bounds.height : bounds.width),
          1,
        ],
        colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

class TextIcon extends StatelessWidget {

  final String text;
  final double width;
  final double height;

  TextIcon(
      this.text,
      {this.width = 24,
      this.height = 24,}
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness==Brightness.light ? Colors.black45 : Colors.white,
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.bodyText1.copyWith(color: Theme.of(context).cardColor),
          ),
        ),
      ),
    );
  }

}
