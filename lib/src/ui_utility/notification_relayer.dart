import 'package:flutter/material.dart';


class NotificationRelayController {

  bool Function(Notification notification) shouldRelay;

  NotificationRelayController(this.shouldRelay);

  List<Function(Notification notification)> _listeners = [];
  List<Function(Notification notification)> get listeners => _listeners;

  void addListener(Function(Notification notification) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  void removeListener(Function(Notification notification) listener) {
    _listeners.remove(listener);
  }

  bool relayNotification(Notification notification) {
    final shouldNotify = shouldRelay(notification);
    if (shouldNotify) {
      for (final e in _listeners) {
        e(notification);
      }
    }
    return shouldNotify;
  }

}


class NotificationRelayListener extends StatelessWidget {

  final Widget child;
  final NotificationRelayController controller;
  final bool consumeRelayedNotifications;

  const NotificationRelayListener({
    required this.child,
    required this.controller,
    this.consumeRelayedNotifications = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      child: child,
      onNotification: (notification) {
        if (notification is Notification) {
          return consumeRelayedNotifications && controller.relayNotification(notification);
        } else {
          return false;
        }
      },
    );
  }

}


class NotificationRelayer extends StatefulWidget {
  final Widget child;
  final NotificationRelayController controller;

  const NotificationRelayer({
    required this.child,
    required this.controller,
    Key? key,
  }) : super(key: key);
  @override
  _NotificationRelayerState createState() => _NotificationRelayerState();
}
class _NotificationRelayerState extends State<NotificationRelayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_relay);
  }

  @override
  void didUpdateWidget(covariant NotificationRelayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_relay);
      widget.controller.addListener(_relay);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_relay);
  }

  void _relay(Notification notification) {
    notification.dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

