import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'change_notifiers/theme_parameters.dart';
import 'router.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  print(await getApplicationDocumentsDirectory());
  await initHive();
  MyFluroRouter.setupRouter();
  fromZeroThemeParametersProvider = ChangeNotifierProvider((ref) {
    return ThemeParameters();
  });
  runApp(MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(600, 450);
    appWindow.minSize = initialSize;
    // appWindow.size = initialSize;
    // appWindow.alignment = Alignment.center;
    appWindow.maximize();
    appWindow.show();
  });
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final themeParameters = ref.watch(fromZeroThemeParametersProvider);
          return MaterialApp(
            title: 'FromZero playground',
            debugShowCheckedModeBanner: false,
            themeMode: themeParameters.themeMode,
            theme: themeParameters.lightTheme,
            darkTheme: themeParameters.darkTheme,
            locale: Locale('ES'), //themeParameters.appLocale
            supportedLocales: List.from(themeParameters.supportedLocales)..remove(null),
            localizationsDelegates: [
              FromZeroLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) {
              return FromZeroAppContentWrapper(child: child);
            },
            initialRoute: '/',
            onGenerateRoute: MyFluroRouter.router.generator,
          );
        },
      ),
    );
  }

}