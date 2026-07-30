import 'package:bitsdojo_window/bitsdojo_window.dart' as bitsdojo;
import 'package:bitsdojo_window_platform_interface/window.dart' as bitsdojo_window;
import 'package:flutter/foundation.dart';
import 'package:fz_platform/fz_platform.dart';

bool windowsDesktopBitsdojoWorking = true;

abstract class WindowExtended {
  static final _appWindow = kIsWeb || !PlatformExtended.isWindows ? null : bitsdojo.appWindow;
  static bitsdojo_window.DesktopWindow? get appWindow => !windowsDesktopBitsdojoWorking ? null : _appWindow;
}
