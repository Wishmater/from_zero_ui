import 'package:dartx/dartx.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';

class ContextMenuFromZero extends ConsumerStatefulWidget {

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
    super.key,
  }) {
    for (int i=0; i<actions.length; i++) {
      if (actions[i].overflowBuilder==ActionFromZero.dividerOverflowBuilder
          && (i==0 || i==actions.lastIndex || actions[i+1].overflowBuilder==ActionFromZero.dividerOverflowBuilder)) {
        actions.removeAt(i); i--;
      }
    }
  }

  @override
  ConsumerState<ContextMenuFromZero> createState() => ContextMenuFromZeroState();

}


class ContextMenuFromZeroState extends ConsumerState<ContextMenuFromZero> {

  final GlobalKey anchorKey = GlobalKey();
  static bool didShowContextMenuThisFrame = false;

  static void showContextMenuFromZero(BuildContext context, WidgetRef ref, {
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
    Offset? mousePosition;
    if (useCursorLocation) {
      if ((ref.read(fromZeroScreenProvider).scale??MediaQuery.textScaleFactorOf(context))==1) {
        mousePosition = tapDownDetails?.globalPosition;
      } else {
        try {
          // hack to support UI scale
          RenderBox box = context.findRenderObject()! as RenderBox;
          final referencePosition = box.localToGlobal(Offset.zero,
            ancestor: context.findAncestorStateOfType<SnackBarHostFromZeroState>()?.context.findRenderObject(),
          ); //this is global position
          mousePosition = tapDownDetails==null ? null : referencePosition + tapDownDetails.localPosition;
        } catch (_) {
          mousePosition = tapDownDetails?.globalPosition;
        }
      }
    }
    showPopupFromZero<dynamic>( // TODO 3 find a way to show a non-blocking popup (an overlay)
      context: context,
      anchorKey: mousePosition==null ? anchorKey : null,
      referencePosition: mousePosition,
      referenceSize: mousePosition==null ? null : const Size(1, 1),
      width: contextMenuWidth,
      popupAlignment: popupAlignment,
      anchorAlignment: anchorAlignment,
      offsetCorrection: offsetCorrection,
      barrierColor: barrierColor,
      builder: (popupContext) {
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (itemContext, index) {
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


  void onTapDown(TapDownDetails details) => tapDownDetails = details;
  void showContextMenu() {
    if (!didShowContextMenuThisFrame) {
      didShowContextMenuThisFrame = true;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        didShowContextMenuThisFrame = false;
      });
      final actions = widget.contextMenuWidget==null ? getAllContextActions() : widget.actions;
      if (widget.enabled && (widget.contextMenuWidget!=null || actions.isNotEmpty)) {
        showContextMenuFromZero(context, ref,
          actions: actions,
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
  }


  List<ActionFromZero> getAllContextActions() {
    final previousContextMenu = context.findAncestorStateOfType<ContextMenuFromZeroState>();
    final result = List<ActionFromZero>.from(widget.actions);
    if (previousContextMenu!=null) {
      final newActions = <ActionFromZero>[];
      for (final e in previousContextMenu.getAllContextActions()) {
        if (!result.any((f) => e.uniqueId==f.uniqueId)) {
          newActions.add(e);
        }
      }
      if (newActions.isNotEmpty) {
        result.add(ActionFromZero.divider());
        result.addAll(newActions);
      }
    }
    return result;
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
              .onTapDown = onTapDown;
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
        onLongPress: PlatformExtended.isMobile ? showContextMenu : null,
        child: result,
      );
    }
    return result;
  }

}



class ContextMenuButton extends StatefulWidget {

  final List<ActionFromZero> actions;
  /// overrides everything else and is used as context menu widget
  final Widget? contextMenuWidget;
  final double contextMenuWidth;
  final Alignment? anchorAlignment;
  final Alignment popupAlignment;
  final Color? barrierColor;
  final bool useCursorLocation;
  final Widget Function(BuildContext context, VoidCallback onTap) buttonBuilder;

  const ContextMenuButton({
    required this.buttonBuilder,
    required this.actions,
    this.contextMenuWidget,
    this.contextMenuWidth = 256,
    this.anchorAlignment,
    this.popupAlignment = Alignment.bottomRight,
    this.barrierColor,
    this.useCursorLocation = false,
    super.key,
  });

  @override
  State<ContextMenuButton> createState() => _ContextMenuButtonState();
}
class _ContextMenuButtonState extends State<ContextMenuButton> {
  final GlobalKey<ContextMenuFromZeroState> contextMenuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ContextMenuFromZero(
            key: contextMenuKey,
            addGestureDetector: false,
            actions: widget.actions,
            contextMenuWidget: widget.contextMenuWidget,
            contextMenuWidth: widget.contextMenuWidth,
            anchorAlignment: widget.anchorAlignment ?? (PlatformExtended.isMobile ? Alignment.topLeft : Alignment.bottomLeft),
            popupAlignment: widget.popupAlignment,
            barrierColor: widget.barrierColor,
            useCursorLocation: widget.useCursorLocation,
            child: Container(),
          ),
        ),
        widget.buttonBuilder(context, () {
          contextMenuKey.currentState!.showContextMenu();
        }),
      ],
    );
  }
}



class TransparentTapGestureRecognizer extends TapGestureRecognizer {
  TransparentTapGestureRecognizer({
    super.debugOwner,
  });

  @override
  void rejectGesture(int pointer) {
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}