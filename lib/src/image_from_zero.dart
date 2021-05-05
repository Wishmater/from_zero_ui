import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:extended_image/extended_image.dart';


enum FullscreenType {
  none,
  onClick,
  asAction,
  onClickAndAsAction,
}

class ImageFromZero extends StatefulWidget {

  String url;
  List<Widget> actions;
  List<Widget> fullscreenActions;
  FullscreenType fullscreenType;
  bool gesturesEnabled;
  double maxScale;
  double minScale;
  bool retryable;

  ImageFromZero({
    required this.url,
    this.actions = const [],
    List<Widget>? fullscreenActions,
    this.fullscreenType = FullscreenType.none,
    this.gesturesEnabled = false,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.retryable = false,
  }) : fullscreenActions = fullscreenActions??actions;

  @override
  _ImageFromZeroState createState() => _ImageFromZeroState();

  void pushFullscreenImage({
    required BuildContext context,
    required String url,
    List<Widget> actions = const [],
    bool gesturesEnabled = true,
    double maxScale = 2.5,
    double minScale = 0.8,
    bool retryable = false,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ZoomedFadeInTransition(
            animation: animation,
            child: ExtendedImageSlidePage(
              slidePageBackgroundHandler: (offset, pageSize) {
                return defaultSlidePageBackgroundHandler(
                    offset: offset,
                    pageSize: pageSize,
                    color: Theme.of(context).canvasColor,
                    pageGestureAxis: SlideAxis.both);
              },
              slideAxis: SlideAxis.both,
              child: ImageFromZero(
                url: url,
                fullscreenType: FullscreenType.none,
                actions: [
                  IconButtonBackground(
                    child: IconButton(
                      icon: Icon(Icons.close),
                      tooltip: FromZeroLocalizations.of(context).translate('close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ...actions
                ],
                gesturesEnabled: gesturesEnabled,
                maxScale: maxScale,
                minScale: minScale,
                retryable: retryable,
              ),
            ),
          );
        },
      ),
    );
  }

}

class _ImageFromZeroState extends State<ImageFromZero> with TickerProviderStateMixin{

  late AnimationController _controller;
  late Animation<double> _animation;
  bool animate = false;
  late AnimationController _doubleClickAnimationController;
  Animation<double>? _doubleClickAnimation;
  VoidCallback? _doubleClickAnimationListener;
  List<double> doubleTapScales = [1.0, 2.0];
  GlobalKey<ExtendedImageGestureState> extendedImageGestureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _doubleClickAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assets = widget.url.length>=6 && widget.url.substring(0, 6)=="assets";
    Widget result;
    if (assets){
      result = ExtendedImage.asset( //TODO 3 why only this breaks on size change
        widget.url,
        fit: BoxFit.contain,
        enableSlideOutPage: true,
        // enableLoadState: false,
        // gaplessPlayback: true,
        loadStateChanged: _loadStateChanged,
        mode: widget.gesturesEnabled ? ExtendedImageMode.gesture : ExtendedImageMode.none,
        onDoubleTap: widget.gesturesEnabled ? _onDoubleTap : null,
        extendedImageGestureKey: extendedImageGestureKey,
      );
    } else{
      result = ExtendedImage.network(
        widget.url,
        fit: BoxFit.contain,
        cache: true,
        enableSlideOutPage: true,
        loadStateChanged: _loadStateChanged,
        mode: widget.gesturesEnabled ? ExtendedImageMode.gesture : ExtendedImageMode.none,
        onDoubleTap: widget.gesturesEnabled ? _onDoubleTap : null,
        extendedImageGestureKey: extendedImageGestureKey,
      );
    }
    if (widget.gesturesEnabled) {
      result = Listener(
        onPointerSignal: (event) {
          if(event is PointerScrollEvent){
            double scale = extendedImageGestureKey.currentState?.gestureDetails?.totalScale ?? 1;
            final mult = -0.002 * (scale*5);
            scale = scale + mult*event.scrollDelta.dy;
            extendedImageGestureKey.currentState!.handleDoubleTap(
                scale: scale,
                doubleTapPosition: event.position);
          }
        },
        child: result,
      );
    }
    return result;
  }

  Widget _loadStateChanged(ExtendedImageState state) {
    switch (state.extendedImageLoadState) {
      case LoadState.loading:
        animate = true;
        _controller.reset();
        return Center(child: CircularProgressIndicator());

    ///if you don't want override completed widget
    ///please return null or state.completedWidget
    //return null;
    //return state.completedWidget;
      case LoadState.completed:
        if (animate){
          animate = false;
          _controller.forward();
        } else{
          _controller.value = 1;
        }
        var stacks = <Widget>[
          Positioned.fill(
            child: state.completedWidget,
          ),
        ];
//        var stacks = <Widget>[
//          Positioned.fill(
//            child: GestureDetector(
//              child: state.completedWidget,
//              onTap: () {
//                Navigator.of(context).push(
//                  TransparentMaterialPageRoute(
//                    builder: (_){
//                      return _getGestureImage(url);
//                    },
//                  ),
//                );
//              },
//            ),
//          ),
//        ];
        if (widget.retryable) {
          stacks.add(Material(
            type: MaterialType.transparency,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 6,
                  right: 6,
                  child: Column(
                    children: widget.fullscreenType==FullscreenType.asAction
                        ||widget.fullscreenType==FullscreenType.onClickAndAsAction ? [
                      IconButtonBackground(
                        child: IconButton(
                          icon: Icon(Icons.fullscreen),
                          tooltip: FromZeroLocalizations.of(context).translate('fullscreen'),
                          onPressed: () {
                            widget.pushFullscreenImage(
                              context: context,
                              url: widget.url,
                              actions: widget.fullscreenActions,
                              maxScale: widget.maxScale,
                              minScale: widget.minScale,
                              retryable: widget.retryable,
                              gesturesEnabled: true,
                            );
                          },
                        ),
                      ),
                      ...widget.actions,
                    ] : widget.actions,
                  ),
                ),
              ],
            ),
          ));
        }
        return FadeTransition(
          opacity: _animation,
          child: SizedBox.expand(
            child: Stack(
              children: stacks,
            ),
          ),
        );

      case LoadState.failed:
        animate = true;
        _controller.reset();
        return ErrorSign(
          title: FromZeroLocalizations.of(context).translate('error_image'),
          icon: Icon(Icons.broken_image, size: 64,),
          onRetry: !widget.retryable ? null : () {
            state.reLoadImage();
          },
        );
    }
  }

  _onDoubleTap(ExtendedImageGestureState state) {
    ///you can use define pointerDownPosition as you can,
    ///default value is double tap pointer down postion.
    final pointerDownPosition = state.pointerDownPosition;
    double? begin = state.gestureDetails?.totalScale;
    double end;

    //remove old
    _doubleClickAnimation
        ?.removeListener(_doubleClickAnimationListener!);

    //stop pre
    _doubleClickAnimationController.stop();

    //reset to use
    _doubleClickAnimationController.reset();

    if (begin == doubleTapScales[0]) {
      end = doubleTapScales[1];
    } else {
      end = doubleTapScales[0];
    }

    _doubleClickAnimationListener = () {
      //print(_animation.value);
      state.handleDoubleTap(
          scale: _doubleClickAnimation!.value,
          doubleTapPosition: pointerDownPosition);
    };
    _doubleClickAnimation = _doubleClickAnimationController
        .drive(Tween<double>(begin: begin, end: end));

    _doubleClickAnimation!
        .addListener(_doubleClickAnimationListener!);

    _doubleClickAnimationController.forward();
  }

}
