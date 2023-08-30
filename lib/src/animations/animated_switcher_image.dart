import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

import 'package:sliver_tools/sliver_tools.dart';


class _ChildEntry {
  _ChildEntry({
    required this.controller,
    required this.animation,
    required this.transition,
    required this.widgetChild,
  });

  // The animation controller for the child's transition.
  final AnimationController controller;

  // The (curved) animation being used to drive the transition.
  final Animation<double> animation;

  // The currently built transition for this child.
  Widget transition;

  // The widget's child at the time this entry was created or updated.
  // Used to rebuild the transition if necessary.
  Widget widgetChild;

  bool isCurrentEntry = true;
  bool isExecutingImageUpdate = false;
  bool needsImageUpdate = false;

  GlobalKey boundaryKey = GlobalKey();
  Future<ImageProvider?>? imageFuture;
  ImageProvider? image;

  @override
  String toString() => 'Entry#${shortHash(this)}($widgetChild)';
}

typedef AnimatedSwitcherImageLayoutBuilder = Widget Function(Widget? currentChild, List<Widget> previousChildren, Alignment alignment, Clip clipBehaviour);

class AnimatedSwitcherImage extends StatefulWidget {

  const AnimatedSwitcherImage({
    super.key,
    this.child,
    required this.duration,
    this.reverseDuration,
    this.switchInCurve = Curves.easeOutCubic,
    this.switchOutCurve = Curves.easeInCubic,
    this.transitionBuilder = defaultTransitionBuilder,
    this.layoutBuilder = defaultLayoutBuilder,
    this.alignment = Alignment.center,
    this.clipBehaviour = Clip.hardEdge,
    this.takeImages = true,
    this.rebuildOutgoingChildrenIfNoImageReady = false,
  });

  final Widget? child;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve switchInCurve;
  final Curve switchOutCurve;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final AnimatedSwitcherImageLayoutBuilder layoutBuilder;
  final Alignment alignment;
  final Clip clipBehaviour;
  final bool takeImages;
  final bool rebuildOutgoingChildrenIfNoImageReady;

  @override
  State<AnimatedSwitcherImage> createState() => _AnimatedSwitcherImageState();

  static Widget defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
        child: child,
      ),
    );
  }

  static Widget sliverTransitionBuilder(Widget child, Animation<double> animation) {
    return SliverFadeTransition(
      opacity: animation,
      sliver: child,
    );
  }

  static Widget defaultLayoutBuilder(Widget? currentChild, List<Widget> previousChildren, Alignment alignment, Clip clipBehaviour) {
    return Stack(
      alignment: alignment,
      clipBehavior: clipBehaviour,
      children: <Widget>[
        // ...previousChildren,
        ...previousChildren.map((e) {
          return Positioned.fill(
            child: Align(
              alignment: alignment,
              child: e,
            ),
          );
        }),
        if (currentChild != null) currentChild,
      ],
    );
  }

  static Widget sliverLayoutBuilder(Widget? currentChild, List<Widget> previousChildren, Alignment alignment, Clip clipBehaviour) {
    return SliverStack(
      positionedAlignment: alignment,
      children: <Widget>[
        ...previousChildren, // SliverPositioned expects a RenderBox (not a Sliver) so it can't be used
        if (currentChild != null) currentChild,
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
    properties.add(IntProperty('reverseDuration', reverseDuration?.inMilliseconds, unit: 'ms', defaultValue: null));
  }
}

class _AnimatedSwitcherImageState extends State<AnimatedSwitcherImage> with TickerProviderStateMixin {
  _ChildEntry? _currentEntry;
  final Set<_ChildEntry> _outgoingEntries = <_ChildEntry>{};
  List<Widget>? _outgoingWidgets = const <Widget>[];
  int _childNumber = 0;

  @override
  void initState() {
    super.initState();
    _addEntryForNewChild(animate: false);
    _markEntryAsNeedingImageUpdateAfterFrame();
  }

  @override
  void didUpdateWidget(AnimatedSwitcherImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the transition builder changed, then update all of the previous
    // transitions.
    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _outgoingEntries.forEach(_updateTransitionForEntry);
      if (_currentEntry != null) {
        _updateTransitionForEntry(_currentEntry!);
      }
      _markChildWidgetCacheAsDirty();
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _currentEntry != null;
    if (hasNewChild != hasOldChild ||
        hasNewChild && !Widget.canUpdate(widget.child!, _currentEntry!.widgetChild)) {
      // Child has changed, fade current entry out and add new entry.
      _childNumber += 1;
      _addEntryForNewChild(animate: true);
    } else if (_currentEntry != null) {
      assert(hasOldChild && hasNewChild);
      assert(Widget.canUpdate(widget.child!, _currentEntry!.widgetChild));
      // Child has been updated. Make sure we update the child widget and
      // transition in _currentEntry even though we're not going to start a new
      // animation, but keep the key from the previous transition so that we
      // update the transition instead of replacing it.
      _currentEntry!.widgetChild = widget.child!;
      _updateTransitionForEntry(_currentEntry!); // uses entry.widgetChild
      _markChildWidgetCacheAsDirty();
    }
  }

  void _addEntryForNewChild({ required bool animate }) { // does making this async break something
    assert(animate || _currentEntry == null);
    if (_currentEntry != null) {
      assert(animate);
      assert(!_outgoingEntries.contains(_currentEntry));
      _outgoingEntries.add(_currentEntry!);
      _currentEntry!.isCurrentEntry = false;
      _updateTransitionForEntry(_currentEntry!); // neded to rebuild as an image
      _currentEntry!.controller.reverse();
      _markChildWidgetCacheAsDirty();
      _currentEntry = null;
    }
    if (widget.child == null) {
      return;
    }
    final AnimationController controller = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      vsync: this,
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: widget.switchInCurve,
      reverseCurve: widget.switchOutCurve,
    );
    _currentEntry = _newEntry(
      child: widget.child!,
      controller: controller,
      animation: animation,
      builder: widget.transitionBuilder,
    );
    _updateTransitionForEntry(_currentEntry!);
    if (animate) {
      controller.forward();
    } else {
      assert(_outgoingEntries.isEmpty);
      controller.value = 1.0;
    }
  }

  _ChildEntry _newEntry({
    required Widget child,
    required AnimatedSwitcherTransitionBuilder builder,
    required AnimationController controller,
    required Animation<double> animation,
  }) {
    final _ChildEntry entry = _ChildEntry(
      widgetChild: child,
      transition: KeyedSubtree.wrap(builder(child, animation), _childNumber),
      animation: animation,
      controller: controller,
    );
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          assert(mounted);
          assert(_outgoingEntries.contains(entry));
          _outgoingEntries.remove(entry);
          _markChildWidgetCacheAsDirty();
        });
        controller.dispose();
      }
    });
    return entry;
  }

  void _markChildWidgetCacheAsDirty() {
    _outgoingWidgets = null;
  }


  void _markEntryAsNeedingImageUpdateAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted && widget.takeImages) {
        final entry = _currentEntry;
        // print ('AFTER FRAME ${entry.hashCode}');
        if (entry!=null) {
          if (!entry.isExecutingImageUpdate) {
            // print ('AFTER FRAME ${entry.hashCode}: execute update immediately');
            _updateImageForEntry(entry);
          } else {
            // print ('AFTER FRAME ${entry.hashCode}: set needsImageUpdate true');
            entry.needsImageUpdate = true;
          }
        }
        _markEntryAsNeedingImageUpdateAfterFrame();
      }
    });
  }
  void _updateImageForEntry(_ChildEntry entry) async {
    entry.isExecutingImageUpdate = true;
    entry.needsImageUpdate = false;
    final future = _getImageFromEntry(entry);
    entry.imageFuture = future;
    final image = await future;
    if (!mounted) return;
    if (image!=null) {
      // print ('Setting image ${entry.hashCode}');
      await precacheImage(image, context);
      await Future.delayed(const Duration(milliseconds: 1000)); // on success, let app breathe for a while before refreshing
      if (!mounted) return;
      entry.image = image;
    }
    entry.isExecutingImageUpdate = false;
    if (entry.needsImageUpdate) {
      // print ('AFTER _updateImageForEntry: needsImageUpdate is true, re-calling...');
      _updateImageForEntry(entry);
    }
  }
  Future<MemoryImage?> _getImageFromEntry(_ChildEntry entry) async {
    final boundary = entry.boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final layer = boundary?.layer;
    // print ('start getting image ${entry.hashCode} $boundary $layer');
    try {
      if (boundary!=null && layer!=null) {
        final OffsetLayer offsetLayer = layer as OffsetLayer;
        final image = await offsetLayer.toImage(Offset.zero & boundary.size, pixelRatio: 1);
        if (!mounted) return null;
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (!mounted) return null;
        // print ('got byte data ${entry.hashCode} $byteData');
        if (byteData!=null) {
          // print ('got image successfully ${entry.hashCode}');
          return MemoryImage(byteData.buffer.asUint8List());
        }
      }
    } catch(_) {}
    // print ('image returned null ${entry.hashCode}');
    return null;
  }

  void _updateTransitionForEntry(_ChildEntry entry) {
    Widget child;
    if (entry.isCurrentEntry) {
      // print ('build current child ${widget.takeImages}: ${entry.hashCode}');
      if (widget.takeImages) {
        child = RepaintBoundary(
          key: entry.boundaryKey,
          child: entry.widgetChild,
        );
      } else {
        child = entry.widgetChild;
      }
    } else {
      if (entry.imageFuture!=null) {
        // print ('build outgouning child: ${entry.hashCode} IMAGE FUTURE ');
        child = FutureBuilder(
          future: entry.imageFuture,
          initialData: entry.image,
          builder: (context, snapshot) {
            final data = snapshot.data ?? entry.image;
            // print ('build outgouning child ${entry.hashCode}: ${snapshot.data} ${entry.image}');
            if (data!=null) {
              // print ('build outgouning child: ${entry.hashCode} IMAGE SHOWN !!!!!!!!!!!!!!!!!!!!!!!!!!! ');
              return Image(image: data);
            }
            // print ('build outgouning child: ${entry.hashCode} NO IMAGE ');
            return widget.rebuildOutgoingChildrenIfNoImageReady
                ? entry.widgetChild
                : const SizedBox.shrink();
          },
        );
      } else {
        // print ('build outgouning child: ${entry.hashCode} NO IMAGE FUTURE ');
        child = widget.rebuildOutgoingChildrenIfNoImageReady
            ? entry.widgetChild
            : const SizedBox.shrink();
      }
    }
    entry.transition = KeyedSubtree(
      key: entry.transition.key,
      child: widget.transitionBuilder(child, entry.animation),
    );
  }

  void _rebuildOutgoingWidgetsIfNeeded() {
    _outgoingWidgets ??= List<Widget>.unmodifiable(
      _outgoingEntries.map<Widget>((_ChildEntry entry) => entry.transition),
    );
    assert(_outgoingEntries.length == _outgoingWidgets!.length);
    assert(_outgoingEntries.isEmpty || _outgoingEntries.last.transition == _outgoingWidgets!.last);
  }

  @override
  void dispose() {
    if (_currentEntry != null) {
      _currentEntry!.controller.dispose();
    }
    for (final _ChildEntry entry in _outgoingEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _rebuildOutgoingWidgetsIfNeeded();
    return widget.layoutBuilder(
      _currentEntry?.transition,
      _outgoingWidgets!,
      widget.alignment,
      widget.clipBehaviour,
    );
  }
}
