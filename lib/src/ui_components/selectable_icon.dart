import 'package:flutter/material.dart';

class SelectableIcon extends StatefulWidget {

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final double unselectedOffset;
  final double selectedOffset;
  final Color? unselectedColor;
  final Color? selectedColor;
  final Curve curve;
  final Curve? reverseCurve;
  final double iconSize;

  const SelectableIcon({
    required this.selected,
    this.icon = Icons.expand_more,
    IconData? selectedIcon,
    this.iconSize = 24,
    this.unselectedColor,
    this.selectedColor,
    this.unselectedOffset = 0,
    this.selectedOffset = 0.5,
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeInCubic,
    super.key,
  })  : this.selectedIcon = selectedIcon ?? icon;

  @override
  State<SelectableIcon> createState() => _SelectableIconState();

}

class _SelectableIconState extends State<SelectableIcon> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  CurvedAnimation? _curvedAnimation;
  Animation<double>? _iconTurns;
  Animation<Color?>? _iconColor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _controller.value = widget.selected ? 1 : 0;
  }
  void initCurvedAnimation() {
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
  }
  void initTurnsAnimation() {
    _iconTurns = _curvedAnimation!.drive(Tween<double>(
      begin: widget.unselectedOffset,
      end: widget.selectedOffset,
    ));
  }
  void initColorAnimation() {
    _iconColor = _curvedAnimation!.drive(ColorTween(
      begin: widget.unselectedColor 
          ?? Theme.of(context).textTheme.caption!.color,
      end: widget.selectedColor 
          ?? Theme.of(context).colorScheme.secondary,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SelectableIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.curve!=oldWidget.curve || widget.reverseCurve!=oldWidget.reverseCurve) {
      initCurvedAnimation();
    }
    if (widget.unselectedOffset!=oldWidget.unselectedOffset || widget.selectedOffset!=oldWidget.selectedOffset) {
      initTurnsAnimation();
    }
    if (widget.unselectedColor!=oldWidget.unselectedColor || widget.selectedColor!=oldWidget.selectedColor) {
      initColorAnimation();
    }
    if (widget.selected) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_curvedAnimation==null) {
      initCurvedAnimation();
      initTurnsAnimation();
      initColorAnimation();
    }
    return  RotationTransition(
      turns: _iconTurns!,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _iconColor!,
        builder: (context, child) {
          return Icon(widget.selected ? widget.selectedIcon : widget.icon,
            color: _iconColor!.value,
            size: widget.iconSize,
          );
        },
      ),
    );
  }

}
