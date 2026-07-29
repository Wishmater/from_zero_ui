# fz_motion_widgets

Animated widget variants using the [motor](https://pub.dev/packages/motor) physics-based animation library.

## Widgets

| Widget | Description |
|---|---|
| `MotionOpacity` | Animated opacity |
| `MotionPadding` | Animated padding |
| `MotionAlign` | Animated alignment + width/height factor |
| `MotionContainer` | Animated Container (alignment, padding, decoration, constraints, margin, transform) |
| `MotionDivider` | Animated Divider / VerticalDivider |
| `MotionPositioned` | Animated Positioned |
| `MotionFractionallySizedBox` | Animated FractionallySizedBox |
| `AnimatedIntrinsicSize` | Animates size changes of child content |

## Usage

```dart
import 'package:fz_motion_widgets/fz_motion_widgets.dart';

MotionContainer(
  motion: MaterialSpringMotion.standardSpatialDefault(),
  padding: EdgeInsets.all(16),
  color: Colors.blue,
  child: Text('Hello'),
)
```
