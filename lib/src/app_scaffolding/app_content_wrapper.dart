import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';




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


/// Override this for custom logging, including logs from from_zero
void Function(Object? message, {
  Object? stackTrace,
  bool? isError,
}) log = (Object? message, {
  Object? stackTrace,
  bool? isError,
}) {
  isError ??= stackTrace!=null || message is Exception;
  if (!isError) {
    stdout.writeln(message);
    if (stackTrace!=null) stdout.writeln(stackTrace);
  } else {
    stderr.writeln(message);
    if (stackTrace!=null) stderr.writeln(stackTrace);
  }
};


/// Put this widget in the builder method of your MaterialApp.
/// Controls different app-wide providers and features needed by other FromZeroWidgets
class FromZeroAppContentWrapper extends ConsumerStatefulWidget {

  final Widget child;
  final GoRouter goRouter;
  final bool allowDraggingWithMouseDownOnDesktop;

  const FromZeroAppContentWrapper({super.key, 
    required this.child,
    required this.goRouter,
    this.allowDraggingWithMouseDownOnDesktop = !kReleaseMode,
  });

  @override
  FromZeroAppContentWrapperState createState() => FromZeroAppContentWrapperState();

  static bool confirmAppCloseOnMobile = true;
  static bool confirmAppCloseOnDesktop = false;
  static String? appNameForCloseConfirmation;

  static String? windowsProcessName;
  static void exitApp(int code) {
    log('Exiting app with code: $code...');
    if (!kIsWeb && Platform.isWindows) {
      log('Detected platform windows, releaseMode=$kReleaseMode, processName=$windowsProcessName');
      if (kReleaseMode && windowsProcessName!=null) {
        log('Running process: taskkill /IM "$windowsProcessName" /F');
        // this ensures the process is completely killed and doesn't hang in older Windows versions
        final result = Process.runSync('cmd', ['/c', 'taskkill', '/IM', '$windowsProcessName', '/F']);
        log('Finished taskkill process with code: ${result.exitCode}');
        log('   stderr:');
        log(result.stderr);
        log('   stdout:');
        log(result.stdout);
        log("Seems like killing the process didn't work...");
        log('Exiting the normal dart way (debugger(); + exit(0);)...');
        debugger(); exit(0);
      } else {
        _exit(code);
      }
    } else {
      _exit(code);
    }
  }
  static void _exit(int code) {
    log('Exiting the normal dart way (debugger(); + exit(0);)...');
    debugger(); exit(0);
  }

  static Future<Map<String, int>> getWindowsProcessess() async {
    final tasklistProc = Process.runSync('tasklist', ['/NH', '/FO', 'csv']);
    final lines = const LineSplitter().convert(tasklistProc.stdout);
    final pids = <String, int>{};
    for (var line in lines) {
      final elems = line.split(',').map((elem) => elem.replaceAll('"', '')).toList();
      final name = elems[0];
      final pid = int.parse(elems[1]);
//     final session = elems[2];
//     final sessionNumber = int.parse(elems[3]);
//     final memUsage = elems[4];
      pids[name] = pid;
    }
    return pids;
  }

}


ValueNotifier<bool> isMouseOverWindowBar = ValueNotifier(false);
class FromZeroAppContentWrapperState extends ConsumerState<FromZeroAppContentWrapper> {

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      // if (WindowEventListener.listeningCount==0) {
      //   WindowEventListener().listen(() => widget.goRouter);
      // }
      if (WindowEventListenerWindowManagerPackage.listener==null) {
        WindowEventListenerWindowManagerPackage.initListener(() => widget.goRouter);
        windowManager.addListener(WindowEventListenerWindowManagerPackage.listener!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //TODO 3 add restrictions to fontSize, uiScale logic, etc. here
    var mediaQueryData = MediaQuery.of(context);
    // final double scale = mediaQueryData.textScaleFactor.clamp(1, 1.25);
    const double scale = 1;
    // TODO 2 experiment with app ui scale with this approach, it looks promising. Some forms break though
    mediaQueryData = mediaQueryData.copyWith(textScaleFactor: scale,);
    final screen = ref.read(fromZeroScreenProvider);
    final scaffoldChangeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
    bool showWindowButtons = PlatformExtended.appWindow!=null && scaffoldChangeNotifier.showWindowBarOnDesktop;
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
              child: FittedBox(
                child: SizedBox(
                  width: screenWidth / scale,
                  height: screenHeight / scale,
                  child: MediaQuery(
                    data: mediaQueryData,
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
                                      context.findAncestorStateOfType<AppearOnMouseOverState>()!.pressed = false;
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
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
  AppearOnMouseOverState createState() => AppearOnMouseOverState();

}
class AppearOnMouseOverState extends State<AppearOnMouseOver> {

  bool visible = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    bool visible = (this.visible||pressed)&&widget.appear;
    return MouseRegion(
      opaque: false,
      onEnter: (event) {
        setState(() {
          this.visible = true;
        });
      },
      onExit: (event) {
        if (pressed) {
          pressed = false;
        } else {
          setState(() {
            this.visible = false;
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: !visible ? null : () {},
        onSecondaryTap: !visible ? null : () {},
        onTapDown: !visible ? null : (details) => pressed = true,
        onTapCancel: !visible ? null : () => pressed = false,
        onTapUp: !visible ? null : (details) => pressed = false,
        onPanStart: !visible ? null : (details) => pressed = true,
        onPanCancel: !visible ? null : () => pressed = true,
        onPanEnd: !visible ? null : (details) => pressed = false,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
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
  final bool showMinimize;
  final bool showMaximizeOrRestore;
  final bool showClose;
  final bool? Function(BuildContext context)? onMinimize;
  final bool? Function(BuildContext context)? onMaximizeOrRestore;
  final bool? Function(BuildContext context)? onClose;
  final Widget? title;
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
    this.showMinimize = true,
    this.showMaximizeOrRestore = true,
    this.showClose = true,
    this.title,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = iconTheme?.color
        ?? theme.appBarTheme.iconTheme?.color 
        ?? theme.primaryIconTheme.color 
        ?? theme.iconTheme.color
        ?? (theme.brightness==Brightness.light ? Colors.black : Colors.white);
    return Container(
      height: height ?? (PlatformExtended.appWindow==null
          ? 32
          : appWindow.isMaximized ? appWindow.titleBarHeight * 0.66 : appWindow.titleBarHeight),
      color: backgroundColor,
      child: MoveWindowFromZero(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (title!=null)
              Expanded(child: title!,),
            if (PlatformExtended.appWindow!=null && showMinimize)
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
            if (PlatformExtended.appWindow!=null && showMaximizeOrRestore)
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
            if (PlatformExtended.appWindow!=null && showClose)
              CloseWindowButton(
                animate: true,
                onPressed: () async {
                  if (onClose?.call(context) ?? true) {
                    final goRouter = this.goRouter ?? GoRouter.of(context);
                    await smartMultiPop(goRouter);
                  }
                },
                colors: WindowButtonColors(
                  mouseOver: const Color(0xFFD32F2F),
                  mouseDown: const Color(0xFFB71C1C),
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
  static Future<void> smartMultiPop(GoRouter goRouter) async {
    final navigator = goRouter.routerDelegate.navigatorKey.currentState!;
    while (true) {

      final goRoute = goRouter.routerDelegate.currentConfiguration.last.route;
      log ('Trying to pop ${goRouter.routerDelegate.currentConfiguration.last.matchedLocation}');
      if (await navigator.maybePop()) {
        final previousGoRouteFromZero = goRoute is GoRouteFromZero ? goRoute : null;
        final newGoRoute = goRouter.routerDelegate.currentConfiguration.last.route;
        final newGoRouteFromZero = newGoRoute is GoRouteFromZero ? newGoRoute : null;
        if (newGoRoute==goRoute) {
          // if route refused to pop, or popped route was a modal, stop iteration
          log('  Route refused to pop, or popped route was a modal, stopping iteration...');
          return;
        }
        if (previousGoRouteFromZero?.pageScaffoldId!=newGoRouteFromZero?.pageScaffoldId) {
          // if new route is a different scaffold ID, stop iteration
          log('  New route is a different scaffold ID, stopping iteration...');
          return;
        }
      } else {
        // if successfully popped last route, exit app (maybePop only false when popDisposition==bubble)
        log ('  Successfully popped last route, exiting app...');
        FromZeroAppContentWrapper.exitApp(0);
        return;
      }
      log ('  Popped successfully, continuing popping iteration...');

    }
  }
}

class MoveWindowFromZero extends StatefulWidget {

  final Widget? child;
  final VoidCallback? onDoubleTap;

  const MoveWindowFromZero({Key? key, this.child, this.onDoubleTap}) : super(key: key);

  @override
  State<MoveWindowFromZero> createState() => _MoveWindowFromZeroState();

}
class _MoveWindowFromZeroState extends State<MoveWindowFromZero> {

  TapDownDetails? lastTapDownDetails;
  Timer? timer;
  void onTapDown(TapDownDetails details) {
    timer?.cancel();
    if (lastTapDownDetails?.globalPosition==details.globalPosition) {
      (widget.onDoubleTap ?? appWindow.maximizeOrRestore).call();
      lastTapDownDetails = null;
    } else {
      lastTapDownDetails = details;
      timer = Timer(500.milliseconds, () {
        lastTapDownDetails = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
    gestures[TransparentTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TransparentTapGestureRecognizer>(
          () => TransparentTapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
        instance
          .onTapDown = onTapDown;
      },
    );
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: gestures,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          appWindow.startDragging();
        },
        child: widget.child ?? Container(),
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
  final bool showWindowBarOnDesktop;

  ScaffoldFromZeroChangeNotifier({
    this.drawerOpenByDefaultOnDesktop = true,
    this.showWindowBarOnDesktop = true,
  });

  int _animationType = ScaffoldFromZero.animationTypeOther;
  int get animationType => _animationType;
  set animationType(int value) {
    _animationType = value;
    notifyListeners();
  }



  // DRAWER RELATED STUFF

  final Map<String, ValueNotifier<double>> drawerContentScrollOffsets = {};
  final Map<int, bool> isTreeNodeExpanded = {};

  final Map<String, double> _currentDrawerWidths = {};
  // remember the width of the scaffold for each id.
  // This is kind of awkward because the option is set in the Scaffold widget,
  // but needs to be controlled here globally.
  final Map<String, double> collapsedDrawerWidths = {};
  final Map<String, double> expandedDrawerWidths = {};
  double getCurrentDrawerWidth(String pageScaffoldId) {
    if (!_currentDrawerWidths.containsKey(pageScaffoldId)) {
      _currentDrawerWidths[pageScaffoldId] =
          drawerOpenByDefaultOnDesktop  ? expandedDrawerWidths[pageScaffoldId] ?? 304
                                        : collapsedDrawerWidths[pageScaffoldId] ?? 56;
      _blockNotify = true;
      if (_previousWidth!=null) {
        _updateDrawerWidths(_previousWidth!<ScaffoldFromZero.screenSizeMedium, _previousWidth!);
      }
      _blockNotify = false;
    }
    return _currentDrawerWidths[pageScaffoldId] ?? 0;
  }
  bool _blockNotify = false;
  void setCurrentDrawerWidth(String pageScaffoldId, double value) {
    if (_currentDrawerWidths[pageScaffoldId] != value) {
      _currentDrawerWidths[pageScaffoldId] = value;
      if (!_blockNotify) notifyListeners();
    }
  }
  void collapseDrawer([String? pageScaffoldId]){
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId] ?? 56);
  }
  void expandDrawer([String? pageScaffoldId]){
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    setCurrentDrawerWidth(pageScaffoldId, expandedDrawerWidths[pageScaffoldId] ?? 304);
  }
  bool get isCurrentDrawerExpanded => isDrawerExpanded();
  bool isDrawerExpanded([String? pageScaffoldId]) {
    pageScaffoldId ??= currentRouteState!.pageScaffoldId;
    return getCurrentDrawerWidth(pageScaffoldId)==expandedDrawerWidths[pageScaffoldId];
  }

  // Mechanism to automatically expand/collapse drawer in response to screen width changes in desktop
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
    } else if (PlatformExtended.isDesktop && _previousWidth!=null && _previousWidth!<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, expandedDrawerWidths[pageScaffoldId] ?? 304);
    } else if (PlatformExtended.isDesktop && _previousWidth!=null && _previousWidth!>=ScaffoldFromZero.screenSizeLarge && width<ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId] ?? 56);
    } else if (getCurrentDrawerWidth(pageScaffoldId) < (collapsedDrawerWidths[pageScaffoldId] ?? 56)){
      setCurrentDrawerWidth(pageScaffoldId, collapsedDrawerWidths[pageScaffoldId] ?? 56);
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
  bool _isSetCurrentRouteStateLocked = false;
  void setCurrentRouteState(GoRouterStateFromZero route) {
    if (!_isSetCurrentRouteStateLocked) {
      _isSetCurrentRouteStateLocked = true;
      _previousRouteState = currentRouteState;
      _currentRouteState = route;
      updateAnimationTypes();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _isSetCurrentRouteStateLocked = false;
      });
    }
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




class WindowEventListenerWindowManagerPackage with WindowListener {

  GoRouter Function() routerGetter;

  WindowEventListenerWindowManagerPackage._(this.routerGetter);

  static WindowEventListenerWindowManagerPackage? listener;
  static void initListener(GoRouter Function() routerGetter) {
    listener = WindowEventListenerWindowManagerPackage._(routerGetter);
    // listener!.readEventsTxt();
  }

  @override
  void onWindowClose() {
    final goRouter = routerGetter();
    WindowBar.smartMultiPop(goRouter);
  }

  // // as of version 3.2.2, windowed mode is no loger shipped, since bitsdojo seems to work on all PCs
  // void readEventsTxt() async { // we still need to do this once to know if we are running in windowed mode
  //   String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
  //       .replaceAll('%20', ' ');
  //   File file = File(p.join(scriptPath, 'events.txt'));
  //   final bytes8 = await file.readAsBytes();
  //   final bytes = <int>[];
  //   for (int i=0; i<bytes8.length; i+=2) {
  //     bytes.add(bytes8[i]); // hack for utf16 encoding
  //   }
  //   String wholeString = (const Windows1252Codec(allowInvalid: true,)).decode(bytes);
  //   List<String> events = wholeString.split("\r\n")..removeLast();
  //   for (int i = 0; i<events.length; i++){
  //     log ("Window event handled: ${events[i]}");
  //     switch(events[i]){
  //       case 'WM_CLOSE':
  //         final goRouter = routerGetter();
  //         WindowBar.smartMultiPop(goRouter);
  //         break;
  //       case 'WINDOW_INIT_ERROR':
  //         windowsDesktopBitsdojoWorking = false;
  //         break;
  //     }
  //   }
  // }

  // @override
  // void onWindowEvent(String eventName) {
  //   log ("Window event handled: $eventName");
  // }

}




class CloseConfirmDialog extends StatelessWidget {

  final bool? forceExitApp;

  const CloseConfirmDialog({
    Key? key,
    this.forceExitApp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DialogFromZero(
      title: Text("¿Seguro que quiere cerrar ${FromZeroAppContentWrapper.appNameForCloseConfirmation ?? 'la aplicación'}?"), // TODO 3 internationalize
      dialogActions: <Widget>[
        const DialogButton.cancel(),
        DialogButton(
          color: Colors.red,
          onPressed: () {
            if (forceExitApp ?? PlatformExtended.isDesktop) {
              FromZeroAppContentWrapper.exitApp(0);
            }
            Navigator.of(context).pop(true);
          },
          child: const Text("CERRAR"),
        ),
        const SizedBox(width: 6,),
      ],
    );
  }

}
