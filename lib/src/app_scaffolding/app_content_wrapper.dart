import 'dart:developer';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_host_from_zero.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;



bool windowsDesktopBitsdojoWorking = true;



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
  final GoRouter goRouter;
  final bool allowDraggingWithMouseDownOnDesktop;

  FromZeroAppContentWrapper({
    required this.child,
    required this.goRouter,
    this.allowDraggingWithMouseDownOnDesktop = !kReleaseMode,
  });

  @override
  _FromZeroAppContentWrapperState createState() => _FromZeroAppContentWrapperState();

}


ValueNotifier<bool> isMouseOverWindowBar = ValueNotifier(false);
class _FromZeroAppContentWrapperState extends ConsumerState<FromZeroAppContentWrapper> {

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows && WindowEventListener.listeningCount==0) {
      WindowEventListener().listen(() => widget.goRouter);
    }
  }

  @override
  Widget build(BuildContext context) {
    //TODO 3 add restrictions to fontSize, uiScale logic, etc. here
    bool showWindowButtons = PlatformExtended.appWindow!=null;
    final screen = ref.read(fromZeroScreenProvider);
    final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
    ScrollBehavior scrollConfiguration = ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
    );
    if (widget.allowDraggingWithMouseDownOnDesktop) {
      scrollConfiguration = scrollConfiguration.copyWith(
        dragDevices: {
          ...PointerDeviceKind.values,
        },
      );
    }
    return ScrollConfiguration(
      behavior: scrollConfiguration,
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
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
                  if (showWindowButtons)
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isMouseOverWindowBar,
                        builder: (context, value, child) {
                          return AppearOnMouseOver(
                            appear: !value,
                            child: WindowBar(
                              backgroundColor: Theme.of(context).cardColor,
                              iconTheme: Theme.of(context).iconTheme,
                              goRouter: widget.goRouter,
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
  final IconThemeData? iconTheme;
  final bool? Function(BuildContext context)? onMinimize;
  final bool? Function(BuildContext context)? onMaximizeOrRestore;
  final bool? Function(BuildContext context)? onClose;
  final GoRouter? goRouter;

  const WindowBar({
    Key? key,
    this.goRouter,
    this.height,
    this.backgroundColor,
    this.onMinimize,
    this.onMaximizeOrRestore,
    this.onClose,
    this.iconTheme,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = this.iconTheme?.color
        ?? theme.appBarTheme.iconTheme?.color 
        ?? theme.primaryIconTheme.color 
        ?? theme.iconTheme.color
        ?? (theme.brightness==Brightness.light ? Colors.black : Colors.white);
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
                mouseOver: iconColor.withOpacity(0.1),
                mouseDown: iconColor.withOpacity(0.2),
                iconNormal: iconColor.withOpacity(0.8),
                iconMouseOver: iconColor,
                iconMouseDown: iconColor,
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
                mouseOver: iconColor.withOpacity(0.1),
                mouseDown: iconColor.withOpacity(0.2),
                iconNormal: iconColor.withOpacity(0.8),
                iconMouseOver: iconColor,
                iconMouseDown: iconColor,
              ),
            ),
            CloseWindowButton(
              animate: true,
              onPressed: () async {
                if (onClose?.call(context) ?? true) {
                  final goRouter = this.goRouter ?? GoRouter.of(context);
                  await smartMultiPop(goRouter);
                }
              },
              colors: WindowButtonColors(
                mouseOver: Color(0xFFD32F2F),
                mouseDown: Color(0xFFB71C1C),
                iconNormal: iconColor.withOpacity(0.8),
                iconMouseOver: Colors.white,
                iconMouseDown: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// used when trying to close the window
  static smartMultiPop(GoRouter goRouter) async {
    final navigator = goRouter.routerDelegate.navigatorKey.currentState!;
    while (true) {

      final goRoute = goRouter.routerDelegate.matches.last.route;
      print ('Trying to pop ${goRouter.routerDelegate.matches.last.subloc}');
      if (await navigator.maybePop()) {
        final previousGoRouteFromZero = goRoute is GoRouteFromZero ? goRoute : null;
        final newGoRoute = goRouter.routerDelegate.matches.last.route;
        final newGoRouteFromZero = newGoRoute is GoRouteFromZero ? newGoRoute : null;
        if (newGoRoute==goRoute) {
          // if route refused to pop, or popped route was a modal, stop iteration
          print('  Route refused to pop, or popped route was a modal, stopping iteration...');
          return;
        }
        if (previousGoRouteFromZero?.pageScaffoldId!=newGoRouteFromZero?.pageScaffoldId) {
          // if new route is a different scaffold ID, stop iteration
          print('  New route is a different scaffold ID, stopping iteration...');
          return;
        }
      } else {
        // if successfully popped last route, exit app (maybePop only false when popDisposition==bubble)
        print ('  Successfully popped last route, exiting app...');
        debugger();
        exit(0);
      }
      print ('  Popped successfully, continuing popping iteration...');

    }
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
  void _updateDrawerWidths(bool isMobileLayout, double width){
    for (final e in _currentDrawerWidths.keys) {
      _updateDrawerWidth(e, isMobileLayout, width);
    }
  }
  void _updateDrawerWidth(String pageScaffoldId, bool isMobileLayout, double width){
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



class WindowEventListener{

  static int listeningCount = 0;

  int currentIndex = 0;

  listen(GoRouter Function() routerGetter) async {
    String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
        .replaceAll('%20', ' ');
    File file = File(p.join(scriptPath, 'events.txt'));
    listeningCount++;
    while(true){
      try{
        // String wholeString = await file.readAsString(); // encoding: Encoding.
        // final bytes = await file.readAsBytes();
        final bytes8 = await file.readAsBytes();
        final bytes = <int>[];
        for (int i=0; i<bytes8.length; i+=2) {
          bytes.add(bytes8[i]); // hack for utf16 encoding
        }
        // String wholeString = Utf16leBytesToCodeUnitsDecoder(bytes).decodeRest();
        String wholeString = (const Windows1252Codec(allowInvalid: true,)).decode(bytes);
        // String wholeString = (const Latin16Decoder(allowInvalid: true,)).convert(bytes);
        // String wholeString = utf8.decode(bytes, allowMalformed: true);
        // String wholeString = String.fromCharCodes(bytes);
        List<String> events = wholeString.split("\r\n")..removeLast();
        // print('String: $wholeString');print(events);
        for (int i = currentIndex; i<events.length; i++){
          print ("Window event handled: ${events[i]}");
          switch(events[i]){
            case 'WM_CLOSE':
              final goRouter = routerGetter();
              WindowBar.smartMultiPop(goRouter);
              break;
            case 'WINDOW_INIT_ERROR':
              windowsDesktopBitsdojoWorking = false;
              break;
          }
        }
        currentIndex = events.length;
      } catch (_){}
      await Future.delayed(Duration(milliseconds: 50));
    }
    listeningCount--;
  }

}

