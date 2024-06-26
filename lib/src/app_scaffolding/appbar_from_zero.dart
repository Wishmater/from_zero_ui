import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


class AppbarFromZero extends StatefulWidget {

//  final Widget leading;
  final Widget title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
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
  final bool mainAppbarShowButtons;
  final double paddingRight;
  final bool addContextMenu;
  final bool contextMenuEnabled;
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
//    this.leading,
    this.title = const SizedBox.shrink(),
    List<Widget>? actions,
    this.useFlutterAppbar = true,
    this.bottom,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.backgroundColor,
    this.surfaceTintColor,
    this.iconTheme,
    this.actionsIconTheme,
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
    this.mainAppbarShowButtons = true,
    this.paddingRight = 8,
    this.addContextMenu = true,
    this.contextMenuEnabled = true,
    this.onShowContextMenu,
    this.skipTraversalForActions = false,
    this.extendTitleBehindActions = false,
    this.transitionsDuration = const Duration(milliseconds: 300),
    this.constraints,
    this.actionPadding = 4,
    super.key,
  }) :
        actions = actions ?? [];

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

  Widget _buildWithConstraints(BuildContext context, BoxConstraints? constraints) {
    bool showWindowButtons = widget.mainAppbar && widget.mainAppbarShowButtons && PlatformExtended.appWindow!=null;
    final double titleBarHeight = !showWindowButtons ? 0
        : appWindow.isMaximized ? appWindow.titleBarHeight * 0.66 : appWindow.titleBarHeight;
    double? toolbarHeight = widget.toolbarHeight
        ?? (widget.useFlutterAppbar
            ? (AppBarTheme.of(context).toolbarHeight??56)-8 + (showWindowButtons ? titleBarHeight : 0)
            : null);
    actions = [];
    final actionsColor = widget.backgroundColor==null
        ? null
        : widget.backgroundColor!.opacity<0.3
            ? Theme.of(context).textTheme.bodyLarge!.color
            : ThemeData.estimateBrightnessForColor(widget.backgroundColor!)==Brightness.light
                ? Colors.black : Colors.white;
    List<ActionFromZero> overflows = [];
    List<ActionFromZero> contextMenuActions = [];
    List<Widget> expanded = [];
    List<int> removeIndices = [];
    if (forceExpanded!=null){
      ActionState state = forceExpanded!.getStateForMaxWidth(constraints!.maxWidth);
      if (state==ActionState.expanded) {
        forceExpanded = null;
      }
    }
    if (forceExpanded==null) {

      actions = List.from(widget.actions);
      for (int i=0; i<actions.length; i++){
        if (actions[i] is ActionFromZero){
          ActionFromZero action = (actions[i] as ActionFromZero);
          action = action.copyWith(
            onTap: _getOnTap(action),
          );
          ActionState state = action.getStateForMaxWidth(constraints!.maxWidth);
          switch (state){
            case ActionState.none:
              removeIndices.add(i);
            case ActionState.popup:
              contextMenuActions.add(action);
              removeIndices.add(i);
            case ActionState.overflow:
              overflows.add(action);
              contextMenuActions.add(action);
              removeIndices.add(i);
            case ActionState.icon:
              actions[i] = action.buildIcon(context, color: actionsColor);
              if (actions[i] is! VerticalDivider && actions[i] is! Divider) {
                actions[i] = Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.actionPadding),
                  child: actions[i],
                );
              }
              contextMenuActions.add(action);
            case ActionState.button:
              actions[i] = action.buildButton(context, color: actionsColor);
              contextMenuActions.add(action);
            case ActionState.expanded:
              if (action.centerExpanded){
                expanded.add(action.buildExpanded(context, color: actionsColor));
                removeIndices.add(i);
              } else{
                actions[i] = action.buildExpanded(context, color: actionsColor);
              }
          }
        }
      }
      for (final element in removeIndices.reversed) {
        actions.removeAt(element);
      }
      if (overflows.length==1 && overflows.first.icon!=null) {
        actions.add(overflows.removeLast().buildIcon(context, color: actionsColor));
      }
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
        final iconButtonColor = Theme.of(context).appBarTheme.toolbarTextStyle?.color
            ?? Theme.of(context).textTheme.bodyLarge!.color!;
        final iconButtonTransparentColor = iconButtonColor.withOpacity(0.05);
        final iconButtonSemiTransparentColor = iconButtonColor.withOpacity(0.1);
        actions.add(
          ContextMenuButton(
            actions: overflows,
            buttonBuilder: (context, onTap) {
              return IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.more_vert),
                color: iconButtonColor,
                hoverColor: iconButtonTransparentColor,
                highlightColor: iconButtonSemiTransparentColor,
                focusColor: iconButtonSemiTransparentColor,
                splashColor: iconButtonSemiTransparentColor,
              );
            },
          ),
        );
      }

    }
    final titleContent = AnimatedSwitcher(
      duration: widget.transitionsDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: Tween<double>(begin: -0.5, end: 1).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: forceExpanded!=null ? const SizedBox.shrink() : widget.title,
    );
    Widget actionsContent = Padding(
      padding: EdgeInsets.only(
        right: widget.paddingRight,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: showWindowButtons ? titleBarHeight*0.7 : 0),
        child: AnimatedSwitcher(
          duration: widget.transitionsDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
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
      surfaceTintColor: Colors.transparent,
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
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
        child: SizedBox(
          key: ValueKey(forceExpanded ?? expanded.isEmpty),
          height: toolbarHeight,
          child: Padding(
            padding: EdgeInsets.only(top: showWindowButtons ? titleBarHeight*0.7 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: forceExpanded==null ? expanded : [
                Expanded(
                  child: forceExpanded!.buildExpanded(context, color: actionsColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
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
          systemStatusBarContrastEnforced: false, // maybe make this optional or circumstantial
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
        surfaceTintColor: widget.surfaceTintColor,
        iconTheme: widget.iconTheme,
        actionsIconTheme: widget.actionsIconTheme,
        primary: widget.primary,
        centerTitle: widget.centerTitle,
        excludeHeaderSemantics: widget.excludeHeaderSemantics,
        titleSpacing: widget.titleSpacing,
        toolbarOpacity: widget.toolbarOpacity,
        bottomOpacity: widget.bottomOpacity,
        toolbarHeight: (toolbarHeight??AppBarTheme.of(context).toolbarHeight??56)+widget.topSafePadding,
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
      content = SizedBox(
        height: toolbarHeight,
        child: content,
      );
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
    // if (showWindowButtons) { // now always built in ScaffoldFromZero, so it takes full width
    //   result = Stack(
    //     children: [
    //       result,
    //       Positioned(
    //         top: 0, left: 0, right: 0,
    //         child: WindowBar(height: titleBarHeight,),
    //       ),
    //     ],
    //   );
    // }
    if (widget.addContextMenu) {
      result = ContextMenuFromZero(
        onShowMenu: widget.onShowContextMenu,
        actions: contextMenuActions,
        enabled: widget.contextMenuEnabled,
        child: result,
      );
    }
    return result;
  }

  void Function(BuildContext context)? _getOnTap (ActionFromZero action){
    final enabled = action.disablingError==null;
    if (!enabled) {
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



