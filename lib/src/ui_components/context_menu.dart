import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';

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
    Key? key,
  }) :  super(key: key);

  @override
  State<ContextMenuFromZero> createState() => ContextMenuFromZeroState();

}

class ContextMenuFromZeroState extends State<ContextMenuFromZero> {

  final GlobalKey anchorKey = GlobalKey();

  void showContextMenu(BuildContext context) {
    var actions = widget.actions.where((e) => e.getStateForMaxWidth(0).shownOnContextMenu).toList();
    if (widget.enabled && (widget.contextMenuWidget!=null || actions.isNotEmpty)) {
      widget.onShowMenu?.call();
      Offset? mousePosition = widget.useCursorLocation ? tapDownDetails?.globalPosition : null;
      showPopupFromZero<dynamic>( // TODO 3 find a way to show a non-blocking popup (an overlay)
        context: context,
        anchorKey: mousePosition==null ? anchorKey : null,
        referencePosition: mousePosition,
        referenceSize: mousePosition==null ? null : Size(1, 1),
        width: widget.contextMenuWidth,
        popupAlignment: widget.popupAlignment,
        anchorAlignment: widget.anchorAlignment,
        offsetCorrection: widget.offsetCorrection,
        barrierColor: widget.barrierColor,
        builder: (context) {
          final scrollController = ScrollController();
          if (widget.contextMenuWidget!=null) {
            return widget.contextMenuWidget!;
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
                    onTap: (context) {
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
  }


  void onTapDown(details) => tapDownDetails = details;
  void _showContextMenu() => showContextMenu(context);


  TapDownDetails? tapDownDetails;
  @override
  Widget build(BuildContext context) {
    Widget result = Container(
      key: anchorKey,
      child: widget.child,
    );
    // bool mouseIsConnected = RendererBinding.instance!.mouseTracker.mouseIsConnected; // doesnt work on windows
    if (widget.addGestureDetector) {
      final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};
      gestures[_TransparentTapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<_TransparentTapGestureRecognizer>(
        () => _TransparentTapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = onTapDown
            ..onSecondaryTapDown = onTapDown
            ..onSecondaryTap = _showContextMenu;
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
          showContextMenu(context);
        } : null,
        child: result,
      );
    }
    return result;
  }

}



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
            contextMenuKey.currentState!.showContextMenu(context);
          },
        ),
      ],
    );
  }

}



class _TransparentTapGestureRecognizer extends TapGestureRecognizer {
  _TransparentTapGestureRecognizer({
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