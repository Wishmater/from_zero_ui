# fz_platform

Platform detection and utilities. Provides `PlatformExtended` with web-safe platform checks and download directory utilities.

## Usage

```dart
import 'package:fz_platform/fz_platform.dart';

if (PlatformExtended.isMobile) {
  // iOS or Android
} else if (PlatformExtended.isWindows) {
  // Windows desktop
}

// Override download directory
PlatformExtended.customDownloadsDirectory = '/path/to/downloads';
final dir = await PlatformExtended.getDownloadsDirectory();
```
