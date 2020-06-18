
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:provider/provider.dart';

import 'change_notifiers/theme_parameters.dart';
import 'router.dart';

void main() {
  FluroRouter.setupRouter();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
//    primaryColor: Color.fromRGBO(0, 0, 100, 1),
//    primaryColorDark: Color.fromRGBO(0, 0, 60, 1),
//    primaryColorLight: Color.fromRGBO(0, 0, 140, 1),
    accentColor: Colors.orangeAccent.shade700,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
  static final lightTheme = ThemeData(
    canvasColor: Colors.grey.shade300,
    primaryColor: Color.fromRGBO(0, 0, 100, 1),
    primaryColorDark: Color.fromRGBO(0, 0, 60, 1),
    primaryColorLight: Color.fromRGBO(0, 0, 140, 1),
    accentColor: Colors.orangeAccent.shade700,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeParameters(),
      child: Consumer<ThemeParameters>(
        builder: (context, themeParameters, child) {
          return MaterialApp(
            title: 'Cutrans CRM',
            debugShowCheckedModeBanner: false,
            themeMode: themeParameters.themeMode, //TODO 2 add another theme, a clear one to test appbar reactivity
            theme: lightTheme,
            darkTheme: darkTheme,
            builder: (context, child) {
              var mediaQueryData = MediaQuery.of(context);
              if (themeParameters.textScaleFactor!=-1){
                mediaQueryData = mediaQueryData.copyWith(textScaleFactor: themeParameters.textScaleFactor);
              } else{
                mediaQueryData = mediaQueryData.copyWith(textScaleFactor: mediaQueryData.textScaleFactor.clamp(1.0, 1.5));
              }
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider (create: (context) => ResponsiveScaffoldChangeNotifier(),),
                ],
                child: MediaQuery(
                  data: mediaQueryData,
                  child: child,
                ),
              );
            },
            initialRoute: '/',
            onGenerateRoute: FluroRouter.router.generator,
          );
        },
      ),
    );
  }
}