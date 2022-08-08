import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_from_zero.dart';
import 'package:from_zero_ui/src/app_scaffolding/snackbar_host_from_zero.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:humanizer/humanizer.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:dartx/dartx.dart';


final _percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 1);

Future<bool> saveFileFromZero ({
  Key? snackBarKey,
  required BuildContext context,
  required FutureOr<Uint8List> data,
  required String? pathAppend,
  required String name,
  ValueNotifier<int>? downloadedAmount,
  ValueNotifier<int?>? fileSize,
  VoidCallback? onCancel,
  FutureOr<Uint8List> Function()? onRetry,
  bool autoOpenOnFinish = true,
  bool showSnackBars = true,
  bool showDownloadSnackBar = true,
  bool showResultSnackBar = true, // TODO 3 implement output pickers in not web (optional)
}) async {

  if (!kIsWeb && Platform.isAndroid && !(await Permission.storage.request().isGranted)) {
    return false;
  }

  SnackBarControllerFromZero? downloadSnackBarController;
  bool cancelled = false;
  // show download progress snackBar
  if (showSnackBars && showDownloadSnackBar) {
    final type = SnackBarFromZero.info;
    Widget progressIndicator;
    if (downloadedAmount!=null && fileSize!=null) {
      progressIndicator = ValueListenableBuilder<int>(
        valueListenable: downloadedAmount,
        builder: (context, count, child) {
          return ValueListenableBuilder<int?>(
            valueListenable: fileSize,
            builder: (context, size, child) {
              if (size==null || size==0) {
                size = 1;
              }
              return LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(SnackBarFromZero.colors[type]),
                backgroundColor: SnackBarFromZero.softColors[type],
                value: count/size,
              );
            },
          );

        },
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation(SnackBarFromZero.colors[type]),
        backgroundColor: SnackBarFromZero.softColors[type],
      );
    }
    downloadSnackBarController = SnackBarFromZero(
      key: snackBarKey ?? ValueKey(data.hashCode),
      context: context,
      type: type,
      progressIndicator: progressIndicator,
      title: Text(FromZeroLocalizations.of(context).translate('downloading')),
      onCancel: () {
        cancelled = true;
        onCancel?.call();
      },
      message: downloadedAmount==null ? null : ValueListenableBuilder<int>(
        valueListenable: downloadedAmount,
        builder: (context, count, child) {
          if (fileSize==null) {
            return Text(count.bytes().toString());
          } else {
            return ValueListenableBuilder<int?>(
              valueListenable: fileSize,
              builder: (context, size, child) {
                if (size==null || size==0) {
                  return Text('');
                } else {
                  return Text('${_percentFormatter.format(count/size)}   ( ${count.bytes().toString()} / ${size.bytes().toString()} )');
                }
              },
            );
          }
        },
      ),
    ).show(context);
  }

  bool success = true;
  bool downloadSuccess = false;
  File? file;
  String? uiPath;
  // execute save
  try {

    // finish download
    Uint8List bytes = await data;
    if (cancelled) {
      return false;
    }
    downloadSuccess = true;

    if (kIsWeb){

      // web download implementation (downloaded by browser)
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = name;
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

    } else{

      // get base path depending on the platform
      String? basePath;
      if (Platform.isWindows) {
        basePath = (await getApplicationDocumentsDirectory()).absolute.path;
      } else if (Platform.isAndroid){
        basePath = (await DownloadsPathProvider.downloadsDirectory).absolute.path;
      }

      if (basePath!=null){

        // add pathAppend to the target path
        if (pathAppend!=null) {
          basePath = p.join(basePath, pathAppend);
        }

        // if file already exists, add numbers at the end to avoid conflict
        int i = 1;
        file = File(p.join(basePath, name));
        String baseName = name;
        String extension = '';
        int pointIndex = name.lastIndexOf('.');
        if (pointIndex >= 0) {
          baseName = name.substring(0, pointIndex);
          extension = name.substring(pointIndex);
        }
        while (file!.existsSync()) {
          i++;
          name = '$baseName ($i)$extension';
          file = File(p.join(basePath, name));
        }

        // write data to file
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);

        // get pretty path to show to user
        if (Platform.isWindows) {
          uiPath = FromZeroLocalizations.of(context).translate('documents');
        } else {
          uiPath = FromZeroLocalizations.of(context).translate('downloads');
        }
        if (pathAppend!=null) {
          uiPath = p.join(uiPath, pathAppend);
        }
        uiPath = p.join(uiPath, name);

      }

    }

  } catch (e, st) {
    log ('Error while saving file:', isError: true);
    log (e, stackTrace: st);
    success = false;
  }
  if (cancelled) {
    return false;
  }

  downloadSnackBarController?.dismiss();
  // show results snackBar
  bool retry = false;
  if (success && autoOpenOnFinish) {
    if (Platform.isAndroid){
      OpenFile.open(file!.absolute.path);
      // OpenFile.open(file!.parent.absolute.path);
    } else{
      await launch(file!.absolute.path);
      // await launch(file!.parent.absolute.path);
    }
  } if (showSnackBars && showResultSnackBar) {
    if (success && uiPath!=null) {
      await SnackBarFromZero(
        key: snackBarKey ?? ValueKey(data.hashCode),
        context: context,
        type: SnackBarFromZero.success,
        duration: Duration(seconds: 8),
        title: Text(FromZeroLocalizations.of(context).translate('download_success')),
        message: Text("${FromZeroLocalizations.of(context).translate('downloaded_to')} $uiPath"),
        actions: [
          SnackBarAction(
            label: FromZeroLocalizations.of(context).translate('open').toUpperCase(),
            onPressed: () async {
              if (Platform.isAndroid){
                OpenFile.open(file!.absolute.path);
              } else{
                await launch(file!.absolute.path);
              }
            },
          ),
          if (Platform.isWindows)
            SnackBarAction(
              label: FromZeroLocalizations.of(context).translate('open_folder').toUpperCase(),
              onPressed: () async {
                if (Platform.isAndroid){
                  OpenFile.open(file!.parent.absolute.path);
                } else{
                  await launch(file!.parent.absolute.path);
                }
              },
            ),
        ],
      ).show(context).closed;
    } else if (!success) {
      await SnackBarFromZero(
        key: snackBarKey ?? ValueKey(data.hashCode),
        context: context,
        type: SnackBarFromZero.error,
        duration: Duration(seconds: 6),
        title: Text(FromZeroLocalizations.of(context).translate('download_fail')),
        message: Text(downloadSuccess
            ? FromZeroLocalizations.of(context).translate('error_file')
            : FromZeroLocalizations.of(context).translate('error_connection')),
        actions: [
          if (onRetry!=null)
          SnackBarAction(
            label: FromZeroLocalizations.of(context).translate('retry'),
            onPressed: () {
              retry = true;
            },
          )
        ],
      ).show(context).closed;
    }
  }

  if (retry) {
    success = await saveFileFromZero(
      context: context,
      data: onRetry!(),
      pathAppend: pathAppend,
      name: name,
      downloadedAmount: downloadedAmount,
      fileSize: fileSize,
      onCancel: onCancel,
      onRetry: onRetry,
      showDownloadSnackBar: showDownloadSnackBar,
      showResultSnackBar: showResultSnackBar,
      showSnackBars: showSnackBars,
      snackBarKey: snackBarKey ?? snackBarKey ?? ValueKey(data.hashCode),
    );
  }

  return success;

}