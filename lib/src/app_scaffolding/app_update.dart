
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:dio_retry/dio_retry.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';

class UpdateFromZero{

  int currentVersion;
  String versionJsonUrl;
  String appDownloadUrl;
  Dio dio;
  Map<String, dynamic>? versionInfo;
  late bool updateAvailable;

  UpdateFromZero(this.currentVersion, this.versionJsonUrl, this.appDownloadUrl, {
    Dio? dio,
  }) : this.dio = dio ?? Dio()..interceptors.add(
    RetryInterceptor(
      dio: dio,
      options: RetryOptions(
        retries: 2,
        retryInterval: const Duration(seconds: 5),
        retryEvaluator: (error) => error.type != DioErrorType.CANCEL && error.type != DioErrorType.RESPONSE,
      ),
    ),
  );

  Future<UpdateFromZero>? _checkUpdate;
  Future<UpdateFromZero> checkUpdate() async{
    if (_checkUpdate==null){
      _checkUpdate = _checkUpdateInternal();
      File file = File(await getDownloadPath());
      if (file.existsSync()) {
        if (file.path.endsWith('.zip')) {
          final bytes = file.readAsBytesSync();
          final archive = ZipDecoder().decodeBytes(bytes);
          String tempDirectory = (await getTemporaryDirectory()).absolute.path;
          File extracted = File(p.join(tempDirectory, archive.first.name.substring(0, archive.first.name.length-1)));
          try{ extracted.deleteSync(recursive: true); } catch(_){}
        }
        file.delete(recursive: true);
      }
    }
    return _checkUpdate!;
  }
  Future<UpdateFromZero> _checkUpdateInternal() async{
    if (versionInfo==null) {
      final response = await dio.get(versionJsonUrl);
      versionInfo = response.data;
    }
    int ver = versionInfo!['windows'];
    updateAvailable = ver > currentVersion;
    return this;
  }

  Future<void> promptUpdate(BuildContext context) async {
    if (updateAvailable==true){
      return showModal(
        context: context,
        builder: (context) => _UpdateWidget(this),
        configuration: FadeScaleTransitionConfiguration(
          barrierDismissible: false,
        ),
      );
    }
  }

  Future<Response?> executeUpdate(BuildContext context, {ProgressCallback? onReceiveProgress}) async{
    if (updateAvailable==true){
      print ('Downloading Update...');
      String tempDirectory = (await getTemporaryDirectory()).absolute.path;
      String downloadPath = await getDownloadPath();
      final download = dio.download(
        appDownloadUrl,
        downloadPath,
        onReceiveProgress: onReceiveProgress ?? (rcv, total) {
          print('received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}');
        },
        deleteOnError: true,
      );
      download.then((value) async{
        if (appDownloadUrl.endsWith('.exe')
            || appDownloadUrl.endsWith('.msi')
            || appDownloadUrl.endsWith('.msix')) {

          // Update is a windows native installer, just run it and let it do its magic
          Process.start(downloadPath.replaceAll('/', '\\'), [],);
          await Future.delayed(Duration(seconds: 1));
          exit(0);

        } else {

          // Assume update is a zip file and manually extract it
          appWindow.title = FromZeroLocalizations.of(context).translate('processing_update');
          final file = File(downloadPath);
          final bytes = file.readAsBytesSync();
          final archive = ZipDecoder().decodeBytes(bytes);
          for (final file in archive) {
            final filename = file.name;
            if (file.isFile) {
              final data = file.content as List<int>;
              File('$tempDirectory/' + filename)
                ..createSync(recursive: true)
                ..writeAsBytesSync(data);
            } else {
              Directory('$tempDirectory/' + filename)
                ..create(recursive: true);
            }
          }
          File argumentsFile = File("update_temp_args.txt");
          String newAppDirectory = p.join(tempDirectory, archive.first.name);
          String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
              .replaceAll('%20', ' ');
          var executableFile = Directory(newAppDirectory).listSync()
              .firstWhere((element) => element.path.endsWith('.exe'));
          argumentsFile.writeAsStringSync(newAppDirectory + "\n" + scriptPath);
          print(executableFile.absolute.path.replaceAll('/', '\\'));
          Process.start(executableFile.absolute.path.replaceAll('/', '\\'), [],
            workingDirectory: scriptPath.replaceAll('/', '\\'),
          );
          await Future.delayed(Duration(seconds: 1));
          exit(0);

        }
      });
      return download;
    }
  }

  Future<String> getDownloadPath() async{
    return p.join((await getTemporaryDirectory()).absolute.path,
      appDownloadUrl.substring(appDownloadUrl.lastIndexOf('/')+1));
  }

  static Future<void> finishUpdate(String newAppPath, String oldAppPath) async{
    await Future.delayed(Duration(seconds: 1));
    Directory oldAppDirectory = Directory(oldAppPath);
    oldAppDirectory.listSync().forEach((element) {
      element.deleteSync(recursive: true);
    });
    Directory newAppDirectory = Directory(newAppPath);
    copyDirectory(newAppDirectory, oldAppDirectory);
    var executableFile = oldAppDirectory.listSync()
        .firstWhere((element) => element.path.endsWith('.exe'));
    Process.start(executableFile.absolute.path.replaceAll('/', '\\'), [],
        workingDirectory: oldAppPath.replaceAll('/', '\\'),
    );
    await Future.delayed(Duration(seconds: 1));
    exit(0);
  }

  static void copyDirectory(Directory source, Directory destination) =>
      source.listSync(recursive: false)
          .forEach((var entity) {
        if (entity is Directory) {
          var newDirectory = Directory(p.join(destination.absolute.path, p.basename(entity.path)));
          newDirectory.createSync();

          copyDirectory(entity.absolute, newDirectory);
        } else if (entity is File) {
          entity.copySync(p.join(destination.path, p.basename(entity.path)));
        }
      });

}


class _UpdateWidget extends StatefulWidget {

  final UpdateFromZero update;

  _UpdateWidget(this.update);

  @override
  __UpdateWidgetState createState() => __UpdateWidgetState();

}

class __UpdateWidgetState extends State<_UpdateWidget> {

  final percentFormatter = NumberFormat("###,###,###,###,##0.0%");
  final doubleDecimalFormatter = NumberFormat("###,###,###,###,##0.00");
  bool started = false;
  double progress = 0;
  double count = -1;
  double total = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      return AlertDialog(
        title: !started ? Text(FromZeroLocalizations.of(context).translate('update_available'))
            : progress==1 ? Text(FromZeroLocalizations.of(context).translate('processing_update'))
            : Text(FromZeroLocalizations.of(context).translate('downloading_update')),
        content: Container(
          width: 384,
          child: PageTransitionSwitcher(
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
                fillColor: Colors.transparent,
              );
            },
            child: !started ? Text(FromZeroLocalizations.of(context).translate('update_available_desc'))
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress==1 ? null : progress,
                    ),
                    SizedBox(height: 6,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(percentFormatter.format(progress)),
                        if (count!=-1 && total!=-1)
                          Text('${doubleDecimalFormatter.format(count)}MB / ${doubleDecimalFormatter.format(total)}MB'),
                      ],
                    ),
                    SizedBox(height: 18,),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(FromZeroLocalizations.of(context).translate('restart_warning'),
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
                  ],
                ),
          ),
        ),
        actions: <Widget>[
          if (!started)
          FlatButton(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(FromZeroLocalizations.of(context).translate('cancel').toUpperCase()
                , style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
            ),
            textColor: Theme.of(context).textTheme.caption!.color,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (!started)
          FlatButton(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(FromZeroLocalizations.of(context).translate('update').toUpperCase()
                , style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
            ),
            textColor: Colors.blue,
            onPressed: () {
              setState(() {
                started = true;
              });
              widget.update.executeUpdate(context,
                onReceiveProgress: (count, total) {
                  setState(() {
                    this.count = count/1048576;
                    this.total = total/1048576;
                    progress = count / total;
                  });
                },
              );
            },
          ),
          SizedBox(width: 6,),
        ],
      );
  }

}
