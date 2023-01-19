import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';
import 'package:dartx/dartx.dart';

class ContextMenuFromZero extends StatefulWidget {

  final Widget child;
  final List<ActionFromZero> actions;
  /// overrides everything else and is used as context menu widget
  final Widget? contextMenuWidget;
  final double contextMenuWidth;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;
  final Offset offsetCorrection;
  final Color? barrierColor;
  final bool useCursorLocation;
  /// Default true. Set to false so menu will only be shown manually. Useful when stacking with a button.
  final bool addGestureDetector;
  final bool enabled;
  final bool addOnTapDown; /// Default true. This blocks GestureDetectors behind it.
  final VoidCallback? onShowMenu;

  ContextMenuFromZero({
    required this.child,
    this.enabled = true,
    this.contextMenuWidget,
    this.actions = const [],
    this.contextMenuWidth = 256,
    this.anchorAlignment = Alignment.bottomRight,
    this.popupAlignment = Alignment.bottomRight,
    this.offsetCorrection = Offset.zero,
    this.barrierColor,
    this.useCursorLocation = true,
    this.addGestureDetector = true,
    this.onShowMenu,
    this.addOnTapDown = true,
    Key? key,
  }) :  super(key: key) {
    for (int i=0; i<actions.length; i++) {
      if (actions[i].overflowBuilder==ActionFromZero.dividerOverflowBuilder
          && (i==0 || i==actions.lastIndex || actions[i+1].overflowBuilder==ActionFromZero.dividerOverflowBuilder)) {
        actions.removeAt(i); i--;
      }
    }
  }

  @override
  State<ContextMenuFromZero> createState() => ContextMenuFromZeroState();

}

class ContextMenuFromZeroState extends State<ContextMenuFromZero> {

  final GlobalKey anchorKey = GlobalKey();

  static void showContextMenuFromZero(BuildContext context, {
    required List<ActionFromZero> actions,
    required GlobalKey anchorKey,
    VoidCallback? onShowMenu,
    bool useCursorLocation = true,
    TapDownDetails? tapDownDetails,
    Widget? contextMenuWidget,
    double contextMenuWidth = 256,
    Alignment anchorAlignment = Alignment.bottomRight,
    Alignment popupAlignment = Alignment.bottomRight,
    Offset offsetCorrection = Offset.zero,
    Color? barrierColor,
  }) {
    actions = actions.where((e) => e.getStateForMaxWidth(0).shownOnContextMenu).toList();
    onShowMenu?.call();
    Offset? mousePosition = useCursorLocation ? tapDownDetails?.globalPosition : null;
    showPopupFromZero<dynamic>( // TODO 3 find a way to show a non-blocking popup (an overlay)
      context: context,
      anchorKey: mousePosition==null ? anchorKey : null,
      referencePosition: mousePosition,
      referenceSize: mousePosition==null ? null : Size(1, 1),
      width: contextMenuWidth,
      popupAlignment: popupAlignment,
      anchorAlignment: anchorAlignment,
      offsetCorrection: offsetCorrection,
      barrierColor: barrierColor,
      builder: (context) {
        final scrollController = ScrollController();
        if (contextMenuWidget!=null) {
          return contextMenuWidget;
        } else {
          return ScrollbarFromZero(
            controller: scrollController,
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemCount: actions.length,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final action = actions[index];
                return action.copyWith(
                  onTap: action.onTap==null ? null : (context) {
                    Navigator.of(context).pop();
                    action.onTap?.call(context);
                  },
                ).buildOverflow(context, forceIconSpace: actions.where((e) => e.icon!=null).isNotEmpty);
              },
            ),
          );
        }
      },
    );
  }


  void onTapDown(details) => tapDownDetails = details;
  void showContextMenu() {
    if (widget.enabled && (widget.contextMenuWidget!=null || widget.actions.isNotEmpty)) {
      showContextMenuFromZero(context,
        actions: widget.actions,
        anchorKey: anchorKey,
        contextMenuWidth: widget.contextMenuWidth,
        popupAlignment: widget.popupAlignment,
        anchorAlignment: widget.anchorAlignment,
        offsetCorrection: widget.offsetCorrection,
        barrierColor: widget.barrierColor,
        contextMenuWidget: widget.contextMenuWidget,
        onShowMenu: widget.onShowMenu,
        tapDownDetails: tapDownDetails,
        useCursorLocation: widget.useCursorLocation,
      );
    }
  }


  TapDownDetails? tapDownDetails;
  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      key: anchorKey,
      child: widget.child,
    );
    // bool mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected; // doesnt work on windows
    if (widget.addGestureDetector) {
      final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
      gestures[TransparentTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TransparentTapGestureRecognizer>(
        () => TransparentTapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          if (widget.addOnTapDown) {
            instance
              ..onTapDown = onTapDown;
          }
          instance
            ..onSecondaryTapDown = onTapDown
            ..onSecondaryTap = showContextMenu;
        },
      );
      result = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: gestures,
        child: result,
      );
      result = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: PlatformExtended.isMobile ? () {
          showContextMenu();
        } : null,
        child: result,
      );
    }
    return result;
  }

}



class ContextMenuButton extends StatelessWidget {

  final List<ActionFromZero> actions;
  /// overrides everything else and is used as context menu widget
  final Widget? contextMenuWidget;
  final double contextMenuWidth;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;
  final Color? barrierColor;
  final bool useCursorLocation;
  final GlobalKey<ContextMenuFromZeroState> contextMenuKey = GlobalKey();
  final Widget Function(BuildContext context, VoidCallback onTap) buttonBuilder;

  ContextMenuButton({
    Key? key,
    required this.buttonBuilder,
    this.actions = const [],
    this.contextMenuWidget,
    this.contextMenuWidth = 192,
    this.anchorAlignment = Alignment.topLeft,
    this.popupAlignment = Alignment.bottomRight,
    this.barrierColor,
    this.useCursorLocation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ContextMenuFromZero(
            key: contextMenuKey,
            addGestureDetector: false,
            actions: actions,
            contextMenuWidget: contextMenuWidget,
            contextMenuWidth: contextMenuWidth,
            anchorAlignment: anchorAlignment,
            popupAlignment: popupAlignment,
            barrierColor: barrierColor,
            useCursorLocation: useCursorLocation,
            child: Container(),
          ),
        ),
        buttonBuilder(context, () {
          contextMenuKey.currentState!.showContextMenu();
        }),
      ],
    );
  }

}



@deprecated
class ContextMenuIconButton extends StatelessWidget {

  final List<ActionFromZero> actions;
  /// overrides everything else and is used as context menu widget
  final Widget? contextMenuWidget;
  final double contextMenuWidth;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;
  final Color? barrierColor;
  final bool useCursorLocation;
  final GlobalKey<ContextMenuFromZeroState> contextMenuKey = GlobalKey();

  final Widget icon;
  final FocusNode? focusNode;
  final double iconSize;
  final Color? color;
  final Color? splashColor;
  final double? splashRadius;
  final Color? disabledColor;
  final Color? focusColor;
  final Color? highlightColor;
  final Color? hoverColor;

  ContextMenuIconButton({
    this.actions = const [],
    this.contextMenuWidget,
    Key? key,
    required this.icon,
    this.focusNode,
    this.iconSize = 24,
    this.color,
    this.splashColor,
    this.splashRadius,
    this.disabledColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.contextMenuWidth = 192,
    this.anchorAlignment = Alignment.topLeft,
    this.popupAlignment = Alignment.bottomRight,
    this.barrierColor,
    this.useCursorLocation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ContextMenuFromZero(
            key: contextMenuKey,
            addGestureDetector: false,
            actions: actions,
            contextMenuWidget: contextMenuWidget,
            contextMenuWidth: contextMenuWidth,
            anchorAlignment: anchorAlignment,
            popupAlignment: popupAlignment,
            barrierColor: barrierColor,
            useCursorLocation: useCursorLocation,
            child: Container(),
          ),
        ),
        IconButton(
          icon: icon,
          focusNode: focusNode,
          color: color,
          iconSize: iconSize,
          splashColor: splashColor,
          splashRadius: splashRadius,
          disabledColor: disabledColor,
          focusColor: focusColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          onPressed: () {
            contextMenuKey.currentState!.showContextMenu();
          },
        ),
      ],
    );
  }

}



class TransparentTapGestureRecognizer extends TapGestureRecognizer {
  TransparentTapGestureRecognizer({
    Object? debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void rejectGesture(int pointer) {
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}