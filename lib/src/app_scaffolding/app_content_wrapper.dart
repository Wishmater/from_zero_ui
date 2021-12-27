import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_host_from_zero.dart';




var fromZeroScreenProvider = ChangeNotifierProvider<ScreenFromZero>((ref) {
  return ScreenFromZero();
});

var fromZeroScaffoldChangeNotifierProvider = ChangeNotifierProvider<ScaffoldFromZeroChangeNotifier>((ref) {
  return ScaffoldFromZeroChangeNotifier();
});

var fromZeroAppbarChangeNotifierProvider = ChangeNotifierProvider<AppbarChangeNotifier>((ref) {
  return AppbarChangeNotifier(0, 0, 0, ScaffoldFromZero.appbarTypeNone, null);
});

var fromZeroThemeParametersProvider = ChangeNotifierProvider<ThemeParametersFromZero>((ref) {
  return ThemeParametersFromZero();
});



/// Put this widget in the builder method of your MaterialApp.
/// Controls different app-wide providers and features needed by other FromZeroWidgets
class FromZeroAppContentWrapper extends ConsumerStatefulWidget {

  final child;

  FromZeroAppContentWrapper({
    this.child,
  });

  @override
  _FromZeroAppContentWrapperState createState() => _FromZeroAppContentWrapperState();

}


ValueNotifier<bool> isMouseOverWindowBar = ValueNotifier(false);
class _FromZeroAppContentWrapperState extends ConsumerState<FromZeroAppContentWrapper> {

  @override
  Widget build(BuildContext context) {
    //TODO 3 add restrictions to fontSize, uiScale logic, etc. here
    final screen = ref.read(fromZeroScreenProvider);
    final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = scaffoldChangeNotifier._previousWidth ?? 1280;
          double screenHeight = scaffoldChangeNotifier._previousHeight ?? 720;
          if (constraints.maxWidth>0){
            screenWidth = constraints.maxWidth;
            screenHeight = constraints.maxHeight;
            if (scaffoldChangeNotifier._previousWidth==null) {
              screen._isMobileLayout = constraints.maxWidth < ScaffoldFromZero.screenSizeMedium;
              if (constraints.maxWidth>=ScaffoldFromZero.screenSizeXLarge){
                screen._breakpoint = ScaffoldFromZero.screenSizeXLarge;
              } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeLarge){
                screen._breakpoint = ScaffoldFromZero.screenSizeLarge;
              } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium){
                screen._breakpoint = ScaffoldFromZero.screenSizeMedium;
              } else{
                screen._breakpoint = ScaffoldFromZero.screenSizeSmall;
              }
              scaffoldChangeNotifier._previousWidth = constraints.maxWidth;
              scaffoldChangeNotifier._previousHeight = constraints.maxHeight;
            } else {
              WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                screen._isMobileLayout = constraints.maxWidth < ScaffoldFromZero.screenSizeMedium;
                if (constraints.maxWidth>=ScaffoldFromZero.screenSizeXLarge){
                  screen.breakpoint = ScaffoldFromZero.screenSizeXLarge;
                } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeLarge){
                  screen.breakpoint = ScaffoldFromZero.screenSizeLarge;
                } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium){
                  screen.breakpoint = ScaffoldFromZero.screenSizeMedium;
                } else{
                  screen.breakpoint = ScaffoldFromZero.screenSizeSmall;
                }
                scaffoldChangeNotifier._updateDrawerWidths(screen.isMobileLayout, constraints.maxWidth);
                scaffoldChangeNotifier._previousWidth = constraints.maxWidth;
                scaffoldChangeNotifier._previousHeight = constraints.maxHeight;
              });
            }
          }
          return OverflowBox(
            alignment: Alignment.center,
            minHeight: 0,
            minWidth: 0,
            maxHeight: double.infinity,
            maxWidth: double.infinity,
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  SnackBarHostFromZero(
                    child: widget.child,
                  ),
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isMouseOverWindowBar,
                      builder: (context, value, child) {
                        return AppearOnMouseOver(
                          appear: !value,
                          child: WindowBar(
                            backgroundColor: Theme.of(context).cardColor,
                            onMaximizeOrRestore: (context) {
                              // hack so the windowBar doesn't get stuck after maximize
                              context.findAncestorStateOfType<_AppearOnMouseOverState>()!.pressed = false;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}




class AppearOnMouseOver extends StatefulWidget {

  final bool appear;
  final Widget child;

  const AppearOnMouseOver({
    required this.child,
    this.appear = true,
    Key? key,
  }) : super(key: key);

  @override
  _AppearOnMouseOverState createState() => _AppearOnMouseOverState();

}
class _AppearOnMouseOverState extends State<AppearOnMouseOver> {

  bool visible = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    bool visible = (this.visible||this.pressed)&&widget.appear;
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        setState(() {
          this.visible = true;
        });
      },
      onExit: (event) {
        if (pressed) {
          this.pressed = false;
        } else {
          setState(() {
            this.visible = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !visible ? null : () => null,
        onSecondaryTap: !visible ? null : () => null,
        onTapDown: !visible ? null : (details) => pressed = true,
        onTapCancel: !visible ? null : () => pressed = false,
        onTapUp: !visible ? null : (details) => pressed = false,
        onPanStart: !visible ? null : (details) => pressed = true,
        onPanCancel: !visible ? null : () => pressed = true,
        onPanEnd: !visible ? null : (details) => pressed = false,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !visible,
            child: widget.child,
          ),
        ),
      ),
    );
  }

}


class WindowBar extends StatelessWidget {

  final double? height;
  final Color? backgroundColor;
  final bool? Function(BuildContext context)? onMinimize;
  final bool? Function(BuildContext context)? onMaximizeOrRestore;
  final bool? Function(BuildContext context)? onClose;

  const WindowBar({
    Key? key,
    this.height,
    this.backgroundColor,
    this.onMinimize,
    this.onMaximizeOrRestore,
    this.onClose,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? (appWindow.isMaximized ? appWindow.titleBarHeight * 0.66 : appWindow.titleBarHeight),
      color: backgroundColor,
      child: MoveWindow(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MinimizeWindowButton(
              animate: true,
              onPressed: () {
                if (onMinimize?.call(context) ?? true) {
                  appWindow.minimize();
                }
              },
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
              onPressed: () {
                if (onMaximizeOrRestore?.call(context) ?? true) {
                  appWindow.maximizeOrRestore();
                }
              },
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
              onPressed: () {
                if (onClose?.call(context) ?? true) {
                  appWindow.close();
                }
              },
              colors: WindowButtonColors(
                mouseOver: Color(0xFFD32F2F),
                mouseDown: Color(0xFFB71C1C),
                iconNormal: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.8),
                iconMouseOver: Colors.white,
                iconMouseDown: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






class ScreenFromZero extends ChangeNotifier{

  late bool _isMobileLayout;
  bool get isMobileLayout => _isMobileLayout;
  set isMobileLayout(bool value) {
    _isMobileLayout = value;
    notifyListeners();
  }

  late double _breakpoint;
  double get breakpoint => _breakpoint;
  set breakpoint(double value) {
    _breakpoint = value;
    notifyListeners();
  }

}


class ScaffoldFromZeroChangeNotifier extends ChangeNotifier{

  final bool drawerOpenByDefaultOnDesktop;

  ScaffoldFromZeroChangeNotifier({
    this.drawerOpenByDefaultOnDesktop = true,
  });

  int _animationType = ScaffoldFromZero.animationTypeOther;
  int get animationType => _animationType;
  set animationType(int value) {
    _animationType = value;
    notifyListeners();
  }



  // DRAWER RELATED STUFF

  final Map<String, ValueNotifier<double>> drawerContentScrollOffsets = {};
  final Map<String, bool> isTreeNodeExpanded = {};

  final Map<String, double> _currentDrawerWidths = {};
  // remember the width of the scaffold for each id.
  // This is kind of awkward because the option is set in the Scaffold widget,
  // but needs to be controlled here globally.
  final Map<String, double> collapsedDrawerWidths = {};
  final Map<String, double> expandedDrawerWidths = {};
  double getCurrentDrawerWidth(String pageScaffoldId) {
    if (!_currentDrawerWidths.containsKey(pageScaffoldId)) {
      _currentDrawerWidths[pageScaffoldId] =
          drawerOpenByDefaultOnDesktop  ? expandedDrawerWidths[pageScaffoldId]!
                                        : collapsedDrawerWidths[pageScaffoldId]!;
      _blockNotify = true;
      _updateDrawerWidths(_previousWidth!<ScaffoldFromZero.screenSizeMedium, _previousWidth!);
      _blockNotify = false;
    }
    return _currentDrawerWidths[pageScaffoldId] ?? 0;
  }
  bool _blockNotify = false;
  setCurrentDrawerWidth(String pageScaffoldId, double value) {
    if (_currentDrawerWidths[pageScaffoldId] != value) {
      _currentDrawerWidths[pageScaffoldId] = value;
      if (!_blockNotify) notifyListeners();
    }
  }
  void collapseDrawer([String? pageScaffoldId]){
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId]!);
  }
  void expandDrawer([String? pageScaffoldId]){
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    setCurrentDrawerWidth(pageScaffoldId, expandedDrawerWidths[pageScaffoldId]!);
  }
  bool get isCurrentDrawerExpanded => isDrawerExpanded();
  bool isDrawerExpanded([String? pageScaffoldId]) {
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    return getCurrentDrawerWidth(pageScaffoldId)==expandedDrawerWidths[pageScaffoldId];
  }

  // Mechanism to automatically expand/collapse drawer in response to screen width changes
  double? _previousWidth;
  double? _previousHeight;
  void _updateDrawerWidths(bool displayMobileLayout, double width){
    for (final e in _currentDrawerWidths.keys) {
      _updateDrawerWidth(e, displayMobileLayout, width);
    }
  }
  void _updateDrawerWidth(String pageScaffoldId, bool displayMobileLayout, double width){
    if (width < ScaffoldFromZero.screenSizeMedium) {
      setCurrentDrawerWidth(pageScaffoldId, 0);
    } else if (_previousWidth!=null && _previousWidth!<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, expandedDrawerWidths[pageScaffoldId]!);
    } else if (_previousWidth!=null && _previousWidth!>=ScaffoldFromZero.screenSizeLarge && width<ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId]!);
    } else if (getCurrentDrawerWidth(pageScaffoldId) < collapsedDrawerWidths[pageScaffoldId]!){
      setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId]!);
    }
  }


  // SCAFFOLD TRANSITION RELATED STUFF

  GoRouterStateFromZero? _currentRouteState;
  GoRouterStateFromZero? get currentRouteState => _currentRouteState;
  GoRouterStateFromZero? _previousRouteState;
  GoRouterStateFromZero? get previousRouteState => _previousRouteState;
  bool fadeAnim = false;
  bool sharedAnim = false;
  bool titleAnimation = false;
  void setCurrentRouteState(GoRouterStateFromZero route) {
    _previousRouteState = currentRouteState;
    _currentRouteState = route;
    updateAnimationTypes();
  }
  void updateAnimationTypes(){
    if (currentRouteState==null || previousRouteState==null || currentRouteState!.pageScaffoldId!=previousRouteState!.pageScaffoldId) {
      _animationType = ScaffoldFromZero.animationTypeOther;
    } else if (currentRouteState!.pageScaffoldDepth > previousRouteState!.pageScaffoldDepth) {
      _animationType = ScaffoldFromZero.animationTypeInner;
    } else if (currentRouteState!.pageScaffoldDepth < previousRouteState!.pageScaffoldDepth) {
      _animationType = ScaffoldFromZero.animationTypeOuter;
    } else {
      _animationType = ScaffoldFromZero.animationTypeSame;
    }
    fadeAnim = animationType==ScaffoldFromZero.animationTypeSame;
    sharedAnim = animationType==ScaffoldFromZero.animationTypeInner || animationType==ScaffoldFromZero.animationTypeOuter;
    titleAnimation = animationType!=ScaffoldFromZero.animationTypeOther;
        // && currentRoute!=null && previousRoute!=null
        // && !(  (currentScaffold.title?.key!=null && previousScaffold.title?.key!=null
        //         && currentScaffold.title?.key==previousScaffold.title?.key)
        //     || (currentScaffold.title is Text && previousScaffold.title is Text
        //         && (currentScaffold.title as Text).data == (previousScaffold.title as Text).data));
              // because of the change to using routes, we lost the ability to compare the titles of the different pages
              // could still be done if the pages put it here, but is messy and not really necessary
  }

}
