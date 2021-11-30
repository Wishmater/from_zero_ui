import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/src/ui_components/context_menu.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';


enum ActionState {
  none,
  popup,
  overflow,
  icon,
  button,
  expanded,
}
extension ActionStateExtension on ActionState {
  bool get shownOnPrimaryToolbar => this==ActionState.icon || this==ActionState.button || this==ActionState.expanded;
  bool get shownOnOverflowMenu => this==ActionState.overflow;
  bool get shownOnContextMenu => this==ActionState.icon || this==ActionState.button || this==ActionState.expanded || this==ActionState.overflow || this==ActionState.popup;
}

typedef void ContextCallback(BuildContext context);
typedef Widget ActionBuilder({
  required BuildContext context,
  required String title,
  Widget? icon,
  ContextCallback? onTap,
  bool enabled,
});

class ActionFromZero extends StatelessWidget{ // TODO 2 separate this into its own file

  /// callback called when icon/button/overflowMenuItem is clicked
  /// if null and expandedWidget!= null, will switch expanded
  final void Function(BuildContext context)? onTap;
  final String title;
  final Widget? icon;
  final bool enabled;

  /// from each breakpoint up, the selected widget will be used
  /// defaults to overflow
  final Map<double, ActionState> breakpoints;

  /// optional callbacks to customize the look of the widget in its different states
  final ActionBuilder overflowBuilder;
  Widget buildOverflow(BuildContext context) => overflowBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled,);

  final ActionBuilder iconBuilder;
  Widget buildIcon(BuildContext context) => iconBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled,);

  final ActionBuilder buttonBuilder;
  Widget buildButton(BuildContext context) => buttonBuilder(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled,);

  final ActionBuilder? expandedBuilder;
  Widget buildExpanded(BuildContext context) => expandedBuilder!(context: context, title: title, icon: icon, onTap: onTap, enabled: enabled,);
  final bool centerExpanded;

  ActionFromZero({
    this.onTap,
    required this.title,
    this.icon,
    this.enabled = true,
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = defaultOverflowBuilder,
    this.iconBuilder = defaultIconBuilder,
    this.buttonBuilder = defaultButtonBuilder,
    this.expandedBuilder,
    this.centerExpanded = true,
  }) : this.breakpoints = breakpoints ?? {
    0: icon==null ? ActionState.overflow : ActionState.icon,
    ScaffoldFromZero.screenSizeLarge: expandedBuilder==null ? ActionState.button : ActionState.expanded,
  };

  ActionFromZero.divider({
    Map<double, ActionState>? breakpoints,
    this.overflowBuilder = dividerOverflowBuilder,
    this.iconBuilder = dividerIconBuilder,
    this.buttonBuilder = dividerIconBuilder,
  }) :  title = '',
        icon = null,
        onTap = null,
        expandedBuilder = null,
        centerExpanded = true,
        enabled = true,
        this.breakpoints = breakpoints ?? {
          0: ActionState.overflow,
          ScaffoldFromZero.screenSizeLarge: ActionState.icon,
        };

  ActionFromZero copyWith({
    void Function(BuildContext context)? onTap,
    String? title,
    Widget? icon,
    Map<double, ActionState>? breakpoints,
    ActionBuilder? overflowBuilder,
    ActionBuilder? iconBuilder,
    ActionBuilder? buttonBuilder,
    ActionBuilder? expandedBuilder,
    bool? centerExpanded,
    bool? enabled,
  }) {
    return ActionFromZero(
      onTap: onTap ?? this.onTap,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      breakpoints: breakpoints ?? this.breakpoints,
      overflowBuilder: overflowBuilder ?? this.overflowBuilder,
      iconBuilder: iconBuilder ?? this.iconBuilder,
      buttonBuilder: buttonBuilder ?? this.buttonBuilder,
      expandedBuilder: expandedBuilder ?? this.expandedBuilder,
      centerExpanded: centerExpanded ?? this.centerExpanded,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildButton(context);
  }

  ActionState getStateForMaxWidth(double width) {
    ActionState state = ActionState.overflow;
    double biggestKey=-1;
    breakpoints.forEach((key, value) {
      if (key<width && key>biggestKey){
        state = value;
        biggestKey = key;
      }
    });
    return state;
  }

  static Widget defaultIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: title,
        icon: icon ?? SizedBox.shrink(),
        onPressed: !enabled ? null : (){
          onTap?.call(context);
        },
      ),
    );
  }

  static Widget defaultButtonBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
  }) {
    return TextButton(
      style: TextButton.styleFrom(
        primary: Theme.of(context).appBarTheme.toolbarTextStyle?.color
            ?? (Theme.of(context).primaryColorBrightness==Brightness.light ? Colors.black : Colors.white),
        padding: EdgeInsets.zero,
      ),
      onPressed: !enabled ? null : (){
        onTap?.call(context);
      },
      onLongPress: () => null,
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

  static Widget defaultOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
  }) {
    return TextButton(
      onPressed: !enabled ? null : () => onTap?.call(context),
      style: TextButton.styleFrom(
        primary: Theme.of(context).textTheme.bodyText1!.color,
        padding: EdgeInsets.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon!=null) SizedBox(width: 12,),
            if (icon!=null) IconTheme(data: Theme.of(context).iconTheme.copyWith(color: Theme.of(context).brightness==Brightness.light ? Colors.black45 : Colors.white), child: icon,),
            SizedBox(width: 12,),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(title, style: TextStyle(fontSize: 16),),
              ),
            ),
            SizedBox(width: 12,),
          ],
        ),
      ),
    );
  }

  static Widget dividerIconBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
  }) {
    return VerticalDivider();
  }

  static Widget dividerOverflowBuilder({
    required BuildContext context,
    required String title,
    Widget? icon,
    ContextCallback? onTap,
    bool enabled = true,
  }) {
    return Divider();
  }

}






class AppbarFromZero extends StatefulWidget {

//  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final Brightness? brightness;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final TextTheme? textTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double toolbarOpacity;
  final double bottomOpacity;
  final double? toolbarHeight;
  final ActionFromZero? initialExpandedAction;
  final AppbarFromZeroController? controller;
  final void Function(ActionFromZero)? onExpanded;
  final VoidCallback? onUnexpanded;
  /// is main window scaffold appbar
  final bool mainAppbar;
  final double paddingRight;

  AppbarFromZero({
    Key? key,
//    this.leading,
    this.title = const SizedBox.shrink(),
    List<Widget>? actions,
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
    this.initialExpandedAction,
    this.controller,
    this.onExpanded,
    this.onUnexpanded,
    this.mainAppbar = false,
    this.paddingRight = 0,
  }) :
        this.actions = actions ?? [],
        super(key: key);

  @override
  _AppbarFromZeroState createState() => _AppbarFromZeroState();

}

class AppbarFromZeroController {

  void Function(ActionFromZero? expanded)? setExpanded;

}

class _AppbarFromZeroState extends State<AppbarFromZero> {

  ActionFromZero? forceExpanded;

  @override
  void initState() {
    super.initState();
    forceExpanded = widget.initialExpandedAction;
    widget.controller?.setExpanded = (newExpanded){
      setState(() {
        forceExpanded = newExpanded;
        if (newExpanded==null){
          widget.onUnexpanded?.call();
        } else{
          widget.onExpanded?.call(newExpanded);
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    bool showWindowButtons = widget.mainAppbar && PlatformExtended.isWindows;
    final double titleBarHeight = !showWindowButtons ? 0
        : appWindow.isMaximized ? appWindow.titleBarHeight * 0.66 : appWindow.titleBarHeight;
    double toolbarHeight = widget.toolbarHeight ?? (48 + (showWindowButtons ? titleBarHeight : 0));
    Widget result = WillPopScope(
      onWillPop: () async {
        if (forceExpanded==null){
          return true;
        } else{
          setState(() {
            forceExpanded = null;
            widget.onUnexpanded?.call();
          });
          return false;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          List<Widget> actions = [];
          List<ActionFromZero> overflows = [];
          List<Widget> expanded = [];
          List<int> removeIndices = [];
          if (forceExpanded!=null){
            ActionState state = forceExpanded!.getStateForMaxWidth(constraints.maxWidth);
            if (state==ActionState.expanded)
              forceExpanded = null;
          }
          if (forceExpanded==null){
            actions = List.from(widget.actions);
            for (int i=0; i<actions.length; i++){
              if (actions[i] is ActionFromZero){
                ActionFromZero action = actions[i] as ActionFromZero;
                ActionState state = action.getStateForMaxWidth(constraints.maxWidth);
                switch (state){
                  case ActionState.none:
                  case ActionState.popup:
                    removeIndices.add(i);
                    break;
                  case ActionState.overflow:
                    overflows.add(action);
                    removeIndices.add(i);
                    break;
                  case ActionState.icon:
                    actions[i] = action.buildIcon(context);
                    break;
                  case ActionState.button:
                    actions[i] = action.buildButton(context);
                    break;
                  case ActionState.expanded:
                    if (action.centerExpanded){
                      expanded.add(action.buildExpanded(context));
                      removeIndices.add(i);
                    } else{
                      actions[i] = action.buildExpanded(context);
                    }
                    break;
                }
              }
            }
            removeIndices.reversed.forEach((element) {actions.removeAt(element);});
            if (overflows.isNotEmpty) {
              actions.add(
                ContextMenuIconButton(
                  icon: Icon(Icons.more_vert),
                  anchorAlignment: Alignment.bottomCenter,
                  popupAlignment: Alignment.bottomCenter,
                  actions: overflows.map((e) => e.copyWith(onTap: (context) => _getOnTap(e)?.call(context),)).toList(),
                ),
              );
            }
          }
          return ContextMenuFromZero(
            actions: widget.actions
                .whereType<ActionFromZero>()
                .where((e) => e.getStateForMaxWidth(constraints.maxWidth).shownOnContextMenu)
                .map((e) {
                    return e.copyWith(onTap: _getOnTap(e));
                }).toList(),
            child: AppBar(
//          leading: widget.leading,
              title: AnimatedSwitcher(
                duration: 300.milliseconds,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: Tween<double>(begin: -0.5, end: 1).animate(animation),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: forceExpanded!=null ? SizedBox.shrink() : widget.title,
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(
                    right: widget.paddingRight,
                  ),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: showWindowButtons ? titleBarHeight*0.7 : 0),
                        child: AnimatedSwitcher(
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
                            children: [
                              ...actions,
                              SizedBox(width: (8 - widget.paddingRight).clamp(2, double.infinity),),
                            ],
                          ),
                        ),
                      ),
                      if (widget.mainAppbar && PlatformExtended.isWindows)
                        Align(
                          alignment: Alignment.topRight,
                          child: SizedBox(
                            height: titleBarHeight,
                            child: Row(
                              children: [
                                MinimizeWindowButton(
                                  animate: true,
                                  colors: WindowButtonColors(
                                    mouseOver: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.1),
                                    mouseDown: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.2),
                                    iconNormal: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                                    iconMouseOver: Theme.of(context).textTheme.bodyText1!.color!,
                                    iconMouseDown: Theme.of(context).textTheme.bodyText1!.color!,
                                  ),
                                ),
                                WindowButton(
                                  animate: true,
                                  iconBuilder: (buttonContext) => appWindow.isMaximized
                                      ? RestoreIcon(color: buttonContext.iconColor)
                                      : MaximizeIcon(color: buttonContext.iconColor),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => appWindow.maximizeOrRestore(),
                                  colors: WindowButtonColors(
                                    mouseOver: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.1),
                                    mouseDown: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.2),
                                    iconNormal: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                                    iconMouseOver: Theme.of(context).textTheme.bodyText1!.color!,
                                    iconMouseDown: Theme.of(context).textTheme.bodyText1!.color!,
                                  ),
                                ),
                                CloseWindowButton(
                                  animate: true,
                                  colors: WindowButtonColors(
                                    mouseOver: Color(0xFFD32F2F),
                                    mouseDown: Color(0xFFB71C1C),
                                    iconNormal: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                                    iconMouseOver: Colors.white,
                                    iconMouseDown: Colors.white,
                                  ),
                                ),
                                // SizedBox(width: 6,)
                                // TODO if scrollbar over appbar, add 12 padding right + 6 if windowed
                              ],
                            ),
                          ),
                        ),
                    ],
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
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                  child: SizedBox(
                    key: ValueKey(forceExpanded!=null ? forceExpanded : expanded.isEmpty),
                    height: toolbarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: forceExpanded==null ? expanded : [
                        Expanded(
                          child: forceExpanded!.buildExpanded(context),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              forceExpanded = null;
                              widget.onUnexpanded?.call();
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
              toolbarHeight: toolbarHeight,
            ),
          );
        },
      ),
    );
    if (showWindowButtons) {
      result = MoveWindow(
        child: result,
      );
    }
    return result;
  }

  void Function(BuildContext context)? _getOnTap (ActionFromZero action){
    if (!action.enabled) {
      return null;
    }
    if (action.onTap==null && action.expandedBuilder!=null){
      return (context){
        setState(() {
          forceExpanded = action;
          widget.onExpanded?.call(action);
        });
      };
    }
    return action.onTap;
  }

}
