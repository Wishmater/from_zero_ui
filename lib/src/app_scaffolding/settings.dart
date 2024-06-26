import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

bool alreadyInitedHive = false;
Future<void> initHive([String? subdir]) async{
  if (!alreadyInitedHive) {
    alreadyInitedHive = true;
    await Hive.initFlutter(subdir);
  }
  if (kIsWeb) {
    await Hive.openBox("settings");
  } else {
    File file = File ('update_temp_args.txt');
    if (file.existsSync()){
      final lines = file.readAsLinesSync();
      file.delete();
      runApp(const LoadingApp());
      doWhenWindowReady(() {
        appWindow.title = "Finishing Update...";
        const initialSize = Size(512, 112);
        appWindow.minSize = initialSize;
        appWindow.size = initialSize;
        appWindow.alignment = Alignment.center;
        appWindow.show();
      });
      await UpdateFromZero.finishUpdate(
        lines[0].replaceAll('%20', ' '),
        lines[1].replaceAll('%20', ' '),);
    } else{
      await Hive.openBox("settings");
    }
  }
}

class ThemeParametersFromZero extends ChangeNotifier {

  ThemeData get lightTheme => themes[selectedTheme]==null
      || themes[selectedTheme]!.brightness!=Brightness.light
      ? defaultLightTheme : themes[selectedTheme]!;
  ThemeData get darkTheme => themes[selectedTheme]==null
      || themes[selectedTheme]!.brightness!=Brightness.dark
      ? defaultDarkTheme : themes[selectedTheme]!;
  ThemeMode get themeMode => themes[selectedTheme]==null ?
      ThemeMode.system : themes[selectedTheme]!.brightness==Brightness.light
      ? ThemeMode.light : ThemeMode.dark;

  ThemeData get defaultLightTheme => ThemeData();
  ThemeData get defaultDarkTheme => ThemeData.dark();

  /// override for custom choices
  List<Widget> get themeIcons => [const Icon(MaterialCommunityIcons.theme_light_dark), const Icon(Icons.wb_sunny), const Icon(MaterialCommunityIcons.weather_night),];
  List<String> Function(BuildContext context) get themeNames =>
          (context) => [
            FromZeroLocalizations.of(context).translate("default_theme"),
            FromZeroLocalizations.of(context).translate("light_theme"),
            FromZeroLocalizations.of(context).translate("dark_theme"),
          ];
  List<ThemeData?> get themes => [null, defaultLightTheme, defaultDarkTheme];

  int get selectedTheme => Hive.box("settings").get("theme", defaultValue: 0);
  set selectedTheme(int value) {
    Hive.box("settings").put("theme", value);
    notifyListeners();
  }


  Locale? get appLocale => supportedLocales[selectedLocale];

  List<Locale?> get supportedLocales => [
    null,
    const Locale('en'),
    const Locale('es'),
  ];
  List<String> Function(BuildContext context) get supportedLocaleTitles =>
          (context) => [
            FromZeroLocalizations.of(context).translate("language_default"),
            "English",
            "Español",
          ];
  List<Widget> get supportedLocaleIcons => supportedLocales.map(
          (e) => e==null ? const Icon(Icons.settings,)
              : TextIcon(e.languageCode),
  ).toList();

  int get selectedLocale => Hive.box("settings").get("locale", defaultValue: 0);
  set selectedLocale(int value) {
    Hive.box("settings").put("locale", value);
    notifyListeners();
  }

  //TODO 2 ??? implement UI scale

}


class FromZeroLocalizations {
  final Locale locale;

  FromZeroLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static FromZeroLocalizations of(BuildContext context) {
    return Localizations.of<FromZeroLocalizations>(context, FromZeroLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<FromZeroLocalizations> delegate = _FromZeroLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    // Load the language JSON file from the "lang" folder
    String jsonString;
    try{
      jsonString = await rootBundle.loadString('packages/from_zero_ui/assets/i18n/${locale.languageCode}.json');

    } catch (_){
      jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    }

    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key]!;
  }
}


class _FromZeroLocalizationsDelegate
    extends LocalizationsDelegate<FromZeroLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _FromZeroLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<FromZeroLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    FromZeroLocalizations localizations = FromZeroLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_FromZeroLocalizationsDelegate old) => false;
}


class ThemeSwitcher extends StatelessWidget {

  final ThemeParametersFromZero themeParameters;

  const ThemeSwitcher(this.themeParameters, {super.key});

  @override
  Widget build(BuildContext context) {
    return ComboFromZero<int>(
      title: FromZeroLocalizations.of(context).translate("theme"),
      value: themeParameters.selectedTheme,
      showSearchBox: false,
      clearable: false,
      popupRowHeight: 48,
      possibleValues: List.generate(themeParameters.themes.length, (index)=>index),
      onSelected: (int? value) {
        if (value!=null && value!=themeParameters.selectedTheme) {
          themeParameters.selectedTheme = value;
        }
        return true;
      },
      buttonChildBuilder: (context, title, hint, value, enabled, clearable, {showDropdownIcon=false}) {
        return IconTheme(
          data: Theme.of(context).iconTheme,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 6,),
                themeParameters.themeIcons[themeParameters.selectedTheme],
                const SizedBox(width: 12,),
                Expanded(
                  child: MaterialKeyValuePair(
                    title: title,
                    value: themeParameters.themeNames(context)[themeParameters.selectedTheme],
                    valueStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 4,),
                // Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyLarge!.color,),
                // const SizedBox(width: 4,),
              ],
            ),
          ),
        );
      },
      popupWidgetBuilder: (value) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 4,),
            themeParameters.themeIcons[value],
            const SizedBox(width: 12,),
            Expanded(
              child: Text(themeParameters.themeNames(context)[value],
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        );
      },
    );
  }

}


class UiScalePicker extends ConsumerStatefulWidget {

  const UiScalePicker({
    super.key,
  });

  @override
  ConsumerState<UiScalePicker> createState() => _UiScalePickerState();

}
class _UiScalePickerState extends ConsumerState<UiScalePicker> {

  double? value;

  @override
  void initState() {
    super.initState();
    value = Hive.box('settings').get('ui_scale');
  }

  @override
  Widget build(BuildContext context) {
    final defaultValue = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Transform.translate(
            offset: const Offset(0, 8),
            child: Text('Zoom',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: CheckboxListTile(
                value: value==null,
                dense: true,
                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                controlAffinity: ListTileControlAffinity.leading,
                title: Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Text('Por Defecto',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    this.value = (value??false) ? null : defaultValue;
                    commitValue();
                  });
                },
              ),
            ),
            Expanded(
              child: TooltipFromZero(
                waitDuration: value==null ? Duration.zero : const Duration(seconds: 1),
                message: value==null
                    ? 'Zoom por defecto del sistema operativo: ${NumberFormat('0.00').format(defaultValue)}\nPara cambiar el zoom manualmente desmarque "Por Defecto"'
                    : null, // 'Zoom: ${NumberFormat('0.00').format(value)}',
                child: Stack(
                  children: [
                    Positioned.fill(
                      left: 6, right: 6,
                      child: Center(
                        child: Container(
                          width: double.infinity, height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                    ),
                    Slider(
                      value: value ?? MediaQuery.textScaleFactorOf(context).clamp(1, 1.5),
                      min: 1,
                      max: 1.5,
                      divisions: 10,
                      label: value==null ? null : 'Zoom: ${NumberFormat('0.00').format(value)}',
                      onChanged: value==null ? null : (value) {
                        setState(() {
                          this.value = value;
                        });
                      },
                      onChangeEnd: (value) {
                        commitValue();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12,),
          ],
        ),
      ],
    );
  }

  void commitValue() {
    Hive.box('settings').put('ui_scale', value);
    ref.read(fromZeroScreenProvider).scale = value;
  }

}



class LocaleSwitcher extends StatelessWidget {

  final ThemeParametersFromZero themeParameters;

  const LocaleSwitcher(this.themeParameters, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => List.generate(themeParameters.supportedLocales.length, (index) => PopupMenuItem(
        value: index,
        child: ListTile(
          title: Text(themeParameters.supportedLocaleTitles(context)[index]),
          leading: themeParameters.supportedLocaleIcons[index],
          contentPadding: EdgeInsets.zero,
        ),
      ),),
      initialValue: themeParameters.selectedLocale,
      onSelected: (int value) => value!=themeParameters.selectedLocale ? themeParameters.selectedLocale = value : null,
      child: ListTile(
        title: Text(FromZeroLocalizations.of(context).translate("language")),
        subtitle: Text(themeParameters.supportedLocaleTitles(context)[themeParameters.selectedLocale]),
        leading: themeParameters.supportedLocaleIcons[themeParameters.selectedLocale],
        trailing: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

}




















class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Finishing Update...",
      builder: (context, child) {
        return Container(
          color: Colors.white,
          alignment: Alignment.center,
//                child: Row(
//                  mainAxisAlignment: MainAxisAlignment.center,
//                  children: [
//                    CircularProgressIndicator(
//                      valueColor: ColorTween(begin: Theme.of(context).primaryColor, end: Theme.of(context).primaryColor).animate(kAlwaysDismissedAnimation),
//                    ),
//                    SizedBox(width: 16,),
//                    Text(
//                      "Procesando...",
//                      style: Theme.of(context).textTheme.titleLarge,
//                    ),
//                  ],
//                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                valueColor: ColorTween(
                    begin: Theme.of(context).primaryColor,
                    end: Theme.of(context).primaryColor,
                ).animate(kAlwaysDismissedAnimation) as Animation<Color>,
              ),
              Expanded(
                child: Text(
                  "Finishing Update...",
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }

}

