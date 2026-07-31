# fz_icons

Icon rendering utilities for Flutter.

- **FzIcon** — multi-source icon resolver that tries direct image data, Flutter icons, XDG/Linux icons, and nerd-font text icons in priority order.
- **SymbolIcon** — enhanced `Icon` wrapper that properly handles material symbols (fill, weight, variation, optical size).
- **TextIcon** — renders a `String` as an icon-sized element, useful for nerd-font icons.
- **ComposedIcon** — stacks a main icon with an optional sub-icon.

## Usage

```dart
import 'package:fz_icons/fz_icons.dart';

FzIcon(
  flutterIcon: Icons.home,
  textIcon: '\u{f015}',
  size: 24,
)
```
