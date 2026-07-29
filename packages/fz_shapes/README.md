# fz_shapes

Custom shape borders and clipping utilities.

- `ExternalRoundedCornersBorder` — a `ShapeBorder` that supports **negative** `BorderRadius` values for outward-rounded corners, with `GradientBorderSide` for gradient-colored borders.
- `ShapeClipper`, `MultiShapeClipper`, `ShapeShadowClipper` — `CustomClipper` utilities for clip paths.
- `ShapeBorderAndShadowPainter` — `CustomPainter` for drawing shadows and gradient borders for arbitrary shapes.

## Usage

```dart
import 'package:fz_shapes/fz_shapes.dart';

ExternalRoundedCornersBorder(
  borderRadius: BorderRadius.all(Radius.circular(8)),
  borderSide: GradientBorderSide(
    colors: [Colors.red, Colors.blue],
    width: 2,
    angle: 45,
  ),
)
```
