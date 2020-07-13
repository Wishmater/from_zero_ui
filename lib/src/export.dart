import 'dart:io';
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:from_zero_ui/util/my_arrow_page_indicator.dart' as my_arrow_page_indicator;
import 'package:intl/intl.dart';
import 'package:page_view_indicators/page_view_indicators.dart';
import 'package:dartx/dartx.dart';
import 'dart:ui' as ui;


class Export extends StatefulWidget {

  static const List<String> supportedFormats = ["PDF", "Imágenes"];
  static const List<String> defaultSizesUI = ["Carta", "A4", "4:3", "16:9",];
  static const List<Size> defaultSizes = [Size(11.0*96, 8.5*96), Size(29.7*38, 21.0*38), Size(16.0*70, 12.0*70), Size(16.0*70, 9.0*70),];

  final int childrenCount;
  final Widget Function(int index, int currentSize, bool portrait, double scale, int format) childBuilder;
  final AppParametersFromZero themeParameters;
  final String path;
  final String title;

  Export({@required this.childBuilder, @required this.childrenCount, @required this.themeParameters, @required this.path, @required this.title});

  @override
  _ExportState createState() => _ExportState();

}

class _ExportState extends State<Export> {

  GlobalKey pageViewKey = GlobalKey();
  List<GlobalKey> boundaryKeys;
  int currentSize = 0;
  int format = 0;
  bool portrait = true;
  double scale = 1;
  PageController controller = PageController(keepPage: true);
  final currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    boundaryKeys = List.generate(widget.childrenCount, (index) => GlobalKey());
  }

  int doneExports=0;
  Future<void> _export([i=0]) async {
    controller.jumpToPage(i);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      await _executeExport(i);
      i++;
      doneExports++;
      if (i<widget.childrenCount) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
          await _export(i);
        });
      }
    });
  }
  Future<void> _executeExport(i) async {
    if (format==0){

    } else if (format==1){

    }
    RenderRepaintBoundary boundary = boundaryKeys[i].currentContext.findRenderObject();
    ui.Image image = await boundary.toImage(pixelRatio: 2/(2-scale));
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    File imgFile = File(widget.path+widget.title+(widget.childrenCount>1?' ${(i+1)}':'')+'.png');
    await imgFile.create(recursive: true);
    await imgFile.writeAsBytes(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    var size = Export.defaultSizes[currentSize];
    if (portrait){
      size = Size((2-scale)*size.height, (2-scale)*size.width);
    } else {
      size = Size((2-scale)*size.width, (2-scale)*size.height);
    }
    return Dialog(
      child: Container(
        width: ScaffoldFromZero.screenSizeLarge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text("Exportar", style: Theme.of(context).textTheme.headline5,),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).canvasColor,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            Widget result = PageView.builder(
                              key: pageViewKey,
                              controller: controller,
                              itemCount: widget.childrenCount,
                              itemBuilder: (context, index) => Center(
                                child: _PageWrapper(
                                  themeParameters: widget.themeParameters,
                                  child: widget.childBuilder(index, currentSize, portrait, scale, format,),
                                  globalKey: boundaryKeys[index],
                                  size: size,
                                  scale: scale,
                                ),
                              ),
                              onPageChanged: (value) => currentPageNotifier.value = value,
                            );
                            if (constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium){
                              result = my_arrow_page_indicator.ArrowPageIndicator(
                                iconPadding: EdgeInsets.symmetric(horizontal: 16),
                                isInside: true,
                                pageController: controller,
                                currentPageNotifier: currentPageNotifier,
                                itemCount: widget.childrenCount,
                                child: result,
                              );
                            }
                            return result;
                          }
                        ),
                      ),
//                      Text(
//                        "Vista Previa", //(Página ${controller.page}/${pages.length})
//                        style: Theme.of(context).textTheme.caption.copyWith(color: Colors.black),
//                      ),
                      if(widget.childrenCount>1)
                      CirclePageIndicator(
                        itemCount: widget.childrenCount,
                        currentPageNotifier: currentPageNotifier,
                        onPageSelected: (value) => controller.animateToPage(value, duration: 300.milliseconds, curve: Curves.easeOut),
                        size: 10,
                        selectedSize: 12,
                        dotColor: Colors.grey.shade600,
                        selectedDotColor: Theme.of(context).accentColor,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 18.0),
                child: Wrap(
                  spacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlineButton(
                      onPressed: (){},
                      child: DropdownButton(
                        value: format,
                        underline: SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => List.generate(Export.supportedFormats.length, (index) =>
                            Center(child: MaterialKeyValuePair(title: "Formato", value: Export.supportedFormats[index])),
                        ),
                        items: List.generate(Export.supportedFormats.length, (index) =>
                            DropdownMenuItem(
                              child: Text(Export.supportedFormats[index]),
                              value: index,
                            ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            format = value;
                          });
                        },
                      ),
                    ),
                    OutlineButton( //TODO 3 streamline this DropdownFromZero (with maybe some other options to control width and such)
                      onPressed: (){},
                      child: DropdownButton(
                        value: portrait,
                        underline: SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => [
                          Center(child: MaterialKeyValuePair(title: "Orientación", value: "Vertical")),
                          Center(child: MaterialKeyValuePair(title: "Orientación", value: "Horizontal")),
                        ],
                        items: [
                          DropdownMenuItem(
                            child: Text("Vertical"),
                            value: true,
                          ),
                          DropdownMenuItem(
                            child: Text("Horizontal"),
                            value: false,
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            portrait = value;
                          });
                        },
                      ),
                    ),
                    OutlineButton(
                      onPressed: (){},
                      child: DropdownButton(
                        value: currentSize,
                        underline: SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => List.generate(Export.defaultSizes.length, (index) =>
                            Center(child: MaterialKeyValuePair(title: "Tamaño", value: Export.defaultSizesUI[index])),
                        ),
                        items: List.generate(Export.defaultSizes.length, (index) =>
                            DropdownMenuItem(
                              child: Text(Export.defaultSizesUI[index]),
                              value: index,
                            ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            currentSize = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text("Zoom", style: Theme.of(context).textTheme.caption,),
                          ),
                          Slider(
                            value: scale,
                            label: "Zoom: "+NumberFormat("###,###,###,###,##0%").format(scale),
                            min: 0.5,
                            max: 1.5,
                            onChanged: (value) {
                              setState(() {
                                scale = value;
                              });
                            },
                            divisions: 100,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FlatButton(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Cancelar"),
                    ),
                    textColor: Theme.of(context).brightness==Brightness.light ? Colors.black : Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 6,),
                  RaisedButton(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Exportar",),
                    ),
                    onPressed: () async{
                      //TODO 1 change flushbar helper declarations here and use it to show loading and done signs
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return LoadingSign();
                        },
                      );
                      _export();
                      while (doneExports<widget.childrenCount){
                        await Future.delayed(100.milliseconds);
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(width: 12,)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

}

class _PageWrapper extends StatelessWidget {

  final double scale;
  final Widget child;
  final Size size;
  final Key globalKey;
  final AppParametersFromZero themeParameters;

  _PageWrapper({this.scale, this.child, this.size, this.globalKey, this.themeParameters});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaleFactor: 1,
        ),
        child: Theme(
          data: themeParameters.lightTheme.copyWith(
            cardTheme: CardTheme(
              elevation: 0,
              color: Colors.white,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: size.width/size.height,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white,
                  child: FittedBox(
                    alignment: Alignment.center,
                    fit: BoxFit.fitHeight,
                    child: RepaintBoundary(
                      key: globalKey,
                      child: Padding(
                        padding: EdgeInsets.all(32*(2-scale)),
                        child: SizedBox.fromSize(
                          size: size,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




