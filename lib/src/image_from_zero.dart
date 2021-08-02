import 'package:animations/animations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:extended_image/extended_image.dart';
import 'dart:math';

import 'package:from_zero_ui/src/web_compile_file.dart';


enum FullscreenType {
  none,
  onClick,
  asAction,
  onClickAndAsAction,
}

enum ImageSourceType {
  assets,
  file,
  network,
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
  bool expand;
  ImageSourceType sourceType;

  ImageFromZero({
    required this.url,
    this.actions = const [],
    List<Widget>? fullscreenActions,
    this.fullscreenType = FullscreenType.none,
    this.gesturesEnabled = false,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.retryable = false,
    this.expand = false,
    ImageSourceType? sourceType,
  })  : fullscreenActions = fullscreenActions??actions,
        this.sourceType = sourceType ?? (url.length>=6 && url.substring(0, 6)=="assets" ? ImageSourceType.assets
                                        : url.length>=4 && url.substring(0, 4)=="http" ? ImageSourceType.network
                                        : ImageSourceType.file);

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
              child: SafeArea(
                child: ImageFromZero(
                  url: url,
                  fullscreenType: FullscreenType.none,
                  expand: true,
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
    Widget result;
    // return Image.asset(widget.url);
    if (widget.sourceType==ImageSourceType.assets){
      result = ExtendedImage.asset( //TODO 3 why only this breaks on size change
        widget.url,
        fit: BoxFit.contain,
        enableSlideOutPage: true,
        enableLoadState: false,
        gaplessPlayback: true,
        loadStateChanged: _loadStateChanged,
        mode: widget.gesturesEnabled ? ExtendedImageMode.gesture : ExtendedImageMode.none,
        onDoubleTap: widget.gesturesEnabled ? _onDoubleTap : null,
        extendedImageGestureKey: extendedImageGestureKey,
      );
    } else if (widget.sourceType==ImageSourceType.file) {
      result = ExtendedImage.file(
        getFileCompilingWebAsNull(widget.url)!,
        fit: BoxFit.contain,
        enableSlideOutPage: true,
        loadStateChanged: _loadStateChanged,
        mode: widget.gesturesEnabled ? ExtendedImageMode.gesture : ExtendedImageMode.none,
        onDoubleTap: widget.gesturesEnabled ? _onDoubleTap : null,
        extendedImageGestureKey: extendedImageGestureKey,
      );
    } else {
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
        if (widget.sourceType==ImageSourceType.network) {
          animate = true;
          _controller.reset();
        }
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
        Widget result = state.completedWidget;
        if (widget.fullscreenType==FullscreenType.onClick || widget.fullscreenType==FullscreenType.onClickAndAsAction) {
          result = Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                _pushFullscreen(context);
              },
              child: result,
            ),
          );
        }
        if (widget.expand) {
          result = Positioned.fill(child: result,);
        }
        result = FadeTransition(
          opacity: _animation,
          child: Stack(
            children: [
              result,
              // if (widget.retryable)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxSize = max(constraints.maxHeight, constraints.maxWidth);
                    if (maxSize<128) {
                      return SizedBox.shrink();
                    }
                    return Material(
                      type: MaterialType.transparency,
                      child: Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.all(maxSize<256 ? 0 : 8),
                        child: Column(
                              children: widget.fullscreenType==FullscreenType.asAction
                                  ||widget.fullscreenType==FullscreenType.onClickAndAsAction ? [
                                      IconButtonBackground(
                                        child: IconButton(
                                          icon: Icon(Icons.fullscreen),
                                          tooltip: FromZeroLocalizations.of(context).translate('fullscreen'),
                                          onPressed: () {
                                            _pushFullscreen(context);
                                          },
                                        ),
                                      ),
                                      ...widget.actions,
                                  ] : widget.actions,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        if (widget.expand) {
          result = SizedBox.expand(
            child: result,
          );
        }
        return result;

      case LoadState.failed:
        animate = true;
        _controller.reset();
        print(state.lastException);
        print(state.lastStack);
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

  void _pushFullscreen(BuildContext context) {
    widget.pushFullscreenImage(
      context: context,
      url: widget.url,
      actions: widget.fullscreenActions,
      maxScale: widget.maxScale,
      minScale: widget.minScale,
      retryable: widget.retryable,
      gesturesEnabled: true,
    );
  }

}
