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
import 'package:hive/hive.dart';
import 'package:mlog/mlog.dart';
import 'package:window_manager/window_manager.dart';




bool windowsDesktopBitsdojoWorking = true;



var fromZeroScreenProvider = ChangeNotifierProvider<ScreenFromZero>((ref) {
  return ScreenFromZero();
});

var fromZeroScaffoldChangeNotifierProvider = ChangeNotifierProvider<ScaffoldFromZeroChangeNotifier>((ref) {
  return ScaffoldFromZeroChangeNotifier();
});

var fromZeroAppbarChangeNotifierProvider = ChangeNotifierProvider<AppbarChangeNotifier>((ref) {
  return AppbarChangeNotifier(0, 0, 0, AppbarType.none, null);
});

var fromZeroThemeParametersProvider = ChangeNotifierProvider<ThemeParametersFromZero>((ref) {
  return ThemeParametersFromZero();
});


/// Override this for custom logging, including logs from from_zero
void Function(LgLvl level, Object? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  int extraTraceLineOffset,
  FlutterErrorDetails? details,
}) log = defaultLog;

void defaultLog(LgLvl level, Object? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  int extraTraceLineOffset = 0,
  FlutterErrorDetails? details,
}) {
  final message = defaultLogGetString(level, msg,
    type: type,
    e: e,
    st: st,
    extraTraceLineOffset: extraTraceLineOffset,
    details: details,
  );
  if (message!=null) {
    print (message); //ignore: avoid_print
  }
}

String? defaultLogGetString(LgLvl level, Object? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  int extraTraceLineOffset = 0,
  FlutterErrorDetails? details,
}) {
  String? message = LogOptions.instance.builder.messageBuilder(level, msg,
    type: type,
    e: e,
    st: st,
    extraTraceLineOffset: extraTraceLineOffset,
  );
  if (message==null) return null;
  if (details!=null) {
    message = addFlutterDetailsToMlog(message, details);
  }
  return message;
}

String addFlutterDetailsToMlog(String msg, FlutterErrorDetails details) {
  String detailsString = '\n${TextTreeRenderer(
    wrapWidthProperties: 100,
    maxDescendentsTruncatableNode: 5,
  ).render(details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error)).trimRight()}';
  detailsString = detailsString.splitMapJoin('\n', onNonMatch: (e) {
    return '    $e';
  },);
  if (msg.length<=3) return detailsString;
  return msg.substring(0, msg.length-2) + detailsString + msg.substring(msg.length-2);
}

enum FzLgType {
  routing('fzRouting', '[FZ_ROUTING]'),
  appUpdate('fzAppUpdate', ' [FZ_APP_UPDATE] '),
  dao('fzDao', ' [FZ_DAO] ');

  final String name;
  final String print;
  const FzLgType(this.name, this.print);

  @override
  String toString() => print;

  /// Dado un string [s] devuelve un [FzLgType] opcional
  static FzLgType fromString(String s) {
    for (final type in FzLgType.values) {
      if (type.name == s) {
        return type;
      }
    }
    throw ArgumentError("String not matching", "s");
  }
}


/// Put this widget in the builder method of your MaterialApp.
/// Controls different app-wide providers and features needed by other FromZeroWidgets
class FromZeroAppContentWrapper extends ConsumerStatefulWidget {

  final Widget child;
  final GoRouter goRouter;
  final bool allowDraggingWithMouseDownOnDesktop;

  const FromZeroAppContentWrapper({
    required this.child,
    required this.goRouter,
    this.allowDraggingWithMouseDownOnDesktop = !kReleaseMode,
    super.key,
  });

  @override
  FromZeroAppContentWrapperState createState() => FromZeroAppContentWrapperState();

  static bool confirmAppCloseOnMobile = true;
  static bool confirmAppCloseOnDesktop = false;
  static String? appNameForCloseConfirmation;

  static String? windowsProcessName;
  static void exitApp(int code) {
    log(LgLvl.info, 'Exiting app with code: $code...', type: FzLgType.routing);
    if (!kIsWeb && Platform.isWindows) {
      log(LgLvl.fine, 'Detected platform windows, releaseMode=$kReleaseMode, processName=$windowsProcessName', type: FzLgType.routing);
      if (kReleaseMode && windowsProcessName!=null) {
        log(LgLvl.fine, 'Running process: taskkill /IM "$windowsProcessName" /F', type: FzLgType.routing);
        // this ensures the process is completely killed and doesn't hang in older Windows versions
        final result = Process.runSync('cmd', ['/c', 'taskkill', '/IM', '$windowsProcessName', '/F']);
        log(LgLvl.error, 'Finished taskkill process with code: ${result.exitCode}\n   stderr:\n${result.stderr}\n   stdout:\n${result.stdout}', type: FzLgType.routing);
        log(LgLvl.error, "Seems like killing the process didn't work...", type: FzLgType.routing);
        log(LgLvl.error, 'Exiting the normal dart way (debugger(); + exit(0);)...', type: FzLgType.routing);
        debugger(); exit(0);
      } else {
        _exit(code);
      }
    } else {
      _exit(code);
    }
  }
  static void _exit(int code) {
    log(LgLvl.fine, 'Exiting the normal dart way (debugger(); + exit(0);)...', type: FzLgType.routing);
    debugger(); exit(0);
  }

  static Future<Map<String, int>> getWindowsProcessess() async {
    final tasklistProc = Process.runSync('tasklist', ['/NH', '/FO', 'csv']);
    final lines = const LineSplitter().convert(tasklistProc.stdout);
    final pids = <String, int>{};
    for (final line in lines) {
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
    var mediaQueryData = MediaQuery.of(context);
    final double scale = ref.watch(fromZeroScreenProvider.select((v) => v.scale)) ?? mediaQueryData.textScaleFactor;
    final extraScale = (scale - 1).clamp(0, 0.5); // assumes scale ranges 1 to 2
    final textScale = 1 + (extraScale * 0.3);
    final uiScale = 1 - (extraScale * 0.7);
    mediaQueryData = mediaQueryData.copyWith(
      textScaleFactor: textScale,
      size: mediaQueryData.size * uiScale,
    );
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
          double screenWidth = scaffoldChangeNotifier.previousWidth ?? 1280;
          double screenHeight = scaffoldChangeNotifier.previousHeight ?? 720;
          if (constraints.maxWidth>0){
            screenWidth = constraints.maxWidth;
            screenHeight = constraints.maxHeight;
            if (scaffoldChangeNotifier.previousWidth==null) {
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
              scaffoldChangeNotifier.previousWidth = constraints.maxWidth;
              scaffoldChangeNotifier.previousHeight = constraints.maxHeight;
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
                scaffoldChangeNotifier.validateDrawerWidths(screen.isMobileLayout, constraints.maxWidth);
                scaffoldChangeNotifier.previousWidth = constraints.maxWidth;
                scaffoldChangeNotifier.previousHeight = constraints.maxHeight;
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
                  width: screenWidth * uiScale,
                  height: screenHeight * uiScale,
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
    super.key,
  });

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

  static String? logoImageAssetsPath;

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context); // listen to resize, to difference maximized
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title!=null)
              title!,
            if (title==null && (logoImageAssetsPath!=null || FromZeroAppContentWrapper.appNameForCloseConfirmation!=null))
              const SizedBox(width: 9,),
            if (title==null && logoImageAssetsPath!=null)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: SizedBox(
                    width: 14, height: 14,
                    child: Image.asset(logoImageAssetsPath!,),
                  ),
                ),
              ),
            if (title==null && logoImageAssetsPath!=null && FromZeroAppContentWrapper.appNameForCloseConfirmation!=null)
              const SizedBox(width: 7,),
            if (title==null && FromZeroAppContentWrapper.appNameForCloseConfirmation!=null)
              IgnorePointer(
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(FromZeroAppContentWrapper.appNameForCloseConfirmation!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            Expanded(child: Container()),
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
    try {
      final navigator = goRouter.routerDelegate.navigatorKey.currentState!;
      while (true) {

        final goRoute = goRouter.routerDelegate.currentConfiguration.last.route;
        log (LgLvl.fine, 'Trying to pop ${goRouter.routerDelegate.currentConfiguration.last.matchedLocation}', type: FzLgType.routing);
        if (await navigator.maybePop()) {
          final previousGoRouteFromZero = goRoute is GoRouteFromZero ? goRoute : null;
          final newGoRoute = goRouter.routerDelegate.currentConfiguration.last.route;
          final newGoRouteFromZero = newGoRoute is GoRouteFromZero ? newGoRoute : null;
          if (newGoRoute==goRoute) {
            // if route refused to pop, or popped route was a modal, stop iteration
            log(LgLvl.finer, 'Route refused to pop, or popped route was a modal, stopping iteration...', type: FzLgType.routing);
            return;
          }
          if (previousGoRouteFromZero?.pageScaffoldId!=newGoRouteFromZero?.pageScaffoldId) {
            // if new route is a different scaffold ID, stop iteration
            log(LgLvl.finer, 'New route is a different scaffold ID, stopping iteration...', type: FzLgType.routing);
            return;
          }
        } else {
          // if successfully popped last route, exit app (maybePop only false when popDisposition==bubble)
          log (LgLvl.finer, 'Successfully popped last route, exiting app...', type: FzLgType.routing);
          FromZeroAppContentWrapper.exitApp(0);
          return;
        }
        log (LgLvl.finer, 'Popped successfully, continuing popping iteration...', type: FzLgType.routing);

      }
    } catch (e, st) {
      log (LgLvl.error, 'Error while processing smartMultiPop, defaulting to exiting app...',
        e: e,
        st: st,
        type: FzLgType.routing,
      );
      FromZeroAppContentWrapper.exitApp(0);
    }
  }
}

class MoveWindowFromZero extends StatefulWidget {

  final Widget? child;
  final VoidCallback? onDoubleTap;

  const MoveWindowFromZero({
    this.child,
    this.onDoubleTap,
    super.key,
  });

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

  double? _scale = Hive.box('settings').get('ui_scale');
  double? get scale => _scale;
  set scale(double? value) {
    _scale = value;
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

  ScaffoldTypeAnimation _animationType = ScaffoldTypeAnimation.other;
  ScaffoldTypeAnimation get animationType => _animationType;
  set animationType(ScaffoldTypeAnimation value) {
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
      blockNotify = true;
      if (previousWidth!=null) {
        validateDrawerWidths(previousWidth!<ScaffoldFromZero.screenSizeMedium, previousWidth!);
      }
      blockNotify = false;
    }
    return _currentDrawerWidths[pageScaffoldId] ?? 0;
  }
  bool blockNotify = false;
  void setCurrentDrawerWidth(String pageScaffoldId, double value) {
    if (_currentDrawerWidths[pageScaffoldId] != value) {
      _currentDrawerWidths[pageScaffoldId] = value;
      if (!blockNotify) notifyListeners();
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
  double? previousWidth;
  double? previousHeight;
  void validateDrawerWidths(bool isMobileLayout, double width){
    for (final e in _currentDrawerWidths.keys) {
      validateDrawerWidth(e, isMobileLayout, width);
    }
  }
  void validateDrawerWidth(String pageScaffoldId, bool isMobileLayout, double width){
    final collapsed = collapsedDrawerWidths[pageScaffoldId] ?? 56;
    final expanded = expandedDrawerWidths[pageScaffoldId] ?? 304;
    if (width < ScaffoldFromZero.screenSizeMedium) {
      setCurrentDrawerWidth(pageScaffoldId, 0);
    } else if (PlatformExtended.isDesktop && previousWidth!=null && previousWidth!<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, expanded);
    } else if (PlatformExtended.isDesktop && previousWidth!=null && previousWidth!>=ScaffoldFromZero.screenSizeLarge && width<ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(pageScaffoldId, collapsed);
    } else {
      final currentWidth = getCurrentDrawerWidth(pageScaffoldId);
      if (currentWidth < collapsed){
        setCurrentDrawerWidth(pageScaffoldId, collapsed);
      } else if (currentWidth > expanded){
        setCurrentDrawerWidth(pageScaffoldId, expanded);
      } else if (currentWidth > collapsed && currentWidth < expanded) {
        if (currentWidth > ((expanded-collapsed)/2)) {
          setCurrentDrawerWidth(pageScaffoldId, expanded);
        } else {
          setCurrentDrawerWidth(pageScaffoldId, collapsed);
        }
      }
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
      _animationType = ScaffoldTypeAnimation.other;
    } else if (currentRouteState!.pageScaffoldDepth > previousRouteState!.pageScaffoldDepth) {
      _animationType = ScaffoldTypeAnimation.inner;
    } else if (currentRouteState!.pageScaffoldDepth < previousRouteState!.pageScaffoldDepth) {
      _animationType = ScaffoldTypeAnimation.outer;
    } else {
      _animationType = ScaffoldTypeAnimation.same;
    }
    fadeAnim = animationType==ScaffoldTypeAnimation.same;
    sharedAnim = animationType==ScaffoldTypeAnimation.inner || animationType==ScaffoldTypeAnimation.outer;
    titleAnimation = animationType!=ScaffoldTypeAnimation.other;
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
    this.forceExitApp,
    super.key,
  });

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
