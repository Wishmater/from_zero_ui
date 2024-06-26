
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';


/// A material design tooltip.
///
/// Tooltips provide text labels which help explain the function of a button or
/// other user interface action. Wrap the button in a [Tooltip] widget and provide
/// a message which will be shown when the widget is long pressed.
///
/// Many widgets, such as [IconButton], [FloatingActionButton], and
/// [PopupMenuButton] have a `tooltip` property that, when non-null, causes the
/// widget to include a [Tooltip] in its build.
///
/// Tooltips improve the accessibility of visual widgets by proving a textual
/// representation of the widget, which, for example, can be vocalized by a
/// screen reader.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EeEfD5fI-5Q}
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example show a basic [Tooltip] which has a [Text] as child.
/// [message] contains your label to be shown by the tooltip when
/// the child that Tooltip wraps is hovered over on web or desktop. On mobile,
/// the tooltip is shown when the widget is long pressed.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return const TooltipFromZero
///     message: 'I am a Tooltip',
///     child: Text('Hover over the text to show a tooltip.'),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_scaffold_center}
///
/// This example covers most of the attributes available in Tooltip.
/// `decoration` has been used to give a gradient and borderRadius to Tooltip.
/// `height` has been used to set a specific height of the Tooltip.
/// `preferBelow` is false, the tooltip will prefer showing above [Tooltip]'s child widget.
/// However, it may show the tooltip below if there's not enough space
/// above the widget.
/// `textStyle` has been used to set the font size of the 'message'.
/// `showDuration` accepts a Duration to continue showing the message after the long
/// press has been released or the mouse pointer exits the child widget.
/// `waitDuration` accepts a Duration for which a mouse pointer has to hover over the child
/// widget before the tooltip is shown.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return TooltipFromZero
///     message: 'I am a Tooltip',
///     child: const Text('Tap this text and hold down to show a tooltip.'),
///     decoration: BoxDecoration(
///       borderRadius: BorderRadius.circular(25),
///       gradient: const LinearGradient(colors: <Color>[Colors.amber, Colors.red]),
///     ),
///     height: 50,
///     padding: const EdgeInsets.all(8.0),
///     preferBelow: false,
///     textStyle: const TextStyle(
///       fontSize: 24,
///     ),
///     showDuration: const Duration(seconds: 2),
///     waitDuration: const Duration(seconds: 1),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * <https://material.io/design/components/tooltips.html>
///  * [TooltipTheme] or [ThemeData.tooltipTheme]
class TooltipFromZero extends StatefulWidget {
  /// Creates a tooltip.
  ///
  /// By default, tooltips should adhere to the
  /// [Material specification](https://material.io/design/components/tooltips.html#spec).
  /// If the optional constructor parameters are not defined, the values
  /// provided by [TooltipTheme.of] will be used if a [TooltipTheme] is present
  /// or specified in [ThemeData].
  ///
  /// All parameters that are defined in the constructor will
  /// override the default values _and_ the values in [TooltipTheme.of].
  const TooltipFromZero({
    required this.message,
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
    this.child,
    this.triggerMode,
    this.enableFeedback,
    this.maxWidth = 512,
    this.maxHeight = 256,
    super.key,
  });

  /// Null means no max cap on width/height
  final double? maxWidth;
  final double? maxHeight;

  /// The text to display in the tooltip.
  /// If null, tooltip is disabled
  final String? message;

  /// The height of the tooltip's [child].
  ///
  /// If the [child] is null, then this is the tooltip's intrinsic height.
  final double? height;

  /// The amount of space by which to inset the tooltip's [child].
  ///
  /// Defaults to 16.0 logical pixels in each direction.
  final EdgeInsetsGeometry? padding;

  /// The empty space that surrounds the tooltip.
  ///
  /// Defines the tooltip's outer [Container.margin]. By default, a
  /// long tooltip will span the width of its window. If long enough,
  /// a tooltip might also span the window's height. This property allows
  /// one to define how much space the tooltip must be inset from the edges
  /// of their display window.
  ///
  /// If this property is null, then [TooltipThemeData.margin] is used.
  /// If [TooltipThemeData.margin] is also null, the default margin is
  /// 0.0 logical pixels on all sides.
  final EdgeInsetsGeometry? margin;

  /// The vertical gap between the widget and the displayed tooltip.
  ///
  /// When [preferBelow] is set to true and tooltips have sufficient space to
  /// display themselves, this property defines how much vertical space
  /// tooltips will position themselves under their corresponding widgets.
  /// Otherwise, tooltips will position themselves above their corresponding
  /// widgets with the given offset.
  final double? verticalOffset;

  /// Whether the tooltip defaults to being displayed below the widget.
  ///
  /// Defaults to true. If there is insufficient space to display the tooltip in
  /// the preferred direction, the tooltip will be displayed in the opposite
  /// direction.
  final bool? preferBelow;

  /// Whether the tooltip's [message] should be excluded from the semantics
  /// tree.
  ///
  /// Defaults to false. A tooltip will add a [Semantics] label that is set to
  /// [Tooltip.message]. Set this property to true if the app is going to
  /// provide its own custom semantics label.
  final bool? excludeFromSemantics;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// Specifies the tooltip's shape and background color.
  ///
  /// The tooltip shape defaults to a rounded rectangle with a border radius of
  /// 4.0. Tooltips will also default to an opacity of 90% and with the color
  /// [Colors.grey]\[700\] if [ThemeData.brightness] is [Brightness.dark], and
  /// [Colors.white] if it is [Brightness.light].
  final Decoration? decoration;

  /// The style to use for the message of the tooltip.
  ///
  /// If null, the message's [TextStyle] will be determined based on
  /// [ThemeData]. If [ThemeData.brightness] is set to [Brightness.dark],
  /// [TextTheme.bodyMedium] of [ThemeData.textTheme] will be used with
  /// [Colors.white]. Otherwise, if [ThemeData.brightness] is set to
  /// [Brightness.light], [TextTheme.bodyMedium] of [ThemeData.textTheme] will be
  /// used with [Colors.black].
  final TextStyle? textStyle;

  /// The length of time that a pointer must hover over a tooltip's widget
  /// before the tooltip will be shown.
  ///
  /// Defaults to 0 milliseconds (tooltips are shown immediately upon hover).
  final Duration? waitDuration;

  /// The length of time that the tooltip will be shown after a long press
  /// is released or mouse pointer exits the widget.
  ///
  /// Defaults to 1.5 seconds for long press released or 0.1 seconds for mouse
  /// pointer exits the widget.
  final Duration? showDuration;

  /// The [TooltipTriggerMode] that will show the tooltip.
  ///
  /// If this property is null, then [TooltipThemeData.triggerMode] is used.
  /// If [TooltipThemeData.triggerMode] is also null, the default mode is
  /// [TooltipTriggerMode.longPress].
  final TooltipTriggerMode? triggerMode;

  /// Whether the tooltip should provide acoustic and/or haptic feedback.
  ///
  /// For example, on Android a tap will produce a clicking sound and a
  /// long-press will produce a short vibration, when feedback is enabled.
  ///
  /// When null, the default value is true.
  ///
  /// See also:
  ///
  ///  * [Feedback], for providing platform-specific feedback to certain actions.
  final bool? enableFeedback;

  static final Set<_TooltipFromZeroState> _openedToolTips = <_TooltipFromZeroState>{};

  /// Dismiss all of the tooltips that are currently shown on the screen.
  ///
  /// This method returns true if it successfully dismisses the tooltips. It
  /// returns false if there is no tooltip shown on the screen.
  static bool dismissAllToolTips() {
    if (_openedToolTips.isNotEmpty) {
      // Avoid concurrent modification.
      final List<_TooltipFromZeroState> openedToolTips = List<_TooltipFromZeroState>.from(_openedToolTips);
      for (final _TooltipFromZeroState state in openedToolTips) {
        state._hideTooltipFromZero(immediately: true);
      }
      return true;
    }
    return false;
  }

  @override
  State<TooltipFromZero> createState() => _TooltipFromZeroState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message, showName: false));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(FlagProperty('position', value: preferBelow, ifTrue: 'below', ifFalse: 'above', showName: true, defaultValue: null));
    properties.add(FlagProperty('semantics', value: excludeFromSemantics, ifTrue: 'excluded', showName: true, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration, defaultValue: null));
    properties.add(DiagnosticsProperty<TooltipTriggerMode>('triggerMode', triggerMode, defaultValue: null));
    properties.add(FlagProperty('enableFeedback', value: enableFeedback, ifTrue: 'true', showName: true, defaultValue: null));
  }
}

class _TooltipFromZeroState extends State<TooltipFromZero> with SingleTickerProviderStateMixin {
  static const double _defaultVerticalOffset = 24.0;
  static const bool _defaultPreferBelow = true;
  static const EdgeInsetsGeometry _defaultMargin = EdgeInsets.zero;
  static const Duration _fadeInDuration = Duration(milliseconds: 150);
  static const Duration _fadeOutDuration = Duration(milliseconds: 75);
  static const Duration _defaultShowDuration = Duration(milliseconds: 1500);
  static const Duration _defaultHoverShowDuration = Duration.zero;
  static const Duration _defaultWaitDuration = Duration.zero;
  static const Duration _defaultHoverOpaqueDuration = Duration(milliseconds: 2500);
  static const bool _defaultExcludeFromSemantics = false;
  static const TooltipTriggerMode _defaultTriggerMode = TooltipTriggerMode.longPress;
  static const bool _defaultEnableFeedback = true;

  late double height;
  late EdgeInsetsGeometry padding;
  late EdgeInsetsGeometry margin;
  late Decoration decoration;
  late TextStyle textStyle;
  late double verticalOffset;
  late bool preferBelow;
  late bool excludeFromSemantics;
  late AnimationController _controller;
  OverlayEntry? _entry;
  Timer? _hideTimer;
  Timer? _removeAfterHideTimer;
  Timer? _showTimer;
  late Duration showDuration;
  late Duration hoverShowDuration;
  late Duration waitDuration;
  late bool _mouseIsConnected;
  bool _pressActivated = false;
  late TooltipTriggerMode triggerMode;
  late bool enableFeedback;

  @override
  void initState() {
    super.initState();
    _mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    _controller = AnimationController(
      duration: _fadeInDuration,
      reverseDuration: _fadeOutDuration,
      vsync: this,
    )
      ..addStatusListener(_handleStatusChanged);
    // Listen to see when a mouse is added.
    RendererBinding.instance.mouseTracker.addListener(_handleMouseTrackerChange);
    // Listen to global pointer events so that we can hide a tooltip immediately
    // if some other control is clicked on.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  @override
  void didUpdateWidget(covariant TooltipFromZero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_entry!=null && oldWidget.message!=widget.message) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted && _entry!=null) {
          _removeEntry(resetMouseRegionBooleans: false);
          ensureTooltipVisible();
        }
      });
    }
  }

  // https://material.io/components/tooltips#specs
  double _getDefaultTooltipHeight() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 24.0;
      default:
        return 32.0;
    }
  }

  EdgeInsets _getDefaultPadding() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const EdgeInsets.symmetric(horizontal: 8.0);
      default:
        return const EdgeInsets.symmetric(horizontal: 16.0);
    }
  }

  double _getDefaultFontSize() {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return 10.0;
      default:
        return 14.0;
    }
  }

  // Forces a rebuild if a mouse has been added or removed.
  void _handleMouseTrackerChange() {
    if (!mounted) {
      return;
    }
    final bool mouseIsConnected = RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (mouseIsConnected != _mouseIsConnected) {
      if (mounted) {
        setState(() {
          _mouseIsConnected = mouseIsConnected;
        });
      }
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _hideTooltipFromZero(immediately: true);
    }
  }

  void _hideTooltipFromZero({ bool immediately = false }) {
    if (immediately) {
      _removeEntry();
      return;
    } else {
      _showTimer?.cancel();
      _showTimer = null;
      final showDuration = _pressActivated ? this.showDuration : hoverShowDuration;
      _hideTimer ??= Timer(showDuration, () {
        if (mounted) {
          _controller.reverse();
        }
      });
      _removeAfterHideTimer ??= Timer(showDuration+_fadeOutDuration, _removeEntry);
    }
    _pressActivated = false;
  }

  void _showTooltipFromZero({ bool immediately = false }) {
    _hideTimer?.cancel();
    _hideTimer = null;
    _removeAfterHideTimer?.cancel();
    _removeAfterHideTimer = null;
    if (immediately) {
      ensureTooltipVisible();
      return;
    }
    _showTimer ??= Timer(waitDuration, ensureTooltipVisible);
  }

  /// Shows the tooltip if it is not already visible.
  ///
  /// Returns `false` when the tooltip was already visible or if the context has
  /// become null.
  bool ensureTooltipVisible() {
    if (!mounted) return false;
    _showTimer?.cancel();
    _showTimer = null;
    if (_entry != null) {
      // Stop trying to hide, if we were.
      _hideTimer?.cancel();
      _hideTimer = null;
      _removeAfterHideTimer?.cancel();
      _removeAfterHideTimer = null;
      _controller.forward();
      return false; // Already visible.
    }
    _createNewEntry();
    _controller.forward();
    return true;
  }

  Stopwatch? timeSinceCreated;
  void _createNewEntry() {
    if (!mounted || widget.message==null || widget.message!.trim().isEmpty) {
      return;
    }
    final OverlayState overlayState = Overlay.of(
      context,
      debugRequiredFor: widget,
    );

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    timeSinceCreated?.stop();
    timeSinceCreated = Stopwatch()..start();
    // We create this widget outside of the overlay entry's builder to prevent
    // updated values from happening to leak into the overlay when the overlay
    // rebuilds.
    final Widget overlay = Directionality(
      textDirection: Directionality.of(context),
      child: _TooltipOverlay(
        message: widget.message!,
        height: height,
        padding: padding,
        margin: margin,
        onEnter: _mouseIsConnected ? (PointerEnterEvent event) {  // only keep showing on hover if it has been shown for 1 second. Prevents blocking content behind on desktop.
          _insideTooltipMouseRegion = true;
        } : null,
        onExit: _mouseIsConnected ? (PointerExitEvent event) {
          _insideTooltipMouseRegion = false;
          _onExitedMouseRegion();
        } : null,
        onForceExit: _hideTooltipFromZero,
        decoration: decoration,
        textStyle: textStyle,
        animation: CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn,
        ),
        target: target,
        verticalOffset: verticalOffset,
        preferBelow: preferBelow,
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
    );
    _entry = OverlayEntry(builder: (BuildContext context) => overlay);
    overlayState.insert(_entry!);
    SemanticsService.tooltip(widget.message!);
    TooltipFromZero._openedToolTips.add(this);
  }

  void _removeEntry({
    bool resetMouseRegionBooleans = true,
  }) {
    TooltipFromZero._openedToolTips.remove(this);
    _hideTimer?.cancel();
    _hideTimer = null;
    _removeAfterHideTimer?.cancel();
    _removeAfterHideTimer = null;
    _showTimer?.cancel();
    _showTimer = null;
    _entry?.remove();
    _entry = null;
    if (resetMouseRegionBooleans) {
      _insideChildMouseRegion = false;
      _insideTooltipMouseRegion = false;
    }
  }

  bool _insideChildMouseRegion = false;
  bool _insideTooltipMouseRegion = false;
  void _onEnteredMouseRegion() {
    if (_entry==null) {
      _showTooltipFromZero();
    }
  }
  void _onExitedMouseRegion() {
    if (!_insideChildMouseRegion && (!_insideTooltipMouseRegion || timeSinceCreated!.elapsed<_defaultHoverOpaqueDuration)) {
      _hideTooltipFromZero();
    }
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_entry == null) {
      return;
    }
    if (!_insideChildMouseRegion && (!_insideTooltipMouseRegion || timeSinceCreated!.elapsed<_defaultHoverOpaqueDuration)) {
      _hideTooltipFromZero();
    }
  }

  @override
  void deactivate() {
    if (_entry != null) {
      _hideTooltipFromZero(immediately: true);
    }
    _showTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointerEvent);
    RendererBinding.instance.mouseTracker.removeListener(_handleMouseTrackerChange);
    _removeEntry();
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    _pressActivated = true;
    final bool tooltipCreated = ensureTooltipVisible();
    if (tooltipCreated && enableFeedback) {
      if (triggerMode == TooltipTriggerMode.longPress) {
        Feedback.forLongPress(context);
      } else {
        Feedback.forTap(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);
    final TextStyle defaultTextStyle;
    final BoxDecoration defaultDecoration;
    if (theme.brightness == Brightness.dark) {
      defaultTextStyle = theme.textTheme.bodyMedium!.copyWith(
        color: Colors.black,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    } else {
      defaultTextStyle = theme.textTheme.bodyMedium!.copyWith(
        color: Colors.white,
        fontSize: _getDefaultFontSize(),
      );
      defaultDecoration = BoxDecoration(
        color: Colors.grey[700]!.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    }

    height = widget.height ?? tooltipTheme.height ?? _getDefaultTooltipHeight();
    padding = widget.padding ?? tooltipTheme.padding ?? _getDefaultPadding();
    margin = widget.margin ?? tooltipTheme.margin ?? _defaultMargin;
    verticalOffset = widget.verticalOffset ?? tooltipTheme.verticalOffset ?? _defaultVerticalOffset;
    preferBelow = widget.preferBelow ?? tooltipTheme.preferBelow ?? _defaultPreferBelow;
    excludeFromSemantics = widget.excludeFromSemantics ?? tooltipTheme.excludeFromSemantics ?? _defaultExcludeFromSemantics;
    decoration = widget.decoration ?? tooltipTheme.decoration ?? defaultDecoration;
    textStyle = widget.textStyle ?? tooltipTheme.textStyle ?? defaultTextStyle;
    waitDuration = widget.waitDuration ?? tooltipTheme.waitDuration ?? _defaultWaitDuration;
    showDuration = widget.showDuration ?? tooltipTheme.showDuration ?? _defaultShowDuration;
    hoverShowDuration = _defaultHoverShowDuration;
    // triggerMode = widget.triggerMode ?? tooltipTheme.triggerMode ?? _defaultTriggerMode;
    triggerMode = widget.triggerMode ?? (PlatformExtended.isMobile
        ? (tooltipTheme.triggerMode ?? _defaultTriggerMode)
        : TooltipTriggerMode.manual);
    enableFeedback = widget.enableFeedback ?? tooltipTheme.enableFeedback ?? _defaultEnableFeedback;

    Widget result = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: (triggerMode == TooltipTriggerMode.longPress) ?
      _handlePress : null,
      onTap: (triggerMode == TooltipTriggerMode.tap) ? _handlePress : null,
      excludeFromSemantics: true,
      child: Semantics(
        label: excludeFromSemantics ? null : widget.message,
        child: widget.child,
      ),
    );

    // Only check for hovering if there is a mouse connected.
    // This causes children to be rebuilt (and state not kept) if mouse exists/enters de window on desktop
    result = Stack(
      fit: StackFit.passthrough,
      children: [
        result,
        if (_mouseIsConnected)
          Positioned.fill(
            child: MouseRegion(
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (PointerEnterEvent event) {
                _insideChildMouseRegion = true;
                _onEnteredMouseRegion();
              },
              onHover: (PointerHoverEvent event) {
                _insideChildMouseRegion = true;
                // _onEnteredMouseRegion();
              },
              onExit: (PointerExitEvent event) {
                _insideChildMouseRegion = false;
                _onExitedMouseRegion();
              },
              // child: result,
            ),
          ),
      ],
    );

    return result;
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// bellow a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _TooltipPositionDelegate({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  });

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target
        || verticalOffset != oldDelegate.verticalOffset
        || preferBelow != oldDelegate.preferBelow;
  }
}



class _TooltipOverlay extends StatefulWidget {

  const _TooltipOverlay({
    required this.message,
    required this.height,
    required this.animation,
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    this.onEnter,
    this.onExit,
    this.maxWidth,
    this.maxHeight,
    this.onForceExit,
  });

  final String message;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final TextStyle? textStyle;
  final Animation<double> animation;
  final Offset target;
  final double verticalOffset;
  final bool preferBelow;
  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final double? maxWidth;
  final double? maxHeight;
  final VoidCallback? onForceExit;

  @override
  State<_TooltipOverlay> createState() => _TooltipOverlayState();

}

class _TooltipOverlayState extends State<_TooltipOverlay> {

  bool opaque = false;
  bool forceOpaque = false;

  @override
  void initState() {
    super.initState();
    Timer(_TooltipFromZeroState._defaultHoverOpaqueDuration, () {
      if (mounted && !forceOpaque) {
        setState(() {
          opaque = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    Widget result = IgnorePointer(
      ignoring: !opaque,
      child: GestureDetector(
        onTapDown: (details) {
          setState(() {
            forceOpaque = true;
            opaque = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            widget.onForceExit?.call();
          });
        },
        child: FadeTransition(
          opacity: widget.animation,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.height,
              maxWidth: widget.maxWidth ?? double.infinity,
              maxHeight: widget.maxHeight ?? double.infinity,
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: Container(
                decoration: widget.decoration,
                margin: widget.margin,
                clipBehavior: Clip.hardEdge,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: Theme.of(context).scrollbarTheme.copyWith(
                      crossAxisMargin: 4,
                      trackColor: MaterialStateProperty.resolveWith((states) {
                        return widget.textStyle?.color?.withOpacity(0.2);
                      }),
                      thumbColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.dragged)) {
                          return widget.textStyle?.color?.withOpacity(0.6);
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return widget.textStyle?.color?.withOpacity(0.5);
                        }
                        return widget.textStyle?.color?.withOpacity(0.4);
                      }),
                    ),
                  ),
                  child: ScrollbarFromZero(
                    controller: scrollController,

                    child: Container(
                      padding: widget.padding,
                      child: Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            widget.message,
                            style: widget.textStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.onEnter != null || widget.onExit != null) {
      result = MouseRegion(
        opaque: opaque,
        onEnter: widget.onEnter,
        onExit: widget.onExit,
        child: result,
      );
    }
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _TooltipPositionDelegate(
          target: widget.target,
          verticalOffset: widget.verticalOffset,
          preferBelow: widget.preferBelow,
        ),
        child: result,
      ),
    );
  }

}
