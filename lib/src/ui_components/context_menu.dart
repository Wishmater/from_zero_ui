import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/appbar_from_zero.dart';
import 'package:from_zero_ui/src/ui_utility/popup_from_zero.dart';

class ContextMenuFromZero extends StatefulWidget {

  final Widget child;
  final List<ActionFromZero>? actions; // TODO 2 rename AppbarAction to ActionFromZero
  /// overrides everything else and is used as context menu widget
  final Widget? contextMenuWidget;
  final double contextMenuWidth;
  final Alignment anchorAlignment;
  final Alignment popupAlignment;
  final Color? barrierColor;
  final bool useCursorLocation;
  /// Default true. Set to false so menu will only be shown manually. Useful when stacking with a button.
  final bool addGestureDetector;
  final bool enabled;

  ContextMenuFromZero({
    required this.child,
    this.enabled = true,
    this.contextMenuWidget,
    this.actions,
    this.contextMenuWidth = 192,
    this.anchorAlignment = Alignment.bottomRight,
    this.popupAlignment = Alignment.bottomRight,
    this.barrierColor,
    this.useCursorLocation = true,
    this.addGestureDetector = true,
    Key? key,
  }) :  assert(actions!=null || contextMenuWidget!=null),
        super(key: key);

  @override
  State<ContextMenuFromZero> createState() => ContextMenuFromZeroState();

}

class ContextMenuFromZeroState extends State<ContextMenuFromZero> {

  final GlobalKey anchorKey = GlobalKey();

  void showContextMenu(BuildContext context) {
    var actions = widget.actions;
    if (widget.contextMenuWidget!=null) {
      actions = widget.actions!.where((e) => e.getStateForMaxWidth(0).shownOnContextMenu).toList();
    }
    if (widget.enabled && (widget.contextMenuWidget!=null || actions!.isNotEmpty)) {
      Offset? mousePosition = widget.useCursorLocation ? tapDownDetails?.globalPosition : null;
      showPopupFromZero<dynamic>( // TODO 3 find a way to show a non-blocking popup (an overlay)
        context: context,
        anchorKey: mousePosition==null ? anchorKey : null,
        referencePosition: mousePosition,
        referenceSize: mousePosition==null ? null : Size(1, 1),
        width: widget.contextMenuWidth,
        popupAlignment: widget.popupAlignment,
        anchorAlignment: widget.anchorAlignment,
        barrierColor: widget.barrierColor,
        builder: (context) {
          return widget.contextMenuWidget ?? ListView.builder(
            shrinkWrap: true,
            itemCount: actions!.length,
            padding: EdgeInsets.symmetric(vertical: 6),
            itemBuilder: (context, index) {
              final action = actions![index];
              return action.copyWith(
                onTap: (context) {
                  Navigator.of(context).pop();
                  action.onTap?.call(context);
                },
              ).buildOverflow(context);
            },
          );
        },
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
    // bool mouseIsConnected = RendererBinding.instance!.mouseTracker.mouseIsConnected; // doesnt work on windows
    if (widget.addGestureDetector) {
      result = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => tapDownDetails = details,
        onSecondaryTapDown: (details) => tapDownDetails = details,
        onLongPress: () {
          if (PlatformExtended.isMobile) {
            showContextMenu(context);
          }
        },
        onSecondaryTap: () => showContextMenu(context),
        child: result,
      );
    }
    return result;
  }

}



class ContextMenuIconButton extends StatelessWidget {

  final List<ActionFromZero>? actions;
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
    this.actions,
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
    return ContextMenuFromZero(
      key: contextMenuKey,
      addGestureDetector: false,
      actions: actions,
      contextMenuWidget: contextMenuWidget,
      contextMenuWidth: contextMenuWidth,
      anchorAlignment: anchorAlignment,
      popupAlignment: popupAlignment,
      barrierColor: barrierColor,
      useCursorLocation: useCursorLocation,
      child: IconButton(
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
    );
  }

}
