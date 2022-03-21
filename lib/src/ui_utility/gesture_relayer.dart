import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


/// Used for relaying scroll gestures to a Scrollable from outside its bounds
/// Could have other applications, but not tested
/// By desgin, only relays to the first Listener found that has the corresponding callback
class GestureRelayController {

  GestureRelayController();

  List<PointerDownEventListener> _onPointerDowns = [];
  List<PointerDownEventListener> get onPointerDowns => _onPointerDowns;
  List<PointerSignalEventListener> _onPointerSignals = [];
  List<PointerSignalEventListener> get onPointerSignals => _onPointerSignals;

  void addOnPointerDown(PointerDownEventListener listener) {
    if (!_onPointerDowns.contains(listener)) {
      _onPointerDowns.add(listener);
    }
  }
  void removeOnPointerDown(PointerDownEventListener listener) {
    _onPointerDowns.remove(listener);
  }
  void relayOnPointerDown(PointerDownEvent event) {
    for (final e in _onPointerDowns) {
      e(event);
    }
  }

  void addOnPointerSignal(PointerSignalEventListener listener) {
    if (!_onPointerSignals.contains(listener)) {
      _onPointerSignals.add(listener);
    }
  }
  void removeOnPointerSignal(PointerSignalEventListener listener) {
    _onPointerSignals.remove(listener);
  }
  void relayOnPointerSignal(PointerSignalEvent event) {
    for (final e in _onPointerSignals) {
      e(event);
    }
  }
  
}

class GestureRelayer extends StatefulWidget {

  final GestureRelayController controller;
  final Widget child;

  const GestureRelayer({
    required this.controller,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<GestureRelayer> createState() => _GestureRelayerState();

}

class _GestureRelayerState extends State<GestureRelayer> {

  @override
  void initState() {
    super.initState();
    widget.controller.addOnPointerDown(_relayOnPointerDown);
    widget.controller.addOnPointerSignal(_relayOnPointerSignal);
  }

  @override
  void didUpdateWidget(covariant GestureRelayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeOnPointerDown(_relayOnPointerDown);
      oldWidget.controller.removeOnPointerSignal(_relayOnPointerSignal);
      widget.controller.addOnPointerDown(_relayOnPointerDown);
      widget.controller.addOnPointerSignal(_relayOnPointerSignal);
    }
  }

  @override
  void dispose() {
    widget.controller.removeOnPointerDown(_relayOnPointerDown);
    widget.controller.removeOnPointerSignal(_relayOnPointerSignal);
    super.dispose();
  }

  void _relayOnPointerDown(PointerDownEvent event) {
    if (mounted) {
      context.visitAncestorElements((element) {
        if (element.widget is Listener) {
          final callback = (element.widget as Listener).onPointerDown;
          if (callback!=null) {
            callback(event);
            return false;
          }
        }
        return true;
      });
    }
  }
  void _relayOnPointerSignal(PointerSignalEvent event) {
    if (mounted) {
      context.visitAncestorElements((element) {
        if (element.widget is Listener) {
          final callback = (element.widget as Listener).onPointerSignal;
          if (callback!=null) {
            callback(event);
            return false;
          }
        }
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

}

class GestureRelayListener extends StatelessWidget {

  final GestureRelayController controller;
  final Widget child;
  final HitTestBehavior behaviour;

  const GestureRelayListener({
    required this.controller,
    required this.child,
    this.behaviour = HitTestBehavior.deferToChild,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behaviour,
      onPointerDown: (event) => controller.relayOnPointerDown(event),
      onPointerSignal: (event) => controller.relayOnPointerSignal(event),
      child: child,
    );
  }

}