
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:archive/archive.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:intl/intl.dart';
import 'package:mlog/mlog.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_upgrade/r_upgrade.dart';

class UpdateFromZero{

  int currentVersion;
  String versionJsonUrl;
  String appDownloadUrl;
  Dio dio;
  Map<String, dynamic>? versionInfo;
  late bool updateAvailable;

  UpdateFromZero(this.currentVersion, this.versionJsonUrl, this.appDownloadUrl, {
    Dio? dio,
  }) : dio = dio ?? Dio() {
    this.dio.interceptors.add(
      RetryInterceptor(
        dio: this.dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }

  Future<UpdateFromZero>? _checkUpdate;
  Future<UpdateFromZero> checkUpdate() async{
    if (_checkUpdate==null){
      _checkUpdate = _checkUpdateInternal();
      File file = File(await getDownloadPath());
      if (file.existsSync()) {
        if (!kIsWeb && Platform.isAndroid && await requestDefaultFilePermission()) {
          file.delete(recursive: true);
        } else {
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
    }
    return _checkUpdate!;
  }
  Future<UpdateFromZero> _checkUpdateInternal() async{
    if (versionInfo==null) {
      final response = await dio.get(versionJsonUrl);
      versionInfo = response.data;
    }
    int? ver = versionInfo![_getPlatformString()];
    updateAvailable = ver != null ?  ver > currentVersion : false;
    return this;
  }
  String _getPlatformString() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isFuchsia) {
      return 'fuchsia';
    }
    return 'unknown';
  }

  Future<bool> promptUpdate(BuildContext context) async {
    if (updateAvailable==true){
      return (await showModalFromZero<bool>(
        context: context,
        builder: (context) => _UpdateWidget(this),
        configuration: const FadeScaleTransitionConfiguration(
          barrierDismissible: false,
        ),
      )) ?? false;
    }
    return false;
  }

  Future<Response?> executeUpdate(BuildContext context, {ProgressCallback? onReceiveProgress}) async{
    if (updateAvailable==true && !kIsWeb){
      log (LgLvl.fine, 'Downloading Update...', type: FzLgType.appUpdate);
      final downloadPath = await getDownloadPath();
      if (!await requestDefaultFilePermission()) {
        return null;
      }
      final download = dio.download(
        appDownloadUrl,
        downloadPath,
        onReceiveProgress: onReceiveProgress ?? (rcv, total) {
          log(LgLvl.finer, 'received: ${rcv.toStringAsFixed(0)} out of total: ${total.toStringAsFixed(0)}', type: FzLgType.appUpdate);
        },
        deleteOnError: true,
      );
      download.then((value) async{
        if (Platform.isWindows) {

          if (appDownloadUrl.endsWith('.exe')
              || appDownloadUrl.endsWith('.msi')
              || appDownloadUrl.endsWith('.msix')) {
            // Update is a windows native installer, just run it and let it do its magic
            Process.start(downloadPath.replaceAll('/', r'\'), [],);
            await Future.delayed(const Duration(seconds: 1));
            FromZeroAppContentWrapper.exitApp(0);
          } else {
            // Assume update is a zip file and manually extract it
            appWindow.title = FromZeroLocalizations.of(context).translate('processing_update');
            final file = File(downloadPath);
            final bytes = file.readAsBytesSync();
            final archive = ZipDecoder().decodeBytes(bytes);
            final tempDirectory = (await getTemporaryDirectory()).absolute.path;
            for (final file in archive) {
              final filename = file.name;
              if (file.isFile) {
                final data = file.content as List<int>;
                File('$tempDirectory/$filename')
                  ..createSync(recursive: true)
                  ..writeAsBytesSync(data);
              } else {
                Directory('$tempDirectory/$filename')
                  .create(recursive: true);
              }
            }
            File argumentsFile = File("update_temp_args.txt");
            String newAppDirectory = p.join(tempDirectory, archive.first.name);
            String scriptPath = Platform.script.path.substring(1, Platform.script.path.indexOf(Platform.script.pathSegments.last))
                .replaceAll('%20', ' ');
            var executableFile = Directory(newAppDirectory).listSync()
                .firstWhere((element) => element.path.endsWith('.exe'));
            argumentsFile.writeAsStringSync("$newAppDirectory\n$scriptPath");
            log(LgLvl.fine, executableFile.absolute.path.replaceAll('/', r'\'), type: FzLgType.appUpdate);
            Process.start(executableFile.absolute.path.replaceAll('/', r'\'), [],
              workingDirectory: scriptPath.replaceAll('/', r'\'),
            );
            await Future.delayed(const Duration(seconds: 1));
            FromZeroAppContentWrapper.exitApp(0);
          }

        } else if (Platform.isAndroid) {

          if (await requestDefaultFilePermission()){
            // this requires adding the following permission to manifest, which causes problems with google play upload
            // <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"></uses-permission>
            RUpgrade.installByPath(downloadPath);
            await Future.delayed(const Duration(seconds: 1));
            // FromZeroAppContentWrapper.exitApp(0);
          }

        }
      });
      return download;
    }
    return null;
  }

  Future<String> getDownloadPath() async{
    final addon = appDownloadUrl.substring(appDownloadUrl.lastIndexOf('/')+1);
    if (!kIsWeb && Platform.isAndroid) {
      return p.join((await PlatformExtended.getDownloadsDirectory()).absolute.path,  addon);
    } else {
      return p.join((await getTemporaryDirectory()).absolute.path,  addon);
    }
  }

  static Future<void> finishUpdate(String newAppPath, String oldAppPath) async{
    await Future.delayed(const Duration(seconds: 1));
    Directory oldAppDirectory = Directory(oldAppPath);
    oldAppDirectory.listSync().forEach((element) {
      element.deleteSync(recursive: true);
    });
    Directory newAppDirectory = Directory(newAppPath);
    copyDirectory(newAppDirectory, oldAppDirectory);
    var executableFile = oldAppDirectory.listSync()
        .firstWhere((element) => element.path.endsWith('.exe'));
    Process.start(executableFile.absolute.path.replaceAll('/', r'\'), [],
        workingDirectory: oldAppPath.replaceAll('/', r'\'),
    );
    await Future.delayed(const Duration(seconds: 1));
    FromZeroAppContentWrapper.exitApp(0);
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

  const _UpdateWidget(this.update);

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
    return DialogFromZero(
      title: !started ? Text(FromZeroLocalizations.of(context).translate('update_available'))
          : progress==1 ? Text(FromZeroLocalizations.of(context).translate('processing_update'))
          : Text(FromZeroLocalizations.of(context).translate('downloading_update')),
      content: SizedBox(
        width: 384,
        child: PageTransitionSwitcher(
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: !started ? Text(FromZeroLocalizations.of(context).translate('update_available_desc'))
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress==1 ? null : progress,
                  ),
                  const SizedBox(height: 6,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(percentFormatter.format(progress)),
                      if (count!=-1 && total!=-1)
                        Text('${doubleDecimalFormatter.format(count)}MB / ${doubleDecimalFormatter.format(total)}MB'),
                    ],
                  ),
                  const SizedBox(height: 18,),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(FromZeroLocalizations.of(context).translate('restart_warning'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
        ),
      ),
      dialogActions: <Widget>[
        if (!started)
          const DialogButton.cancel(),
        if (!started)
          DialogButton.accept(
            child: Text(FromZeroLocalizations.of(context).translate('update').toUpperCase()),
            onPressed: () async {
              setState(() {
                started = true;
              });
              await widget.update.executeUpdate(context,
                onReceiveProgress: (count, total) {
                  setState(() {
                    this.count = count/1048576;
                    this.total = total/1048576;
                    progress = count / total;
                  });
                },
              );
              Navigator.of(context).pop();
            },
          ),
        const SizedBox(width: 6,),
      ],
    );
  }

}

