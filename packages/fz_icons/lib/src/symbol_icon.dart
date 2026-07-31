import "package:flutter/material.dart";
import "package:fz_icons/src/text_icon.dart";

enum IconVariation {
  outlined,
  rounded,
  sharp,
}

extension IconDataCopyWith on IconData {
  IconData copyWith({
    int? codePoint,
    String? fontFamily,
    String? fontPackage,
    bool? matchTextDirection,
    List<String>? fontFamilyFallback,
  }) {
    return IconData(
      // ignore: non_const_argument_for_const_parameter
      codePoint ?? this.codePoint,
      // ignore: non_const_argument_for_const_parameter
      fontFamily: fontFamily ?? this.fontFamily,
      // ignore: non_const_argument_for_const_parameter
      fontPackage: fontPackage ?? this.fontPackage,
      matchTextDirection: matchTextDirection ?? this.matchTextDirection,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    );
  }
}

extension SymbolIconData on IconData {
  IconData getVariation(IconVariation variation) {
    switch (variation) {
      case IconVariation.outlined:
        return copyWith(fontFamily: 'MaterialSymbolsOutlined');
      case IconVariation.rounded:
        return copyWith(fontFamily: 'MaterialSymbolsRounded');
      case IconVariation.sharp:
        return copyWith(fontFamily: 'MaterialSymbolsSharp');
    }
  }

  Map<IconVariation, IconData> getVariations() {
    return {
      for (final variation in IconVariation.values) //
        variation: getVariation(variation),
    };
  }
}

/// does a few things that flutter default Icon should do, but it doesn't,
/// especially related to new material Symbols. like setting the appropriate
/// opticalSize
class SymbolIcon extends StatelessWidget {
  // TODO: 2 these should be in theme, so we can react to them?
  static double defaultFlutterFill = 0;
  static double defaultFlutterWeight = 400;
  static IconVariation defaultFlutterVariation = IconVariation.outlined;

  const SymbolIcon(
    this.icon, {
    super.key,
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
    this.blendMode,
    this.fontWeight,
    this.variation,
    this.twoTone,
  });

  final IconData? icon;
  final double? size;
  final double? fill;
  final double? weight;
  final double? grade;
  final double? opticalSize;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final bool? applyTextScaling;
  final BlendMode? blendMode;
  final FontWeight? fontWeight;
  final IconVariation? variation;
  // TODO: 1 maybe this should be a separate widget
  final bool? twoTone;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? TextIcon.getIconEffectiveSize(context);
    final opticalSize = this.opticalSize ?? size.clamp(20, 48);
    final fill = this.fill ?? SymbolIcon.defaultFlutterFill;
    final weight = this.weight ?? SymbolIcon.defaultFlutterWeight;
    var icon = this.icon;
    if (icon != null) {
      icon = icon.getVariation(variation ?? SymbolIcon.defaultFlutterVariation);
    }
    final mainIcon = Icon(
      icon,
      size: size,
      fill: fill,
      weight: weight,
      grade: grade,
      opticalSize: opticalSize,
      color: color,
      shadows: shadows,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      applyTextScaling: applyTextScaling,
      blendMode: blendMode,
      fontWeight: fontWeight,
    );
    // TODO: 1 Implement two-tone icons, requires better color declarations in theme

    // if (!(twoTone ?? mainConfig.theme.iconFlutterTwoTone)) {
    return mainIcon;
    // }
    // return Stack(
    //   fit: StackFit.passthrough,
    //   children: [
    //     Icon(
    //       icon,
    //       size: size,
    //       fill: 1 - fill,
    //       weight: weight,
    //       grade: grade,
    //       opticalSize: opticalSize,
    //       color: mainConfig.theme.errorColor!,
    //       shadows: shadows,
    //       semanticLabel: semanticLabel,
    //       textDirection: textDirection,
    //       applyTextScaling: applyTextScaling,
    //       blendMode: blendMode,
    //       fontWeight: fontWeight,
    //     ),
    //     mainIcon,
    //   ],
    // );
  }
}
