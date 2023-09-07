import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/web_compile_file/web_compile_file.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';


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

  final String url;
  final List<Widget> actions;
  final List<Widget> fullscreenActions;
  final FullscreenType fullscreenType;
  final bool gesturesEnabled;
  final double maxScale;
  final double minScale;
  final bool retryable;
  final bool expand;
  final bool renderAsHtmlOnWebToAvoidCors;
  final bool removeHighlightAndHoverFromPicInkWell;
  final bool applySafeAreaToActions;
  final bool fullscreenAsNewTabOnWeb;
  final ImageSourceType sourceType;
  /// this means the image already has a hero with this tag, a hero will not be added to the image if this is not null
  final String? heroTag;

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
    this.renderAsHtmlOnWebToAvoidCors = false,
    this.removeHighlightAndHoverFromPicInkWell = false,
    this.applySafeAreaToActions = false,
    this.heroTag,
    this.fullscreenAsNewTabOnWeb = true,
    ImageSourceType? sourceType,
    super.key,
  })  : fullscreenActions = fullscreenActions??actions,
        sourceType = sourceType ?? (url.length>=6 && url.substring(0, 6)=="assets" ? ImageSourceType.assets
                                        : url.length>=4 && url.substring(0, 4)=="http" ? ImageSourceType.network
                                        : ImageSourceType.file);

  @override
  ImageFromZeroState createState() => ImageFromZeroState();

  void pushFullscreenImage({
    required BuildContext context,
    required String url,
    List<Widget> actions = const [],
    bool gesturesEnabled = true,
    double maxScale = 2.5,
    double minScale = 0.8,
    bool retryable = false,
    bool applySafeAreaToActions = true,
    String? heroTag,
  }) {
    GlobalKey<ExtendedImageSlidePageState> slidePagekey = GlobalKey();
    Navigator.of(context).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ExtendedImageSlidePage(
              key: slidePagekey,
              slidePageBackgroundHandler: (offset, pageSize) {
                return defaultSlidePageBackgroundHandler(
                    offset: offset,
                    pageSize: pageSize,
                    color: Theme.of(context).canvasColor,
                    pageGestureAxis: SlideAxis.both,);
              },
              slideAxis: SlideAxis.both,
              child: ExtendedImageSlidePageHandler(
                heroBuilderForSlidingPage: (Widget result) {
                  return HeroWidget(
                    tag: heroTag ?? url,
                    slideType: SlideType.onlyImage,
                    slidePagekey: slidePagekey,
                    child: result,
                  );
                },
                child: ImageFromZero(
                  url: url,
                  fullscreenType: FullscreenType.none,
                  expand: true,
                  applySafeAreaToActions: applySafeAreaToActions,
                  gesturesEnabled: gesturesEnabled,
                  maxScale: maxScale,
                  minScale: minScale,
                  retryable: retryable,
                  heroTag: heroTag,
                  actions: [
                    TooltipFromZero(
                      message: FromZeroLocalizations.of(context).translate('close'),
                      child: IconButtonBackground(
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

class ImageFromZeroState extends State<ImageFromZero> with TickerProviderStateMixin{

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
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _doubleClickAnimationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this,);
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
    if (widget.sourceType==ImageSourceType.assets){
      // return Image.asset(widget.url);
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
    if (widget.heroTag==null) {
      result = Hero(
        tag: widget.url,
        child: result,
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
                doubleTapPosition: event.position,);
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
        final progress = state.loadingProgress?.expectedTotalBytes==null ? null
            :  state.loadingProgress!.cumulativeBytesLoaded / state.loadingProgress!.expectedTotalBytes!;
        return ApiProviderBuilder.defaultLoadingBuilder(context, ValueNotifier(progress));

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
        if (widget.expand) {
          result = Positioned.fill(child: result,);
        }
        result = FadeTransition(
          opacity: _animation,
          child: Stack(
            children: [
              result,
              if (widget.fullscreenType==FullscreenType.onClick || widget.fullscreenType==FullscreenType.onClickAndAsAction)
                Positioned.fill(
                  child: buildFullScreenLink(
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        highlightColor: widget.removeHighlightAndHoverFromPicInkWell ? Colors.transparent : null,
                        hoverColor: widget.removeHighlightAndHoverFromPicInkWell ? Colors.transparent : null,
                        onTap: () {
                          _pushFullscreen(context);
                        },
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxSize = max(constraints.maxHeight, constraints.maxWidth);
                    if (maxSize<128) {
                      return const SizedBox.shrink();
                    }
                    Widget actions = Column(
                        children: widget.fullscreenType==FullscreenType.asAction
                                    || widget.fullscreenType==FullscreenType.onClickAndAsAction
                            ? [
                              buildFullScreenLink(
                                TooltipFromZero(
                                  message: FromZeroLocalizations.of(context).translate('fullscreen'),
                                  child: IconButtonBackground(
                                    child: IconButton(
                                      icon: const Icon(Icons.fullscreen),
                                      onPressed: () {
                                        _pushFullscreen(context);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              ...widget.actions,
                            ] : widget.actions,
                    );
                    if (widget.applySafeAreaToActions) {
                      actions = SafeArea(
                        child: actions,
                      );
                    }
                    return Material(
                      type: MaterialType.transparency,
                      child: Container(
                        alignment: Alignment.topRight,
                        padding: EdgeInsets.all(maxSize<256 ? 0 : 8),
                        child: actions,
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
        log('Error while loading ImageFromZero:');
        log(state.lastException, stackTrace: state.lastStack);
        return ErrorSign(
          title: FromZeroLocalizations.of(context).translate('error_image'),
          icon: const Icon(Icons.broken_image, size: 64,),
          onRetry: !widget.retryable ? null : () {
            state.reLoadImage();
          },
        );
    }
  }

  Widget buildFullScreenLink(Widget child) {
    if (kIsWeb && widget.fullscreenAsNewTabOnWeb && widget.sourceType==ImageSourceType.network) {
      try {
        return Link(
          uri: Uri.parse(widget.url),
          builder: (context, followLink) => child,
        );
      } catch(_) {}
    }
    return child;
  }

  void _onDoubleTap(ExtendedImageGestureState state) {
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
      state.handleDoubleTap(
          scale: _doubleClickAnimation!.value,
          doubleTapPosition: pointerDownPosition,);
    };
    _doubleClickAnimation = _doubleClickAnimationController
        .drive(Tween<double>(begin: begin, end: end));

    _doubleClickAnimation!
        .addListener(_doubleClickAnimationListener!);

    _doubleClickAnimationController.forward();
  }

  Future<void> _pushFullscreen(BuildContext context) async {
    if (kIsWeb && widget.fullscreenAsNewTabOnWeb && widget.sourceType==ImageSourceType.network && (await canLaunch(widget.url))) {
      launch(widget.url);
    } else {
      widget.pushFullscreenImage(
        context: context,
        url: widget.url,
        actions: widget.fullscreenActions,
        maxScale: widget.maxScale,
        minScale: widget.minScale,
        retryable: widget.retryable,
        gesturesEnabled: true,
        heroTag: widget.heroTag,
      );
    }
  }

}





class HeroWidget extends StatefulWidget {
  const HeroWidget({
    required this.child,
    required this.tag,
    required this.slidePagekey,
    this.slideType = SlideType.onlyImage,
    super.key,
  });
  final Widget child;
  final SlideType slideType;
  final Object tag;
  final GlobalKey<ExtendedImageSlidePageState> slidePagekey;

  @override
  HeroWidgetState createState() => HeroWidgetState();

}

class HeroWidgetState extends State<HeroWidget> {

  late RectTween _rectTween;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.tag,
      createRectTween: (Rect? begin, Rect? end) {
        _rectTween = RectTween(begin: begin, end: end);
        return _rectTween;
      },
      // make hero better when slide out
      flightShuttleBuilder: (BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,) {
        // make hero more smoothly
        final Hero hero = (flightDirection == HeroFlightDirection.pop
            ? fromHeroContext.widget
            : toHeroContext.widget) as Hero;
        if (flightDirection == HeroFlightDirection.pop) {
          final bool fixTransform = widget.slideType == SlideType.onlyImage &&
              (widget.slidePagekey.currentState!.offset != Offset.zero ||
                  widget.slidePagekey.currentState!.scale != 1.0);

          final Widget toHeroWidget = (toHeroContext.widget as Hero).child;
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext buildContext, Widget? child) {
              Widget animatedBuilderChild = hero.child;

              // make hero more smoothly
              animatedBuilderChild = Stack(
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                children: <Widget>[
                  Opacity(
                    opacity: 1 - animation.value,
                    child: UnconstrainedBox(
                      child: SizedBox(
                        width: _rectTween.begin!.width,
                        height: _rectTween.begin!.height,
                        child: toHeroWidget,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: animation.value,
                    child: animatedBuilderChild,
                  ),
                ],
              );

              // fix transform when slide out
              if (fixTransform) {
                final Tween<Offset> offsetTween = Tween<Offset>(
                    begin: Offset.zero,
                    end: widget.slidePagekey.currentState!.offset,);

                final Tween<double> scaleTween = Tween<double>(
                    begin: 1.0, end: widget.slidePagekey.currentState!.scale,);
                animatedBuilderChild = Transform.translate(
                  offset: offsetTween.evaluate(animation),
                  child: Transform.scale(
                    scale: scaleTween.evaluate(animation),
                    child: animatedBuilderChild,
                  ),
                );
              }

              return animatedBuilderChild;
            },
          );
        }
        return hero.child;
      },
      child: widget.child,
    );
  }
}