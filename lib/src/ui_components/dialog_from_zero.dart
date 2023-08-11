import 'dart:io';
import 'dart:ui' as ui;
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';



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



class DialogFromZero extends StatefulWidget {

  final Widget? appBar;
  final Widget content;
  final List<Widget> dialogActions;
  /// if this is passed, we assume scrolling is handled outside
  /// if null, a SingleChildScrollView is built around the content
  final ScrollController? scrollController;
  final bool useReponsiveInsets;
  /// set to false is useful to include AnimatedSwitcher below Dialog
  final bool includeDialogWidget;
  final EdgeInsets contentPadding;
  // TODO 1 add necessary Dialog fields

  const DialogFromZero({
    this.appBar,
    required this.content,
    this.dialogActions = const [],
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.scrollController,
    this.useReponsiveInsets = true,
    this.includeDialogWidget = true,
    super.key,
  });

  @override
  State<DialogFromZero> createState() => _DialogFromZeroState();

}

class _DialogFromZeroState extends State<DialogFromZero> {

  late final appBarSizeNotifier = ValueNotifier<Size>(Size(0, widget.appBar==null ? 0 : 56));
  late final actionsSizeNotifier = ValueNotifier<Size>(Size(0, widget.dialogActions.isEmpty ? 0 : 61));

  @override
  Widget build(BuildContext context) {
    final scrollController = widget.scrollController ?? ScrollController();
    Widget content = Padding(
      padding: widget.contentPadding,
      child: widget.content,
    );
    if (widget.scrollController==null) {
      content = SingleChildScrollView(
        controller: scrollController,
        child: content,
      );
    }
    Widget result = Stack(
      children: [
        MultiValueListenableBuilder(
          valueListenables: [
            appBarSizeNotifier,
            actionsSizeNotifier,
          ],
          builder: (context, values, child) {
            return Padding(
              padding: EdgeInsets.only(
                top: (values[0] as Size).height,
                bottom: (values[1] as Size).height,
              ),
              child: child!,
            );
          },
          child: ScrollbarFromZero(
            controller: scrollController,
            child: content,
          ),
        ),
        if (widget.dialogActions.isNotEmpty)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FillerRelayer(
              notifier: actionsSizeNotifier,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                child: Wrap(
                  runAlignment: WrapAlignment.end,
                  alignment: WrapAlignment.end,
                  children: widget.dialogActions,
                ),
              ),
            ),
          ),
        if (widget.appBar!=null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Theme(
              data: Theme.of(context).copyWith(
                appBarTheme: AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 68,
                ),
              ),
              child: FillerRelayer(
                notifier: appBarSizeNotifier,
                child: widget.appBar!,
              ),
            ),
          ),
      ],
    );
    if (widget.includeDialogWidget) {
      if (widget.useReponsiveInsets) {
        result = ResponsiveInsetsDialog(
          child: result,
        );
      } else {
        result = Dialog(
          child: result,
        );
      }
    }
    result = MediaQuery.removeViewPadding(
      context: context,
      child: result,
    );
    return result;
  }

}



enum DialogButtonType {
  cancel,
  accept,
  other,
}
class DialogButton extends StatelessWidget {

  final DialogButtonType _dialogButtonType;
  final Widget? child;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Color? color;
  final EdgeInsets? padding;
  final FocusNode? focusNode;
  final ButtonStyle? style; /// this overrides color and padding
  final String? tooltip;

  const DialogButton({
    required Widget child, // required non-null child
    required this.onPressed,
    this.leading,
    this.color,
    this.padding,
    this.focusNode,
    this.style,
    this.tooltip,
    super.key,
  })  : this.child = child,
        _dialogButtonType = DialogButtonType.other;

  const DialogButton.cancel({
    this.child,
    this.onPressed,
    this.leading,
    this.color,
    this.padding,
    this.focusNode,
    this.style,
    this.tooltip,
    super.key,
})  : _dialogButtonType = DialogButtonType.cancel;

  const DialogButton.accept({
    this.child,
    required this.onPressed,
    this.leading,
    this.color,
    this.padding,
    this.focusNode,
    this.style,
    this.tooltip,
    super.key,
  })  : _dialogButtonType = DialogButtonType.accept;

  @override
  Widget build(BuildContext context) {
    final child = this.child ?? _defaultChild(context);
    final onPressed = this.onPressed ?? _defaultOnPressed(context);
    Color? color = onPressed==null
        ? Theme.of(context).disabledColor
        : (this.color ?? _defaultColor(context));
    Widget result = TextButton(
      onPressed: onPressed,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child, // TODO 1 add leading
        ),
      ),
      focusNode: focusNode,
      style: this.style ?? TextButton.styleFrom(
        primary: color,
        padding: padding,
      ),
    );
    if (tooltip!=null) {
      result = TooltipFromZero(
        message: tooltip,
        child: result,
      );
    }
    return result;
  }

  Widget _defaultChild(BuildContext context) {
    switch(_dialogButtonType) {
      case DialogButtonType.cancel:
        return Text(FromZeroLocalizations.of(context).translate("cancel_caps"));
      case DialogButtonType.accept:
        return Text(FromZeroLocalizations.of(context).translate("accept_caps"));
      case DialogButtonType.other:
        return Text('???');
    }
  }

  Color? _defaultColor(BuildContext context) {
    switch(_dialogButtonType) {
      case DialogButtonType.cancel:
        return Theme.of(context).textTheme.caption!.color;
      case DialogButtonType.accept:
        return Colors.blue;
      case DialogButtonType.other:
        return null;
    }
  }

  VoidCallback? _defaultOnPressed(BuildContext context) {
    switch(_dialogButtonType) {
      case DialogButtonType.cancel:
        return () {
          Navigator.of(context).pop(null); // Dismiss alert dialog
        };
      case DialogButtonType.accept:
        return null;
      case DialogButtonType.other:
        return null;
    }
  }

}





class RelayedFiller extends StatelessWidget {
  final ValueNotifier<Size?> notifier;
  const RelayedFiller({
    required this.notifier,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Size?>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return SizedBox.fromSize(size: value);
      },
    );
  }
}

class FillerRelayer extends StatelessWidget {
  final ValueNotifier<Size?> notifier;
  final Widget child;
  const FillerRelayer({
    required this.notifier,
    required this.child,
    super.key,
  });
  void _addCallback(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      notifier.value = context.size;
    });
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _addCallback(context);
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            _addCallback(context);
            return false;
          },
          child: child,
        );
      },
    );
  }
}


