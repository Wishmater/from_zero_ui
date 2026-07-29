import "dart:io";

import "package:dartx/dartx_io.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:fz_icons/src/symbol_icon.dart";
import "package:fz_icons/src/text_icon.dart";
import "package:fz_tooltip/fz_tooltip.dart";
import "package:xdg_icons/xdg_icons.dart";

enum IconType {
  direct, // image data received directly from apps through dbus or other protocols
  flutter, // flutter material icon
  linux, // standard xdg/freedesktop icons read from environmnet
  nerdFont,
}

// TODO: 2 ICONS migrate modules to use FzIcon: nm, tray, notifications
// TODO: 3 is there a way to use nerdFonts from their "class" name, so we can use them for apps, OS, and such dynamically

class FzIcon extends StatelessWidget {
  static bool defaultShowDebugTooltip = false;
  static List<IconType> defaultIconPriority = [
    IconType.flutter,
    IconType.direct,
    IconType.linux,
    IconType.nerdFont,
  ];

  final List<ImageData>? directImageData;
  final IconData? flutterIcon;
  final List<String>? iconNames; // linux
  final String? textIcon; // nerdFont

  /// defaults to to iconPriorities defined in mainConfig
  final List<IconType>? iconPriorities;

  /// defaults to building SizedBox.empty()
  final WidgetBuilder? notFoundBuilder;

  final double? size;
  final Color? color;

  /// specific builders if there is the need to build a more complicated widget for a type
  /// this will override the default widget built from value
  final WidgetBuilder? directBuilder;
  final WidgetBuilder? flutterBuilder;
  final WidgetBuilder? linuxBuilder;
  final WidgetBuilder? textIconBuilder;

  final IconUsageLog? _iconUsageLog;

  const FzIcon({
    this.directImageData,
    this.flutterIcon,
    this.iconNames,
    this.textIcon,
    this.iconPriorities,
    this.notFoundBuilder,
    this.size,
    this.color,
    this.directBuilder,
    this.flutterBuilder,
    this.linuxBuilder,
    this.textIconBuilder,
    super.key,
  }) : _iconUsageLog = null;

  const FzIcon._({
    required this.directImageData,
    required this.flutterIcon,
    required this.iconNames,
    required this.textIcon,
    required this.iconPriorities,
    required this.notFoundBuilder,
    required this.size,
    required this.color,
    required this.directBuilder,
    required this.flutterBuilder,
    required this.linuxBuilder,
    required this.textIconBuilder,
    required IconUsageLog iconUsageLog,
  }) : _iconUsageLog = iconUsageLog;

  @override
  Widget build(BuildContext context) {
    final iconUsageLog = _iconUsageLog ?? IconUsageLog();
    Widget result = buildContent(context, iconUsageLog);
    if (FzIcon.defaultShowDebugTooltip && _iconUsageLog == null) {
      final debugText = buildDebugTooltipText(iconUsageLog);
      if (debugText != null) {
        result = TooltipFromZero(
          message: debugText,
          child: result,
        );
      }
    }
    return result;
  }

  Widget buildContent(BuildContext context, IconUsageLog iconUsageLog) {
    var remainingIconPriorities = iconPriorities ?? FzIcon.defaultIconPriority;
    while (remainingIconPriorities.isNotEmpty) {
      final iconType = remainingIconPriorities.first;
      remainingIconPriorities = remainingIconPriorities.sublist(1);

      switch (iconType) {
        case IconType.direct:
          if (directImageData == null) continue;
          if (directBuilder != null) {
            return directBuilder!(context);
          } else {
            return FzRawIcon(
              directImageData: directImageData!,
              flutterIcon: flutterIcon,
              iconNames: iconNames,
              textIcon: textIcon,
              iconPriorities: remainingIconPriorities,
              notFoundBuilder: notFoundBuilder,
              size: size,
              color: color,
              directBuilder: directBuilder,
              flutterBuilder: flutterBuilder,
              linuxBuilder: linuxBuilder,
              textIconBuilder: textIconBuilder,
              iconUsageLog: iconUsageLog,
            );
          }

        case IconType.flutter:
          if (flutterIcon == null) continue;
          if (flutterBuilder != null) {
            return flutterBuilder!(context);
          } else {
            return SymbolIcon(
              flutterIcon,
              size: size,
              color: color,
            );
          }

        case IconType.linux:
          if (this.iconNames == null) continue;
          final iconNames = this.iconNames!.where((e) => e.isNotEmpty).toList();
          if (iconNames.isEmpty) continue;
          if (linuxBuilder != null) {
            return linuxBuilder!(context);
          } else {
            return _FzXdgIcon(
              directImageData: directImageData,
              flutterIcon: flutterIcon,
              iconNames: iconNames,
              textIcon: textIcon,
              iconPriorities: remainingIconPriorities,
              notFoundBuilder: notFoundBuilder,
              size: size,
              color: color,
              directBuilder: directBuilder,
              flutterBuilder: flutterBuilder,
              linuxBuilder: linuxBuilder,
              textIconBuilder: textIconBuilder,
              iconUsageLog: iconUsageLog,
            );
          }

        case IconType.nerdFont:
          if (textIcon.isNullOrBlank) continue;
          if (textIconBuilder != null) {
            return textIconBuilder!(context);
          } else {
            return _FzTextIcon(
              directImageData: directImageData,
              flutterIcon: flutterIcon,
              iconNames: iconNames,
              textIcon: textIcon!,
              iconPriorities: remainingIconPriorities,
              notFoundBuilder: notFoundBuilder,
              size: size,
              color: color,
              directBuilder: directBuilder,
              flutterBuilder: flutterBuilder,
              linuxBuilder: linuxBuilder,
              textIconBuilder: textIconBuilder,
              iconUsageLog: iconUsageLog,
            );
          }
      }
    }
    return notFoundBuilder?.call(context) ?? SizedBox.shrink();
  }

  String? buildDebugTooltipText(IconUsageLog iconUsageLog) {
    final types = <String>[];
    final priorities = iconPriorities ?? FzIcon.defaultIconPriority;

    IconType? showing;
    for (final iconType in priorities) {
      switch (iconType) {
        case IconType.direct:
          if (directImageData == null || directImageData!.isEmpty) continue;
          types.add('Direct');
          for (final e in directImageData!) {
            final error = iconUsageLog.directImageDataErrors[e];
            if (error != null) {
              types.add('  $e: $error');
            } else if (showing == null) {
              types.add('  $e: SHOWING');
              showing = iconType;
            }
          }
        case IconType.flutter:
          if (flutterIcon == null) continue;
          types.add('Flutter');
          if (showing == null) {
            types.add('  SHOWING');
            showing = iconType;
          }
        case IconType.linux:
          if (iconNames == null || iconNames!.isEmpty) continue;
          types.add('Linux');
          for (final e in iconNames!) {
            final error = iconUsageLog.iconNamesErrors[e];
            if (error != null) {
              types.add('  $e: $error');
            } else if (showing == null) {
              types.add('  $e: SHOWING');
              showing = iconType;
            }
          }
        case IconType.nerdFont:
          if (textIcon == null) continue;
          types.add('Nerd Font');
          final error = iconUsageLog.textIconError;
          if (error != null) {
            types.add('  $textIcon: $error');
          } else if (showing == null) {
            types.add('  $textIcon: SHOWING');
            showing = iconType;
          }
      }
    }
    if (types.isEmpty) return null;
    return 'Icon debug:\n${types.join('\n')}';
  }
}

abstract class ImageData {
  const ImageData();

  Widget build(BuildContext context, FzRawIcon widget);
}

class AbsolutePathFileImageData extends ImageData {
  final String absolutePath;
  const AbsolutePathFileImageData(this.absolutePath);

  @override
  String toString() {
    return "AbsolutePathFileImageData: $absolutePath";
  }

  @override
  Widget build(BuildContext context, FzRawIcon widget) {
    final size = widget.size ?? TextIcon.getIconEffectiveSize(context);
    return Image.file(
      File(absolutePath),
      width: size,
      height: size,
      errorBuilder: (context, e, st) {
        return widget.buildFallback(context, e.toString());
      },
    );
  }
}

class RawImageData extends ImageData {
  // TODO 3: raw image needs some kind of information
  // for the widget to know how to render it
  final Uint8List data;
  RawImageData(List<int> data) : data = data is Uint8List ? data : Uint8List.fromList(data);

  @override
  String toString() {
    return "RawImageData: length = ${data.length}";
  }

  @override
  Widget build(BuildContext context, FzRawIcon widget) {
    final size = widget.size ?? TextIcon.getIconEffectiveSize(context);
    return Image.memory(
      data,
      width: size,
      height: size,
      errorBuilder: (context, e, st) {
        return widget.buildFallback(context, e.toString());
      },
    );
  }
}

class FzRawIcon extends StatelessWidget {
  final List<ImageData> directImageData;
  final IconData? flutterIcon;
  final List<String>? iconNames;
  final String? textIcon;
  final List<IconType> iconPriorities;
  final WidgetBuilder? notFoundBuilder;
  final double? size;
  final Color? color;
  final WidgetBuilder? directBuilder;
  final WidgetBuilder? flutterBuilder;
  final WidgetBuilder? linuxBuilder;
  final WidgetBuilder? textIconBuilder;
  final IconUsageLog iconUsageLog;

  const FzRawIcon({
    required this.directImageData,
    required this.flutterIcon,
    required this.iconNames,
    required this.textIcon,
    required this.iconPriorities,
    required this.notFoundBuilder,
    required this.size,
    required this.color,
    required this.directBuilder,
    required this.flutterBuilder,
    required this.linuxBuilder,
    required this.textIconBuilder,
    required this.iconUsageLog,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return directImageData.first.build(context, this);
  }

  Widget buildFallback(BuildContext context, String error) {
    iconUsageLog.directImageDataErrors[directImageData.first] = error;
    if (directImageData.length > 1) {
      return FzRawIcon(
        directImageData: directImageData.sublist(1),
        flutterIcon: flutterIcon,
        iconNames: iconNames,
        textIcon: textIcon,
        iconPriorities: iconPriorities,
        notFoundBuilder: notFoundBuilder,
        size: size,
        color: color,
        directBuilder: directBuilder,
        flutterBuilder: flutterBuilder,
        linuxBuilder: linuxBuilder,
        textIconBuilder: textIconBuilder,
        iconUsageLog: iconUsageLog,
      );
    } else {
      return FzIcon._(
        directImageData: directImageData,
        flutterIcon: flutterIcon,
        iconNames: iconNames,
        textIcon: textIcon,
        iconPriorities: iconPriorities,
        notFoundBuilder: notFoundBuilder,
        size: size,
        color: color,
        directBuilder: directBuilder,
        flutterBuilder: flutterBuilder,
        linuxBuilder: linuxBuilder,
        textIconBuilder: textIconBuilder,
        iconUsageLog: iconUsageLog,
      );
    }
  }
}

class _FzXdgIcon extends StatelessWidget {
  final List<ImageData>? directImageData;
  final IconData? flutterIcon;
  final List<String> iconNames;
  final String? textIcon;
  final List<IconType> iconPriorities;
  final WidgetBuilder? notFoundBuilder;
  final double? size;
  final Color? color;
  final WidgetBuilder? directBuilder;
  final WidgetBuilder? flutterBuilder;
  final WidgetBuilder? linuxBuilder;
  final WidgetBuilder? textIconBuilder;
  final IconUsageLog iconUsageLog;

  const _FzXdgIcon({
    required this.directImageData,
    required this.flutterIcon,
    required this.iconNames,
    required this.textIcon,
    required this.iconPriorities,
    required this.notFoundBuilder,
    required this.size,
    required this.color,
    required this.directBuilder,
    required this.flutterBuilder,
    required this.linuxBuilder,
    required this.textIconBuilder,
    required this.iconUsageLog,
  });

  @override
  Widget build(BuildContext context) {
    return XdgIcon(
      name: iconNames.first,
      size: size?.round(),
      // color: color,
      iconNotFoundBuilder: () {
        iconUsageLog.iconNamesErrors[iconNames.first] = "Icon not found";
        if (iconNames.length > 1) {
          return _FzXdgIcon(
            directImageData: directImageData,
            flutterIcon: flutterIcon,
            iconNames: iconNames.sublist(1),
            textIcon: textIcon,
            iconPriorities: iconPriorities,
            notFoundBuilder: notFoundBuilder,
            size: size,
            color: color,
            directBuilder: directBuilder,
            flutterBuilder: flutterBuilder,
            linuxBuilder: linuxBuilder,
            textIconBuilder: textIconBuilder,
            iconUsageLog: iconUsageLog,
          );
        } else {
          return FzIcon._(
            directImageData: directImageData,
            flutterIcon: flutterIcon,
            iconNames: iconNames,
            textIcon: textIcon,
            iconPriorities: iconPriorities,
            notFoundBuilder: notFoundBuilder,
            size: size,
            color: color,
            directBuilder: directBuilder,
            flutterBuilder: flutterBuilder,
            linuxBuilder: linuxBuilder,
            textIconBuilder: textIconBuilder,
            iconUsageLog: iconUsageLog,
          );
        }
      },
    );
  }
}

class _FzTextIcon extends StatelessWidget {
  final List<ImageData>? directImageData;
  final IconData? flutterIcon;
  final List<String>? iconNames;
  final String textIcon;
  final List<IconType> iconPriorities;
  final WidgetBuilder? notFoundBuilder;
  final double? size;
  final Color? color;
  final WidgetBuilder? directBuilder;
  final WidgetBuilder? flutterBuilder;
  final WidgetBuilder? linuxBuilder;
  final WidgetBuilder? textIconBuilder;
  final IconUsageLog iconUsageLog;

  const _FzTextIcon({
    required this.directImageData,
    required this.flutterIcon,
    required this.iconNames,
    required this.textIcon,
    required this.iconPriorities,
    required this.notFoundBuilder,
    required this.size,
    required this.color,
    required this.directBuilder,
    required this.flutterBuilder,
    required this.linuxBuilder,
    required this.textIconBuilder,
    required this.iconUsageLog,
  });

  @override
  Widget build(BuildContext context) {
    return TextIcon(
      text: textIcon,
      size: size,
      color: color,
      // // TODO: 2 how to know if textIcon is "not found" (there is no font that can render the glyph)
      //
      // iconNotFoundBuilder: () {
      //   return FzIcon(
      //   );
      // },
    );
  }
}

class IconSpacer extends StatelessWidget {
  final double? size;

  const IconSpacer({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size ?? TextIcon.getIconEffectiveSize(context));
  }
}

class IconUsageLog {
  final Map<ImageData, String> directImageDataErrors = {};
  final Map<String, String> iconNamesErrors = {}; // linux
  String? textIconError; // nerdFont
}
