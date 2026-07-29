import "package:flutter/material.dart";

class PopupTooltipFromZero extends StatefulWidget {
  final Widget child;
  final WidgetBuilder tooltipBuilder;
  final Alignment alignment;
  final EdgeInsets padding;
  final Duration? showDelay;
  final bool ignorePointer;

  const PopupTooltipFromZero({
    required this.child,
    required this.tooltipBuilder,
    this.alignment = Alignment.bottomCenter,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.showDelay,
    this.ignorePointer = true,
    super.key,
  });

  @override
  State<PopupTooltipFromZero> createState() => _PopupTooltipFromZeroState();
}

class _PopupTooltipFromZeroState extends State<PopupTooltipFromZero> {
  OverlayEntry? _entry;
  final GlobalKey _childKey = GlobalKey();

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _showTooltip() {
    _removeEntry();
    if (!mounted) return;

    final OverlayState overlayState = Overlay.of(context);
    final RenderBox box = _childKey.currentContext!.findRenderObject()! as RenderBox;
    final Offset childTopLeft = box.localToGlobal(
      Offset.zero,
      ancestor: overlayState.context.findRenderObject(),
    );
    final Size childSize = box.size;

    final tooltipContent = widget.tooltipBuilder(context);

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return _PopupTooltipOverlay(
          childTopLeft: childTopLeft,
          childSize: childSize,
          alignment: widget.alignment,
          padding: widget.padding,
          ignorePointer: widget.ignorePointer,
          onRemove: _removeEntry,
          child: tooltipContent,
        );
      },
    );
    overlayState.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = MouseRegion(
      key: _childKey,
      onEnter: (_) {
        if (widget.showDelay != null) {
          Future.delayed(widget.showDelay!, () {
            if (mounted) {
              _showTooltip();
            }
          });
        } else {
          _showTooltip();
        }
      },
      onExit: (_) {
        _removeEntry();
      },
      child: widget.child,
    );

    return result;
  }
}

class _PopupTooltipOverlay extends StatelessWidget {
  final Offset childTopLeft;
  final Size childSize;
  final Alignment alignment;
  final EdgeInsets padding;
  final bool ignorePointer;
  final Widget child;
  final VoidCallback onRemove;

  const _PopupTooltipOverlay({
    required this.childTopLeft,
    required this.childSize,
    required this.alignment,
    required this.padding,
    required this.ignorePointer,
    required this.child,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          childTopLeft: childTopLeft,
          childSize: childSize,
          alignment: alignment,
          padding: padding,
        ),
        child: MouseRegion(
          onEnter: (_) {},
          onExit: (_) {
            onRemove();
          },
          child: IgnorePointer(
            ignoring: ignorePointer,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  final Offset childTopLeft;
  final Size childSize;
  final Alignment alignment;
  final EdgeInsets padding;

  _TooltipPositionDelegate({
    required this.childTopLeft,
    required this.childSize,
    required this.alignment,
    required this.padding,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x =
        childTopLeft.dx + this.childSize.width * ((alignment.x + 1) / 2) - childSize.width * ((alignment.x + 1) / 2);
    double y =
        childTopLeft.dy + this.childSize.height * ((alignment.y + 1) / 2) - childSize.height * ((alignment.y + 1) / 2);

    // shift by alignment: if bottomCenter, place tooltip below the child
    if (alignment.y > 0) {
      y = childTopLeft.dy + this.childSize.height + padding.top;
    } else if (alignment.y < 0) {
      y = childTopLeft.dy - childSize.height - padding.bottom;
    }

    x = x.clamp(padding.left, size.width - childSize.width - padding.right);
    y = y.clamp(padding.top, size.height - childSize.height - padding.bottom);

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _TooltipPositionDelegate oldDelegate) {
    return childTopLeft != oldDelegate.childTopLeft || childSize != oldDelegate.childSize;
  }
}
