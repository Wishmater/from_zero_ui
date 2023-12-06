import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:animations/animations.dart';
import 'package:dartx/dartx.dart';
import 'package:date/date.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/util/copied_flutter_widgets/my_arrow_page_indicator.dart' as my_arrow_page_indicator;
import 'package:intl/intl.dart';
import 'package:page_view_indicators/page_view_indicators.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

enum FileAutoOpenType {
  none,
  file,
  folder,
}

class Export extends StatefulWidget { //TODO 3 internationalize

  static const List<String> defaultSizesUI = ["Carta", "A4", "4:3", "16:9",];
  static final List<PdfPageFormat> defaultFormats = [PdfPageFormat.letter, PdfPageFormat.a4,
    PdfPageFormat(PdfPageFormat.a4.height*3/4, PdfPageFormat.a4.height),
    PdfPageFormat(PdfPageFormat.a4.height*9/16, PdfPageFormat.a4.height),];

  // TODO 2 this is god awful. Completely refactor this class if we intend on using it again, or scrap it and decouple TableController excel export from it (which is the only use it has now)
  int Function(int currentSize, bool portrait, double scale, String format)? childrenCount;
  final Widget Function(BuildContext context, int index, int currentSize, bool portrait, double scale, String format)? childBuilder;
  final Widget Function(BuildContext context, int index, int currentSize, bool portrait, double scale, String format, ScrollController scrollController)? scrollableChildBuilder;
  final double scrollableStickyOffset;
  final ThemeParametersFromZero? themeParameters;
  final FutureOr<String> path;
  final String title;
  final ThemeData exportThemeData;
  final List<TextEditingController?>? textEditingControllers;
  final bool showTitle;
  final List<Widget> actions;
  final BuildContext? scaffoldContext;
  final Widget? dummyChild;
  final List<GlobalKey>? significantWidgetsKeys;
  final Map<String, TableController>? Function()? excelSheets;
  final bool isPdfFormatAvailable;
  final bool isPngFormatAvailable;
  final bool autoExport;
  final FileAutoOpenType autoOpenFile;

  Export.excelOnly({
    required this.path,
    required this.title,
    required this.scaffoldContext,
    required this.excelSheets,
    this.actions = const [],
    this.autoExport = true,
    this.autoOpenFile = FileAutoOpenType.file,
    super.key,
  })  : isPdfFormatAvailable = false,
        isPngFormatAvailable = false,childBuilder = null,
        childrenCount = null,
        textEditingControllers = null,
        showTitle = false,
        significantWidgetsKeys = null,
        scrollableChildBuilder = null,
        scrollableStickyOffset = 0,
        dummyChild = null,
        themeParameters = null,
        exportThemeData = ThemeData();

  Export.scrollable({
    required this.scrollableChildBuilder,
    required this.themeParameters,
    required this.path,
    required this.title,
    required this.scaffoldContext,
    this.scrollableStickyOffset = 0,
    this.textEditingControllers,
    bool? showTitle,
    this.actions = const [],
    this.dummyChild,
    this.significantWidgetsKeys,
    this.excelSheets,
    this.isPdfFormatAvailable = true,
    this.isPngFormatAvailable = true,
    this.autoExport = true,
    this.autoOpenFile = FileAutoOpenType.file,
    super.key,
  })  : showTitle = showTitle ?? textEditingControllers==null ? true : false,
        exportThemeData =  (themeParameters?.lightTheme ?? ThemeData()).copyWith(
          canvasColor: Colors.white,
          cardColor: Colors.white,
          cardTheme: const CardTheme(
            elevation: 0,
            color: Colors.white,
//            shape: Border.all(style: BorderStyle.none),
          ),
        ),
        childBuilder = null;

  Export.dummy({
    required this.dummyChild,
    required this.themeParameters,
    this.isPdfFormatAvailable = true,
    this.isPngFormatAvailable = true,
    super.key,
  }) :  autoExport = true,
        autoOpenFile = FileAutoOpenType.file,
        childBuilder = null,
        childrenCount = null,
        path = '',
        title = '',
        scaffoldContext = null,
        textEditingControllers = null,
        showTitle = false,
        actions = [],
        significantWidgetsKeys = null,
        scrollableChildBuilder = null,
        excelSheets = null,
        scrollableStickyOffset = 0,
        exportThemeData = (themeParameters?.lightTheme ?? ThemeData());

  Export({
    required this.childBuilder,
    required this.childrenCount,
    required this.themeParameters,
    required this.path,
    required this.title,
    required this.scaffoldContext,
    this.textEditingControllers,
    this.excelSheets,
    bool? showTitle,
    this.actions = const [],
    this.dummyChild,
    this.significantWidgetsKeys,
    this.isPdfFormatAvailable = true,
    this.isPngFormatAvailable = true,
    this.autoExport = true,
    this.autoOpenFile = FileAutoOpenType.file,
    super.key,
  })  : showTitle = showTitle ?? textEditingControllers==null ? true : false,
        exportThemeData =  (themeParameters?.lightTheme ?? ThemeData()).copyWith(
          canvasColor: Colors.white,
          cardColor: Colors.white,
          cardTheme: const CardTheme(
            elevation: 0,
            color: Colors.white,
//            shape: Border.all(style: BorderStyle.none),
          ),
        ),
        scrollableChildBuilder = null,
        scrollableStickyOffset = 0;

  @override
  ExportState createState() => ExportState();

  static Future<String> getDefaultDirectoryPath([String? addon]) async{
    String result = (await PlatformExtended.getDownloadsDirectory()).absolute.path;
    if (addon!=null){
      result = p.join(result, addon);
    }
    return result;
  }

}

class ExportState extends State<Export> {

  List<String> get supportedFormats => [
    if (widget.isPdfFormatAvailable) "PDF",
    if (widget.isPngFormatAvailable) "PNG",
    if (widget.excelSheets?.call()!=null) 'Excel',
  ];

  // int get currentSize => Hive.box("settings").get("export_size", defaultValue: 0);
  // set currentSize(int value) => Hive.box("settings").put("export_size", value);
  // int get format => Hive.box("settings").get("export_format", defaultValue: 0);
  // set format(int value) => Hive.box("settings").put("export_format", value);
  // bool get portrait => Hive.box("settings").get("export_portrait", defaultValue: true);
  // set portrait(bool value) => Hive.box("settings").put("export_portrait", value);
  // double get scale => Hive.box("settings").get("export_scale", defaultValue: 1.0);
  // set scale(double value) => Hive.box("settings").put("export_scale", value);
  int currentSize = 0;
  int formatIndex = 0;
  String get format => supportedFormats[formatIndex];
  bool portrait = true;
  double scale = 1;

  GlobalKey pageViewKey = GlobalKey();
  List<GlobalKey> boundaryKeys = [];
  PageController controller = PageController(keepPage: true);
  final currentPageNotifier = ValueNotifier<int>(0);
  List<TextEditingController> textEditingControllers = [];
  List<ScrollController> scrollControllers = [];

  List<double> jumpsSeparatingPages = [0];
  List<double> pageBottomPaddings = [0];
  int? lastSize;
  bool? lastPortrait;
  double? lastScale;
  String? lastFormat;
  bool first = true;

  @override
  void initState() {
    super.initState();
    if (widget.scrollableChildBuilder!=null){
      widget.childrenCount = ((currentSize, bool portrait, double scale, String format){
        if (first){
          first = false;
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
            await Future.delayed(500.milliseconds);
            if (mounted) {
              setState(() {});
            }
          });
          return 1;
        }
        if (currentSize==lastSize && portrait==lastPortrait
            && scale==lastScale && format==lastFormat){
          return jumpsSeparatingPages.length;
        }
        lastSize = currentSize;
        lastPortrait = portrait;
        lastScale = scale;
        lastFormat = format;
        try{
          final position = scrollControllers[0].position;
          position.haveDimensions;
          double totalHeight = position.maxScrollExtent+position.viewportDimension;
          List<double> significantWidgetVisibleAtStartOffsets = [0];
          for (final element in widget.significantWidgetsKeys!) {
            if (element.currentContext!=null) {
              final object = element.currentContext!.findRenderObject();
              final viewport = RenderAbstractViewport.of(object);
              significantWidgetVisibleAtStartOffsets.add(viewport.getOffsetToReveal(object!, 0.0).offset);
            }
          }
          significantWidgetVisibleAtStartOffsets.add(position.maxScrollExtent + position.viewportDimension);
          significantWidgetVisibleAtStartOffsets.sort();
          scrollControllers = [];
          jumpsSeparatingPages = [0];
          pageBottomPaddings = [];
//          log (significantWidgetVisibleAtStartOffsets);
          for (var i = 1; i < significantWidgetVisibleAtStartOffsets.length; ++i) {
            if (significantWidgetVisibleAtStartOffsets[i]
                > jumpsSeparatingPages.last+position.viewportDimension){
              jumpsSeparatingPages.add((significantWidgetVisibleAtStartOffsets[i-1]
                  - widget.scrollableStickyOffset).clamp(0, double.infinity),);
              pageBottomPaddings.add(position.viewportDimension - (significantWidgetVisibleAtStartOffsets[i-1]
                  - jumpsSeparatingPages[jumpsSeparatingPages.length-2]),);
            }
          }
          pageBottomPaddings.add((position.viewportDimension - (totalHeight - jumpsSeparatingPages.last)).clamp(0.0, double.infinity));
//          log (jumpsSeparatingPages);
//          log (pageBottomPaddings);
          return jumpsSeparatingPages.length;
        } catch(e){
          // log(e, stackTrace: st);
          lastSize = null;
          return 1;
        }
      });
    }
    currentPageNotifier.addListener(() {

    });
    if (widget.autoExport && widget.dummyChild==null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _onExportButtonPressed();
      });
    }
  }

  @override
  void dispose(){
    currentPageNotifier.dispose();
    super.dispose();
  }

  late Future<void> Function() export;


  Future<void> _onExportButtonPressed() async{
    await export();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  int doneExports = 0;
  Future<void> _export(Size size, [int i=0, dynamic pdf]) async {
    if (format=='Excel'){
      return _executeExcelExport();
    }
    controller.jumpToPage(i);
    if (format=='PDF' && pdf==null){
      pdf = pw.Document(
        title: widget.title,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      await Future.delayed(100.milliseconds);
      if (!mounted) return;
      setState(() {});
      await Future.delayed(400.milliseconds);
      if (!mounted) return;
      await _executeExport(size, i, pdf);
      i++;
      doneExports++;
      if (i<widget.childrenCount!(currentSize, portrait, scale, format,)) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
          if (!mounted) return;
          await _export(size, i, pdf);
        });
      }
    });
  }
  Future<void> _executeExport(Size size, int i, pw.Document pdf) async {
    if (format=='PDF'){
      var format = Export.defaultFormats[currentSize];
      if (!portrait) format = PdfPageFormat(format.height, format.width);
      if (!mounted) return;
      Uint8List pngBytes = await _getImageBytes(size, await _getImage(size, boundaryKeys[i]));
      if (!mounted) return;
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Image(
            pw.MemoryImage(pngBytes),
          ),
        ),
      );
      if (i==widget.childrenCount!(currentSize, portrait, scale, this.format,)-1){
        if (!mounted) return;
        saveFileFromZero( // don't await, so the window closes before snackbar
          context: context,
          name: '${widget.title}.pdf',
          pathAppend: await widget.path,
          data: pdf.save,
        );
      }
    } else if (format=='PNG'){
      final title = '${widget.title}${widget.childrenCount!(currentSize, portrait, scale, format,)>1?' ${(i+1)}':''}.png';
      final path = await widget.path;
      if (!mounted) return;
      final pngBytes = _getImageBytes(size, await _getImage(size, boundaryKeys[i]));
      if (i==0){
        saveFileFromZero( // don't await, so the window closes before snackbar, might have issues with multiple files
          context: context,
          name: title,
          pathAppend: path,
          data: pdf.save,
        );
      } else {
        final imgFile = File(path+title);
        await imgFile.create(recursive: true);
        final bytes = await pngBytes;
        if (!mounted) return;
        await imgFile.writeAsBytes(bytes);
      }
      if (!mounted) return;
    }
  }
  Future<ui.Image> _getImage(Size size, GlobalKey boundaryKey) async{
    RenderRepaintBoundary boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: 1920/size.longestSide);
  }
  Future<Uint8List> _getImageBytes(Size size, ui.Image image) async{
    ByteData byteData = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return byteData.buffer.asUint8List();
  }

  Future<void> _executeExcelExport() async {
    final dateFormat = DateFormat("dd-MM-yyyy");
    
    var excel = Excel.createExcel();
    widget.excelSheets!()!.forEach((key, value) {
      Sheet sheetObject = excel[key];
      bool flexCalc = false;
      bool widthSetted = false;
      double flexMultiplier = 0;
      final tableWidth = value.currentState!.widget.minWidthGetter!(value.currentState!.currentColumnKeys?.toList()
          ?? (value.currentState!.widget.columns?.keys.where((e) => value.currentState!.widget.columns![e]!.flex!=0))?.toList() ?? [],);
      for (var i = value.currentState!.widget.columns==null ? 0 : -1; i < value.currentState!.filtered.length; ++i) {
        RowModel row;
        if (i==-1) {
          row = SimpleRowModel(
            id: value.currentState!.widget.columns,
            values: value.currentState!.widget.columns!.map((key, value) => MapEntry(key, value.name)),
          );
        } else{
          row = value.currentState!.filtered[i];
        }
        if (row.alwaysOnTop==null){
          final keys = value.currentState!.currentColumnKeys 
              ?? (value.currentState!.widget.columns?.keys.where((e) => value.currentState!.widget.columns![e]!.flex!=0)
              ?? row.values.keys).toList();
          for (int j=0; j<keys.length+1; j++) {
            if(j<keys.length){
              final key = keys[j];
              ColModel? col = value.currentState!.widget.columns==null ? null : value.currentState!.widget.columns![key];
              if(!flexCalc){
                flexMultiplier += col?.width??(col?.flex??0);
              } else if(!widthSetted) {
                final percentage = (col?.width??(col?.flex??0)) * 100 / flexMultiplier;
                double w = (tableWidth * percentage / 100);
                sheetObject.setColWidth(j, w/6.4);
                if(j==keys.length-1){
                  widthSetted = true;
                }
              }
              Color? backgroundColor;
              if (i==-1){
                backgroundColor = col?.backgroundColor;
                if (backgroundColor!=null){
                  backgroundColor = backgroundColor.withOpacity(backgroundColor.opacity*0.5);
                }
              } else{
                if (value.currentState!.widget.rowStyleTakesPriorityOverColumn){
                  backgroundColor = row.backgroundColor ?? col?.backgroundColor;
                } else{
                  backgroundColor = col?.backgroundColor ?? row.backgroundColor;
                }
              }
              if (backgroundColor!=null) {
                backgroundColor = Color.alphaBlend(backgroundColor, Colors.white);
              }
              TextStyle? style;
              if (value.currentState!.widget.rowStyleTakesPriorityOverColumn){
                style = row.textStyle ?? col?.textStyle;
              } else{
                style = col?.textStyle ?? row.textStyle;
              }
              TextAlign? alignment = col?.alignment;
              CellStyle cellStyle = CellStyle();
              Data cell = sheetObject.cell(CellIndex.indexByColumnRow(rowIndex: i+1, columnIndex: j));
              if (style!=null){
                if (i!=-1){
                  cellStyle.isBold = FontWeight.values.indexOf(style.fontWeight??FontWeight.w100) > 4
                      || (style.fontSize??1)>=16;
                }
              }
              if (alignment==TextAlign.right||alignment==TextAlign.end){
                cellStyle.horizontalAlignment = HorizontalAlign.Right;
              }
              if (backgroundColor!=null){
                cellStyle.backgroundColor = backgroundColor.toHex(includeAlpha: false);
              }
              cellStyle.fontSize = 12;
              final dynamic cellValue;
              if (col is DateColModel && (row.values[key] is DateTime
                  || row.values[key] is Date
                  || row.values[key] is ContainsValue<DateTime>)) {
                final DateTime dateTime = row.values[key] is DateTime ? row.values[key]
                    : row.values[key] is Date ? (row.values[key] as Date).toDateTime()
                    : (row.values[key] as ContainsValue<DateTime>).value;
                cellValue = (col.formatter??dateFormat).format(dateTime);
              } else if (col is NumColModel && (row.values[key] is double
                  || (row.values[key] is ContainsValue<num> && ((row.values[key] as ContainsValue<num>).value is double)))) {
                cellValue = row.values[key] is double ? row.values[key] : (row.values[key] as ContainsValue<num>).value;
                final formatter = col.formatter;
                if (formatter!=null) {
                  final pattern = formatter.toString().split(',');
                  pattern.removeAt(0);
                  cellStyle.numFormat = pattern.join(',').replaceAll(')', '').trim();
                } else {
                  cellStyle.numFormat = "###,###,###,###,##0.00";
                }
                if (cellStyle.numFormat!=null) {
                  if(!excel.numFormats.contains(cellStyle.numFormat)) {
                    excel.addNumFormats(cellStyle.numFormat!);
                  }
                }
              } else if (col is BoolColModel && (row.values[key] is bool || row.values[key] is ContainsValue<bool>)) {
                cellValue = col.getValueString(row, key);
              }  else if (row.values[key] is ContainsValue){
                cellValue = (row.values[key] as ContainsValue).value==null
                    ? null
                    : (row.values[key] as ContainsValue).value is num
                        ? (row.values[key] as ContainsValue).value
                        : row.values[key].toString();
              } else {
                cellValue = row.values[key];
              }
              if (cellValue==null || cellValue is num) {
                cell.value = cellValue ?? '';
              } else if (cellValue is List) {
                cell.value = ListField.listToStringAll(cellValue);
              } else {
                cell.value = cellValue.toString();
              }
              cell.cellStyle = cellStyle;
            } else {
              flexCalc = true;
              Data cell = sheetObject.cell(CellIndex.indexByColumnRow(rowIndex: i+1, columnIndex: j));
              cell.value = ' ';
            }
          }
        }
      }
      /*double flexMultiplier = 6.4;
      if (value.columns==null || value.columns!.values.where((element) => element.flex!=null&&element.flex!>10).length==0)
        flexMultiplier *= 10.0;
      if (value.columns!=null){
        for (var i = 0; i < value.columns!.length; ++i) {
          ColModel? col = value.columns![i];
          log(value.columns![i]);
          double w = ((col?.width??(col?.flex??1.0))*flexMultiplier).toDouble();
          //log(w);
          sheetObject.setColWidth(i, w);
        }
      }*/
    });
    excel.delete('Sheet1');
    if (!mounted) return;
    saveFileFromZero( // don't await, so the window closes before snackbar
      context: context,
      name: '${widget.title}.xlsx',
      pathAppend: await widget.path,
      data: () async => excel.encode()!,
    );
    doneExports = widget.childrenCount?.call(currentSize, portrait, scale, format,)??1;
  }


  @override
  Widget build(BuildContext context) {
    if (widget.dummyChild!=null) return widget.dummyChild!;
    while (textEditingControllers.length<(widget.childrenCount?.call(currentSize, portrait, scale, format,)??1)){
      textEditingControllers.add(
        widget.textEditingControllers==null ? TextEditingController()
          : widget.textEditingControllers!.length > textEditingControllers.length
            ? widget.textEditingControllers![textEditingControllers.length] ?? TextEditingController()
            : widget.textEditingControllers!.last ?? TextEditingController(),
      );
    }
    while (boundaryKeys.length < (widget.childrenCount?.call(currentSize, portrait, scale, format,)??1)){
      boundaryKeys.add(GlobalKey());
    }
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    var size = Size(
      Export.defaultFormats[currentSize].width/PdfPageFormat.inch*96*devicePixelRatio,
      Export.defaultFormats[currentSize].height/PdfPageFormat.inch*96*devicePixelRatio,
    );
    var mult = (2-scale)*(1.5/devicePixelRatio);
    if (!portrait){
      size = Size(mult*size.height, mult*size.width);
    } else {
      size = Size(mult*size.width, mult*size.height);
    }
    export = () async {
      if (await requestDefaultFilePermission()){
        showModalFromZero(
          context: context,
          configuration: const FadeScaleTransitionConfiguration(
            barrierDismissible: false,
          ),
          builder: (context) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16,),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.8),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.pop();
                      },
                      child: const Text('CANCELAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        doneExports = 0;
        _export(size);
        do {
          await Future.delayed(500.milliseconds);
        } while (doneExports<(widget.childrenCount?.call(currentSize, portrait, scale, format,)??1));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    };
    return ResponsiveInsetsDialog(
      child: SizedBox(
        width: ScaffoldFromZero.screenSizeLarge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text("Exportar", style: Theme.of(context).textTheme.headlineSmall,),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).canvasColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (format=='Excel'){
                              return const Center(
                                child: Text('Vista previa no disponible'),
                              );
                            }
                            Widget result;
                            result = PageView.builder(
                              key: pageViewKey,
                              controller: controller,
                              itemCount: widget.childrenCount?.call(currentSize, portrait, scale, format,)??10,
                              itemBuilder: (context, index) => Center(
                                child: ValueListenableBuilder(
                                  valueListenable: textEditingControllers[index],
                                  builder: (context, value, child) => _getChild(index, size, boundaryKeys[index]),
                                ),
                              ),
                              onPageChanged: (value) => currentPageNotifier.value = value,
                            );
                            if (constraints.maxWidth>=ScaffoldFromZero.screenSizeMedium){
                              result = my_arrow_page_indicator.ArrowPageIndicator(
                                iconPadding: const EdgeInsets.symmetric(horizontal: 16),
                                isInside: true,
                                pageController: controller,
                                currentPageNotifier: currentPageNotifier,
                                itemCount: widget.childrenCount?.call(currentSize, portrait, scale, format,)??1,
                                child: result,
                              );
                            }
                            return result;
                          },
                        ),
                      ),
//                      Text(
//                        "Vista Previa", //(Página ${controller.page}/${pages.length})
//                        style: Theme.of(context).textTheme.bodySmall.copyWith(color: Colors.black),
//                      ),
                      if((widget.childrenCount?.call(currentSize, portrait, scale, format,)??1) > 1)
                        CirclePageIndicator(
                          itemCount: widget.childrenCount?.call(currentSize, portrait, scale, format,)??1,
                          currentPageNotifier: currentPageNotifier,
                          onPageSelected: (value) => controller.animateToPage(value, duration: 300.milliseconds, curve: Curves.easeOut),
                          size: 10,
                          selectedSize: 12,
                          dotColor: Colors.grey.shade600,
                          selectedDotColor: Theme.of(context).colorScheme.secondary,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 256,
                      child: ValueListenableBuilder(
                        valueListenable: currentPageNotifier,
                        builder: (context, int value, child) {
                          return Stack(
                            fit: StackFit.passthrough,
                            alignment: Alignment.centerRight,
                            children: [
                              TextField(
                                key: ValueKey(value),
                                controller: textEditingControllers[value],
                                decoration: InputDecoration(
                                  labelText: "Título", // TODO 3 internationalize
                                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.75)),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.only(left: 12, right: 34, top: 17, bottom: 18),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ValueListenableBuilder(
                                    valueListenable: textEditingControllers[value],
                                    builder: (context, TextEditingValue text, child) {
                                      bool empty = text.text.isEmpty;
                                      return PageTransitionSwitcher(
                                        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                                          return FadeThroughTransition(
                                            animation: primaryAnimation,
                                            secondaryAnimation: secondaryAnimation,
                                            fillColor: Colors.transparent,
                                            child: child,
                                          );
                                        },
                                        child: empty ? const SizedBox.shrink()
                                            : IconButton(
                                          icon: Icon(MaterialCommunityIcons.close_circle,
                                            color: Theme.of(context).textTheme.bodySmall!.color,
                                          ),
                                          onPressed: (){
                                            textEditingControllers[value].clear();
                                          },
                                          splashRadius: 24,
                                        ),
                                      );
                                    },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: (){},
                      child: DropdownButton(
                        value: formatIndex,
                        underline: const SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => List.generate(supportedFormats.length, (index) =>
                            Center(child: MaterialKeyValuePair(title: "Formato", value: supportedFormats[index])),
                        ),
                        items: List.generate(supportedFormats.length, (index) =>
                            DropdownMenuItem(
                              value: index,
                              child: Text(supportedFormats[index]),
                            ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            formatIndex = (value!);
                          });
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: format=='Excel' ? null : (){},
                      child: DropdownButton(
                        value: portrait,
                        underline: const SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => [
                          const Center(child: MaterialKeyValuePair(title: "Orientación", value: "Vertical")),
                          const Center(child: MaterialKeyValuePair(title: "Orientación", value: "Horizontal")),
                        ],
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text("Vertical"),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text("Horizontal"),
                          ),
                        ],
                        onChanged: format=='Excel' ? null : (value) {
                          setState(() {
                            portrait = (value! as bool);
                          });
                        },
                      ),
                    ),
                    OutlinedButton(
                      onPressed: format=='Excel' ? null : (){},
                      child: DropdownButton(
                        value: currentSize,
                        underline: const SizedBox.shrink(),
                        dropdownColor: Theme.of(context).cardColor,
                        selectedItemBuilder: (context) => List.generate(Export.defaultFormats.length, (index) =>
                            Center(child: MaterialKeyValuePair(title: "Tamaño", value: Export.defaultSizesUI[index])),
                        ),
                        items: List.generate(Export.defaultFormats.length, (index) =>
                            DropdownMenuItem(
                              value: index,
                              child: Text(Export.defaultSizesUI[index]),
                            ),
                        ),
                        onChanged: format=='Excel' ? null : (value) {
                          setState(() {
                            currentSize = (value! as int);
                          });
                        },
                      ),
                    ),
                    Container(
                      width: 256,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Theme.of(context).dividerColor),
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text("Zoom:", style: Theme.of(context).textTheme.bodySmall,),
                          ),
                          Expanded(
                            child: Slider(
                              value: scale,
                              label: "Zoom: ${NumberFormat("###,###,###,###,##0%").format(scale)}",
                              min: 0.5,
                              max: 1.5,
                              onChanged: format=='Excel' ? null : (value) {
                                setState(() {
                                  scale = value;
                                });
                              },
                              divisions: 100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...widget.actions,
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Directionality(
                  textDirection: rendering.TextDirection.rtl,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    verticalDirection: VerticalDirection.up,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(width: 6,),
                          DialogButton(
                            color: Colors.blue,
                            onPressed: _onExportButtonPressed,
                            child: const Text("EXPORTAR"),
                          ),
                          const SizedBox(width: 6,),
                          const DialogButton.cancel(),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: DialogButton(
                          leading: const Icon(MaterialCommunityIcons.presentation_play, color: Colors.blue,),
                          color: Colors.blue,
                          onPressed: () async{
                            showModalFromZero(
                              context: context,
                              builder: (context) {
                                int index = currentPageNotifier.value;
                                return RawKeyboardListener(
                                  focusNode: FocusNode(),
                                  autofocus: true,
                                  onKey: (value) {
                                    if (PlatformExtended.isWindows && value.logicalKey != LogicalKeyboardKey.escape){
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: GestureDetector(
                                    onTapDown: (details) {
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      color: Colors.black87,
                                      alignment: Alignment.center,
                                      child: Export.dummy(
                                        themeParameters: widget.themeParameters,
                                        dummyChild: _getChild(index, size, null),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text("VISTA PREVIA"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getChild(int index, Size size, Key? key){
    return _PageWrapper(
      themeData: widget.exportThemeData,
      title: widget.showTitle ? textEditingControllers[index].text : null,
      globalKey: key,
      size: size,
      scale: scale,
      child: Builder(
        builder: (context) {
          if (widget.childBuilder!=null){
            return widget.childBuilder!(context, index, currentSize, portrait, scale, format,);
          } else{
            while (scrollControllers.length <= index){
              scrollControllers.add(ScrollController(initialScrollOffset: jumpsSeparatingPages[index]));
            }
            Widget result = widget.scrollableChildBuilder!(context, index, currentSize, portrait, scale, format, scrollControllers[index]);
            result = Padding(
              padding: EdgeInsets.only(bottom: pageBottomPaddings[index]),
              child: result,
            );
            return result;
          }
        },
      ),
    );
  }

}

class _PageWrapper extends StatelessWidget {

  final double scale;
  final Widget child;
  final Size size;
  final Key? globalKey;
  final ThemeData themeData;
  final String? title;

  const _PageWrapper({required this.scale, required this.child, required this.size,
    required this.globalKey, required this.themeData, required this.title,});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(globalKey==null ? 0 : 8.0),
          child: AspectRatio(
            aspectRatio: size.width/size.height,
            child: SizedBox.expand(
              child: ColoredBox(
                color: Colors.white,
                child: FittedBox(
                  alignment: Alignment.center,
                  fit: BoxFit.fitHeight,
                  clipBehavior: Clip.none,
                  child: RepaintBoundary(
                    key: globalKey,
                    child: MediaQuery(
                      data: mediaQuery.copyWith(
                        disableAnimations: true, //TODO 3 this doesn't work for some reason
                      ),
                      child: Theme(
                        data: themeData,
                        child: SizedBox.fromSize(
                          size: size,
                          child: Padding(
                            padding: EdgeInsets.all(32*(2-scale)*(mediaQuery.devicePixelRatio/1.5)),
                            child: Column(
                              children: [
                                if (title!=null && title!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(title!,
                                      style: Theme.of(context).textTheme.headlineMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                Expanded(child: child),
                              ],
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
        ),
      ),
    );
  }
}




