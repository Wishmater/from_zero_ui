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
              child: SnackBarHostFromZero(
                child: widget.child,
              ),
            ),
          );
        },
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
    if (_previousWidth!=null && _previousWidth!<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
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
    } else if (currentRouteState!.pageScaffoldDepth > previousRouteState!.pageScaffoldDepth) { // TODO depth should be calculated dynamically (adding width from goRouter.matches stack)
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
