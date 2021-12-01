import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/settings.dart';


import '../../change_notifiers/theme_parameters.dart';

class PageSettings extends PageFromZero {

  @override
  int get pageScaffoldDepth => -1;
  @override
  String get pageScaffoldId => "Settings";

  PageSettings();

  @override
  _PageSettingsState createState() => _PageSettingsState();

}

class _PageSettingsState extends State<PageSettings> {

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      currentPage: widget,
      title: Text("Settings"),
      body: ScrollbarFromZero(
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 12,),
                SizedBox(
                  width: 512,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer(
                            builder: (context, ref, child) => ThemeSwitcher(ref.watch(fromZeroThemeParametersProvider)),
                          ),
                          Consumer(
                            builder: (context, ref, child) => LocaleSwitcher(ref.watch(fromZeroThemeParametersProvider)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
