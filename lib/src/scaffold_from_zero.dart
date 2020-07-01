
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/custom_painters.dart';
import 'package:from_zero_ui/src/fluro_router_from_zero.dart';
import 'package:from_zero_ui/src/scrollbar_from_zero.dart';
import 'package:provider/provider.dart';
import '../util/no_fading_shared_axis_transition.dart' as no_fading_shared_axis_transition;
import '../util/no_fading_fade_through_transition.dart' as no_fading_fade_through_transition;




typedef Widget DrawerContentBuilder(bool compact,);

class ScaffoldFromZero extends StatefulWidget {

  static const double small = 0;
  static const double medium = 612;
  static const double large = 848;
  static const double xLarge = 1280;
  static const List<double> sizes = [small, medium, large, xLarge];
  static const int animationTypeSame = 0;
  static const int animationTypeOther = 1;
  static const int animationTypeInner = 2;
  static const int animationTypeOuter = 3;

  final GlobalKey bodyGlobalKey = GlobalKey();

  final Widget title;
  final List<Widget> actions;
  final Widget body;
  final Widget floatingActionButton;
  final DrawerContentBuilder drawerContentBuilder;
  final DrawerContentBuilder drawerFooterBuilder;
  final Widget drawerTitle;
  final bool useCompactDrawerInsteadOfClose;
  final double appbarHeight;
  final bool constraintBodyOnXLargeScreens;
  final PageFromZero currentPage;


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
    this.appbarHeight = 56, //TODO 3 increase appbarHeight with font size to avoid it breaking
    this.currentPage,
  });

  @override
  _ScaffoldFromZeroState createState() => _ScaffoldFromZeroState(
    drawerContentBuilder==null ? 0 : useCompactDrawerInsteadOfClose ? 56 : 0,
  );

}

class _ScaffoldFromZeroState extends State<ScaffoldFromZero> {

  static const double appbarElevation = 4;
  static const double drawerElevation = 2;
  static const double drawerWidth = 304;
  static const int drawerAnimationDuration = 300;
  static const drawerAnimationCurve = Curves.easeOutCubic;

  double width;
  double height;
  bool displayMobileLayout;
  double compactDrawerWidth;
  ScrollController drawerContentScrollController = ScrollController();
  bool canPop;
  double previousWidth;
  double previousHeight;


  get animation => widget.currentPage?.animation ?? kAlwaysCompleteAnimation;
  get secondaryAnimation => widget.currentPage?.secondaryAnimation ?? kAlwaysDismissedAnimation;



  _ScaffoldFromZeroState(this.compactDrawerWidth);


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
    super.dispose();
    changeNotifier.popPageFromStack(widget.currentPage);
    changeNotifier.popScaffoldFromStack(widget);
    changeNotifier.updateStackRelatedVariables();
  }


  @override
  Widget build(BuildContext context) {

    if (canPop==null) canPop = Navigator.of(context).canPop();
    return Consumer<ScaffoldFromZeroChangeNotifier>(
      builder: (context, changeNotifier, child) {
        return LayoutBuilder(
            builder: (context, constraints) {
              width = constraints.maxWidth;
              height = constraints.maxHeight;
              if (width==0 && previousWidth!=null) width = previousWidth;
              if (height==0 && previousHeight!=null) height = previousHeight;
              displayMobileLayout = width < ScaffoldFromZero.medium;
              if (displayMobileLayout || widget.drawerContentBuilder==null)
                changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, 0);
              else if (widget.drawerContentBuilder!=null && changeNotifier.getCurrentDrawerWidth(widget.currentPage) < compactDrawerWidth)
                changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, compactDrawerWidth);
              else if (previousWidth!=null && previousWidth<ScaffoldFromZero.large && width>=ScaffoldFromZero.large){
                changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, drawerWidth);
              } else if (previousWidth!=null && previousWidth>=ScaffoldFromZero.large && width<ScaffoldFromZero.large){
                changeNotifier.setCurrentDrawerWidthSILENT(widget.currentPage, compactDrawerWidth);
              }
              previousWidth = width;
              previousHeight = height;
              double fabPadding = (width-changeNotifier.getCurrentDrawerWidth(widget.currentPage)-ScaffoldFromZero.xLarge)/2 ;
              if (fabPadding < 12) fabPadding = width < ScaffoldFromZero.medium ? 0 : 12;
              return FadeUpwardsSlideTransition(
                routeAnimation: changeNotifier.animationType==ScaffoldFromZero.animationTypeOther ? animation : kAlwaysCompleteAnimation,
                child: FadeUpwardsFadeTransition(
                  routeAnimation: animation,
                  child: Scaffold(
                    floatingActionButton: Padding(
                      padding: EdgeInsets.only(bottom: width < ScaffoldFromZero.medium ? 0 : 12, right: fabPadding), //TODO TEST make fab always be on the edge of the usable surface,
                      child: widget.floatingActionButton,
                    ),
                    drawer: displayMobileLayout && widget.drawerContentBuilder!=null ? Drawer(
                      child: _getResponsiveDrawerContent(context, changeNotifier),
                      elevation: drawerElevation,
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
  }

  Widget _getBody(context, ScaffoldFromZeroChangeNotifier changeNotifier) {
    return Stack(
      children: [

        //BACKGROUND STRIPE TO PREVENT APPBAR TEARING WHEN CLOSE/OPEN DRAWER
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: widget.appbarHeight,
            color: Theme.of(context).primaryColor,
          ),
        ),


        //DESKTOP DRAWER
        displayMobileLayout || widget.drawerContentBuilder==null
            ? SizedBox.shrink()
            : widget.useCompactDrawerInsteadOfClose
            ? Positioned(
          left: 0,
          child: AnimatedContainer(
            duration: Duration(milliseconds: drawerAnimationDuration),
            curve: drawerAnimationCurve,
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
          duration: Duration(milliseconds: drawerAnimationDuration),
          curve: drawerAnimationCurve,
          left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)-drawerWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details, changeNotifier),
            onHorizontalDragEnd: (details) => onHorizontalDragEnd(details, changeNotifier),
            child: Container(
              width: drawerWidth,
              height: height,
              child: _getResponsiveDrawerContent(context, changeNotifier),
            ),
          ),
        ),

        //APPBAR + BODY
        AnimatedPositioned(
          duration: Duration(milliseconds: drawerAnimationDuration),
          curve: drawerAnimationCurve,
          left: changeNotifier.getCurrentDrawerWidth(widget.currentPage),
          child: AnimatedContainer(
            duration: Duration(milliseconds: drawerAnimationDuration),
            curve: drawerAnimationCurve,
            width: width-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
            height: height,
            child: Stack(
              children: <Widget>[

                //APPBAR
                SizedBox(
                  height: widget.appbarHeight,
                  child: AppBar(
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
                          duration: Duration(milliseconds: drawerAnimationDuration),
                          curve: drawerAnimationCurve,
                          child: AnimatedContainer(
                            width: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>56 ? 0: 56-changeNotifier.getCurrentDrawerWidth(widget.currentPage),
                            duration: Duration(milliseconds: drawerAnimationDuration),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.only(right: 8),
                            alignment: Alignment.centerLeft,
                            child: Builder(
                                builder: (context) {
                                  return IconButton(
                                    icon: Icon(Icons.menu),
                                    tooltip: "Abrir Menú",
                                    onPressed: () => _toggleDrawer(context, changeNotifier),
                                    hoverColor: Colors.white.withOpacity(0.1), //TODO 2 make this actually responsive that actually gets params from parent dark theme (just use AppBar)
                                  );
                                }
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
                  )
                ),

                //BODY
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: widget.appbarHeight,),
                    width: widget.constraintBodyOnXLargeScreens ? ScaffoldFromZero.xLarge : double.infinity,
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

        // custom shadows
        if (!displayMobileLayout)
        AnimatedContainer(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(top: widget.appbarHeight, left: changeNotifier.getCurrentDrawerWidth(widget.currentPage)),
          duration: Duration(milliseconds: drawerAnimationDuration),
          curve: drawerAnimationCurve,
          child: SizedBox(
            width: drawerElevation,
            height: double.infinity,
            child: CustomPaint(
              painter: SimpleShadowPainter(direction: SimpleShadowPainter.right, shadowOpacity: 0.3),
            ),
          ),
        ),
        Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: widget.appbarHeight),
          child: SizedBox(
            width: double.infinity,
            height: appbarElevation,
            child: CustomPaint(
              painter: SimpleShadowPainter(direction: SimpleShadowPainter.down, shadowOpacity: 0.4),
            ),
          ),
        ),

      ],
    );
  }

  _getResponsiveDrawerContent(context, ScaffoldFromZeroChangeNotifier changeNotifier){
    Widget drawerContent = widget.drawerContentBuilder(changeNotifier.getCurrentDrawerWidth(widget.currentPage)==compactDrawerWidth);
    return Column(
      children: <Widget>[

        //TODO 2 add a way to paint an unscrollable header that can stack over the drawer appbar (or not)
        //DRAWER APPBAR
        SizedBox(
          height: widget.appbarHeight,
          child: OverflowBox(
            minWidth: 0,
            maxWidth: drawerWidth,
            minHeight: widget.appbarHeight,
            maxHeight: widget.appbarHeight,
            alignment: Alignment.centerRight,
            child: Material(
              color: Theme.of(context).primaryColor,
              child: Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: Colors.white.withOpacity(0.1), //TODO 2 make this actually responsive that actually gets params from parent dark theme
                  iconTheme: Theme.of(context).iconTheme.copyWith(
                    color: Colors.white,
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: kIsWeb ? 4 : 8), // TODO WTFF dps are bigger in web ???
                      child: IconButton(
                        icon: Icon(widget.useCompactDrawerInsteadOfClose&&!displayMobileLayout ? Icons.menu : Icons.close),
                        tooltip: changeNotifier.getCurrentDrawerWidth(widget.currentPage)>compactDrawerWidth||displayMobileLayout ? "Cerrar Menú" : "Abrir Menú",
                        onPressed: (){
                          if (displayMobileLayout)
                            Navigator.of(context).pop();
                          else
                            _toggleDrawer(context, changeNotifier);
                        },
                      ),
                    ),
                    Expanded(child: Container()),
                    if (widget.drawerTitle!=null)
                      Hero(
                        tag: "responsive_drawer_title",
                        child: widget.drawerTitle,
                        flightShuttleBuilder: HeroesFromZero.fadeThroughFlightShuttleBuilder,
                      ),
                    SizedBox(width: 8,),
                    if (canPop)
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        tooltip: "Página Anterior", //TODO 3 internationalize
                        onPressed: () async{
                          var navigator = Navigator.of(context);
                          if (displayMobileLayout)
                            navigator.pop(); //TODO 2 implement a way to prevent route pop
//                        Confirmation prevent = Provider.of<AppbarStatus>(context, listen: false).preventNavigationCallback;
//                        if (prevent==null || await prevent()){
                          if (navigator.canPop())
                            navigator.pop();
//                        }
                        },
                      ),
                    SizedBox(width: 8,),
                  ],
                ),
              ),
            ),
          ),
        ),


        //DRAWER CONTENT
        Expanded(
          child: Container(
            decoration: BoxDecoration(),
            clipBehavior: Clip.hardEdge,
            child: OverflowBox(
              minWidth: drawerWidth,
              maxWidth: drawerWidth,
              minHeight: height-widget.appbarHeight,
              maxHeight: height-widget.appbarHeight,
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
                          widget.drawerFooterBuilder != null ? widget.drawerFooterBuilder(changeNotifier.getCurrentDrawerWidth(widget.currentPage)==compactDrawerWidth) : SizedBox.shrink(),
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
      if (changeNotifier.getCurrentDrawerWidth(widget.currentPage) > compactDrawerWidth){
        changeNotifier.setCurrentDrawerWidth(widget.currentPage, compactDrawerWidth);
      } else{
        changeNotifier.setCurrentDrawerWidth(widget.currentPage, drawerWidth);
      }
    }
  }

  void onHorizontalDragUpdate (DragUpdateDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(widget.currentPage) + details.delta.dx;
    if (jump<compactDrawerWidth) jump = compactDrawerWidth;
    if (jump>drawerWidth) jump = drawerWidth;
    changeNotifier.setCurrentDrawerWidth(widget.currentPage, jump);
  }
  static const double _kMinFlingVelocity = 365.0;
  void onHorizontalDragEnd (DragEndDetails details, ScaffoldFromZeroChangeNotifier changeNotifier) {
    double jump = changeNotifier.getCurrentDrawerWidth(widget.currentPage);
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity){
      if (details.velocity.pixelsPerSecond.dx>0) jump = drawerWidth;
      else jump = compactDrawerWidth;
    }
    else if (jump<drawerWidth/2) jump = compactDrawerWidth;
    else jump = drawerWidth;
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

  int _animationType;
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
          && currentScaffold.title!=previousScaffold.title
          && (!(currentScaffold.title is Text) || !(previousScaffold.title is Text)
              || (currentScaffold.title as Text).data != (previousScaffold.title as Text).data);
  }

}


