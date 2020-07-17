import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:marquee/marquee.dart';


enum ActionState {
  overflow,
  icon,
  button,
  expanded,
}

class AppbarAction extends StatelessWidget{

  /// callback called when icon/button/overflowMenuItem is clicked
  /// if null and expandedWidget!= null, will switch expanded
  final VoidCallback onTap;
  final String title;
  final Widget icon;

  /// from each breakpoint up, the selected widget will be used
  /// defaults to overflow
  Map<double, ActionState> breakpoints;

  /// optional callbacks to customize the look of the widget in its different states
  Widget Function(BuildContext context, String title, Widget icon) overflowBuilder;
  Widget Function(BuildContext context, String title, Widget icon, VoidCallback onTap) iconBuilder;
  Widget Function(BuildContext context, String title, Widget icon, VoidCallback onTap) buttonBuilder;
  Widget Function(BuildContext context, String title, Widget icon) expandedBuilder;

  AppbarAction({
    this.onTap,
    @required this.title,
    this.icon,
    this.breakpoints,
    this.overflowBuilder,
    this.iconBuilder,
    this.buttonBuilder,
    this.expandedBuilder,
  }){
    if (breakpoints==null) breakpoints = {
      0: icon==null ? ActionState.overflow : ActionState.icon,
      ScaffoldFromZero.screenSizeLarge: expandedBuilder==null ? ActionState.button : ActionState.expanded,
    };
    if (overflowBuilder==null) overflowBuilder = _defaultOverflowBuilder;
    if (iconBuilder==null) iconBuilder = _defaultIconBuilder;
    if (buttonBuilder==null) buttonBuilder = _defaultButtonBuilder;
  }

  @override
  Widget build(BuildContext context) {
    return icon==null
        ? buttonBuilder(context, title, icon, onTap)
        : iconBuilder(context, title, icon, onTap);
  }

  Widget _defaultIconBuilder(BuildContext context, String title, Widget icon, VoidCallback onTap){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: title,
        icon: icon,
        onPressed: onTap,
      ),
    );
  }

  Widget _defaultButtonBuilder(BuildContext context, String title, Widget icon, VoidCallback onTap){
    return FlatButton(
      onPressed: onTap,
      colorBrightness: Theme.of(context).appBarTheme?.brightness ?? Theme.of(context).primaryColorBrightness,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 6),
          if (icon!=null)
            icon,
          if (icon!=null)
            SizedBox(width: 8,),
          Text(title, style: TextStyle(fontSize: 16),),
          SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _defaultOverflowBuilder(BuildContext context, String title, Widget icon){
    return Text(title);
  }

}


class AppbarFromZero extends StatefulWidget {

//  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget bottom;
  final double elevation;
  final Color shadowColor;
  final ShapeBorder shape;
  final Color backgroundColor;
  final Brightness brightness;
  final IconThemeData iconTheme;
  final IconThemeData actionsIconTheme;
  final TextTheme textTheme;
  final bool primary;
  final bool centerTitle;
  final bool excludeHeaderSemantics;
  final double titleSpacing;
  final double toolbarOpacity;
  final double bottomOpacity;
  final double toolbarHeight;

  AppbarFromZero({
    Key key,
//    this.leading,
    Widget title,
    List<Widget> actions,
    this.bottom,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.actionsIconTheme,
    this.textTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.toolbarHeight,
  }) :
        this.actions = actions ?? [],
        this.title = title,
        super(key: key);

  @override
  _AppbarFromZeroState createState() => _AppbarFromZeroState();

}


class _AppbarFromZeroState extends State<AppbarFromZero> {

  AppbarAction forceExpanded;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (forceExpanded==null){
          return true;
        } else{
          setState(() {
            forceExpanded = null;
          });
          return false;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          List<Widget> actions = [];
          List<AppbarAction> overflows = [];
          List<Widget> expanded = [];
          List<int> removeIndices = [];
          if (forceExpanded!=null){
            ActionState state = ActionState.overflow;
            double biggestKey=-1;
            forceExpanded.breakpoints.forEach((key, value) {
              if (key<constraints.maxWidth && key>biggestKey){
                state = value;
                biggestKey = key;
              }
            });
            if (state==ActionState.expanded)
              forceExpanded = null;
          }
          if(forceExpanded==null){
            actions = List.from(widget.actions);
            for (int i=0; i<actions.length; i++){
              if (actions[i] is AppbarAction){
                AppbarAction action = actions[i] as AppbarAction;
                ActionState state = ActionState.overflow;
                double biggestKey=-1;
                action.breakpoints.forEach((key, value) {
                  if (key<constraints.maxWidth && key>biggestKey){
                    state = value;
                    biggestKey = key;
                  }
                });
                switch (state){
                  case ActionState.overflow:
                    overflows.add(action);
                    removeIndices.add(i);
                    break;
                  case ActionState.icon:
                    actions[i] = action.iconBuilder(context, action.title, action.icon, _getOnTap(action));
                    break;
                  case ActionState.button:
                    actions[i] = action.buttonBuilder(context, action.title, action.icon, _getOnTap(action));
                    break;
                  case ActionState.expanded:
                    expanded.add(action.expandedBuilder(context, action.title, action.icon));
                    removeIndices.add(i);
                    break;
                }
              }
            }
            removeIndices.forEach((element) {actions.removeAt(element);});
            if (overflows.isNotEmpty){
              actions.add(PopupMenuButton<AppbarAction>(
                icon: Icon(Icons.more_vert),
                itemBuilder: (context) => List.generate(overflows.length, (index) => PopupMenuItem(
                  value: overflows[index],
                  child: overflows[index].overflowBuilder(context, overflows[index].title, overflows[index].icon),
                )),
                onSelected: (value) => _getOnTap(value),
              ));
            }
            if (actions.isNotEmpty) actions.add(SizedBox(width: 8,));
          }
          return AppBar(
//          leading: widget.leading,
            title: AnimatedSwitcher(
              duration: 300.milliseconds,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: forceExpanded!=null ? SizedBox.shrink() : widget.title,
            ),
            actions: [
              AnimatedSwitcher(
                duration: 300.milliseconds,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(forceExpanded),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ],
            flexibleSpace: AppBar(
              excludeHeaderSemantics: true,
              automaticallyImplyLeading: false,
              centerTitle: true,
              elevation: widget.elevation,
              backgroundColor: Colors.transparent,
              titleSpacing: 8,
              title: AnimatedSwitcher(
                duration: 300.milliseconds,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  ),
                ),
                child: SizedBox(
                  key: ValueKey(forceExpanded!=null ? forceExpanded : expanded.isEmpty),
                  height: widget.toolbarHeight ?? 56,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: forceExpanded==null ? expanded : [
                      Expanded(
                        child: forceExpanded.expandedBuilder(context, forceExpanded.title, forceExpanded.icon),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            forceExpanded = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            automaticallyImplyLeading: false,
            bottom: widget.bottom,
            elevation: widget.elevation,
            shadowColor: widget.shadowColor,
            shape: widget.shape,
            backgroundColor: widget.backgroundColor,
            brightness: widget.brightness,
            iconTheme: widget.iconTheme,
            actionsIconTheme: widget.actionsIconTheme,
            textTheme: widget.textTheme,
            primary: widget.primary,
            centerTitle: widget.centerTitle,
            excludeHeaderSemantics: widget.excludeHeaderSemantics,
            titleSpacing: widget.titleSpacing,
            toolbarOpacity: widget.toolbarOpacity,
            bottomOpacity: widget.bottomOpacity,
            toolbarHeight: widget.toolbarHeight,
          );
        },
      ),
    );
  }

  VoidCallback _getOnTap (AppbarAction action){
    if (action.onTap==null && action.expandedBuilder!=null){
      return (){
        setState(() {
          forceExpanded = action;
        });
      };
    }
    return action.onTap;
  }

}
