import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class ImageFromZero extends StatelessWidget {

  static const fullscreenTypeNone = 1000;
  static const fullscreenTypeOnImageClick = 1001;
  static const fullscreenTypeIconButton = 1002;
  static const fullscreenTypeBoth = 1003;


  /*
  TODO: import ExtendedImage in pubspec.yaml
        add a property for gestureType or just enable gesture
        the fullscreen method opens another ImageFromZero with fullscreenTypeNone and gestures enabled
        AnimatedSwitcher over the ExtendedImage loadingStete method key=loadingState
        ImageFromZero has to be stateful for the gesture animations to work
   */

  String url;
  final bool retryable;
  final int fullscreenType;
  final Alignment iconButtonAlignment;
  final bool showLink;
  /// passing this parameters means the image is already inside a Hero widget and will use this same id for the fullscreen dialog
  final String? heroTag;
  final String? errorTitle;
  final String? errorSubtitle;
  final Widget errorIcon;
  final Widget loadingWidget;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;
  final List<Widget> actions;
  // TODO 2 implement download

  ImageFromZero(this.url, {
    this.retryable=true,
    this.showLink=true,
    this.heroTag,
    this.transitionBuilder,
    this.errorIcon = const Icon(Icons.broken_image),
    this.errorTitle,
    this.errorSubtitle,
    this.loadingWidget = const LoadingSign(),
    this.fullscreenType = fullscreenTypeOnImageClick,
    this.iconButtonAlignment = Alignment.topRight,
    this.actions = const [],
  });
        // : this.errorTitle = errorTitle ?? FromZeroLocalizations.of(context).translate("error_image"),
        // this.errorSubtitle = errorSubtitle ?? (retryable ? "Check your connection and try again" : '');

  @override
  Widget build(BuildContext context) {
    return Container();
  }

}

