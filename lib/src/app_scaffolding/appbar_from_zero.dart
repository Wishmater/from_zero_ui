import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/services.dart';
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
  final double topSafePadding;
  final ActionFromZero? initialExpandedAction;
  final AppbarFromZeroController? controller;
  final void Function(ActionFromZero)? onExpanded;
  final VoidCallback? onUnexpanded;
  /// is main window scaffold appbar
  final bool mainAppbar;
  final double paddingRight;
  final bool addContextMenu;
  final VoidCallback? onShowContextMenu;
  /// sometimes, it's useful to disable flutter AppBar and just use a Row
  /// for title and actions.
  /// Default true.
  /// False does not support a lot of the appBar features.
  /// Used in Table row actions.
  final bool useFlutterAppbar;
  /// only applied if useFlutterAppbar==true
  final bool extendTitleBehindActions;
  final bool skipTraversalForActions;
  final Duration transitionsDuration;
  final BoxConstraints? constraints;
  final double actionPadding;

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
    this.topSafePadding = 0,
    this.initialExpandedAction,
    this.controller,
    this.onExpanded,
    this.onUnexpanded,
    this.mainAppbar = false,
    this.paddingRight = 8,
    this.addContextMenu = true,
    this.onShowContextMenu,
    this.skipTraversalForActions = false,
    this.extendTitleBehindActions = false,
    this.transitionsDuration = const Duration(milliseconds: 300),
    this.constraints,
    this.actionPadding = 4,
  }) :
        this.actions = actions ?? [],
        super(key: key);

  @override
  AppbarFromZeroState createState() => AppbarFromZeroState();

}

class AppbarFromZeroController {

  void Function(ActionFromZero? expanded)? setExpanded;

}

class AppbarFromZeroState extends State<AppbarFromZero> {

  ActionFromZero? forceExpanded;
  late List<Widget> actions; // this is kept so children can check how many actions are currently showing, used in Field

  @override
  void initState() {
    super.initState();
    forceExpanded = widget.initialExpandedAction;
    actions = widget.actions;
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
      child: widget.constraints!=null || widget.actions.isEmpty // assumes LayoutBuilder is needed only for actions
          ? _buildWithConstraints(context, widget.constraints)
          : LayoutBuilder(
            builder: _buildWithConstraints,
          ),
    );
    if (widget.mainAppbar && PlatformExtended.appWindow!=null) {
      result = MouseRegion(
        opaque: false,
        onEnter: (event) {
          isMouseOverWindowBar.value = true;
        },
        onExit: (event) {
          isMouseOverWindowBar.value = false;
        },
        child: MoveWindowFromZero(
          child: result,
        ),
      );
    }
    return result;
  }

  Widget _buildWithConstraints(context, constraints) {
    bool showWindowButtons = widget.mainAppbar && PlatformExtended.appWindow!=null;
    final double titleBarHeight = !showWindowButtons ? 0
        : appWindow.isMaximized ? appWindow.titleBarHeight * 0.66 : appWindow.titleBarHeight;
    double? toolbarHeight = widget.toolbarHeight ?? (widget.useFlutterAppbar
                                                      ? 48 + (showWindowButtons ? titleBarHeight : 0)
                                                      : null);
    actions = [];
    List<ActionFromZero> overflows = [];
    List<ActionFromZero> contextMenuActions = [];
    List<Widget> expanded = [];
    List<int> removeIndices = [];
    if (forceExpanded!=null){
      ActionState state = forceExpanded!.getStateForMaxWidth(constraints.maxWidth);
      if (state==ActionState.expanded)
        forceExpanded = null;
    }
    if (forceExpanded==null) {

      actions = List.from(widget.actions);
      for (int i=0; i<actions.length; i++){
        if (actions[i] is ActionFromZero){
          ActionFromZero action = (actions[i] as ActionFromZero);
          action = action.copyWith(
            onTap: _getOnTap(action),
          );
          ActionState state = action.getStateForMaxWidth(constraints.maxWidth);
          switch (state){
            case ActionState.none:
              removeIndices.add(i);
              break;
            case ActionState.popup:
              contextMenuActions.add(action);
              removeIndices.add(i);
              break;
            case ActionState.overflow:
              overflows.add(action);
              contextMenuActions.add(action);
              removeIndices.add(i);
              break;
            case ActionState.icon:
              actions[i] = action.buildIcon(context);
              if (actions[i] is! VerticalDivider && actions[i] is! Divider) {
                actions[i] = Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.actionPadding),
                  child: actions[i],
                );
              }
              contextMenuActions.add(action);
              break;
            case ActionState.button:
              actions[i] = action.buildButton(context);
              contextMenuActions.add(action);
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
      for (int i=0; i<actions.length; i++) {
        if ((actions[i] is VerticalDivider || actions[i] is Divider)
            && (i==0 || i==actions.lastIndex || actions[i+1] is VerticalDivider || actions[i+1] is Divider)) {
          actions.removeAt(i); i--;
        }
      }
      for (int i=0; i<overflows.length; i++) {
        if (overflows[i].overflowBuilder==ActionFromZero.dividerOverflowBuilder
            && (i==0 || i==overflows.lastIndex || overflows[i+1].overflowBuilder==ActionFromZero.dividerOverflowBuilder)) {
          overflows.removeAt(i); i--;
        }
      }
      if (overflows.isNotEmpty) {
        actions.add(
          ContextMenuIconButton(
            icon: Icon(Icons.more_vert),
            anchorAlignment: Alignment.bottomCenter,
            popupAlignment: Alignment.bottomCenter,
            actions: overflows,
          ),
        );
      }

    }
    final titleContent = AnimatedSwitcher(
      duration: widget.transitionsDuration,
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
    Widget actionsContent = Padding(
      padding: EdgeInsets.only(
        right: widget.paddingRight,
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: EdgeInsets.only(top: showWindowButtons ? titleBarHeight*0.7 : 0),
            child: AnimatedSwitcher(
              duration: widget.transitionsDuration,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...actions,
                  SizedBox(width: showWindowButtons ? 8 : 0,),
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
    if (widget.skipTraversalForActions) {
      actionsContent = FocusScope(
        canRequestFocus: false,
        child: actionsContent,
      );
    }
    final expandedContent = AppBar(
      excludeHeaderSemantics: true,
      automaticallyImplyLeading: false,
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      titleSpacing: 8,
      toolbarHeight: toolbarHeight,
      title: AnimatedSwitcher(
        duration: widget.transitionsDuration,
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
          child: Padding(
            padding: EdgeInsets.only(top: showWindowButtons ? titleBarHeight*0.7 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
    );
    Widget result;
    if (widget.useFlutterAppbar) {
      final statusBarColor = widget.backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;
      Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(statusBarColor);
      statusBarBrightness = statusBarBrightness==Brightness.light ? Brightness.dark : Brightness.light;
      result = AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          systemStatusBarContrastEnforced: true, // TODO 2 conditionally allow transparency in status bar for cool quickReturn appbars, currently disabled because popups break it
          statusBarColor: statusBarColor,
          statusBarIconBrightness: statusBarBrightness, // For Android (dark icons)
          statusBarBrightness: statusBarBrightness, // For iOS (dark icons)
        ),
        // title: titleContent,
        // actions: [actionsContent],
        // flexibleSpace: expandedContent,
        title: Padding(padding: EdgeInsets.only(top: widget.topSafePadding), child: titleContent),
        actions: [Padding(padding: EdgeInsets.only(top: widget.topSafePadding), child: actionsContent)],
        flexibleSpace: Padding(padding: EdgeInsets.only(top: widget.topSafePadding), child: expandedContent),
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
        toolbarHeight: (toolbarHeight??56)+widget.topSafePadding,
      );
    } else {
      Widget content;
      if (widget.extendTitleBehindActions) {
        content = Stack(
          children: [
            titleContent,
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: actionsContent,
            ),
          ],
        );
      } else {
        content = Row(
          children: [
            Expanded(child: titleContent,),
            actionsContent,
          ],
        );
      }
      result = Column(
        children: [
          SizedBox(height: widget.topSafePadding,),
          Stack(
            children: [
              content,
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: forceExpanded==null,
                  child: expandedContent,
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (widget.addContextMenu) {
      result = ContextMenuFromZero(
        onShowMenu: widget.onShowContextMenu,
        actions: contextMenuActions,
        child: result,
      );
    }
    return result;
  }

  void Function(BuildContext context)? _getOnTap (ActionFromZero action){
    if (!action.enabled) {
      return null;
    }
    if (action.onTap==null && action.expandedBuilder!=null && forceExpanded!=action) {
      return (context) {
        setState(() {
          forceExpanded = action;
          widget.onExpanded?.call(action);
        });
      };
    }
    return action.onTap;
  }

}



