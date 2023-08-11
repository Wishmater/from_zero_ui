import 'dart:io';
import 'dart:ui' as ui;
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';



Future<T?> showModalFromZero<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  ModalConfiguration? configuration,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  ui.ImageFilter? filter,
  bool? showWindowBarOnDesktop,
}) {
  return showModal<T?>(
    context: context,
    builder: builder,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    filter: filter,
    configuration: configuration ?? FromZeroModalConfiguration(
      showWindowBarOnDesktop: showWindowBarOnDesktop ?? useRootNavigator,
    ),
  );
}
class FromZeroModalConfiguration extends FadeScaleTransitionConfiguration {
  final bool showWindowBarOnDesktop;
  const FromZeroModalConfiguration({
    super.barrierColor = Colors.black54,
    super.barrierDismissible = true,
    super.transitionDuration = const Duration(milliseconds: 150),
    super.reverseTransitionDuration = const Duration(milliseconds: 75),
    super.barrierLabel = 'Dismiss',
    this.showWindowBarOnDesktop = true,
  });
  @override
  Widget transitionBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeUpwardsFadeTransition(
      routeAnimation: animation,
      child: Column(
        children: [
          if (showWindowBarOnDesktop && !kIsWeb
              && Platform.isWindows && windowsDesktopBitsdojoWorking)
            WindowBar(backgroundColor: Theme.of(context).cardColor),
          Expanded(
            child: FadeUpwardsSlideTransition(
              routeAnimation: animation,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}



class DialogFromZero extends StatelessWidget {

  final bool useReponsiveInsets;

  const DialogFromZero({
    super.key,
    this.useReponsiveInsets = true,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

}



class DialogButton extends StatelessWidget {

  final Widget child;
  final VoidCallback onPressed;
  final Widget? leading;
  final Color? color;
  final FocusNode? focusNode;
  final EdgeInsets? padding;
  final ButtonStyle? style; /// this overrides color and padding

  const DialogButton({
    required this.onPressed,
    required this.child,
    this.leading,
    this.color,
    this.padding,
    this.focusNode,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: child, // TODO 1 add leading
      focusNode: focusNode,
      style: color==null&&padding==null
          ? null
          : TextButton.styleFrom(
              primary: color,
              padding: padding,
            ),
    );
  }

}

