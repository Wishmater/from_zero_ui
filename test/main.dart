
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'change_notifiers/theme_parameters.dart';
import 'router.dart';

void main() async{
  await initHive();
  await FromZeroLocalizations.delegate;
  FluroRouter.setupRouter();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeParameters(),
      child: Consumer<ThemeParameters>(
        builder: (context, themeParameters, child) {
          return MaterialApp(
            title: 'FromZero playground',
            debugShowCheckedModeBanner: false,
            themeMode: themeParameters.themeMode,
            theme: themeParameters.lightTheme,
            darkTheme: themeParameters.darkTheme,
            locale: themeParameters.appLocale,
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
            onGenerateRoute: FluroRouter.router.generator,
          );
        },
      ),
    );
  }

}