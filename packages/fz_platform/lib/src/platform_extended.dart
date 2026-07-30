import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class PlatformExtended {
  static bool get isWindows {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.windows;
    } else {
      return Platform.isWindows;
    }
  }

  static bool get isAndroid {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android;
    } else {
      return Platform.isAndroid;
    }
  }

  static bool get isIOS {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.iOS;
    } else {
      return Platform.isIOS;
    }
  }

  static bool get isLinux {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.linux;
    } else {
      return Platform.isLinux;
    }
  }

  static bool get isMacOS {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.macOS;
    } else {
      return Platform.isMacOS;
    }
  }

  static bool get isFuchsia {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.fuchsia;
    } else {
      return Platform.isFuchsia;
    }
  }

  static bool get isMobile {
    return PlatformExtended.isAndroid || PlatformExtended.isIOS;
  }

  static bool get isDesktop {
    return !PlatformExtended.isMobile;
  }

  static String? customDownloadsDirectory;
  static Future<Directory> getDownloadsDirectory() async {
    if (customDownloadsDirectory != null) return Directory(customDownloadsDirectory!);
    if (kIsWeb) {
      throw UnimplementedError('Web needs to download through the browser');
    }

    Directory? result;
    if (Platform.isWindows) {
      result = await path_provider.getApplicationDocumentsDirectory();
      if (!(await result.exists())) {
        result = await getDownloadsDirectory();
      }
    } else if (Platform.isAndroid) {
      result = Directory('/storage/emulated/0/Download');
      if (!(await result.exists())) {
        result = await path_provider.getExternalStorageDirectory();
      }
    }

    if (result == null || !(await result.exists())) {
      result = await path_provider.getApplicationDocumentsDirectory();
    }
    return result;
  }
}
