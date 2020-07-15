
import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/custom_painters.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/scrollbar_from_zero.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:provider/provider.dart';
import '../util/no_fading_shared_axis_transition.dart' as no_fading_shared_axis_transition;
import '../util/no_fading_fade_through_transition.dart' as no_fading_fade_through_transition;
import 'package:dartx/dartx.dart';


typedef Widget DrawerContentBuilder(bool compact,);


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

  final Duration drawerAnimationDuration = 300.milliseconds; //TODO 3- allow coustomization of durations and curves of appbar and drawer animations (fix conflicts)
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
  final DrawerContentBuilder drawerHeaderBuilder;
  final Widget drawerTitle;
  final double drawerElevation;
  final bool useCompactDrawerInsteadOfClose;
  final bool constraintBodyOnXLargeScreens;


  ScaffoldFromZero({
    this.title,
    this.actions,
    this.body,
    this.floatingActionButton,
    this.drawerContentBuilder,
    this.drawerFooterBuilder,
    this.drawerTitle,
    this.useCompactDrawerInsteadOfClose = true,
    this.constraintBodyOnXLargeScreens = true,
    this.appbarHeight = 56,
    this.currentPage,
    this.appbarType = ScaffoldFromZero.appbarTypeStatic,
    this.mainScrollController,
    double collapsibleBackgroundLength,
    this.collapsibleBackgroundColor,
    int scrollbarType, //TODO 3 allow a way to customize scrollbar (maybe throug theme, or a theme-like widget)
    bool bodyFloatsBelowAppbar,
    this.drawerHeaderBuilder,
    double compactDrawerWidth,
    this.drawerWidth = 304,
    this.drawerElevation = 2,
    this.appbarElevation = 4,
  }) : this.collapsibleBackgroundHeight = collapsibleBackgroundLength ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? -1 : appbarHeight*3),
  this.scrollbarType = scrollbarType ?? (appbarType==ScaffoldFromZero.appbarTypeStatic ? scrollbarTypeBellowAppbar : scrollbarTypeOverAppbar),
  this.bodyFloatsBelowAppbar = bodyFloatsBelowAppbar ?? appbarType==ScaffoldFromZero.appbarTypeQuickReturn,
  this.compactDrawerWidth = drawerContentBuilder==null ? 0 : useCompactDrawerInsteadOfClose ? 56 : 0;

  @override
  _ScaffoldFromZeroState createState() => _ScaffoldFromZeroState();

}

class _ScaffoldFromZeroState extends State<ScaffoldFromZero> {


  AppbarChangeNotifier _appbarChangeNotifier;
  double width;
  double height;
  bool displayMobileLayout;
  ScrollController drawerContentScrollController = ScrollController();
  bool canPop;
  double previousWidth;
  double previousHeight;
  Animation animation;
  Animation secondaryAnimation;


  _ScaffoldFromZeroState();


  ScaffoldFromZeroChangeNotifier changeNotifier;
  @override
  void initState() {
    super.initState();
    if (widget.currentPage != null){
      widget.currentPage.randomId  = DateTime.now().millisecondsSinceEpoch;
    }
    changeNotifier = Provider.of<ScaffoldFromZeroChangeNotifier>(context, listen: false);
    changeNotifier.pushPageToStack(widget.currentPage);
    changeNotifier.pushScaffoldToStack(widget);
    changeNotifier.updateStackRelatedVariables();
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
    changeNotifier.popPageFromStack(widget.currentPage);
    changeNotifier.popScaffoldFromStack(widget);
    changeNotifier.updateStackRelatedVariables();
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
    return ChangeNotifierProvider.value(
      value: _appbarChangeNotifier,
      builder: (context, child) {
        return Consumer<ScaffoldFromZeroChangeNotifier>(
          builder: (context, changeNotifier, child) {
            return LayoutBuilder(
                builder: (context, constraints) {
                  width = constraints.maxWidth;
                  height = constraints.maxHeight;
                  if (width==0 && previousWidth!=null) width = previousWidth;
                  if (height==0 && previousHeight!=null) height = previousHeight;
                  displayMobileLayout = width < ScaffoldFromZero.screenSizeMedium;
                  if (displayMobileLayout || widget.drawerContentBuilder==null)
                    changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, 0);
                  else if (widget.drawerContentBuilder!=null && changeNotifier.getCurrentDrawerWidth(widget.currentPage) < widget.compactDrawerWidth)
                    changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, widget.compactDrawerWidth);
                  else if (previousWidth!=null && previousWidth<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
                    changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, widget.drawerWidth);
                  } else if (previousWidth!=null && previousWidth>=ScaffoldFromZero.screenSizeLarge && width<ScaffoldFromZero.screenSizeLarge){
                    changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, widget.compactDrawerWidth);
                  }
                  previousWidth = width;
                  previousHeight = height;
                  double fabPadding = (width-changeNotifier.getCurrentDrawerWidth(widget.currentPage)-ScaffoldFromZero.screenSizeXLarge)/2 ;
                  if (fabPadding < 0) fabPadding = 0;
                  if (width >= ScaffoldFromZero.screenSizeMedium) fabPadding+=12;
                  return FadeUpwardsSlideTransition(
                    routeAnimation: changeNotifier.animationType==ScaffoldFromZero.animationTypeOther ? animation : kAlwaysCompleteAnimation,
                    child: FadeUpwardsFadeTransition(
                      routeAnimation: animation,
                      child: Scaffold(
                        floatingActionButton: AnimatedPadding(
                          padding: EdgeInsets.only(bottom: width < ScaffoldFromZero.screenSizeMedium ? 0 : 12, right: fabPadding),
                          duration: widget.drawerAnimationDuration,
                          curve: widget.drawerAnimationCurve,
                          child: widget.floatingActionButton,
                        ),
                        drawer: displayMobileLayout && widget.drawerContentBuilder!=null ? Drawer(
                          child: _getResponsiveDrawerContent(context, changeNotifier),
                          elevation: widget.drawerElevation,
                        ) : null,
                        body: Builder(
                          builder: (context) {
                            return _getBody(context, changeNotifier);
                          },
                        ),
                      ),
                    ),
                  );
                }
            );
          },
        );
      },
    );
  }

  Widget _getBody(context, ScaffoldFromZeroChangeNotifier changeNotifier) {
    return Stack(
      children: [

        // COLLAPSIBLE BACKGROUND
        Consumer<AppbarChangeNotifier>(
          builder: (context, appbarChangeNotifier, child) {
            return AnimatedPositioned(
              duration: widget.appbarAnimationDuration,
              curve: widget.appbarAnimationCurve,
              top: appbarChangeNotifier.currentBackgroundOffset,
              width: width,
              height: appbarChangeNotifier.safeAreaOffset+appbarChangeNotifier.backgroundHeight,
              child: Container(
                color: (widget.collapsibleBackgroundColor ?? Theme.of(context).primaryColorDark),
//                decoration: BoxDecoration(
//                  gradient: LinearGradient(
//                    begin: Alignment.topCenter,
//                    end: Alignment.bottomCenter,
//                    colors: [
//                      (widget.collapsibleBackgroundColor ?? Theme.of(context).primaryColorDark),
//                      (widget.collapsibleBackgroundColor ?? Theme.of(context).primaryColorDark).withOpacity(0),
//                    ],
//                    stops: [
//                      0.8,
//                      1,
//                    ],
//                  )
//                ),
              ),
            );
          },
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
        displayMobileLayout || widget.drawerContentBuilder==null
            ? SizedBox.shrink()
            : widget.useCompactDrawerInsteadOfClose
            ? Positioned(
          left: 0,
          child: AnimatedContainer(
            duration: widget.drawerAnimationDuration,
            curve: widget.drawerAnimationCurve,
            width: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
            height: height,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
              onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
              child: _getResponsiveDrawerContent(context, changeNotifier),
            ),
          ),
        )
            : AnimatedPositioned(
          duration: widget.drawerAnimationDuration,
          curve: widget.drawerAnimationCurve,
          left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)-widget.drawerWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
            onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
            child: Container(
              width: widget.drawerWidth,
              height: height,
              child: _getResponsiveDrawerContent(context, changeNotifier),
            ),
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
            child: CustomPaint(
              painter: SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.3),
            ),
          ),
        ),

        //APPBAR + BODY
        AnimatedPositioned(
          duration: widget.drawerAnimationDuration,
          curve: widget.drawerAnimationCurve,
          left: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
          child: AnimatedContainer(
            duration: widget.drawerAnimationDuration,
            curve: widget.drawerAnimationCurve,
            width: width-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
            height: height,
            child: ScrollbarFromZero(
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
                                      if (changeNotifier.sharedAnim) {
                                        return no_fading_shared_axis_transition.SharedAxisTransition(
                                          animation: changeNotifier.animationType==ScaffoldFromZero.animationTypeOuter
                                              ? ReverseAnimation(secondaryAnimation) : animation,
                                          secondaryAnimation: changeNotifier.animationType==ScaffoldFromZero.animationTypeOuter
                                              ? ReverseAnimation(animation) : secondaryAnimation,
                                          child: child,
                                          transitionType: no_fading_shared_axis_transition.SharedAxisTransitionType.scaled,
                                          fillColor: Colors.transparent,
                                        );
                                      } else if (changeNotifier.fadeAnim) {
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
                        child: CustomPaint(
                          painter: SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.5),
                        ),
                      ),
                    ),

                    //APPBAR
                    AnimatedPositioned(
                      duration: widget.appbarAnimationDuration,
                      curve: widget.appbarAnimationCurve,
                      top: appbarChangeNotifier.currentAppbarOffset,
                      height: appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset,
                      width: width-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                      child: AppBar(
                        backgroundColor: (Theme.of(context).appBarTheme.color??Theme.of(context).primaryColor).withOpacity(0.9),
                        elevation: 0,
                        automaticallyImplyLeading: widget.drawerContentBuilder==null,
                        actions: widget.actions, // TODO 2 do something about overflowing actions
                        titleSpacing: (!displayMobileLayout&&widget.useCompactDrawerInsteadOfClose)||widget.drawerContentBuilder==null ? 16 : 8,
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[

                            //DRAWER HAMBURGER BUTTON (only if not using compact style)
                            (!displayMobileLayout&&widget.useCompactDrawerInsteadOfClose)||widget.drawerContentBuilder==null ? SizedBox.shrink()
                                : AnimatedOpacity(
                              opacity: 1-changeNotifier.getCurrentDrawerWidth(widget.currentPage)/56<0 ? 0 : 1-changeNotifier.getCurrentDrawerWidth(widget.currentPage)/56,
                              duration: widget.drawerAnimationDuration,
                              curve: widget.drawerAnimationCurve,
                              child: AnimatedContainer(
                                width: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>56 ? 0: 56-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                                duration: widget.drawerAnimationDuration,
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.only(right: 8),
                                alignment: Alignment.centerLeft,
                                child: Builder(
                                  builder: (context) {
                                    if (displayMobileLayout&&canPop){
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
                                        onPressed: () => _toggleDrawer(context, changeNotifier),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),

                            //TITLE
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedBuilder(
                                    animation: secondaryAnimation,
                                    child: widget.title,
                                    builder: (context, child) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        child: child,
                                        builder: (context, child) {
                                          return ZoomedFadeInTransition(
                                            animation: changeNotifier.titleAnimation ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                                            child: SizeTransition(
                                              sizeFactor: changeNotifier.titleAnimation ? animation : kAlwaysCompleteAnimation,
                                              axis: Axis.horizontal,
                                              axisAlignment: 1,
                                              child: child,
                                            ),
                                          );
                                        },
                                      );
                                    }
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    //DESKTOP DRAWER OPEN GESTURE DETECTOR
                    displayMobileLayout||widget.drawerContentBuilder==null ? const SizedBox.shrink()
                        : GestureDetector(
                      onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
                      onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
                      behavior: HitTestBehavior.translucent,
                      excludeFromSemantics: true,
                      child: Container(width: 18,),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),

        // CUSTOM SHADOWS (drawer right)
        if (!displayMobileLayout && widget.drawerContentBuilder!=null)
        Consumer<AppbarChangeNotifier>(
          builder: (context, appbarChangeNotifier, child) => AnimatedContainer(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(top: appbarChangeNotifier.currentAppbarHeight, left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)),
            duration: widget.drawerAnimationDuration,
            curve: widget.drawerAnimationCurve,
            child: SizedBox(
              width: widget.drawerElevation,
              height: double.infinity,
              child: CustomPaint(
                painter: SimpleShadowPainter(direction: SimpleShadowPainter.right, shadowOpacity: 0.4),
              ),
            ),
          ),
        ),

      ],
    );
  }

  _getResponsiveDrawerContent(BuildContext context, ScaffoldFromZeroChangeNotifier changeNotifier){
    Widget drawerContent = widget.drawerContentBuilder(changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth);
    AppbarChangeNotifier appbarChangeNotifier = Provider.of<AppbarChangeNotifier>(context, listen: false);
    return Column(
      children: <Widget>[

        //TODO 2 add a way to paint an unscrollable header that can stack over the drawer appbar (or not)
        //DRAWER APPBAR
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
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (!displayMobileLayout && canPop)
                    Positioned(
                      left: -8,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back),
                        tooltip: "Página Anterior", //TODO 3 internationalize
                        onPressed: () async{
                          var navigator = Navigator.of(context);
                          if (displayMobileLayout)
                            navigator.pop();
                          if (navigator.canPop() && (await ModalRoute.of(context).willPop()==RoutePopDisposition.pop)){
                            navigator.pop();
                          }
                        },
                      ),
                    ),
                    if(widget.drawerTitle!=null)
                    AnimatedPositioned(
                      left: canPop ? 56 : 0,
                      duration: 300.milliseconds,
                      curve: widget.drawerAnimationCurve,
                      child: widget.drawerTitle,
                    ),
                  ],
                ),
              ),
              actions: [
                if (!displayMobileLayout)
                Padding(
                  padding: EdgeInsets.only(right: kIsWeb ? 4 : 8), // TODO 1 WTFF dps are bigger in web ??? this could be because of visualDensity TEST
                  child: IconButton(
                    icon: Icon(widget.useCompactDrawerInsteadOfClose&&!displayMobileLayout ? Icons.menu : Icons.close),
                    tooltip: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>widget.compactDrawerWidth||displayMobileLayout ? "Cerrar Menú" : "Abrir Menú",
                    onPressed: (){
                      if (displayMobileLayout)
                        Navigator.of(context).pop();
                      else
                        _toggleDrawer(context, changeNotifier);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),


        //DRAWER CONTENT
        Expanded(
          child: Container(
            decoration: BoxDecoration(),
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              minWidth: widget.drawerWidth,
              maxWidth: widget.drawerWidth,
              minHeight: height-(appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset),
              maxHeight: height-(appbarChangeNotifier.appbarHeight+appbarChangeNotifier.safeAreaOffset),
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
                            child: drawerContent,
                            builder: (context, child) {
                              return AnimatedBuilder(
                                animation: animation,
                                child: child,
                                builder: (context, child) {
                                  return ZoomedFadeInTransition(
                                    animation: changeNotifier.sharedAnim
                                        ? ReverseAnimation(secondaryAnimation) : kAlwaysCompleteAnimation,
                                    child: FadeUpwardsSlideTransition(
                                      routeAnimation: changeNotifier.sharedAnim
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
                          Divider(height: 1,),
                          SizedBox(height: 6,),
                          widget.drawerFooterBuilder != null ? widget.drawerFooterBuilder(changeNotifier.getCurrentDrawerWidth(widget.currentPage)==widget.compactDrawerWidth) : SizedBox.shrink(),
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

class ScaffoldFromZeroChangeNotifier extends ChangeNotifier{

  Map<String, double> _currentDrawerWidth = {};
  double getCurrentDrawerWidth(PageFromZero page) {
    if (!_currentDrawerWidth.containsKey(page.pageScaffoldId))
      _currentDrawerWidth[page.pageScaffoldId] = 304;
    return _currentDrawerWidth[page.pageScaffoldId];
  }
  setCurrentDrawerWidth(PageFromZero page, double value) {
    _currentDrawerWidth[page.pageScaffoldId] = value;
    notifyListeners();
  }
  setCurrentDrawerWidthSILENT(PageFromZero page, double value) {
    _currentDrawerWidth[page.pageScaffoldId] = value;
  }

  int _animationType = ScaffoldFromZero.animationTypeOther;
  int get animationType => _animationType;
  set animationType(int value) {
    _animationType = value;
    notifyListeners();
  }
  set animationTypeSILENT(int value) {
    _animationType = value;
  }

  List<PageFromZero> _pagesStack = [];
  List<PageFromZero> get pagesStack => _pagesStack;
//  set pagesStack(List<PageFromZero> value) {
//    _pagesStack = value;
//  }
  void pushPageToStack (PageFromZero page){
    _pagesStack.add(page);
  }
  void popPageFromStack (PageFromZero page){
    _pagesStack.removeWhere((element) => element.randomId==page.randomId);
  }

  List<ScaffoldFromZero> _scaffoldsStack = [];
  List<ScaffoldFromZero> get scaffoldsStack => _scaffoldsStack;
//  set scaffoldsStack(List<ScaffoldFromZero> value) {
//    _scaffoldsStack = value;
//  }
  void pushScaffoldToStack (ScaffoldFromZero scaffold){
    _scaffoldsStack.add(scaffold);
  }
  void popScaffoldFromStack (ScaffoldFromZero scaffold){
    _scaffoldsStack.removeWhere((element) => element.currentPage.randomId==scaffold.currentPage.randomId);
  }

  bool fadeAnim = false;
  bool sharedAnim = false;
  bool titleAnimation = false;
  updateStackRelatedVariables(){
    int animationType = ScaffoldFromZero.animationTypeOther;
    PageFromZero currentPage, previousPage;
    ScaffoldFromZero currentScaffold, previousScaffold;
    try{
      currentPage = _pagesStack[_pagesStack.length-1];
      previousPage = _pagesStack[_pagesStack.length-2];
      currentScaffold = _scaffoldsStack[scaffoldsStack.length-1];
      previousScaffold = _scaffoldsStack[scaffoldsStack.length-2];
    } catch(_, __) {}
    if (currentPage!=null && previousPage!=null) {
      if (currentPage.pageScaffoldId == previousPage.pageScaffoldId) {
        if (currentPage.pageScaffoldDepth > previousPage.pageScaffoldDepth) {
          animationType = ScaffoldFromZero.animationTypeInner;
        } else if (currentPage.pageScaffoldDepth < previousPage.pageScaffoldDepth) {
          animationType = ScaffoldFromZero.animationTypeOuter;
        } else {
          animationType = ScaffoldFromZero.animationTypeSame;
        }
      }
    }
    _animationType = animationType;
    fadeAnim = animationType==ScaffoldFromZero.animationTypeSame;
    sharedAnim = animationType==ScaffoldFromZero.animationTypeInner || animationType==ScaffoldFromZero.animationTypeOuter;
    titleAnimation = animationType!=ScaffoldFromZero.animationTypeOther
          && currentScaffold!=null && previousScaffold!=null
          && ((currentScaffold.title.key!=null && currentScaffold.title.key!=previousScaffold.title.key)
          || (!(currentScaffold.title is Text) || !(previousScaffold.title is Text)
              || (currentScaffold.title as Text).data != (previousScaffold.title as Text).data));
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
  set currentAppbarOffsetSILENT(double c){
    _currentAppbarOffset = c;
  }
  double _currentBackgroundOffset = 0;
  double get currentBackgroundOffset => _currentBackgroundOffset;
  set currentBackgroundOffset(double value) {
    _currentBackgroundOffset = value;
    notifyListeners();
  }
  set currentBackgroundOffsetSILENT(double c){
    _currentBackgroundOffset = c;
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

    //TODO activate this after source of memory leak is detected
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
