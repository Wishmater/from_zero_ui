import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';
import 'package:from_zero_ui/util/web_initial_config/web_initial_config.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'change_notifiers/theme_parameters.dart';
import 'router.dart';


void main() async{
  initAppConfigWebSensitive();
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
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


final initChangeNotifier = DefaultInitChangeNotifier();

class MyApp extends StatelessWidget {

  final _router = GoRouter(
    routes: GoRouteFromZero.getCleanRoutes([
      initRoute,
      ...mainRoutes,
    ]),
    refreshListenable: initChangeNotifier,
    // debugLogDiagnostics: true,
    redirect: (context, state) {
      print ('REDIRECT');
      final initialized = initChangeNotifier.initialized;
      final goingToInitScreen = state.matchedLocation == '/login';
      print (state.matchedLocation);
      print (initialized);
      print (goingToInitScreen);
      print ('END REDIRECT');
      // the user is not logged in and not headed to /login, they need to login
      if (!initialized && !goingToInitScreen) return '/login?from=${state.uri.toString()}';
      // the user is logged in and headed to /login, no need to login again
      if (initialized && goingToInitScreen) return state.uri.queryParameters['from'] ?? '/';
      // no need to redirect at all
      return null;
    },
  );

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final themeParameters = ref.watch(fromZeroThemeParametersProvider);
          return MaterialApp.router(
            title: 'FromZero playground',
            debugShowCheckedModeBanner: false,
            themeMode: themeParameters.themeMode,
            theme: themeParameters.lightTheme,
            darkTheme: themeParameters.darkTheme,
            locale: Locale('ES'), //themeParameters.appLocale
            supportedLocales: List.from(themeParameters.supportedLocales.where((e) => e!=null)),
            localizationsDelegates: [
              FromZeroLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            shortcuts: {
              ...WidgetsApp.defaultShortcuts,
              ...fromZeroDefaultShortcuts,
            },
            builder: (context, child) {
              return FromZeroAppContentWrapper(
                child: child,
                goRouter: _router,
              );
            },
            routerConfig: _router,
          );
        },
      ),
    );
  }

}