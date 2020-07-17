
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_content_wrapper.dart';
import 'package:from_zero_ui/src/appbar_from_zero.dart';
import 'package:from_zero_ui/src/custom_painters.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
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
  final Widget title;
  final List<Widget> actions;
  final double appbarHeight;
  final double appbarElevation;
  final int appbarType;
  final ScrollController mainScrollController;
  final int scrollbarType;
  final double collapsibleBackgroundHeight;
  final Color collapsibleBackgroundColor;
  final Widget body;
  final bool bodyFloatsBelowAppbar;
  final Widget floatingActionButton;
  final double drawerWidth;
  final double compactDrawerWidth;
  final DrawerContentBuilder drawerContentBuilder;
  final DrawerContentBuilder drawerFooterBuilder;
  final Widget drawerTitle;
  final double drawerElevation;
  final bool useCompactDrawerInsteadOfClose = true;
  final bool constraintBodyOnXLargeScreens;


  ScaffoldFromZero({
    this.title,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.drawerContentBuilder,
    this.drawerFooterBuilder,
    this.drawerTitle,
//    this.useCompactDrawerInsteadOfClose = true, //TODO 3- fix fully closable drawer and expose this option again
    this.constraintBodyOnXLargeScreens = true,
    this.appbarHeight = 56,
    this.currentPage,
    this.appbarType = ScaffoldFromZero.appbarTypeStatic,
    this.mainScrollController,
    double collapsibleBackgroundLength,
    this.collapsibleBackgroundColor,
    int scrollbarType, //TODO 3 allow a way to customize scrollbar (maybe throug theme, or a theme-like widget)
    bool bodyFloatsBelowAppbar,
    double compactDrawerWidth,
    this.drawerWidth = 304,
    this.drawerElevation = 2,
    this.appbarElevation = 4,
  }) : this.collapsibleBackgroundHeight = collapsibleBackgroundLength ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? -1 : appbarHeight*3),
  this.scrollbarType = scrollbarType ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? scrollbarTypeBellowAppbar : scrollbarTypeOverAppbar),
  this.bodyFloatsBelowAppbar = bodyFloatsBelowAppbar ?? appbarType==ScaffoldFromZero.appbarTypeQuickReturn,
  this.compactDrawerWidth = drawerContentBuilder==null ? 0 : 56; //useCompactDrawerInsteadOfClose ? 56 : 0

  @override
  _ScaffoldFromZeroState createState() => _ScaffoldFromZeroState();

}

class _ScaffoldFromZeroState extends State<ScaffoldFromZero> {


  AppbarChangeNotifier _appbarChangeNotifier;
  ScrollController drawerContentScrollController = ScrollController();
  bool canPop;
  Animation animation;
  Animation secondaryAnimation;


  _ScaffoldFromZeroState();


  ScaffoldFromZeroChangeNotifier _changeNotifier;
  @override
  void initState() {
    super.initState();
    if (widget.currentPage != null){
      widget.currentPage.randomId  = DateTime.now().millisecondsSinceEpoch;
    }
    _changeNotifier = Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false);
    _changeNotifier.pushPageToStack(widget.currentPage);
    _changeNotifier.pushScaffoldToStack(widget);
    _changeNotifier.updateStackRelatedVariables();
    if (widget.mainScrollController!=null){
      widget.mainScrollController.addListener(_handleScroll);
    }
  }

  @override
  void didUpdateWidget(ScaffoldFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPage!=null && oldWidget.currentPage!=null){
      widget.currentPage.randomId  = oldWidget.currentPage.randomId;
    }
  }

  @override
  void dispose() {
    _appbarChangeNotifier.dispose();
    super.dispose();
    _changeNotifier.popPageFromStack(widget.currentPage);
    _changeNotifier.popScaffoldFromStack(widget);
    _changeNotifier.updateStackRelatedVariables();
    if (widget.mainScrollController!=null){
      widget.mainScrollController.removeListener(_handleScroll);
      widget.mainScrollController.dispose();
    }
  }

  void _handleScroll() {
    _appbarChangeNotifier.handleMainScrollerControllerCall(widget.mainScrollController);
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
      animation = ModalRoute.of(context).animation;
      secondaryAnimation = ModalRoute.of(context).secondaryAnimation;
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appbarChangeNotifier,),
      ],
      builder: (context, child) {
        return Consumer2<ScaffoldFromZeroChangeNotifier, ScreenFromZero>(
          builder: (context, changeNotifier, screen, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return FadeUpwardsSlideTransition(
                  routeAnimation: changeNotifier.animationType==ScaffoldFromZero.animationTypeOther ? animation : kAlwaysCompleteAnimation,
                  child: FadeUpwardsFadeTransition(
                    routeAnimation: animation,
                    child: Scaffold(
                      floatingActionButton: AnimatedPadding(
                        padding: EdgeInsets.only(
                          bottom: screen.displayMobileLayout ? 0 : 12,
                          right: screen.displayMobileLayout ? 0
                              : 12 + ((constraints.maxWidth-changeNotifier.getCurrentDrawerWidth(widget.currentPage)-ScaffoldFromZero.screenSizeXLarge)/2).coerceIn(0),
                        ),
                        duration: widget.drawerAnimationDuration,
                        curve: widget.drawerAnimationCurve,
                        child: widget.floatingActionButton,
                      ),
                      drawer: screen.displayMobileLayout && widget.drawerContentBuilder!=null ? Drawer(
                        child: _getResponsiveDrawerContent(context),
                        elevation: widget.drawerElevation,
                      ) : null,
                      body: Builder(
                        builder: (context) {
                          return _getMainLayout(context);
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _mainLayout;
  Widget _getMainLayout(context) {
    if (_mainLayout==null){
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

              //DESKTOP DRAWER
              screen.displayMobileLayout || widget.drawerContentBuilder==null
                  ? SizedBox.shrink()
                  : widget.useCompactDrawerInsteadOfClose
                  ? AnimatedContainer(
                duration: widget.drawerAnimationDuration,
                curve: widget.drawerAnimationCurve,
                width: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
                  onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
                  child: _getResponsiveDrawerContent(context),
                ),
              )
                  : AnimatedPositioned(
                duration: widget.drawerAnimationDuration,
                curve: widget.drawerAnimationCurve,
                left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)-widget.drawerWidth,
                width: widget.drawerWidth,
                top: 0, bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
                  onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
                  child: _getResponsiveDrawerContent(context),
                ),
              ),

              //CUSTOM SHADOWS (drawer appbar)
              AnimatedContainer(
                duration: widget.drawerAnimationDuration,
                curve: widget.drawerAnimationCurve,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: widget.appbarHeight+Provider.of<AppbarChangeNotifier>(context, listen: false).safeAreaOffset,),
                width: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.appbarElevation,
                  child: const CustomPaint(
                    painter: const SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.3),
                  ),
                ),
              ),

              //APPBAR + BODY
              AnimatedPositioned(
                  duration: widget.drawerAnimationDuration,
                  curve: widget.drawerAnimationCurve,
                  left: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                  right: 0, top: 0, bottom: 0,
                  child: _getBody(context)
              ),

              // CUSTOM SHADOWS (drawer right)
              if (!screen.displayMobileLayout && widget.drawerContentBuilder!=null)
                Consumer<AppbarChangeNotifier>(
                  builder: (context, appbarChangeNotifier, child) => AnimatedContainer(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight, left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)),
                    duration: widget.drawerAnimationDuration,
                    curve: widget.drawerAnimationCurve,
                    child: SizedBox(
                      width: widget.drawerElevation,
                      height: double.infinity,
                      child: const CustomPaint(
                        painter: const SimpleShadowPainter(direction: SimpleShadowPainter.right, shadowOpacity: 0.4),
                      ),
                    ),
                  ),
                ),

            ],
          );
        },
      );
    }
    return _mainLayout;
  }

  Widget _body;
  Widget _getBody (BuildContext context){
    if (_body==null){
      var changeNotifierNotListen = Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false);
      _body = ScrollbarFromZero(
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
                                if (changeNotifierNotListen.sharedAnim) {
                                  return no_fading_shared_axis_transition.SharedAxisTransition(
                                    animation: changeNotifierNotListen.animationType==ScaffoldFromZero.animationTypeOuter
                                        ? ReverseAnimation(secondaryAnimation) : animation,
                                    secondaryAnimation: changeNotifierNotListen.animationType==ScaffoldFromZero.animationTypeOuter
                                        ? ReverseAnimation(animation) : secondaryAnimation,
                                    child: child,
                                    transitionType: no_fading_shared_axis_transition.SharedAxisTransitionType.scaled,
                                    fillColor: Colors.transparent,
                                  );
                                } else if (changeNotifierNotListen.fadeAnim) {
                                  return FadeThroughTransition(
                                    animation: animation,
                                    secondaryAnimation: secondaryAnimation,
                                    child: child,
                                    fillColor: Colors.transparent,
                                  );
                                } else {
                                  return child;
                                }
                              },
                            );
                          }
                      ),
                    ),
                  ),
                ),
              ),

              // CUSTOM SHADOWS (appbar)
              AnimatedContainer(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight,),
                child: SizedBox(
                  width: double.infinity,
                  height: widget.appbarElevation,
                  child: const CustomPaint(
                    painter: const SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.5),
                  ),
                ),
              ),

              //APPBAR
              AnimatedPositioned(
                duration: widget.appbarAnimationDuration,
                curve: widget.appbarAnimationCurve,
                top: appbarChangeNotifier.currentAppbarOffset,
                height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                left: 0, right: 0,
                child: AppbarFromZero(
                  backgroundColor: (Theme.of(context).appBarTheme.color??Theme.of(context).primaryColor).withOpacity(0.9),
                  elevation: 0,
                  actions: widget.actions, // TODO 2 do something about overflowing actions
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[

                      //DRAWER HAMBURGER BUTTON (only if not using compact style)
                      !(canPop||widget.drawerContentBuilder!=null) ? SizedBox.shrink()
                      : Consumer<ScaffoldFromZeroChangeNotifier>(
                        builder: (context, changeNotifier, child) {
                          return AnimatedOpacity(
                            opacity: 1-changeNotifier.getCurrentDrawerWidth(widget.currentPage)/56<0 ? 0 : 1-changeNotifier.getCurrentDrawerWidth(widget.currentPage)/56,
                            duration: widget.drawerAnimationDuration,
                            curve: widget.drawerAnimationCurve,
                            child: AnimatedContainer(
                              width: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>56 ? 0: 56-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                              height: widget.appbarHeight,
                              duration: widget.drawerAnimationDuration,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.centerLeft,
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              left: -36,
                              child: Center(
                                child: Consumer<ScreenFromZero>(
                                  builder: (context, screen, child) {
                                    if ((screen.displayMobileLayout||widget.drawerContentBuilder==null)&&canPop){
                                      return IconButton(
                                        icon: Icon(Icons.arrow_back),
                                        tooltip: "Página Anterior", //TODO 3 internationalize
                                        onPressed: () async{
                                          var navigator = Navigator.of(context);
                                          if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                                            navigator.pop();
                                          }
                                        },
                                      );
                                    } else{
                                      return IconButton(
                                        icon: Icon(Icons.menu),
                                        tooltip: "Abrir Menú",
                                        onPressed: () => _toggleDrawer(context, changeNotifierNotListen),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      //TITLE
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedBuilder(
                            animation: animation,
                            child: widget.title,
                            builder: (context, child) {
                              return SizedBox(
                                height: widget.appbarHeight,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned.fill(
                                      left: Tween<double>(begin: -40.0, end: 0.0)
                                          .evaluate(changeNotifierNotListen.titleAnimation ? animation : kAlwaysCompleteAnimation),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: AnimatedBuilder(
                                          animation: secondaryAnimation,
                                          child: child,
                                          builder: (context, child) {
                                            return ZoomedFadeInTransition(
                                              animation: changeNotifierNotListen.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              //DESKTOP DRAWER OPEN GESTURE DETECTOR
              Consumer<ScreenFromZero>(
                builder: (context, screen, child) {
                  return screen.displayMobileLayout||widget.drawerContentBuilder==null ? const SizedBox.shrink()
                      : GestureDetector(
                    onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifierNotListen),
                    onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifierNotListen),
                    behavior: HitTestBehavior.translucent,
                    excludeFromSemantics: true,
                    child: Container(width: 18,),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    return _body;
  }

  Widget _drawerContent;
  _getResponsiveDrawerContent(BuildContext context){
    if (_drawerContent==null){
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
                      child: Consumer<ScreenFromZero>(
                        builder: (context, screen, child) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              if (!screen.displayMobileLayout && canPop)
                                Positioned(
                                  left: -8,
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back),
                                    tooltip: "Página Anterior", //TODO 3 internationalize
                                    onPressed: () async{
                                      var navigator = Navigator.of(context);
                                      if (screen.displayMobileLayout)
                                        navigator.pop();
                                      if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                                        navigator.pop();
                                      }
                                    },
                                  ),
                                ),
                              if(widget.drawerTitle!=null)
                                AnimatedPositioned(
                                  left: !screen.displayMobileLayout && canPop ? 56 : 0,
                                  duration: 300.milliseconds,
                                  curve: widget.drawerAnimationCurve,
                                  child: widget.drawerTitle,
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
                              padding: EdgeInsets.only(right: kIsWeb ? 4 : 8), // TODO 1 WTFF dps are bigger in web ??? this could be because of visualDensity TEST
                              child: IconButton(
                                icon: Icon(widget.useCompactDrawerInsteadOfClose&&!screen.displayMobileLayout ? Icons.menu : Icons.close),
                                tooltip: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>widget.compactDrawerWidth||screen.displayMobileLayout ? "Cerrar Menú" : "Abrir Menú",
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
                child: Material(
                    color: Theme.of(context).cardColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ScrollbarFromZero(
                            controller: drawerContentScrollController,
                            child: SingleChildScrollView(
                              controller: drawerContentScrollController,
                              child: AnimatedBuilder(
                                animation: secondaryAnimation,
                                child: Consumer<ScaffoldFromZeroChangeNotifier>(
                                  builder: (context, changeNotifier, child) {
                                    return _getUserDrawerContent(context, changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth);
                                  },
                                ),
                                builder: (context, child) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    child: child,
                                    builder: (context, child) {
                                      return ZoomedFadeInTransition(
                                        animation: changeNotifierNotListen.sharedAnim
                                            ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                                        child: FadeUpwardsSlideTransition(
                                          routeAnimation: changeNotifierNotListen.sharedAnim
                                              ? animation : kAlwaysCompleteAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Theme.of(context).cardColor,
                          child: Column(
                            children: <Widget>[
                              Divider(height: 3, thickness: 3,),
                              SizedBox(height: 6,),
                              widget.drawerFooterBuilder != null
                                  ? Consumer<ScaffoldFromZeroChangeNotifier>(
                                    builder: (context, changeNotifier, child) {
                                      return _getUserDrawerFooter(context, changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth);
                                    },
                                  )
                                  : SizedBox.shrink(),
                              SizedBox(height: 12,),
                            ],
                          ),
                        ),
                      ],
                    )
                ),
              ),
            ),
          ),

        ],
      );
    }
    return _drawerContent;
  }

  Widget _userDrawerContent;
  bool _isUserDrawerContentCompact;
  _getUserDrawerContent(BuildContext context, bool compact){
    if (_isUserDrawerContentCompact!=compact){
      _isUserDrawerContentCompact = compact;
      _userDrawerContent = widget.drawerContentBuilder(context, compact);
    }
    return _userDrawerContent;
  }

  Widget _userDrawerFooter;
  bool _isUserDrawerFooterCompact;
  _getUserDrawerFooter(BuildContext context, bool compact){
    if (_isUserDrawerFooterCompact!=compact){
      _isUserDrawerFooterCompact = compact;
      _userDrawerFooter = widget.drawerFooterBuilder(context, compact);
    }
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

  AppbarChangeNotifier(this.appbarHeight, this.safeAreaOffset, this.backgroundHeight, this.appbarType, double unaffectedScrollLength)
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
  int lastScrollUpdateTime; //TODO 1 wait for the scroll gesture to end instead of the timer
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

    //TODO 1 activate this after source of memory leak is detected
    if (false && appbarType==ScaffoldFromZero.appbarTypeQuickReturn && lastScrollUpdateTime == null){
      lastScrollUpdateTime = DateTime.now().millisecondsSinceEpoch;
      Future.doWhile(() async{
        await Future.delayed(80.milliseconds);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!disposed && DateTime.now().millisecondsSinceEpoch - lastScrollUpdateTime > 500){
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
