import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ensure_visible_when_focused/ensure_visible_when_focused.dart';

///
/// Helper class that ensures a Widget is visible when it has the focus
/// For example, for a TextFormField when the keyboard is displayed
///
/// How to use it:
///
/// In the class that implements the Form,
///   Instantiate a FocusNode
///   FocusNode _focusNode = new FocusNode();
///
/// In the build(BuildContext context), wrap the TextFormField as follows:
///
///   new EnsureVisibleWhenFocused(
///     focusNode: _focusNode,
///     child: new TextFormField(
///       ...
///       focusNode: _focusNode,
///     ),
///   ),
///
/// Initial source code written by Collin Jackson.
/// Extended (see highlighting) to cover the case when the keyboard is dismissed and the
/// user clicks the TextFormField/TextField which still has the focus.
///
class EnsureVisibleWhenFocused extends StatefulWidget {
  const EnsureVisibleWhenFocused({
    Key? key,
    required this.child,
    required this.focusNode,
    this.curve = Curves.easeOut,
    this.duration = const Duration(milliseconds: 100),
    this.alignmentStart = 0.1,
    this.alignmentEnd = 0.9,
  }) : super(key: key);

  final double alignmentStart;
  final double alignmentEnd;

  /// The node we will monitor to determine if the child is focused
  final FocusNode focusNode;

  /// The child widget that we are wrapping
  final Widget child;

  /// The curve we will use to scroll ourselves into view.
  ///
  /// Defaults to Curves.ease.
  final Curve curve;

  /// The duration we will use to scroll ourselves into view
  ///
  /// Defaults to 100 milliseconds.
  final Duration duration;

  @override
  EnsureVisibleWhenFocusedState createState() =>
      EnsureVisibleWhenFocusedState();
}

///
/// We implement the WidgetsBindingObserver to be notified of any change to the window metrics
///
class EnsureVisibleWhenFocusedState extends State<EnsureVisibleWhenFocused>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_ensureVisible);
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    widget.focusNode.removeListener(_ensureVisible);
    super.dispose();
  }

  ///
  /// This routine is invoked when the window metrics have changed.
  /// This happens when the keyboard is open or dismissed, among others.
  /// It is the opportunity to check if the field has the focus
  /// and to ensure it is fully visible in the viewport when
  /// the keyboard is displayed
  ///
  @override
  void didChangeMetrics() {
    _ensureVisible();
  }

  ///
  /// This routine waits for the keyboard to come into view.
  /// In order to prevent some issues if the Widget is dismissed in the
  /// middle of the loop, we need to check the "mounted" property
  ///
  /// This method was suggested by Peter Yuen (see discussion).
  ///
  Future<void> _keyboardToggled() async {
    if (mounted) {
      final edgeInsets = MediaQuery.of(context).viewInsets;
      while (mounted && MediaQuery.of(context).viewInsets == edgeInsets) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    return;
  }

  Future<void> _ensureVisible() async {

    // Wait for the keyboard to come into view
    // await Future.any([
    //   Future.delayed(const Duration(milliseconds: 300)),
    //   _keyboardToggled()
    // ]);

    // No need to go any further if the node has not the focus
    if (!widget.focusNode.hasFocus) {
      return;
    }

    await ensureVisibleForContext(
      context: context,
      alignmentStart: widget.alignmentStart,
      alignmentEnd: widget.alignmentEnd,
      curve: widget.curve,
      duration: widget.duration,
    );

  }

  static Future<void> ensureVisibleForContext({
    required BuildContext context,
    double alignmentStart = 0.0,
    double alignmentEnd = 1.0,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 100),
  }) async {

    // Find the object which has the focus
    final object = context.findRenderObject()!;
    final viewport = RenderAbstractViewport.of(object);

    // If we are not working in a Scrollable, skip this routine
    if (viewport == null) {
      return;
    }

    // Get the Scrollable state (in order to retrieve its offset)
    final scrollableState = Scrollable.of(context)!;

    await _executeEnsureVisible(
      object: object,
      viewport: viewport,
      scrollableState: scrollableState,
      alignmentStart: alignmentStart,
      alignmentEnd: alignmentEnd,
      curve: curve,
      duration: duration,
    );
    return ensureVisibleForContext(
      context: scrollableState.context,
      curve: curve,
      duration: duration,
      alignmentStart: alignmentStart,
      alignmentEnd: alignmentEnd,
      // alignmentStart: 0.0,
      // alignmentEnd: 1.0, // force hard edge alignment for nested scrollables
    );

  }

  static _executeEnsureVisible({
    required RenderObject object,
    required RenderAbstractViewport viewport,
    required ScrollableState scrollableState,
    double alignmentStart = 0.0,
    double alignmentEnd = 1.0,
    Curve curve = Curves.easeOut,
    Duration duration = const Duration(milliseconds: 100),
  }) async {

    // Get its offset
    final position = scrollableState.position;

    late double alignment;
    final offsetToRevealStart = viewport.getOffsetToReveal(object, alignmentStart).offset + 5;
    final offsetToRevealEnd = viewport.getOffsetToReveal(object, alignmentEnd).offset - 5;
    if (offsetToRevealEnd > offsetToRevealStart) {
      // widget is larger than viewport, do nothing
      return;
    } else if (position.pixels > offsetToRevealStart) {
      // Move down to the top of the viewport
      alignment = alignmentStart;
    } else if (position.pixels < offsetToRevealEnd) {
      // Move up to the bottom of the viewport
      alignment = alignmentEnd;
    } else {
      // No scrolling is necessary to reveal the child
      return;
    }
    return position.ensureVisible(
      object,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
    // viewport.showOnScreen(
    //   descendant: object,
    //   duration: widget.duration,
    //   curve: widget.curve,
    // );

  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
