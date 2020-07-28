import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';

/// Put this widget in the builder method of your MaterialApp.
/// Controls different app-wide providers and features needed by other FromZeroWidgets
class FromZeroAppContentWrapper extends StatefulWidget {

  final child;

  FromZeroAppContentWrapper({this.child});

  @override
  _FromZeroAppContentWrapperState createState() => _FromZeroAppContentWrapperState();

}

class _FromZeroAppContentWrapperState extends State<FromZeroAppContentWrapper> {

  final screen = ScreenFromZero();
  final changeNotifier = ScaffoldFromZeroChangeNotifier();

  @override
  Widget build(BuildContext context) {
    //TODO 3 add restrictions to fontSize, uiScale logic, etc. here
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth>0){
          screen.displayMobileLayout = constraints.maxWidth < ScaffoldFromZero.screenSizeMedium;
          if (constraints.maxWidth>=ScaffoldFromZero.screenSizeXLarge){
            screen.breakpoint = ScaffoldFromZero.screenSizeXLarge;
          } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeLarge){
            screen.breakpoint = ScaffoldFromZero.screenSizeLarge;
          } else if (constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium){
            screen.breakpoint = ScaffoldFromZero.screenSizeMedium;
          } else{
            screen.breakpoint = ScaffoldFromZero.screenSizeSmall;
          }
          changeNotifier._updateScaffolds(screen.displayMobileLayout, constraints.maxWidth);
          changeNotifier._previousWidth = constraints.maxWidth;
          changeNotifier._previousHeight = constraints.maxHeight;
        }
        return FittedBox(
          child: SizedBox(
            width: changeNotifier._previousWidth ?? 1280,
            height: changeNotifier._previousHeight ?? 720,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: changeNotifier,),
                ChangeNotifierProvider.value(value: screen,),
              ],
              builder: (context, _) {
                return widget.child;
              },
            ),
          ),
        );
      },
    );
  }

}


class ScreenFromZero extends ChangeNotifier{

  bool _displayMobileLayout;
  bool get displayMobileLayout => _displayMobileLayout;
  set displayMobileLayout(bool value) {
    _displayMobileLayout = value;
    notifyListeners();
  }

  double _breakpoint;
  double get breakpoint => _breakpoint;
  set breakpoint(double value) {
    _breakpoint = value;
    notifyListeners();
  }

}

class ScaffoldFromZeroChangeNotifier extends ChangeNotifier{

  Map<String, double> _currentDrawerWidth = {};
  double getCurrentDrawerWidth(PageFromZero page) {
    if (!_currentDrawerWidth.containsKey(page.pageScaffoldId)){
      _currentDrawerWidth[page.pageScaffoldId] = 304;
      _blockNotify = true;
      _updateScaffolds(_previousWidth<ScaffoldFromZero.screenSizeMedium, _previousWidth);
      _blockNotify = false;
    }
    return _currentDrawerWidth[page.pageScaffoldId];
  }
  bool _blockNotify = false;
  setCurrentDrawerWidth(PageFromZero page, double value) {
    _currentDrawerWidth[page.pageScaffoldId] = value;
    if (!_blockNotify) notifyListeners();
  }

  int _animationType = ScaffoldFromZero.animationTypeOther;
  int get animationType => _animationType;
  set animationType(int value) {
    _animationType = value;
    notifyListeners();
  }

  List<PageFromZero> _pagesStack = [];
  List<PageFromZero> get pagesStack => _pagesStack;
  void pushPageToStack (PageFromZero page){
    _pagesStack.add(page);
  }
  void popPageFromStack (PageFromZero page){
    _pagesStack.removeWhere((element) => element.randomId==page.randomId);
  }

  List<ScaffoldFromZero> _scaffoldsStack = [];
  List<ScaffoldFromZero> get scaffoldsStack => _scaffoldsStack;
  void pushScaffoldToStack (ScaffoldFromZero scaffold){
    _scaffoldsStack.add(scaffold);
  }
  void popScaffoldFromStack (ScaffoldFromZero scaffold){
    _scaffoldsStack.removeWhere((element) => element.currentPage.randomId==scaffold.currentPage.randomId);
  }

  double _previousWidth;
  double _previousHeight;
  void _updateScaffolds(bool displayMobileLayout, double width){
    for (int i=0; i<scaffoldsStack.length; i++){
      _updateScaffold(i, displayMobileLayout, width);
    }
  }
  void _updateScaffold(int index, bool displayMobileLayout, double width){
    var scaffold = scaffoldsStack[index];
    if (displayMobileLayout || scaffold.drawerContentBuilder==null) {
      setCurrentDrawerWidth(scaffold.currentPage, 0);
    } else if (scaffold.drawerContentBuilder!=null && getCurrentDrawerWidth(scaffold.currentPage) < scaffold.compactDrawerWidth){
      setCurrentDrawerWidth(scaffold.currentPage, scaffold.compactDrawerWidth);
    } else if (_previousWidth!=null && _previousWidth<ScaffoldFromZero.screenSizeLarge && width>=ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(scaffold.currentPage, scaffold.drawerWidth);
    } else if (_previousWidth!=null && _previousWidth>=ScaffoldFromZero.screenSizeLarge && width<ScaffoldFromZero.screenSizeLarge){
      setCurrentDrawerWidth(scaffold.currentPage, scaffold.compactDrawerWidth);
    }
  }

  bool fadeAnim = false;
  bool sharedAnim = false;
  bool titleAnimation = false;
  void updateStackRelatedVariables(){
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
        && !(  (currentScaffold.title.key!=null && previousScaffold.title.key!=null
                && currentScaffold.title.key==previousScaffold.title.key)
            || (currentScaffold.title is Text && previousScaffold.title is Text
                && (currentScaffold.title as Text).data == (previousScaffold.title as Text).data));
  }

}
