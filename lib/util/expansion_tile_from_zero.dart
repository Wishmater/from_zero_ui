
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:from_zero_ui/src/ui_components/drawer_menu_from_zero.dart';




const Duration _kExpand = Duration(milliseconds: 200);

/// A single-line [ListTile] with a trailing button that expands or collapses
/// the tile to reveal or hide the [children].
///
/// This widget is typically used with [ListView] to create an
/// "expand / collapse" list entry. When used with scrolling widgets like
/// [ListView], a unique [PageStorageKey] must be specified to enable the
/// [ExpansionTileFromZero] to save and restore its expanded state when it is scrolled
/// in and out of view.
///
/// See also:
///
///  * [ListTile], useful for creating expansion tile [children] when the
///    expansion tile represents a sublist.
///  * The "Expand/collapse" section of
///    <https://material.io/guidelines/components/lists-controls.html>.
class ExpansionTileFromZero extends StatefulWidget {
  /// Creates a single-line [ListTile] with a trailing button that expands or collapses
  /// the tile to reveal or hide the [children]. The [initiallyExpanded] property must
  /// be non-null.
  const ExpansionTileFromZero({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.backgroundColor,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.expanded,
    this.onPostExpansionChanged,
    this.style,
    this.actionPadding = EdgeInsets.zero,
  }) :  assert(
        expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
        'CrossAxisAlignment.baseline is not supported since the expanded children '
            'are aligned in a column, not a row. Try to use another constant.',
        ),
        super(key: key);



  final bool? expanded;
  final void Function(bool)? onPostExpansionChanged;
  final int? style;
  final EdgeInsets actionPadding;

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Called when the tile expands or collapses.
  /// Only if the function returns true will the expansion actually happen
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final FutureOr<bool> Function(bool)? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final List<Widget> children;

  /// The color to display behind the sublist when expanded.
  final Color? backgroundColor;

  /// A widget to display instead of a rotating arrow icon.
  final Widget? trailing;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// Specifies whether the state of the children is maintained when the tile expands and collapses.
  ///
  /// When true, the children are kept in the tree while the tile is collapsed.
  /// When false (default), the children are removed from the tree when the tile is
  /// collapsed and recreated upon expansion.
  final bool maintainState;

  /// Specifies padding for the [ListTile].
  ///
  /// Analogous to [ListTile.contentPadding], this property defines the insets for
  /// the [leading], [title], [subtitle] and [trailing] widgets. It does not inset
  /// the expanded [children] widgets.
  ///
  /// When the value is null, the tile's padding is `EdgeInsets.symmetric(horizontal: 16.0)`.
  final EdgeInsetsGeometry? tilePadding;

  /// Specifies the alignment of [children], which are arranged in a column when
  /// the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and [Align] widget to align the column. The `expandedAlignment`
  /// parameter is passed directly into the [Align].
  ///
  /// Modifying this property controls the alignment of the column within the
  /// expanded tile, not the alignment of [children] widgets within the column.
  /// To align each child within [children], see [expandedCrossAxisAlignment].
  ///
  /// The width of the column is the width of the widest child widget in [children].
  ///
  /// When the value is null, the value of `expandedAlignment` is [Alignment.center].
  final Alignment? expandedAlignment;

  /// Specifies the alignment of each child within [children] when the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and the `crossAxisAlignment` parameter is passed directly into the [Column].
  ///
  /// Modifying this property controls the cross axis alignment of each child
  /// within its [Column]. Note that the width of the [Column] that houses
  /// [children] will be the same as the widest child widget in [children]. It is
  /// not necessarily the width of [Column] is equal to the width of expanded tile.
  ///
  /// To align the [Column] along the expanded tile, use the [expandedAlignment] property
  /// instead.
  ///
  /// When the value is null, the value of `expandedCrossAxisAlignment` is [CrossAxisAlignment.center].
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  /// Specifies padding for [children].
  ///
  /// When the value is null, the value of `childrenPadding` is [EdgeInsets.zero].
  final EdgeInsetsGeometry? childrenPadding;

  @override
  _ExpansionTileFromZeroState createState() => _ExpansionTileFromZeroState();
}

class _ExpansionTileFromZeroState extends State<ExpansionTileFromZero> with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  late Animatable<double> _halfTween;

  final ColorTween _borderColorTween = ColorTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  late Animation<Color> _borderColor;
  late Animation<Color> _headerColor;
  late Animation<Color> _iconColor;
  late Animation<Color> _backgroundColor;

  bool _isExpanded = false;


  @override
  void initState() {
    super.initState();
    _halfTween = widget.style==DrawerMenuFromZero.styleDrawerMenu
        ? Tween<double>(begin: 0.0, end: 0.5)
        : Tween<double>(begin: -0.25, end: 0.0);

    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
    _borderColor = _controller.drive(_borderColorTween.chain(_easeOutTween)) as Animation<Color>;
    _headerColor = _controller.drive(_headerColorTween.chain(_easeInTween)) as Animation<Color>;
    _iconColor = _controller.drive(_iconColorTween.chain(_easeInTween)) as Animation<Color>;
    _backgroundColor = _controller.drive(_backgroundColorTween.chain(_easeOutTween)) as Animation<Color>;

    _isExpanded = widget.expanded ?? (PageStorage.of(context)?.readState(context) ?? widget.initiallyExpanded);
    if (_isExpanded)
      _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(ExpansionTileFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded!=null) {
      setExpanded(widget.expanded!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    if (widget.onExpansionChanged == null){
      setExpanded(!_isExpanded);
    } else{
      if (await widget.onExpansionChanged!(_isExpanded)){
        setExpanded(!_isExpanded);
      }
    }
  }
  void setExpanded(bool expanded, [force=false]) {
//    if (widget.expanded!=null) expanded=widget.expanded;
    if (_isExpanded != expanded){
      setState(() {
        _isExpanded = expanded;
        if (_isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse().then<void>((void value) {
            if (!mounted)
              return;
            setState(() {
              // Rebuild without widget.children.
            });
          });
        }
        PageStorage.of(context)?.writeState(context, _isExpanded);
        widget.onPostExpansionChanged?.call(expanded);
      });
    }
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    // final Color borderSideColor = _borderColor.value;

    return Container(
      // decoration: BoxDecoration(
      //   color: _backgroundColor.value,
      //   border: Border(
      //     top: BorderSide(color: borderSideColor),
      //     bottom: BorderSide(color: borderSideColor),
      //   ),
      // ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
//          ListTileTheme.merge(
//            iconColor: _iconColor.value,
//            textColor: _headerColor.value,
//            child: ListTile(
//              onTap: _handleTap,
//              contentPadding: widget.tilePadding,
//              leading: widget.leading,
//              title: widget.title,
//              dense: true,
//              subtitle: widget.subtitle,
//              trailing: widget.trailing ?? RotationTransition(
//                turns: _iconTurns,
//                child: Icon(Icons.expand_more, color: _iconColor.value,),
//              ),
//            ),
//          ),
          InkWell(
            onTap: _handleTap,
            child: Stack(
              children: [
                widget.title,
                if (!(widget.trailing is SizedBox))
                  Positioned(
                    top: 0, bottom: 0,
                    right: widget.style==DrawerMenuFromZero.styleDrawerMenu ? 4 : null,
                    left: widget.style==DrawerMenuFromZero.styleTree ? 0 : null,
                    child: Padding(
                      padding: widget.actionPadding,
                      child: IconButton(
                        icon: widget.trailing ?? RotationTransition(
                          turns: _iconTurns,
                          child: Icon(Icons.expand_more, color: _iconColor.value, size: 26,),
                        ),
                        iconSize: 26,
                        onPressed: () {
                          setExpanded(!_isExpanded);
                        },
                        splashRadius: 28,
                      ),
                    ),
                  ),
                if (widget.trailing==null && widget.style==DrawerMenuFromZero.styleTree && _isExpanded)
                  Positioned(
                    left: 10, right: 0, bottom: -1, top: -1,
                    child: FractionallySizedBox(
                      heightFactor: 0.5,
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: EdgeInsets.only(top: 8, left: widget.actionPadding.left+10),
                        alignment: Alignment.bottomLeft,
                        child: VerticalDivider(
                          thickness: 2, width: 2,
                          color: Color.alphaBlend(Theme.of(context).dividerColor.withOpacity(Theme.of(context).dividerColor.opacity*3), Material.of(context)!.color!),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ClipRect(
            child: Align(
              alignment: widget.expandedAlignment ?? Alignment.center,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _borderColorTween.end = theme.dividerColor;
    _headerColorTween
      ..begin = theme.textTheme.subtitle1!.color
      ..end = theme.accentColor;
    _iconColorTween
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;
    _backgroundColorTween.end = widget.backgroundColor;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    final bool shouldRemoveChildren = closed && !widget.maintainState;

    final Widget result = Offstage(
        child: TickerMode(
          child: Padding(
            padding: widget.childrenPadding ?? EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: widget.expandedCrossAxisAlignment ?? CrossAxisAlignment.center,
              children: widget.children,
            ),
          ),
          enabled: !closed,
        ),
        offstage: closed
    );

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: shouldRemoveChildren ? null : result,
    );
  }
}