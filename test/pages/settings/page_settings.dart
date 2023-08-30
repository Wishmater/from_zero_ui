import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:from_zero_ui/from_zero_ui.dart';



class PageSettings extends StatefulWidget {

  const PageSettings({super.key});

  @override
  PageSettingsState createState() => PageSettingsState();

}

class PageSettingsState extends State<PageSettings> {

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ScaffoldFromZero(
      title: const Text("Settings"),
      body: ScrollbarFromZero(
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 12,),
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
