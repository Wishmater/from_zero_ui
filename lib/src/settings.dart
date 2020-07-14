import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:from_zero_ui/src/export.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

Future<void> initHive(String subfolder) async{ //TODO 4 remove argument when manual Windows init is no longer needed
  await Hive.initFlutter();
  await Hive.openBox("settings");
}

abstract class AppParametersFromZero extends ChangeNotifier {

  ThemeData get lightTheme => themes[selectedTheme]==null
      || themes[selectedTheme].brightness!=Brightness.light
      ? defaultLightTheme : themes[selectedTheme];
  ThemeData get darkTheme => themes[selectedTheme]==null
      || themes[selectedTheme].brightness!=Brightness.dark
      ? defaultDarkTheme : themes[selectedTheme];
  ThemeMode get themeMode => themes[selectedTheme]==null ?
      ThemeMode.system : themes[selectedTheme].brightness==Brightness.light
      ? ThemeMode.light : ThemeMode.dark;

  ThemeData get defaultLightTheme;
  ThemeData get defaultDarkTheme;

  /// override for custom choices
  List<Icon> get themeIcons => [Icon(MaterialCommunityIcons.theme_light_dark), Icon(Icons.wb_sunny), Icon(MaterialCommunityIcons.weather_night),];
  List<String> get themeNames => ["Por Defecto", "Tema Claro", "Tema Oscuro"]; //TODO 2 internationalize
  List<ThemeData> get themes => [null, defaultLightTheme, defaultDarkTheme];

  int get selectedTheme => Hive.box("settings").get("theme", defaultValue: 0);
  set selectedTheme(int value) {
    Hive.box("settings").put("theme", value);
    notifyListeners();
  }

  //TODO ??? implement UI scale

}

class ThemeSwitcher extends StatelessWidget {

  final AppParametersFromZero themeParameters;

  ThemeSwitcher(this.themeParameters);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton( //TODO 2 generalize THIS into DropdownFromZero, add comodities
      child: ListTile(
        title: Text("Tema de Colores"), //TODO 2 internationalize
        subtitle: Text(themeParameters.themeNames[themeParameters.selectedTheme]),
        leading: themeParameters.themeIcons[themeParameters.selectedTheme],
        trailing: Icon(Icons.arrow_drop_down),
      ),
      itemBuilder: (context) => List.generate(themeParameters.themes.length, (index) => PopupMenuItem(
        value: index,
        child: ListTile(
          title: Text(themeParameters.themeNames[index]),
          leading: themeParameters.themeIcons[index],
          contentPadding: EdgeInsets.all(0),
        ),
      )),
      initialValue: themeParameters.selectedTheme,
      onSelected: (value) => value!=themeParameters.selectedTheme ? themeParameters.selectedTheme = value : null,
    );
  }

}
