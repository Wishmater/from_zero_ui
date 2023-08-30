
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/action_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/app_content_wrapper.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/ui_utility/custom_painters.dart';
import 'package:from_zero_ui/src/app_scaffolding/scrollbar_from_zero.dart';

import 'package:from_zero_ui/util/no_fading_transitions/no_fading_shared_axis_transition.dart' as no_fading_shared_axis_transition;
import 'package:dartx/dartx.dart';


typedef Widget DrawerContentBuilder(BuildContext context, bool compact,);

typedef Widget ScaffoldFromZeroTransitionBuilder ({
  required Widget child,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required ScaffoldFromZeroChangeNotifier scaffoldChangeNotifier,
});

class ScaffoldFromZero extends ConsumerStatefulWidget {


  static const double screenSizeSmall = 0;
  static const double screenSizeMedium = 612;
  static const double screenSizeLarge = 848;
  static const double screenSizeXLarge = 1280;
  static const List<double> sizes = [screenSizeSmall, screenSizeMedium, screenSizeLarge, screenSizeXLarge];
  static const int animationTypeSame = 5000;
  static const int animationTypeOther = 5001;
  static const int animationTypeInner = 5002;
  static const int animationTypeOuter = 5003;
  static const int appbarTypeNone = 6003;
  static const int appbarTypeStatic = 6000;
  static const int appbarTypeCollapse = 6001;
  static const int appbarTypeQuickReturn = 6002;
  static const int scrollbarTypeNone = 7001;
  static const int scrollbarTypeBellowAppbar = 7002;
  static const int scrollbarTypeOverAppbar = 7003;

  final Duration drawerAnimationDuration = 300.milliseconds; //TODO 3- allow customization of durations and curves of appbar and drawer animations (fix conflicts)
  final drawerAnimationCurve = Curves.easeOutCubic;
  final Duration appbarAnimationDuration = 300.milliseconds;
  final appbarAnimationCurve = Curves.easeOutCubic;

  final Widget? title;
  final double titleSpacing;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final ActionFromZero? initialExpandedAction;
  final double appbarHeight;
  final double appbarElevation;
  final int appbarType;
  final AppbarFromZeroController? appbarController;
  final void Function(ActionFromZero)? onAppbarActionExpanded;
  final VoidCallback? onAppbarActionUnexpanded;
  final ScrollController? mainScrollController;
  final int scrollbarType;
  final double collapsibleBackgroundHeight;
  final Color? collapsibleBackgroundColor;
  final Widget body;
  final bool bodyFloatsBelowAppbar;
  final Widget? floatingActionButton;
  final double drawerWidth;
  final double compactDrawerWidth;
  final DrawerContentBuilder? drawerContentBuilder;
  final DrawerContentBuilder? drawerFooterBuilder;
  final Widget? drawerTitle;
  final bool centerDrawerTitle;
  final double drawerElevation;
  final double drawerAppbarElevation;
  final TransitionBuilder? drawerBackground;
  final bool useCompactDrawerInsteadOfClose;
  final WidgetBuilder? bottomNavigationBarBuilder;
  final double bottomNavigationBarBreakpoint; // onlyShown when screen is smaller than this breakpoint
  final bool constraintBodyOnXLargeScreens;
  final bool centerTitle;
  final double drawerPaddingTop;
  final bool addFooterDivisions;
  final bool applyHeroToDrawerTitle;
  final bool rememberDrawerScrollOffset;
  final bool alwaysShowHamburgerButtonOnMobile;
  final ScaffoldFromZeroTransitionBuilder titleTransitionBuilder;
  final ScaffoldFromZeroTransitionBuilder drawerContentTransitionBuilder;
  final ScaffoldFromZeroTransitionBuilder bodyTransitionBuilder;
  final bool appbarAddContextMenu;
  final bool isPrimaryScaffold; // don't show windowBar if false


  ScaffoldFromZero({
    required this.body,
    this.title,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
    this.drawerContentBuilder,
    this.drawerFooterBuilder,
    this.drawerTitle,
    this.useCompactDrawerInsteadOfClose = true,
    this.constraintBodyOnXLargeScreens = true,
    double? appbarHeight,
    this.appbarType = appbarTypeStatic,
    this.appbarController,
    this.onAppbarActionExpanded,
    this.onAppbarActionUnexpanded,
    this.mainScrollController,
    double? collapsibleBackgroundLength,
    this.collapsibleBackgroundColor,
    int? scrollbarType,
    bool? bodyFloatsBelowAppbar,
    double? compactDrawerWidth,
    double? drawerWidth,
    this.drawerElevation = 2,
    this.appbarElevation = 3,
    this.drawerBackground,
    this.drawerAppbarElevation = 3,
    this.centerTitle = false,
    this.drawerPaddingTop = 6,
    this.initialExpandedAction,
    this.titleSpacing = 8,
    this.addFooterDivisions = true,
    this.applyHeroToDrawerTitle = true,
    this.rememberDrawerScrollOffset = true,
    this.alwaysShowHamburgerButtonOnMobile = false,
    this.bottomNavigationBarBuilder,
    this.bottomNavigationBarBreakpoint = screenSizeMedium, // mobile only
    this.centerDrawerTitle = false,
    this.appbarAddContextMenu = true,
    this.isPrimaryScaffold = true,
    ScaffoldFromZeroTransitionBuilder? titleTransitionBuilder,
    ScaffoldFromZeroTransitionBuilder? drawerContentTransitionBuilder,
    ScaffoldFromZeroTransitionBuilder? bodyTransitionBuilder,
  }) :
        // this.appbarType = appbarType ?? (title==null&&(actions==null||actions.isEmpty)&&drawerContentBuilder==null ? appbarTypeNone : appbarTypeStatic),
        this.drawerWidth = drawerWidth ?? (drawerContentBuilder==null ? 0 : 304),
        this.collapsibleBackgroundHeight = collapsibleBackgroundLength ?? (appbarType==ScaffoldFromZero.appbarTypeStatic||appbarHeight==null ? -1 : appbarHeight*4),
        this.scrollbarType = scrollbarType ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? scrollbarTypeBellowAppbar : scrollbarTypeOverAppbar),
        this.bodyFloatsBelowAppbar = bodyFloatsBelowAppbar ?? appbarType==ScaffoldFromZero.appbarTypeQuickReturn,
        this.compactDrawerWidth = drawerContentBuilder==null||!useCompactDrawerInsteadOfClose ? 0 : 56,
        this.appbarHeight = appbarHeight ?? (appbarType==ScaffoldFromZero.appbarTypeNone ? 0 : (48 + (PlatformExtended.appWindow?.titleBarHeight??8))), //useCompactDrawerInsteadOfClose ? 56 : 0
        this.titleTransitionBuilder = titleTransitionBuilder ?? defaultTitleTransitionBuilder,
        this.drawerContentTransitionBuilder = drawerContentTransitionBuilder ?? defaultDrawerContentTransitionBuilder,
        this.bodyTransitionBuilder = bodyTransitionBuilder ?? defaultBodyTransitionBuilder;

  @override
  ScaffoldFromZeroState createState() => ScaffoldFromZeroState();

  static Widget defaultTitleTransitionBuilder({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required ScaffoldFromZeroChangeNotifier scaffoldChangeNotifier,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: Tween<double>(begin: 64.0, end: 0.0)
                  .evaluate(CurvedAnimation( curve: Curves.easeInQuad,
                  parent: scaffoldChangeNotifier.titleAnimation ? animation : kAlwaysCompleteAnimation),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation( curve: Curves.easeOutCubic,
                  parent: scaffoldChangeNotifier.titleAnimation ? animation : kAlwaysCompleteAnimation,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation( curve: Curves.easeOutCubic,
                    parent: scaffoldChangeNotifier.titleAnimation ? animation : kAlwaysCompleteAnimation,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: secondaryAnimation,
                      child: child,
                      builder: (context, child) {
                        return ScaleTransition(
                          scale: CurvedAnimation( curve: Curves.easeOutCubic,
                            parent: scaffoldChangeNotifier.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                          ),
                          alignment: Alignment.topLeft,
                          child: FadeTransition(
                            opacity: CurvedAnimation( curve: Curves.easeOutCubic,
                              parent: scaffoldChangeNotifier.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                            ),
                            child: child,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget defaultDrawerContentTransitionBuilder({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required ScaffoldFromZeroChangeNotifier scaffoldChangeNotifier,
  }) {
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return FadeTransition(
              opacity: scaffoldChangeNotifier.sharedAnim
                  ? Tween<double>(begin: 1, end: -1.5).animate(secondaryAnimation)
                  : kAlwaysCompleteAnimation,
              child: FadeUpwardsSlideTransition(
                routeAnimation: scaffoldChangeNotifier.sharedAnim
                    ? animation : kAlwaysCompleteAnimation,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }

  static Widget defaultBodyTransitionBuilder({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required ScaffoldFromZeroChangeNotifier scaffoldChangeNotifier,
    bool upwards = true,
  }) {
    return AnimatedBuilder(
      child: child,
      animation: animation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: secondaryAnimation,
          child: child,
          builder: (context, child) {
            if (secondaryAnimation.value>0.9) return Opacity(opacity: 0, child: child,);
            if (scaffoldChangeNotifier.sharedAnim) {
              var sharedSecondaryAnimation = secondaryAnimation;
              var sharedAnimation = animation;
              if (secondaryAnimation.status == AnimationStatus.reverse
                  || animation.status == AnimationStatus.reverse) {
                sharedSecondaryAnimation = ReverseAnimation(animation);
                sharedAnimation = ReverseAnimation(secondaryAnimation);
              }
              return no_fading_shared_axis_transition.SharedAxisTransition(
                animation: scaffoldChangeNotifier.animationType==ScaffoldFromZero.animationTypeOuter
                    ? ReverseAnimation(sharedSecondaryAnimation) : sharedAnimation,
                secondaryAnimation: scaffoldChangeNotifier.animationType==ScaffoldFromZero.animationTypeOuter
                    ? ReverseAnimation(sharedAnimation).isCompleted ? kAlwaysDismissedAnimation : ReverseAnimation(sharedAnimation)
                    : sharedSecondaryAnimation.isCompleted ? kAlwaysDismissedAnimation : sharedSecondaryAnimation,
                child: child!,
                transitionType: no_fading_shared_axis_transition.SharedAxisTransitionType.scaled,
                fillColor: Colors.transparent,
              );
            } else if (scaffoldChangeNotifier.fadeAnim) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: ReverseAnimation(secondaryAnimation),
                  curve: Interval(0.33, 1, curve: Curves.easeInCubic),
                ),
                child: FadeUpwardsSlideTransition(
                  routeAnimation: animation,
                  child: child!,
                  upwards: upwards,
                ),
              );
              // return FadeThroughTransition(
              //   animation: animation,
              //   secondaryAnimation: secondaryAnimation.isCompleted ? kAlwaysDismissedAnimation : secondaryAnimation,
              //   child: child,
              //   fillColor: Colors.transparent,
              // );
            } else {
              return child!;
            }
          },
        );
      },
    );
  }

}

class ScaffoldFromZeroState extends ConsumerState<ScaffoldFromZero> {

  AppbarChangeNotifier? appbarChangeNotifier;
  late ScrollController drawerContentScrollController;
  late bool canPop;
  final GlobalKey bodyGlobalKey = GlobalKey();
  final GlobalKey drawerGlobalKey = GlobalKey();
  final GlobalKey appbarGlobalKey = GlobalKey();


  bool lockListenToDrawerScroll = false;
  GoRouterStateFromZero? route;
  late ScaffoldFromZeroChangeNotifier _changeNotifier;
  @override
  void initState() {
    super.initState();
    _changeNotifier = ref.read(fromZeroScaffoldChangeNotifierProvider);
    route = context.findAncestorStateOfType<OnlyOnActiveBuilderState>()?.state;
    _changeNotifier.expandedDrawerWidths[pageScaffoldId] = widget.drawerWidth;
    _changeNotifier.collapsedDrawerWidths[pageScaffoldId] = widget.compactDrawerWidth;
    widget.mainScrollController?.addListener(_handleScroll);
    if (route!=null && widget.rememberDrawerScrollOffset) {
      if (_changeNotifier.drawerContentScrollOffsets[pageScaffoldId]==null){
        _changeNotifier.drawerContentScrollOffsets[pageScaffoldId] = ValueNotifier(0);
      }
      _changeNotifier.drawerContentScrollOffsets[pageScaffoldId]?.addListener(_onDrawerScrollOffsetChanged);
    }
  }

  void _onDrawerScroll() {
    if (mounted && drawerContentScrollController.hasClients){
      lockListenToDrawerScroll = true;
      _changeNotifier.drawerContentScrollOffsets[pageScaffoldId]?.value = drawerContentScrollController.position.pixels;
    }
  }
  void _onDrawerScrollOffsetChanged() {
    if (!lockListenToDrawerScroll && mounted && drawerContentScrollController.hasClients){
      drawerContentScrollController.jumpTo(_changeNotifier.drawerContentScrollOffsets[pageScaffoldId]?.value ?? 0);
      lockListenToDrawerScroll = false;
    }
  }
  
  String get pageScaffoldId {
    if (route!=null) {
      return route!.pageScaffoldId;
    } else {
      return 'temp';
    }
  }

  @override
  void didUpdateWidget(ScaffoldFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mainScrollController!=oldWidget.mainScrollController) {
      oldWidget.mainScrollController?.removeListener(_handleScroll);
      if (widget.mainScrollController!=null) {
        widget.mainScrollController?.addListener(_handleScroll);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _handleScroll();
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _changeNotifier.drawerContentScrollOffsets[pageScaffoldId]?.removeListener(_onDrawerScrollOffsetChanged);
    widget.mainScrollController?.removeListener(_handleScroll);
  }

  void _handleScroll() {
    appbarChangeNotifier!.handleMainScrollerControllerCall(widget.mainScrollController!);
  }


  @override
  Widget build(BuildContext context) {
    if (appbarChangeNotifier==null){
      appbarChangeNotifier = AppbarChangeNotifier(
        widget.appbarHeight,
        MediaQuery.of(context).padding.top,
        widget.collapsibleBackgroundHeight,
        widget.appbarType,
        null,
      );
      canPop = ModalRoute.of(context)?.canPop ?? Navigator.of(context).canPop();
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: MediaQuery.of(context).padding.copyWith(top: 0)),
      child: ProviderScope(
        overrides: [
          fromZeroAppbarChangeNotifierProvider.overrideWithProvider(ChangeNotifierProvider<AppbarChangeNotifier>((ref) {
            return appbarChangeNotifier!;
          })),
        ],
        child: FadeUpwardsFadeTransition(
          routeAnimation: ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
          child: FadeUpwardsSlideTransition(
            routeAnimation: ref.read(fromZeroScaffoldChangeNotifierProvider).animationType==ScaffoldFromZero.animationTypeOther
                ? (ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation)
                : kAlwaysCompleteAnimation,
            child: Consumer(
              builder: (context, ref, child) {
                final isMobileLayout = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout));
                return Scaffold(
                  backgroundColor: widget.backgroundColor,
                  floatingActionButton: Consumer(
                    builder: (context, ref, child) {
                      final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
                      Widget result = LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedPadding(
                            padding: EdgeInsets.only(
                              bottom: isMobileLayout ? 0 : 12,
                              right: isMobileLayout ? 0
                                  : 12 + ((constraints.maxWidth-changeNotifier.getCurrentDrawerWidth(pageScaffoldId)-ScaffoldFromZero.screenSizeXLarge)/2).coerceIn(0),
                            ),
                            duration: widget.drawerAnimationDuration,
                            curve: widget.drawerAnimationCurve,
                            child: widget.floatingActionButton,
                          );
                        },
                      );
                      if (!canPop && (PlatformExtended.isDesktop
                          ? FromZeroAppContentWrapper.confirmAppCloseOnDesktop
                          : FromZeroAppContentWrapper.confirmAppCloseOnMobile)) {
                        result = WillPopScope(
                          onWillPop: () async {
                            try {
                              final scaffold = Scaffold.of(context); // this context needs to be below the scaffold
                              if (scaffold.isDrawerOpen || scaffold.isEndDrawerOpen) {
                                return Future.value(true);
                              }
                            } catch(_) {}
                            return ((await showModalFromZero<bool?>(context: context, builder: (context) => CloseConfirmDialog(),)) ?? false);
                          },
                          child: result,
                        );
                      }
                      return result;
                    },
                  ),
                  drawer: isMobileLayout && widget.drawerContentBuilder!=null ? Container(
                    width: widget.drawerWidth,
                    child: Drawer(
                      child: _getResponsiveDrawerContent(context),
                      elevation: widget.drawerElevation*5,
                    ),
                  ) : null,
                  body: child!,
                );
              },
              child: _getMainLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getMainLayout(context) {
    Widget result = Consumer(
      builder: (context, ref, child) {
        final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
        final screen = ref.watch(fromZeroScreenProvider);
        return Stack(
          fit: StackFit.passthrough,
          children: [

            // COLLAPSIBLE BACKGROUND
            Consumer(
              builder: (context, ref, child) {
                final appbarChangeNotifier = ref.watch(fromZeroAppbarChangeNotifierProvider);
                return AnimatedPositioned(
                  duration: widget.appbarAnimationDuration,
                  curve: widget.appbarAnimationCurve,
                  top: appbarChangeNotifier.currentBackgroundOffset,
                  height: appbarChangeNotifier.safeAreaOffset+appbarChangeNotifier.backgroundHeight,
                  left: 0, right: 0,
                  child: child!,
                );
              },
              child: Container(
                color: (widget.collapsibleBackgroundColor ?? Theme.of(context).primaryColorDark),
              ),
            ),

            //BACKGROUND STRIPE TO PREVENT APPBAR TEARING WHEN CLOSE/OPEN DRAWER
            Consumer(
              builder: (context, ref, child) {
                final appbarChangeNotifier = ref.watch(fromZeroAppbarChangeNotifierProvider);
                return AnimatedContainer(
                  duration: widget.appbarAnimationDuration,
                  curve: widget.appbarAnimationCurve,
                  height: appbarChangeNotifier.currentAppbarHeight,
                  color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
                );
              },
            ),

            //APPBAR + BODY
            AnimatedPositioned(
              duration: widget.drawerAnimationDuration,
              curve: widget.drawerAnimationCurve,
              left: changeNotifier.getCurrentDrawerWidth(pageScaffoldId),
              right: 0, top: 0, bottom: 0,
              child: _getBody(context),
            ),

            // CUSTOM SHADOWS (drawer right)
            Consumer(
              builder: (context, ref, child) {
                final appbarChangeNotifier = ref.watch(fromZeroAppbarChangeNotifierProvider);
                if (!screen.isMobileLayout && widget.drawerContentBuilder!=null){
                  return AnimatedContainer(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight, left: changeNotifier.getCurrentDrawerWidth(pageScaffoldId)),
                    duration: widget.drawerAnimationDuration,
                    curve: widget.drawerAnimationCurve,
                    child: SizedBox(
                      width: widget.drawerElevation,
                      height: double.infinity,
                      child: const CustomPaint(
                        painter: const SimpleShadowPainter(direction: SimpleShadowPainter.right, shadowOpacity: 0.45),
                      ),
                    ),
                  );
                } else{
                  return SizedBox.shrink();
                }
              },
            ),

            //DESKTOP DRAWER
            Container(
              child: screen.isMobileLayout || widget.drawerContentBuilder==null ? Container()
                  : widget.useCompactDrawerInsteadOfClose
                    ? AnimatedContainer(
                      duration: widget.drawerAnimationDuration,
                      curve: widget.drawerAnimationCurve,
                      width: changeNotifier.getCurrentDrawerWidth(pageScaffoldId),
                      child: _getResponsiveDrawerContent(context),
                    )
                    : AnimatedPositioned(
                      duration: widget.drawerAnimationDuration,
                      curve: widget.drawerAnimationCurve,
                      left: changeNotifier.getCurrentDrawerWidth(pageScaffoldId)-widget.drawerWidth,
                      width: widget.drawerWidth,
                      top: 0, bottom: 0,
                      child: _getResponsiveDrawerContent(context),
                    ),
            ),

            //DESKTOP DRAWER OPEN GESTURE DETECTOR
            screen.isMobileLayout || widget.drawerContentBuilder==null || PlatformExtended.isDesktop // this should be if no mouse, instead of platform based
                ? Positioned(top: 0, bottom: 0, width: 0, child: Container(),)
                : Positioned(
                  top: 0, bottom: 0, left: 0, width: changeNotifier.getCurrentDrawerWidth(pageScaffoldId)+18,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
                    onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
                    behavior: HitTestBehavior.translucent,
                    excludeFromSemantics: true,
                  ),
                ),
          ],
        );
      },
    );
    return result;
  }

  Widget _getBody (BuildContext context){
    var changeNotifierNotListen = ref.read(fromZeroScaffoldChangeNotifierProvider);
    Widget body = Align(
      alignment: Alignment.topCenter,
      child: Container(
        alignment: Alignment.topCenter,
        width: widget.constraintBodyOnXLargeScreens ? ScaffoldFromZero.screenSizeXLarge : double.infinity,
        child: widget.bodyTransitionBuilder(
          child: NotificationListener(
            key: bodyGlobalKey,
            child: widget.body,
            onNotification: (notification) {
              if (notification is ScrollMetricsNotification) {
                return notification.metrics.axis==Axis.horizontal;
              }
              if (notification is ScrollNotification) {
                return notification.metrics.axis==Axis.horizontal;
              }
              return false;
            },
          ),
          animation: ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
          secondaryAnimation: ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation,
          scaffoldChangeNotifier: changeNotifierNotListen,
        ),
      ),
    );
    if (widget.scrollbarType==ScaffoldFromZero.scrollbarTypeBellowAppbar) {
      body = ScrollbarFromZero(
        applyOpacityGradientToChildren: false,
        ignoreDevicePadding: false,
        mainScrollbar: true,
        controller: widget.mainScrollController,
        child: body,
      );
    }
    if (widget.isPrimaryScaffold && widget.appbarType==ScaffoldFromZero.appbarTypeNone
        && changeNotifierNotListen.showWindowBarOnDesktop && !kIsWeb
        && Platform.isWindows && windowsDesktopBitsdojoWorking) {
      body = Column(
        children: [
          WindowBar(backgroundColor: Theme.of(context).cardColor,),
          Expanded(child: body),
        ],
      );
    }
    Widget result = Consumer(
      builder: (context, ref, child) {
        final appbarChangeNotifier = ref.watch(fromZeroAppbarChangeNotifierProvider);
        return Stack(
          children: <Widget>[

            // show correct color on mobile status bar when no appbar
            if (widget.appbarType == ScaffoldFromZero.appbarTypeNone)
              Positioned(
                top: 0, left: 0, right: 0,
                height: appbarChangeNotifier.safeAreaOffset,
                child: Builder(
                  builder: (context) {
                    final statusBarColor = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;
                    Brightness statusBarBrightness = ThemeData.estimateBrightnessForColor(statusBarColor);
                    statusBarBrightness = statusBarBrightness==Brightness.light ? Brightness.dark : Brightness.light;
                    return AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle(
                        systemStatusBarContrastEnforced: true, // TODO 2 conditionally allow transparency in status bar for cool quickReturn appbars, currently disabled because popups break it
                        statusBarColor: statusBarColor,
                        statusBarIconBrightness: statusBarBrightness, // For Android (dark icons)
                        statusBarBrightness: statusBarBrightness, // For iOS (dark icons)
                      ),
                      child: ColoredBox(color: statusBarColor,),
                    );
                  }
                ),
              ),

            //BODY
            AnimatedPadding(
              duration: widget.appbarAnimationDuration,
              curve: widget.appbarAnimationCurve,
              padding: EdgeInsets.only(top: widget.bodyFloatsBelowAppbar ? 0 : appbarChangeNotifier.currentAppbarHeight,),
              child: body,
            ),

            // CUSTOM SHADOWS (appbar)
            if (widget.appbarType != ScaffoldFromZero.appbarTypeNone)
              AnimatedContainer(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight,),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.appbarElevation,
                  child: const CustomPaint(
                    painter: const SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.6),
                  ),
                ),
              ),

            // APPBAR
            if (widget.appbarType != ScaffoldFromZero.appbarTypeNone)
              AnimatedPositioned(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                top: appbarChangeNotifier.currentAppbarOffset,
                height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                left: 0, right: 0,
                child: Stack(
                  children: [
                    Positioned.fill(child: AbsorbPointer()),
                    AppbarFromZero(
                      key: appbarGlobalKey,
                      mainAppbar: widget.isPrimaryScaffold && changeNotifierNotListen.showWindowBarOnDesktop,
                      controller: widget.appbarController,
                      onExpanded: widget.onAppbarActionExpanded,
                      onUnexpanded: widget.onAppbarActionUnexpanded,
                      backgroundColor: (Theme.of(context).appBarTheme.backgroundColor??Theme.of(context).primaryColor).withOpacity(0.9),
                      elevation: 0,
                      titleSpacing: 0,
                      centerTitle: widget.centerTitle,
                      actions: widget.actions,
                      initialExpandedAction: widget.initialExpandedAction,
                      toolbarHeight: widget.appbarHeight,
                      topSafePadding: appbarChangeNotifier.safeAreaOffset,
                      addContextMenu: widget.appbarAddContextMenu,
                      paddingRight: widget.scrollbarType!=ScaffoldFromZero.scrollbarTypeOverAppbar ? 0
                          : (Theme.of(context).scrollbarTheme.thickness?.resolve({}) ?? 8)
                              + (Theme.of(context).scrollbarTheme.crossAxisMargin ?? 0)
                                  .clamp((PlatformExtended.appWindow?.isMaximized??true) ? 0 : 6, double.infinity),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[

                          SizedBox(width: 8,),

                          //DRAWER HAMBURGER BUTTON (only if not using compact style)
                          Consumer(
                            builder: (context, ref, child) {
                              final isMobileLayout = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout));
                              if ((widget.useCompactDrawerInsteadOfClose && widget.drawerContentBuilder!=null && !isMobileLayout)
                                  || (!canPop && widget.drawerContentBuilder==null)) {
                                return SizedBox(width: 4+widget.titleSpacing,);
                              } else{
                                Widget result;
                                if (canPop&&(widget.drawerContentBuilder==null||(!widget.alwaysShowHamburgerButtonOnMobile&&isMobileLayout))){
                                  final onPressed = () async{
                                    var navigator = Navigator.of(context);
                                    if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                                      navigator.pop();
                                    }
                                  };
                                  final iconButtonColor = Theme.of(context).appBarTheme.toolbarTextStyle?.color
                                      ?? (Theme.of(context).textTheme.bodyLarge!.color!);
                                  final iconButtonTransparentColor = iconButtonColor.withOpacity(0.05);
                                  final iconButtonSemiTransparentColor = iconButtonColor.withOpacity(0.1);
                                  result = TooltipFromZero(
                                    message: FromZeroLocalizations.of(context).translate("back"),
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_back),
                                      color: iconButtonColor,
                                      hoverColor: iconButtonTransparentColor,
                                      highlightColor: iconButtonSemiTransparentColor,
                                      focusColor: iconButtonSemiTransparentColor,
                                      splashColor: iconButtonSemiTransparentColor,
                                      onPressed: onPressed,
                                    ),
                                  );
                                } else{
                                  final iconButtonColor = Theme.of(context).appBarTheme.toolbarTextStyle?.color
                                      ?? (Theme.of(context).textTheme.bodyLarge!.color!);
                                  final iconButtonTransparentColor = iconButtonColor.withOpacity(0.05);
                                  final iconButtonSemiTransparentColor = iconButtonColor.withOpacity(0.1);
                                  result = AnimatedBuilder(
                                    animation: ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation,
                                    builder: (context, child) => TooltipFromZero(
                                      message: FromZeroLocalizations.of(context).translate("menu_open"),
                                      child: IconButton(
                                        color: iconButtonColor,
                                        hoverColor: iconButtonTransparentColor,
                                        highlightColor: iconButtonSemiTransparentColor,
                                        focusColor: iconButtonSemiTransparentColor,
                                        splashColor: iconButtonSemiTransparentColor,
                                        onPressed: () => _toggleDrawer(context, changeNotifierNotListen),
                                        icon: AnimatedIcon(
                                          progress: widget.alwaysShowHamburgerButtonOnMobile
                                              ? kAlwaysDismissedAnimation
                                              : (ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation),
                                          icon: AnimatedIcons.menu_arrow,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                if (widget.useCompactDrawerInsteadOfClose){
                                  result = Container(
                                    width: 48+widget.titleSpacing,
                                    height: widget.appbarHeight,
                                    alignment: Alignment.centerLeft,
                                    child: result,
                                  );
                                } else{
                                  result = Consumer(
                                      child: result,
                                      builder: (context, ref, child) {
                                        final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
                                        double currentWidth = changeNotifier.getCurrentDrawerWidth(pageScaffoldId);
                                        final breakSpace = (56-4-widget.titleSpacing);
                                        return  IgnorePointer(
                                          ignoring: currentWidth>breakSpace,
                                          child: ExcludeFocus(
                                            excluding: currentWidth>breakSpace,
                                            child: Focus(
                                              child: AnimatedOpacity(
                                                opacity: 1-currentWidth/breakSpace<0 ? 0 : 1-currentWidth/breakSpace,
                                                duration: widget.drawerAnimationDuration,
                                                curve: widget.drawerAnimationCurve,
                                                child: AnimatedContainer(
                                                  width: currentWidth>breakSpace ? 4+widget.titleSpacing : 56-currentWidth,
                                                  height: widget.appbarHeight,
                                                  duration: widget.drawerAnimationDuration,
                                                  curve: Curves.easeOutCubic,
                                                  alignment: Alignment.centerLeft,
                                                  child: child,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                  );
                                }
                                return result;
                              }
                            },
                          ),

                          //TITLE
                          widget.title==null ? SizedBox.shrink()
                              : Expanded(
                            child: Container(
                              height: widget.appbarHeight,
                              alignment: Alignment.centerLeft,
                              child: widget.titleTransitionBuilder(
                                child: widget.title!,
                                animation: ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
                                secondaryAnimation: ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation,
                                scaffoldChangeNotifier: changeNotifierNotListen,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),

          ],
        );
      },
    );
    if (widget.scrollbarType==ScaffoldFromZero.scrollbarTypeOverAppbar) {
      result = ScrollbarFromZero(
        controller: widget.mainScrollController,
        ignoreDevicePadding: false,
        mainScrollbar: true,
        applyOpacityGradientToChildren: false,
        child: result,
      );
    }
    if (widget.bottomNavigationBarBuilder!=null) {
      result = Column(
        children: [
          Expanded(child: result),
          Consumer(
            builder: (context, ref, child) {
              if (ref.watch(fromZeroScreenProvider.select((value) => value.breakpoint<widget.bottomNavigationBarBreakpoint))) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    widget.bottomNavigationBarBuilder!(context),
                    Positioned(
                      left: 0, right: 0,
                      top: -widget.appbarElevation*0.7,
                      height: widget.appbarElevation*0.7,
                      child: const CustomPaint(
                        painter: const SimpleShadowPainter(direction: SimpleShadowPainter.up, shadowOpacity: 0.4),
                      ),
                    ),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      );
    }
    return result;
  }

  _getResponsiveDrawerContent(BuildContext context){
    return Consumer(
      builder: (context, ref, child) {
        final appbarChangeNotifier = ref.read(fromZeroAppbarChangeNotifierProvider);
        final changeNotifierNotListen = ref.read(fromZeroScaffoldChangeNotifierProvider); // ! this used to be watch, might bring problems with drawer
        drawerContentScrollController = ScrollController(
          initialScrollOffset: widget.rememberDrawerScrollOffset
              ? _changeNotifier.drawerContentScrollOffsets[pageScaffoldId]?.value ?? 0
              : 0,
        );
        drawerContentScrollController.addListener(_onDrawerScroll);
        Widget drawerAppbar =  OverflowBox(
          minWidth: 0,
          maxWidth: widget.drawerWidth,
          minHeight: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
          maxHeight: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
          alignment: Alignment.centerRight,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: EdgeInsets.only(top: appbarChangeNotifier.safeAreaOffset)),
            child: AppbarFromZero(
              elevation: 0,
              toolbarHeight: widget.appbarHeight,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
              mainAppbar: true,
              mainAppbarShowButtons: false,
              paddingRight: 0,
              title: SizedBox(
                height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                child: Consumer(
                  builder: (context, ref, child) {
                    final isMobileLayout = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout));
                    final onBackPressed = () async {
                      var navigator = Navigator.of(context);
                      if (isMobileLayout)
                        navigator.pop();
                      if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                        navigator.pop();
                      }
                    };
                    final iconButtonColor = Theme.of(context).appBarTheme.toolbarTextStyle?.color
                        ?? (Theme.of(context).textTheme.bodyLarge!.color!);
                    final iconButtonTransparentColor = iconButtonColor.withOpacity(0.05);
                    final iconButtonSemiTransparentColor = iconButtonColor.withOpacity(0.1);
                    return Stack(
                      alignment: Alignment.centerLeft,
                      clipBehavior: Clip.none,
                      children: [
                        if (!isMobileLayout && canPop)
                          Positioned(
                            left: -8,
                            child: TooltipFromZero(
                              message: FromZeroLocalizations.of(context).translate("back"),
                              child: IconButton(
                                icon: Icon(Icons.arrow_back),
                                color: iconButtonColor,
                                hoverColor: iconButtonTransparentColor,
                                highlightColor: iconButtonSemiTransparentColor,
                                focusColor: iconButtonSemiTransparentColor,
                                splashColor: iconButtonSemiTransparentColor,
                                onPressed: onBackPressed,
                              ),
                            ),
                          ),
                        if(widget.drawerTitle!=null)
                          Positioned(
                            left: !isMobileLayout && canPop ? 40 : 0,
                            right: widget.centerDrawerTitle ? 0 : null,
                            top: 0, bottom: 0,
//                                  duration: 300.milliseconds,
//                                  curve: widget.drawerAnimationCurve,
                            child: widget.applyHeroToDrawerTitle ? Hero(
                              tag: "scaffold-fz-drawer-title",
                              child: widget.drawerTitle!,
                            ) : widget.drawerTitle!,
                          ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
                    final isMobileLayout = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout));
                    if (!isMobileLayout){
                      final onTap = (){
                        if (isMobileLayout)
                          Navigator.of(context).pop();
                        else
                          _toggleDrawer(context, changeNotifier);
                      };
                      final iconButtonColor = Theme.of(context).appBarTheme.toolbarTextStyle?.color
                          ?? (Theme.of(context).textTheme.bodyLarge!.color!);
                      final iconButtonTransparentColor = iconButtonColor.withOpacity(0.05);
                      final iconButtonSemiTransparentColor = iconButtonColor.withOpacity(0.1);
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: TooltipFromZero(
                          message: changeNotifier.getCurrentDrawerWidth(pageScaffoldId)>widget.compactDrawerWidth||isMobileLayout
                              ? FromZeroLocalizations.of(context).translate("menu_close") : FromZeroLocalizations.of(context).translate("menu_open"),
                          child: IconButton(
                            icon: Icon(Icons.menu),
                            color: iconButtonColor,
                            hoverColor: iconButtonTransparentColor,
                            highlightColor: iconButtonSemiTransparentColor,
                            focusColor: iconButtonSemiTransparentColor,
                            splashColor: iconButtonSemiTransparentColor,
                            onPressed: onTap,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
        Widget result = Column(
          children: <Widget>[

            //DRAWER APPBAR
            SizedBox(
              height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
              child: drawerAppbar,
            ),

            //DRAWER CONTENT
            Expanded(
              child: Container(
                decoration: BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                child: OverflowBox(
                  minWidth: widget.drawerWidth,
                  maxWidth: widget.drawerWidth,
                  alignment: Alignment.bottomLeft,
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          Widget result = Material(
                            type: widget.drawerBackground==null ? MaterialType.card : MaterialType.transparency,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Consumer(
                                    builder: (context, ref, child) {
                                      final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
                                      final currentDrawerWidth = changeNotifier.getCurrentDrawerWidth(pageScaffoldId);
                                      Widget result = _getUserDrawerContent(context, currentDrawerWidth==widget.compactDrawerWidth);
                                      result = widget.drawerContentTransitionBuilder(
                                        child: result,
                                        animation: ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation,
                                        secondaryAnimation: ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation,
                                        scaffoldChangeNotifier: changeNotifierNotListen,
                                      );
                                      result = ScrollbarFromZero(
                                        controller: drawerContentScrollController,
                                        applyOpacityGradientToChildren: false,
                                        ignoreDevicePadding: false,
                                        child: SingleChildScrollView(
                                          clipBehavior: Clip.none,
                                          controller: drawerContentScrollController,
                                          child: Padding(
                                            padding: EdgeInsets.only(top: widget.drawerPaddingTop),
                                            child: result,
                                          ),
                                        ),
                                      );
                                      if (widget.useCompactDrawerInsteadOfClose) {
                                        final isMobileLayout = ref.watch(fromZeroScreenProvider.select((value) => value.isMobileLayout));
                                        if (!isMobileLayout) {
                                          result = AnimatedTheme(
                                            duration: widget.drawerAnimationDuration,
                                            curve: widget.appbarAnimationCurve,
                                            data: Theme.of(context).copyWith(
                                              scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
                                                thickness: MaterialStateProperty.resolveWith((states) {
                                                  final baseThickness = states.contains(MaterialState.hovered) ? 12.0 : 8.0;
                                                  return baseThickness + (widget.drawerWidth - currentDrawerWidth - 4).coerceIn(0);
                                                }),
                                              ),
                                            ),
                                            child: result,
                                          );
                                        }
                                      }
                                      return result;
                                    },
                                  ),
                                ),
                                widget.drawerFooterBuilder != null
                                    ? Consumer(
                                      builder: (context, ref, child) {
                                        final changeNotifier = ref.watch(fromZeroScaffoldChangeNotifierProvider);
                                        return widget.addFooterDivisions ?
                                            Material(
                                              color: Theme.of(context).cardColor,
                                              child: Column(
                                                children: <Widget>[
                                                  Divider(height: 3, thickness: 3,),
                                                  SizedBox(height: 8,),
                                                  _getUserDrawerFooter(context, changeNotifier.getCurrentDrawerWidth(pageScaffoldId)==widget.compactDrawerWidth),
                                                  SizedBox(height: 12,),
                                                ],
                                              ),
                                            ) : _getUserDrawerFooter(context, changeNotifier.getCurrentDrawerWidth(pageScaffoldId)==widget.compactDrawerWidth);
                                      },
                                    ) : SizedBox.shrink(),
                              ],
                            ),
                          );
                          if (widget.drawerBackground!=null) {
                            result = widget.drawerBackground!(context, result);
                          }
                          return result;
                        }
                      ),

                      //CUSTOM SHADOWS (drawer appbar)
                      AnimatedContainer(
                        duration: widget.drawerAnimationDuration,
                        curve: widget.drawerAnimationCurve,
                        alignment: Alignment.topCenter,
                        width: widget.drawerWidth,
                        child: SizedBox(
                          width: double.infinity,
                          height: widget.drawerAppbarElevation,
                          child: const CustomPaint(
                            painter: const SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        );
        return result;
      },
    );
  }

  _getUserDrawerContent(BuildContext context, bool compact) {
    return Container(
      key: drawerGlobalKey,
      child: widget.drawerContentBuilder!(context, compact),
    );
  }

  _getUserDrawerFooter(BuildContext context, bool compact) => widget.drawerFooterBuilder!(context, compact);

  _toggleDrawer(context, ScaffoldFromZeroChangeNotifier changeNotifier){
    var scaffold = Scaffold.of(context);
    if (scaffold.hasDrawer){
      if (scaffold.isDrawerOpen){
        // not clickable
      } else{
        scaffold.openDrawer();
      }
    } else{
      if (changeNotifier.getCurrentDrawerWidth(pageScaffoldId) > widget.compactDrawerWidth){
        changeNotifier.setCurrentDrawerWidth(pageScaffoldId, widget.compactDrawerWidth);
      } else{
        changeNotifier.setCurrentDrawerWidth(pageScaffoldId, widget.drawerWidth);
      }
    }
  }

  void onHorizontalDragUpdate (DragUpdateDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(pageScaffoldId) + details.delta.dx;
    if (jump<widget.compactDrawerWidth) jump = widget.compactDrawerWidth;
    if (jump>widget.drawerWidth) jump = widget.drawerWidth;
    changeNotifier.setCurrentDrawerWidth(pageScaffoldId, jump);
  }
  static const double _kMinFlingVelocity = 365.0;
  void onHorizontalDragEnd (DragEndDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(pageScaffoldId);
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity){
      if (details.velocity.pixelsPerSecond.dx>0) jump = widget.drawerWidth;
      else jump = widget.compactDrawerWidth;
    }
    else if (jump<widget.drawerWidth/2) jump = widget.compactDrawerWidth;
    else jump = widget.drawerWidth;
    changeNotifier.setCurrentDrawerWidth(pageScaffoldId, jump);
  }

}



class AppbarChangeNotifier extends ChangeNotifier{

  final double appbarHeight;
  final double safeAreaOffset;
  final double backgroundHeight;
  final int appbarType;
  final double appbarScrollMultiplier = 0.5; //TODO 3 expose scroll appbar effect multipliers
  final double backgroundScrollMultiplier = 1.5;
  final double unaffectedScrollLength; //TODO 3 expose this as well in Scaffold

  AppbarChangeNotifier(this.appbarHeight, this.safeAreaOffset, this.backgroundHeight, this.appbarType, double? unaffectedScrollLength)
      : this.unaffectedScrollLength = unaffectedScrollLength ?? appbarHeight;

  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  get currentAppbarHeight => appbarHeight+safeAreaOffset+currentAppbarOffset;

  double _currentAppbarOffset = 0;
  double get currentAppbarOffset => _currentAppbarOffset;
  set currentAppbarOffset(double value) {
    _currentAppbarOffset = value;
    notifyListeners();
  }

  double _currentBackgroundOffset = 0;
  double get currentBackgroundOffset => _currentBackgroundOffset;
  set currentBackgroundOffset(double value) {
    _currentBackgroundOffset = value;
    notifyListeners();
  }

  double mainScrollPosition = 0;
  int? lastScrollUpdateTime; //TODO 2 wait for the scroll gesture to end instead of the timer ? how
  void handleMainScrollerControllerCall(ScrollController scrollController){
    if (appbarType==ScaffoldFromZero.appbarTypeStatic) return;
    if (!scrollController.hasClients) return;

    var currentPosition = scrollController.position.pixels;
    if (appbarType==ScaffoldFromZero.appbarTypeCollapse)
      currentPosition = currentPosition.coerceIn(0, unaffectedScrollLength+(safeAreaOffset+appbarHeight)/appbarScrollMultiplier);
    double delta = currentPosition - mainScrollPosition;
    mainScrollPosition = currentPosition;

    if (mainScrollPosition>unaffectedScrollLength || delta<0){
      double jump = -currentAppbarOffset;
      jump += delta * appbarScrollMultiplier;
      if (jump < 0) jump = 0;
      else if (jump > appbarHeight+safeAreaOffset) jump = appbarHeight+safeAreaOffset;
      currentAppbarOffset = -jump;

      jump = -currentBackgroundOffset;
      jump += delta * backgroundScrollMultiplier;
      if (jump < 0) jump = 0;
      else if (jump > backgroundHeight+safeAreaOffset) jump = backgroundHeight+safeAreaOffset;
      currentBackgroundOffset = -jump;
    }

    if (appbarType==ScaffoldFromZero.appbarTypeQuickReturn && lastScrollUpdateTime == null){
      lastScrollUpdateTime = DateTime.now().millisecondsSinceEpoch;
      Future.doWhile(() async{
        await Future.delayed(80.milliseconds);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!disposed && DateTime.now().millisecondsSinceEpoch - lastScrollUpdateTime! > 500){
            if (currentAppbarOffset>-(appbarHeight)/2) {
              expand();
            } else {
              collapse();
            }
          }
        });
        return !disposed;
      },);
    } else{
      lastScrollUpdateTime = DateTime.now().millisecondsSinceEpoch;
    }

  }
  void collapse(){
    currentAppbarOffset = -(appbarHeight+safeAreaOffset);
    currentBackgroundOffset = -(backgroundHeight+safeAreaOffset);
  }
  void expand(){
    currentAppbarOffset = 0;
    currentBackgroundOffset = 0;
  }

}
