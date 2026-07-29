import "package:flutter/material.dart";
import "package:fz_icons/src/text_icon.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";

/// does a few things that flutter default Icon should do, but it doesn't,
/// especially related to new material Symbols. like setting the appropriate
/// opticalSize
class SymbolIcon extends StatelessWidget {
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
  final bool? twoTone;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? TextIcon.getIconEffectiveSize(context);
    final opticalSize = this.opticalSize ?? size.clamp(20, 48);
    final fill = this.fill ?? SymbolIcon.defaultFlutterFill;
    final weight = this.weight ?? SymbolIcon.defaultFlutterWeight;
    var icon = this.icon;
    if (icon != null && icon is VariedIconData) {
      icon = icon.getVariation(SymbolIcon.defaultFlutterVariation);
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
    // TODO: 1 ICONS Implement two-tone icons, requires better color declarations in theme

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
