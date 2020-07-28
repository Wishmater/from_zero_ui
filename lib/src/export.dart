import 'dart:io';
import 'dart:typed_data';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/flushbar_helper.dart';
import 'package:from_zero_ui/src/settings.dart';
import 'package:from_zero_ui/util/my_arrow_page_indicator.dart' as my_arrow_page_indicator;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:page_view_indicators/page_view_indicators.dart';
import 'package:dartx/dartx.dart';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

class Export extends StatefulWidget { //TODO 3 internationalize

  static const List<String> supportedFormats = ["PDF", "Imágenes (.png)"];
  static const List<String> defaultSizesUI = ["Carta", "A4", "4:3", "16:9",];
  static final List<PdfPageFormat> defaultFormats = [PdfPageFormat.letter, PdfPageFormat.a4,
    PdfPageFormat(PdfPageFormat.a4.height*3/4, PdfPageFormat.a4.height),
    PdfPageFormat(PdfPageFormat.a4.height*9/16, PdfPageFormat.a4.height),];

  final int Function(int currentSize, bool portrait, double scale, int format) childrenCount;
  final Widget Function(BuildContext context, int index, int currentSize, bool portrait, double scale, int format) childBuilder;
  final AppParametersFromZero themeParameters;
  final Future<String> path;
  final String title;
  final ThemeData exportThemeData;

  Export({@required this.childBuilder, @required this.childrenCount, @required this.themeParameters, @required this.path, @required this.title})
      :
        this.exportThemeData =  themeParameters.lightTheme.copyWith(
          cardTheme: CardTheme(
            elevation: 0,
            color: Colors.white,
//            shape: Border.all(style: BorderStyle.none),
          ),
        );

  @override
  _ExportState createState() => _ExportState();

}

class _ExportState extends State<Export> {

  int get currentSize => Hive.box("settings").get("export_size", defaultValue: 0);
  set currentSize(int value) => Hive.box("settings").put("export_size", value);
  int get format => Hive.box("settings").get("export_format", defaultValue: 0);
  set format(int value) => Hive.box("settings").put("export_format", value);
  bool get portrait => Hive.box("settings").get("export_portrait", defaultValue: true);
  set portrait(bool value) => Hive.box("settings").put("export_portrait", value);
  double get scale => Hive.box("settings").get("export_scale", defaultValue: 1.0);
  set scale(double value) => Hive.box("settings").put("export_scale", value);

  GlobalKey pageViewKey = GlobalKey();
  List<GlobalKey> boundaryKeys;
  PageController controller = PageController(keepPage: true);
  final currentPageNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
  }

  int doneExports = 0;
  String directoryPath;
  String filePath;
  String pathUi;
  Future<void> _export([i=0, pdf]) async {
    controller.jumpToPage(i);
    if (format==0 && pdf==null){
      pdf = pw.Document(
        title: widget.title,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      await _executeExport(i, pdf);
      i++;
      doneExports++;
      if (i<widget.childrenCount) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
          await _export(i, pdf);
        });
      }
    });
  }
  Future<void> _executeExport(i, pw.Document pdf) async {
    if (format==0){
      var format = Export.defaultFormats[currentSize];
      if (!portrait) format = PdfPageFormat(format.height, format.width);
      Uint8List pngBytes = await _getImageBytes(await _getImage(boundaryKeys[i]));
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(0),
          build: (context) => pw.Image(
            PdfImage.file(pdf.document, bytes: pngBytes),
          ),
        )
      );
      if (i==widget.childrenCount(currentSize, portrait, scale, this.format,)-1){
        final file = File((await widget.path)+widget.title+'.pdf');
        await file.create(recursive: true);
        if (filePath==null){
          filePath = file.absolute.path;
          directoryPath = file.parent.absolute.path;
          pathUi = filePath.substring(filePath.indexOf("Document"));
        }
        await file.writeAsBytes(pdf.save());
      }
    } else if (format==1){
      File imgFile = File((await widget.path)+widget.title+(widget.childrenCount(currentSize, portrait, scale, this.format,)>1?' ${(i+1)}':'')+'.png');
      await imgFile.create(recursive: true);
      if (filePath==null){
        filePath = imgFile.absolute.path;
        directoryPath = imgFile.parent.absolute.path;
        pathUi = filePath.substring(filePath.indexOf("Document"));
      }
      Uint8List pngBytes = await _getImageBytes(await _getImage(boundaryKeys[i]));
      await imgFile.writeAsBytes(pngBytes);
    }
  }
  Future<ui.Image> _getImage(GlobalKey boundaryKey) async{
    RenderRepaintBoundary boundary = boundaryKey.currentContext.findRenderObject();
    return await boundary.toImage(pixelRatio: 2/(2-scale));
  }
  Future<Uint8List> _getImageBytes(ui.Image image) async{
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    boundaryKeys = List.generate(widget.childrenCount(currentSize, portrait, scale, format,),
            (index) => GlobalKey());
    var size = Size(
      Export.defaultFormats[currentSize].width/PdfPageFormat.inch*96*MediaQuery.of(context).devicePixelRatio,
      Export.defaultFormats[currentSize].height/PdfPageFormat.inch*96*MediaQuery.of(context).devicePixelRatio,
    );
    if (!portrait){
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
                              itemCount: widget.childrenCount(currentSize, portrait, scale, format,),
                              itemBuilder: (context, index) => Center(
                                child: _PageWrapper(
                                  themeData: widget.exportThemeData,
                                  child: widget.childBuilder(context, index, currentSize, portrait, scale, format,),
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
                                itemCount: widget.childrenCount(currentSize, portrait, scale, format,),
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
                      if(widget.childrenCount(currentSize, portrait, scale, format,)>1)
                      CirclePageIndicator(
                        itemCount: widget.childrenCount(currentSize, portrait, scale, format,),
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
                        selectedItemBuilder: (context) => List.generate(Export.defaultFormats.length, (index) =>
                            Center(child: MaterialKeyValuePair(title: "Tamaño", value: Export.defaultSizesUI[index])),
                        ),
                        items: List.generate(Export.defaultFormats.length, (index) =>
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
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return LoadingSign();
                        },
                      );
                      _export();
                      while (doneExports<widget.childrenCount(currentSize, portrait, scale, format,)){
                        await Future.delayed(100.milliseconds);
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      String path = await widget.path;
                      if (Platform.isWindows){
                        path = path.replaceAll("/", "\\");
                      }
                      var flush;
                      flush = FlushbarHelperFromZero.createSuccess(
                        title: "Archivo exportado con exito a",
                        message:  pathUi,
                        duration: 10.seconds,
                        actions: [
                          FlatButton(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("ABRIR", style: FlushbarHelperFromZero.recommendedSuccessButtonTextStyle,),
                            ),
                            onPressed: () async {
                              flush.dismiss();
                              return launch(filePath);
                            },
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          SizedBox(height: 6,),
                          FlatButton(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("ABRIR CARPETA", style: FlushbarHelperFromZero.recommendedSuccessButtonTextStyle,),
                            ),
                            onPressed: () async {
                              flush.dismiss();
                              return launch(directoryPath);
                            },
                            padding: EdgeInsets.all(0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      );
                      flush.show(context);
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
  final ThemeData themeData;

  _PageWrapper({this.scale, this.child, this.size, this.globalKey, this.themeData});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: true,
                      textScaleFactor: 1,
                    ),
                    child: Theme(
                      data: themeData,
                      child: SizedBox.fromSize(
                        size: size,
                        child: Padding(
                          padding: EdgeInsets.all(32*(2-scale)),
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




