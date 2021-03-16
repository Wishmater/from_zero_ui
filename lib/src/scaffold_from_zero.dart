
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_content_wrapper.dart';
import 'package:from_zero_ui/src/appbar_from_zero.dart';
import 'package:from_zero_ui/src/custom_painters.dart';
import 'package:from_zero_ui/src/scrollbar_from_zero.dart';
import 'package:provider/provider.dart';
import '../util/no_fading_shared_axis_transition.dart' as no_fading_shared_axis_transition;
import 'package:dartx/dartx.dart';


typedef Widget DrawerContentBuilder(BuildContext context, bool compact,);


class ScaffoldFromZero extends StatefulWidget {


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

  final GlobalKey bodyGlobalKey = GlobalKey();

  final Duration drawerAnimationDuration = 300.milliseconds; //TODO 3- allow customization of durations and curves of appbar and drawer animations (fix conflicts)
  final drawerAnimationCurve = Curves.easeOutCubic;
  final Duration appbarAnimationDuration = 300.milliseconds;
  final appbarAnimationCurve = Curves.easeOutCubic;

  final PageFromZero currentPage;
  final Widget? title;
  final double titleSpacing;
  final List<Widget>? actions;
  final AppbarAction? initialExpandedAction;
  final double appbarHeight;
  final double appbarElevation;
  final int appbarType;
  final AppbarFromZeroController? appbarController;
  final void Function(AppbarAction)? onAppbarActionExpanded;
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
  final double drawerElevation;
  final double drawerAppbarElevation;
  final Color? drawerBackgroundColor;
  final bool useCompactDrawerInsteadOfClose;
  final bool constraintBodyOnXLargeScreens;
  final bool centerTitle;
  final double drawerPaddingTop;
  final bool animateDrawer;
  final bool addFooterDivisions;
  final bool applyHeroToDrawerTitle;
  final bool alwaysShowHamburgerButtonOnMobile;
  final bool assumeTheScrollBarWillShowOnDesktop;
  final Widget Function(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen) titleTransitionBuilder;
  final Widget Function(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen) drawerContentTransitionBuilder;


  ScaffoldFromZero({
    this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.drawerContentBuilder,
    this.drawerFooterBuilder,
    this.drawerTitle,
    this.useCompactDrawerInsteadOfClose = true,
    this.constraintBodyOnXLargeScreens = true,
    double? appbarHeight,
    required this.currentPage,
    this.appbarType = appbarTypeStatic,
    this.appbarController,
    this.onAppbarActionExpanded,
    this.onAppbarActionUnexpanded,
    this.mainScrollController,
    double? collapsibleBackgroundLength,
    this.collapsibleBackgroundColor,
    int? scrollbarType, //TODO 3 allow a way to customize scrollbar (maybe through Theme, or a theme-like widget)
    bool? bodyFloatsBelowAppbar,
    double? compactDrawerWidth,
    this.drawerWidth = 304,
    this.drawerElevation = 2,
    this.appbarElevation = 3,
    this.drawerBackgroundColor,
    this.drawerAppbarElevation = 3,
    this.centerTitle = false,
    this.drawerPaddingTop = 6,
    this.initialExpandedAction,
    this.animateDrawer = true,
    this.titleSpacing = 8,
    this.addFooterDivisions = true,
    this.applyHeroToDrawerTitle = true,
    this.alwaysShowHamburgerButtonOnMobile = false,
    this.assumeTheScrollBarWillShowOnDesktop = false,
    Widget Function(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen)? titleTransitionBuilder,
    Widget Function(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen)? drawerContentTransitionBuilder,
  }) :
        // this.appbarType = appbarType ?? (title==null&&(actions==null||actions.isEmpty)&&drawerContentBuilder==null ? appbarTypeNone : appbarTypeStatic),
        this.collapsibleBackgroundHeight = collapsibleBackgroundLength ?? (appbarType==ScaffoldFromZero.appbarTypeStatic||appbarHeight==null ? -1 : appbarHeight*3),
        this.scrollbarType = scrollbarType ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? scrollbarTypeBellowAppbar : scrollbarTypeOverAppbar),
        this.bodyFloatsBelowAppbar = bodyFloatsBelowAppbar ?? appbarType==ScaffoldFromZero.appbarTypeQuickReturn,
        this.compactDrawerWidth = drawerContentBuilder==null||!useCompactDrawerInsteadOfClose ? 0 : 56,
        this.appbarHeight = appbarHeight ?? (appbarType==ScaffoldFromZero.appbarTypeNone ? 0 : 56), //useCompactDrawerInsteadOfClose ? 56 : 0
        this.titleTransitionBuilder = titleTransitionBuilder ?? defaultTitleTransitionBuilder,
        this.drawerContentTransitionBuilder = drawerContentTransitionBuilder ?? defaultDrawerContentTransitionBuilder;

  @override
  _ScaffoldFromZeroState createState() => _ScaffoldFromZeroState();

  static Widget defaultTitleTransitionBuilder(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen){
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
                  parent: changeNotifierNotListen.titleAnimation ? animation : kAlwaysCompleteAnimation),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation( curve: Curves.easeOutCubic,
                  parent: changeNotifierNotListen.titleAnimation ? animation : kAlwaysCompleteAnimation,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation( curve: Curves.easeOutCubic,
                    parent: changeNotifierNotListen.titleAnimation ? animation : kAlwaysCompleteAnimation,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: secondaryAnimation,
                      child: child,
                      builder: (context, child) {
                        return ScaleTransition(
                          scale: CurvedAnimation( curve: Curves.easeOutCubic,
                            parent: changeNotifierNotListen.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                          ),
                          alignment: Alignment.topLeft,
                          child: FadeTransition(
                            opacity: CurvedAnimation( curve: Curves.easeOutCubic,
                              parent: changeNotifierNotListen.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
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

  static Widget defaultDrawerContentTransitionBuilder(Widget child, Animation<double> animation, Animation<double> secondaryAnimation, ScaffoldFromZeroChangeNotifier changeNotifierNotListen){
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return FadeUpwardsSlideTransition(
              routeAnimation: changeNotifierNotListen.sharedAnim
                  ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
              child: FadeUpwardsSlideTransition(
                routeAnimation: changeNotifierNotListen.sharedAnim
                    ? animation : kAlwaysCompleteAnimation,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }

}

class _ScaffoldFromZeroState extends State<ScaffoldFromZero> {


  AppbarChangeNotifier? _appbarChangeNotifier;
  late ScrollController drawerContentScrollController;
  late bool canPop;
  late Animation<double> animation;
  late Animation<double> secondaryAnimation;


  _ScaffoldFromZeroState();


  late ScaffoldFromZeroChangeNotifier _changeNotifier;
  bool lockListenToDrawerScroll = false;
  @override
  void initState() {
    super.initState();
    widget.currentPage.randomId  = DateTime.now().millisecondsSinceEpoch;
    _changeNotifier = Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false);
    _changeNotifier.pushPageToStack(widget.currentPage);
    _changeNotifier.pushScaffoldToStack(widget);
    _changeNotifier.updateStackRelatedVariables();
    widget.mainScrollController?.addListener(_handleScroll);
    if (_changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId]==null){
      _changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId] = ValueNotifier(0);
    }
    drawerContentScrollController = ScrollController(
        initialScrollOffset: _changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId]?.value ?? 0,
    );
    drawerContentScrollController.addListener(() {
      if (mounted && drawerContentScrollController.hasClients){
        lockListenToDrawerScroll = true;
        _changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId]?.value
            = drawerContentScrollController.position.pixels;
      }
    });
    _changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId]?.addListener(() {
      if (!lockListenToDrawerScroll && mounted && drawerContentScrollController.hasClients){
        drawerContentScrollController.jumpTo(_changeNotifier.drawerContentScrollOffsets[widget.currentPage.pageScaffoldId]?.value ?? 0);
        lockListenToDrawerScroll = false;
      }
    });
  }

  @override
  void didUpdateWidget(ScaffoldFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.currentPage.randomId  = oldWidget.currentPage.randomId;
  }

  @override
  void dispose() {
    _appbarChangeNotifier!.dispose();
    super.dispose();
    _changeNotifier.popPageFromStack(widget.currentPage);
    _changeNotifier.popScaffoldFromStack(widget);
    _changeNotifier.updateStackRelatedVariables();
    widget.mainScrollController?.removeListener(_handleScroll);
    widget.mainScrollController?.dispose();
  }

  void _handleScroll() {
    _appbarChangeNotifier!.handleMainScrollerControllerCall(widget.mainScrollController!);
  }


  @override
  Widget build(BuildContext context) {
    if (_appbarChangeNotifier==null){
      _appbarChangeNotifier = AppbarChangeNotifier(
        widget.appbarHeight,
        MediaQuery.of(context).padding.top,
        widget.collapsibleBackgroundHeight,
        widget.appbarType,
        null,
      );
      canPop = Navigator.of(context).canPop();
      animation = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
      secondaryAnimation = ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation;
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appbarChangeNotifier!,),
      ],
      builder: (context, child) {
        return Builder(
          builder: (context) {
            var drawerContent = _getResponsiveDrawerContent(context);
            var body = _getMainLayout(context);
            return FadeUpwardsFadeTransition(
              routeAnimation: animation,
              child: FadeUpwardsSlideTransition(
                routeAnimation: Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false).animationType==ScaffoldFromZero.animationTypeOther ? animation : kAlwaysCompleteAnimation,
                child: Selector<ScreenFromZero, bool>(
                    selector: (context, screen) => screen.displayMobileLayout,
                    builder: (context, displayMobileLayout, child) {
                      return Scaffold(
                        floatingActionButton: Consumer<ScaffoldFromZeroChangeNotifier>(
                          builder: (context, changeNotifier, child) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return AnimatedPadding(
                                  padding: EdgeInsets.only(
                                    bottom: displayMobileLayout ? 0 : 12,
                                    right: displayMobileLayout ? 0
                                        : 12 + ((constraints.maxWidth-changeNotifier.getCurrentDrawerWidth(widget.currentPage)-ScaffoldFromZero.screenSizeXLarge)/2).coerceIn(0),
                                  ),
                                  duration: widget.drawerAnimationDuration,
                                  curve: widget.drawerAnimationCurve,
                                  child: widget.floatingActionButton,
                                );
                              },
                            );
                          },
                        ),
                        drawer: displayMobileLayout && widget.drawerContentBuilder!=null ? Container(
                          width: widget.drawerWidth,
                          child: Drawer(
                            child: drawerContent,
                            elevation: widget.drawerElevation*5,
                          ),
                        ) : null,
                        body: body,
                      );
                    }
                ),
              ),
            );
          },
        );
      },
    );
  }

  late Widget _mainLayout;
  Widget _getMainLayout(context) {
//    if (_mainLayout==null){
      _mainLayout = Consumer2<ScaffoldFromZeroChangeNotifier, ScreenFromZero>(
        builder: (context, changeNotifier, screen, child) {
          return Stack(
            fit: StackFit.passthrough,
            children: [

              // COLLAPSIBLE BACKGROUND
              Consumer<AppbarChangeNotifier>(
                builder: (context, appbarChangeNotifier, child) {
                  return AnimatedPositioned(
                    duration: widget.appbarAnimationDuration,
                    curve: widget.appbarAnimationCurve,
                    top: appbarChangeNotifier.currentBackgroundOffset,
                    height: appbarChangeNotifier.safeAreaOffset+appbarChangeNotifier.backgroundHeight,
                    left: 0, right: 0,
                    child: child,
                  );
                },
                child: Container(
                  color: (widget.collapsibleBackgroundColor ?? Theme.of(context).primaryColorDark),
                ),
              ),

              //BACKGROUND STRIPE TO PREVENT APPBAR TEARING WHEN CLOSE/OPEN DRAWER
              Consumer<AppbarChangeNotifier>(
                builder: (context, appbarChangeNotifier, child) => AnimatedContainer(
                  duration: widget.appbarAnimationDuration,
                  curve: widget.appbarAnimationCurve,
                  height: appbarChangeNotifier.currentAppbarHeight,
                  color: Theme.of(context).appBarTheme.color ?? Theme.of(context).primaryColor,
                ),
              ),

              //APPBAR + BODY
              AnimatedPositioned(
                duration: widget.drawerAnimationDuration,
                curve: widget.drawerAnimationCurve,
                left: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                right: 0, top: 0, bottom: 0,
                child: _getBody(context),
              ),

              // CUSTOM SHADOWS (drawer right)
              Consumer<AppbarChangeNotifier>(
                builder: (context, appbarChangeNotifier, child) {
                  if (!screen.displayMobileLayout && widget.drawerContentBuilder!=null){
                    return AnimatedContainer(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight, left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)),
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
                child: screen.displayMobileLayout || widget.drawerContentBuilder==null
                    ? Container()
                    : widget.useCompactDrawerInsteadOfClose
                    ? AnimatedContainer(
                      duration: widget.drawerAnimationDuration,
                      curve: widget.drawerAnimationCurve,
                      width: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                      child: _getResponsiveDrawerContent(context),
                    )
                    : AnimatedPositioned(
                      duration: widget.drawerAnimationDuration,
                      curve: widget.drawerAnimationCurve,
                      left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)-widget.drawerWidth,
                      width: widget.drawerWidth,
                      top: 0, bottom: 0,
                      child: _getResponsiveDrawerContent(context),
                    ),
              ),

              //DESKTOP DRAWER OPEN GESTURE DETECTOR
              screen.displayMobileLayout || widget.drawerContentBuilder==null
                  ? Positioned(top: 0, bottom: 0, width: 0, child: Container(),)
                  : Positioned(
                top: 0, bottom: 0, left: 0, width: changeNotifier.getCurrentDrawerWidth(widget.currentPage)+18,
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
//    }
    return _mainLayout;
  }

  late Widget _body;
  Widget _getBody (BuildContext context){
//    if (_body==null){
      var changeNotifierNotListen = Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false);
      _body = ScrollbarFromZero(
        assumeTheScrollBarWillShowOnDesktop: widget.assumeTheScrollBarWillShowOnDesktop,
        controller: widget.scrollbarType==ScaffoldFromZero.scrollbarTypeOverAppbar ? widget.mainScrollController : null,
        child: Consumer<AppbarChangeNotifier>(
          builder: (context, appbarChangeNotifier, child) => Stack(
            children: <Widget>[

              //BODY
              AnimatedPadding(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                padding: EdgeInsets.only(top: widget.bodyFloatsBelowAppbar ? 0 : appbarChangeNotifier.currentAppbarHeight,),
                child: ScrollbarFromZero(
                  assumeTheScrollBarWillShowOnDesktop: widget.assumeTheScrollBarWillShowOnDesktop,
                  controller: widget.scrollbarType==ScaffoldFromZero.scrollbarTypeBellowAppbar ? widget.mainScrollController : null,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      alignment: Alignment.topCenter,
                      width: widget.constraintBodyOnXLargeScreens ? ScaffoldFromZero.screenSizeXLarge : double.infinity,
                      child: AnimatedBuilder(
                        child: Container(key: widget.bodyGlobalKey, child: widget.body),
                        animation: animation,
                        builder: (context, child) {
                          return AnimatedBuilder(
                            animation: secondaryAnimation,
                            child: child,
                            builder: (context, child) {
                              if (secondaryAnimation.value>0.9) return Opacity(opacity: 0, child: child,);
                              if (changeNotifierNotListen.sharedAnim) {
                                return no_fading_shared_axis_transition.SharedAxisTransition(
                                  animation: changeNotifierNotListen.animationType==ScaffoldFromZero.animationTypeOuter
                                      ? ReverseAnimation(secondaryAnimation) : animation,
                                  secondaryAnimation: changeNotifierNotListen.animationType==ScaffoldFromZero.animationTypeOuter
                                      ? ReverseAnimation(animation).isCompleted ? kAlwaysDismissedAnimation : ReverseAnimation(animation)
                                      : secondaryAnimation.isCompleted ? kAlwaysDismissedAnimation : secondaryAnimation,
                                  child: child!,
                                  transitionType: no_fading_shared_axis_transition.SharedAxisTransitionType.scaled,
                                  fillColor: Colors.transparent,
                                );
                              } else if (changeNotifierNotListen.fadeAnim) {
                                return FadeThroughTransition(
                                  animation: animation,
                                  secondaryAnimation: secondaryAnimation.isCompleted ? kAlwaysDismissedAnimation : secondaryAnimation,
                                  child: child,
                                  fillColor: Colors.transparent,
                                );
                              } else {
                                return child!;
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
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

              //APPBAR
              if (widget.appbarType != ScaffoldFromZero.appbarTypeNone)
              AnimatedPositioned(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                top: appbarChangeNotifier.currentAppbarOffset,
                height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                left: 0, right: 0,
                child: AppbarFromZero(
                  controller: widget.appbarController,
                  onExpanded: widget.onAppbarActionExpanded,
                  onUnexpanded: widget.onAppbarActionUnexpanded,
                  backgroundColor: (Theme.of(context).appBarTheme.color??Theme.of(context).primaryColor).withOpacity(0.9),
                  elevation: 0,
                  titleSpacing: 0,
                  centerTitle: widget.centerTitle,
                  actions: widget.actions,
                  initialExpandedAction: widget.initialExpandedAction,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[

                      SizedBox(width: 8,),

                      //DRAWER HAMBURGER BUTTON (only if not using compact style)
                      Selector<ScreenFromZero, bool>(
                        selector: (context, screen) => screen.displayMobileLayout,
                        builder: (context, displayMobileLayout, child) {
                          if ((widget.useCompactDrawerInsteadOfClose && widget.drawerContentBuilder!=null && !displayMobileLayout)
                              || (!canPop && widget.drawerContentBuilder==null)) {
                            return SizedBox(width: 4+widget.titleSpacing,);
                          } else{
                            Widget result;
                            if (canPop&&(widget.drawerContentBuilder==null||(!widget.alwaysShowHamburgerButtonOnMobile&&displayMobileLayout))){
                              result = IconButton(
                                icon: Icon(Icons.arrow_back),
                                tooltip: FromZeroLocalizations.of(context).translate("back"),
                                onPressed: () async{
                                  var navigator = Navigator.of(context);
                                  if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                                    navigator.pop();
                                  }
                                },
                              );
                            } else{
                              result = AnimatedBuilder(
                                animation: secondaryAnimation,// ?? kAlwaysDismissedAnimation,
                                builder: (context, child) => IconButton(
                                  icon: AnimatedIcon(
                                    progress: widget.alwaysShowHamburgerButtonOnMobile ? kAlwaysDismissedAnimation
                                        : secondaryAnimation,// ?? kAlwaysDismissedAnimation,
                                    icon: AnimatedIcons.menu_arrow,
                                    color: (Theme.of(context).appBarTheme.brightness ?? Theme.of(context).primaryColorBrightness)
                                        == Brightness.light ? Colors.black : Colors.white,
                                  ),
                                  tooltip: FromZeroLocalizations.of(context).translate("menu_open"),
                                  onPressed: () => _toggleDrawer(context, changeNotifierNotListen),
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
                              result = Consumer<ScaffoldFromZeroChangeNotifier>(
                                child: result,
                                builder: (context, changeNotifier, child) {
                                  double currentWidth = changeNotifier.getCurrentDrawerWidth(widget.currentPage);
                                  return  AnimatedOpacity(
                                    opacity: 1-currentWidth/56<0 ? 0 : 1-currentWidth/56,
                                    duration: widget.drawerAnimationDuration,
                                    curve: widget.drawerAnimationCurve,
                                    child: AnimatedContainer(
                                      width: currentWidth>56 ? 0 : 56-currentWidth,
                                      height: widget.appbarHeight,
                                      duration: widget.drawerAnimationDuration,
                                      curve: Curves.easeOutCubic,
                                      alignment: Alignment.centerLeft,
                                      child: child,
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
                          child: widget.titleTransitionBuilder(widget.title!, animation, secondaryAnimation, changeNotifierNotListen),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      );
//    }
    return _body;
  }

  late Widget _drawerContent;
  _getResponsiveDrawerContent(BuildContext context){
//    if (_drawerContent==null){
      AppbarChangeNotifier appbarChangeNotifier = Provider.of<AppbarChangeNotifier>(context, listen: false);
      var changeNotifierNotListen = Provider.of<ScaffoldFromZeroChangeNotifier>(context);
      _drawerContent = Column(
        children: <Widget>[

          //DRAWER APPBAR
          Stack(
            children: [
              SizedBox(
                height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: widget.drawerWidth,
                  minHeight: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                  maxHeight: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                  alignment: Alignment.centerRight,
                  child: AppBar(
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: SizedBox(
                      height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                      child: Selector<ScreenFromZero, bool>(
                        selector: (context, screen) => screen.displayMobileLayout,
                        builder: (context, displayMobileLayout, child) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            overflow: Overflow.visible,
                            children: [
                              if (!displayMobileLayout && canPop)
                                Positioned(
                                  left: -8,
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back),
                                    tooltip: FromZeroLocalizations.of(context).translate("back"),
                                    onPressed: () async{
                                      var navigator = Navigator.of(context);
                                      if (displayMobileLayout)
                                        navigator.pop();
                                      if (navigator.canPop() && (await ModalRoute.of(context)!.willPop()==RoutePopDisposition.pop)){
                                        navigator.pop();
                                      }
                                    },
                                  ),
                                ),
                              if(widget.drawerTitle!=null)
                                Positioned(
                                  left: !displayMobileLayout && canPop ? 40 : 0,
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
                      )
                    ),
                    actions: [
                      Consumer2<ScaffoldFromZeroChangeNotifier, ScreenFromZero>(
                        builder: (context, changeNotifier, screen, child) {
                          if (!screen.displayMobileLayout){
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: Icon(Icons.menu),
                                tooltip: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>widget.compactDrawerWidth||screen.displayMobileLayout
                                    ? FromZeroLocalizations.of(context).translate("menu_close") : FromZeroLocalizations.of(context).translate("menu_open"),
                                onPressed: (){
                                  if (screen.displayMobileLayout)
                                    Navigator.of(context).pop();
                                  else
                                    _toggleDrawer(context, changeNotifier);
                                },
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        },
                      )

                    ],
                  ),
                ),
              ),
            ],
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
                    Material(
                      color: widget.drawerBackgroundColor ?? Theme.of(context).cardColor,
                      child: Column(
                        children: [
                          Expanded(
                            child: ScrollbarFromZero(
                              controller: drawerContentScrollController,
                              child: SingleChildScrollView(
                                clipBehavior: Clip.none,
                                controller: drawerContentScrollController,
                                child: Padding(
                                  padding: EdgeInsets.only(top: widget.drawerPaddingTop),
                                  child:  Consumer<ScaffoldFromZeroChangeNotifier>(
                                    builder: (context, changeNotifier, child) {
                                      Widget result = _getUserDrawerContent(context, changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth);
                                      if (widget.animateDrawer){
                                        result = widget.drawerContentTransitionBuilder(result, animation, secondaryAnimation, changeNotifierNotListen,);
                                      }
                                      return result;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          widget.drawerFooterBuilder != null
                          ? Consumer<ScaffoldFromZeroChangeNotifier>(
                            builder: (context, changeNotifier, child) {
                              return widget.addFooterDivisions ?
                              Material(
                                color: Theme.of(context).cardColor,
                                child: Column(
                                  children: <Widget>[
                                    Divider(height: 3, thickness: 3, color: Theme.of(context).brightness==Brightness.light ? Colors.grey : Colors.grey.shade900,),
                                    SizedBox(height: 8,),
                                    _getUserDrawerFooter(context, changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth),
                                    SizedBox(height: 12,),
                                  ],
                                ),
                              ) : _getUserDrawerFooter(context, changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth);
                            },
                          ) : SizedBox.shrink(),
                        ],
                      ),
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
//    }
    return _drawerContent;
  }

  late Widget _userDrawerContent;
  late bool _isUserDrawerContentCompact;
  _getUserDrawerContent(BuildContext context, bool compact){
//    if (_isUserDrawerContentCompact!=compact){
      _isUserDrawerContentCompact = compact;
      _userDrawerContent = widget.drawerContentBuilder!(context, compact);
//    }
    return _userDrawerContent;
  }

  late Widget _userDrawerFooter;
  late bool _isUserDrawerFooterCompact;
  _getUserDrawerFooter(BuildContext context, bool compact){
//    if (_isUserDrawerFooterCompact!=compact){
      _isUserDrawerFooterCompact = compact;
      _userDrawerFooter = widget.drawerFooterBuilder!(context, compact);
//    }
    return _userDrawerFooter;
  }

  _toggleDrawer(context, ScaffoldFromZeroChangeNotifier changeNotifier){
    var scaffold = Scaffold.of(context);
    if (scaffold.hasDrawer){
      if (scaffold.isDrawerOpen){
        // not clickable
      } else{
        scaffold.openDrawer();
      }
    } else{
      if (changeNotifier.getCurrentDrawerWidth(widget.currentPage) > widget.compactDrawerWidth){
        changeNotifier.setCurrentDrawerWidth(widget.currentPage, widget.compactDrawerWidth);
      } else{
        changeNotifier.setCurrentDrawerWidth(widget.currentPage, widget.drawerWidth);
      }
    }
  }

  void onHorizontalDragUpdate (DragUpdateDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(widget.currentPage) + details.delta.dx;
    if (jump<widget.compactDrawerWidth) jump = widget.compactDrawerWidth;
    if (jump>widget.drawerWidth) jump = widget.drawerWidth;
    changeNotifier.setCurrentDrawerWidth(widget.currentPage, jump);
  }
  static const double _kMinFlingVelocity = 365.0;
  void onHorizontalDragEnd (DragEndDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(widget.currentPage);
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity){
      if (details.velocity.pixelsPerSecond.dx>0) jump = widget.drawerWidth;
      else jump = widget.compactDrawerWidth;
    }
    else if (jump<widget.drawerWidth/2) jump = widget.compactDrawerWidth;
    else jump = widget.drawerWidth;
    changeNotifier.setCurrentDrawerWidth(widget.currentPage, jump);
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
  int? lastScrollUpdateTime; //TODO 1 wait for the scroll gesture to end instead of the timer
  void handleMainScrollerControllerCall(ScrollController scrollController){
    if (appbarType==ScaffoldFromZero.appbarTypeStatic) return;

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
        WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
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
