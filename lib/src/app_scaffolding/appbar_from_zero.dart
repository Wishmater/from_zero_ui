import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:dartx/dartx.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/action_from_zero.dart';
import 'package:from_zero_ui/src/ui_components/context_menu.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:from_zero_ui/src/ui_utility/ui_utility_widgets.dart';



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
  final bool addContextMenu;
  /// sometimes, it's useful to disable flutter AppBar and just use a Row
  /// for title and actions.
  /// Default true.
  /// False does not support a lot of the appBar features.
  /// Used in Table row actions.
  final bool useFlutterAppbar;

  AppbarFromZero({
    Key? key,
//    this.leading,
    this.title = const SizedBox.shrink(),
    List<Widget>? actions,
    this.useFlutterAppbar = true,
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
    this.paddingRight = 8,
    this.addContextMenu = true,
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
          final titleContent = AnimatedSwitcher(
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
          );
          final actionsContent = Padding(
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
                        SizedBox(width: showWindowButtons ? 2 : 0,),
                      ],
                    ),
                  ),
                ),
                if (showWindowButtons)
                  Align(
                    alignment: Alignment.topRight,
                    child: WindowBar(height: titleBarHeight,),
                  ),
              ],
            ),
          );
          final expandedContent = AppBar(
            excludeHeaderSemantics: true,
            automaticallyImplyLeading: false,
            centerTitle: true,
            elevation: widget.elevation,
            backgroundColor: Colors.transparent,
            titleSpacing: 8,
            toolbarHeight: toolbarHeight,
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
          );
          Widget result;
          if (widget.useFlutterAppbar) {
            result = AppBar(
              title: titleContent,
              actions: [actionsContent],
              flexibleSpace: expandedContent,
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
            );
          } else {
            result = SizedBox(
              height: toolbarHeight,
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(child: titleContent,),
                      actionsContent,
                    ],
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: forceExpanded==null,
                      child: expandedContent,
                    ),
                  ),
                ],
              ),
            );
          }
          if (widget.addContextMenu) {
            result = ContextMenuFromZero(
                actions: widget.actions
                .whereType<ActionFromZero>()
                .where((e) => e.getStateForMaxWidth(constraints.maxWidth).shownOnContextMenu)
                .map((e) {
                  return e.copyWith(onTap: _getOnTap(e));
                }).toList(),
              child: result,
            );
          }
          return result;
        },
      ),
    );
    if (showWindowButtons) {
      result = MouseRegion(
        opaque: false,
        onEnter: (event) {
          isMouseOverWindowBar.value = true;
        },
        onExit: (event) {
          isMouseOverWindowBar.value = false;
        },
        child: MoveWindow(
          child: result,
        ),
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



