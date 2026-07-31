# fz_state_positioning

Utilities for measuring and tracking widget positions, sizes, and layout changes in Flutter. Provides mixins for State classes, notifier-based controllers, and a `RememberMaxSize` widget.

## Usage

```dart
import 'package:fz_state_positioning/fz_state_positioning.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with StatePositioningMixin {
  @override
  Widget build(BuildContext context) {
    final positioning = getPositioning();
    return Container();
  }
}
```
