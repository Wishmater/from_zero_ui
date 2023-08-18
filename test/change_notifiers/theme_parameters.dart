import 'package:flutter/material.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';

class ThemeParameters extends ThemeParametersFromZero {

  @override
  ThemeData get defaultDarkTheme => themes[3]!;

  @override
  ThemeData get defaultLightTheme => themes[2]!;

  List<Icon> get themeIcons => [Icon(MaterialCommunityIcons.theme_light_dark), Icon(Icons.check_box_outline_blank), Icon(Icons.wb_sunny), Icon(MaterialCommunityIcons.weather_night),];
  get themeNames => (context) => ["System Theme", "Clear Theme", "Light Theme", "Dark Theme"];
  List<ThemeData?> get themes => [
    null,
    ThemeData( // TODO 3 make static const ThemeData definitions on settings, meant to be used with .copyWith
      useMaterial3: true,
      canvasColor: Colors.grey.shade300,
      primaryColor: Color.fromRGBO(0, 0, 100, 1),
      primaryColorDark: Color.fromRGBO(0, 0, 60, 1),
      primaryColorLight: Color.fromRGBO(0, 0, 140, 1),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: Colors.orangeAccent.shade700,
      ),
      visualDensity: VisualDensity.compact,
      focusColor: Colors.blue.withOpacity(0.1),
      hoverColor: Colors.blue.withOpacity(0.05), // lighter
      highlightColor: Colors.transparent,
      splashColor: Colors.blue.withOpacity(0.1),
      appBarTheme: AppBarTheme(
        color: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.black,
        ),
        iconTheme: IconThemeData(
            color: Colors.black
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.grey.shade700.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
        textStyle: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        // isAlwaysShown: PlatformExtended.isDesktop,
        // showTrackOnHover: true,
        crossAxisMargin: 0,
        mainAxisMargin: 0,
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.dragged)) {
            return Colors.black54;
          }
          if (states.contains(MaterialState.hovered)) {
            return Colors.black45;
          }
          return Colors.black38;
        }),
      ),
    ),
    ThemeData(
      useMaterial3: true,
      canvasColor: Colors.grey.shade300,
      primaryColor: Color.fromRGBO(0, 0, 100, 1),
      primaryColorDark: Color.fromRGBO(0, 0, 60, 1),
      primaryColorLight: Color.fromRGBO(0, 0, 140, 1),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: Colors.orangeAccent.shade700,
      ),
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        color: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.black,
        ),
        iconTheme: IconThemeData(
            color: Colors.black
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.grey.shade700.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
        textStyle: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        // isAlwaysShown: PlatformExtended.isDesktop,
        // showTrackOnHover: true,
        crossAxisMargin: 0,
        mainAxisMargin: 0,
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.dragged)) {
            return Colors.black54;
          }
          if (states.contains(MaterialState.hovered)) {
            return Colors.black45;
          }
          return Colors.black38;
        }),
      ),
    ),
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
      ).copyWith(
        secondary: Colors.orangeAccent.shade700,
      ),
      visualDensity: VisualDensity.compact,
      focusColor: Colors.blue.withOpacity(0.1),
      hoverColor: Colors.blue.withOpacity(0.05),
      highlightColor: Colors.transparent,
      splashColor: Colors.blue.withOpacity(0.1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.all(Radius.circular(999999)),
        ),
        padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
        textStyle: TextStyle(
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        // isAlwaysShown: PlatformExtended.isDesktop,
        // showTrackOnHover: true,
        crossAxisMargin: 0,
        mainAxisMargin: 0,
      ),
    ),
  ];

}