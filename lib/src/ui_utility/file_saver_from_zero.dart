import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:from_zero_ui/from_zero_ui.dart';
import 'package:humanizer/humanizer.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';


final _percentFormatter = NumberFormat.decimalPercentPattern(decimalDigits: 1);

Future<bool> saveFileFromZero ({
  required BuildContext context,
  required FutureOr<List<int>> data,
  required String? pathAppend,
  required String name,
  Key? snackBarKey,
  ValueNotifier<int>? downloadedAmount,
  ValueNotifier<int?>? fileSize,
  VoidCallback? onCancel,
  FutureOr<List<int>> Function()? onRetry,
  bool autoOpenOnFinish = false,
  bool showSnackBars = true,
  bool showDownloadSnackBar = true,
  bool showResultSnackBar = true, // TODO 3 implement output pickers in not web (optional)
  String? successTitle,
  String? successMessage,
  bool isHostContext = false,
}) async {

  // avoid using the context over async gaps
  final snackbarHostContext = isHostContext ? context : context.findAncestorStateOfType<SnackBarHostFromZeroState>()!.context;
  final localizations = FromZeroLocalizations.of(snackbarHostContext);

  if (!kIsWeb && Platform.isAndroid && !(await Permission.storage.request().isGranted)) {
    return false;
  }
  name = name // cleanup filename so it doesn't cause issues with system file path requirements
      .replaceAll('/', '-')
      .replaceAll(r'\', '-'); // TODO 2 validate all banned characters, depending on Platform

  SnackBarControllerFromZero? downloadSnackBarController;
  bool cancelled = false;
  // show download progress snackBar
  if (showSnackBars && showDownloadSnackBar) {
    const type = SnackBarFromZero.info;
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
    // we're trusting that the parent SnackbarHost won't be disposed while waiting. SnackbarHost should live at the root of the widget tree for as long as the app lives.
    // ignore: use_build_context_synchronously
    downloadSnackBarController = SnackBarFromZero(
      key: snackBarKey ?? ValueKey(data.hashCode),
      context: snackbarHostContext,
      type: type,
      progressIndicator: progressIndicator,
      title: Text(localizations.translate('downloading')),
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
                  return const Text('');
                } else {
                  return Text('${_percentFormatter.format(count/size)}   ( ${count.bytes()} / ${size.bytes()} )');
                }
              },
            );
          }
        },
      ),
    ).show(isHostContext: true);
  }

  bool success = true;
  bool downloadSuccess = false;
  File? file;
  String? uiPath;
  Object? error;
  StackTrace? stackTrace;
  // execute save
  try {

    // finish download
    List<int> bytes = await data;
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
      String basePath = (await PlatformExtended.getDownloadsDirectory()).absolute.path;
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
        uiPath = localizations.translate('documents');
      } else {
        uiPath = localizations.translate('downloads');
      }
      if (pathAppend!=null) {
        uiPath = p.join(uiPath, pathAppend);
      }
      uiPath = p.join(uiPath, name);

    }

  } catch (e, st) {
    log ('Error while saving file:', isError: true);
    log (e, stackTrace: st);
    error = e;
    stackTrace = st;
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
      await OpenFile.open(file!.absolute.path);
    } else{
      await launch(file!.absolute.path);
    }
  }
  if (error!=null || (showSnackBars && showResultSnackBar)) {
    if (success && uiPath!=null) {
      // we're trusting that the parent SnackbarHost won't be disposed while waiting. SnackbarHost should live at the root of the widget tree for as long as the app lives.
      // ignore: use_build_context_synchronously
      await SnackBarFromZero(
        key: snackBarKey ?? ValueKey(data.hashCode),
        context: snackbarHostContext,
        type: SnackBarFromZero.success,
        duration: const Duration(seconds: 8),
        title:  Text(successTitle ?? localizations.translate('download_success')),
        message: Text(successMessage ?? "${localizations.translate('downloaded_to')} $uiPath"),
        actions: [
          SnackBarAction(
            label: localizations.translate('open').toUpperCase(),
            onPressed: () async {
              if (Platform.isAndroid){
                await OpenFile.open(file!.absolute.path);
              } else{
                await launch(file!.absolute.path);
              }
            },
          ),
          if (Platform.isWindows)
            SnackBarAction(
              label: 'COPIAR', // TODO 3 internationalize
              onPressed: () async {
                await Process.run('cmd', ['/c', 'echo.|clip']); // clear windows clipboard, necessary because if a file is copied to clipboard, Pasteboard.writeFiles doesn't work
                await Pasteboard.writeFiles([file!.absolute.path]);
              },
            ),
          SnackBarAction(
            label: localizations.translate('open_folder').toUpperCase(),
            onPressed: () async {
              if (Platform.isAndroid) {
                await OpenFile.open(file!.parent.absolute.path);
              } else if (Platform.isWindows) {
                await Process.run('explorer.exe /select,"${file!.absolute.path.replaceAll('/', r'\')}"', []);
              } else {
                await launch(file!.parent.absolute.path);
              }
            },
          ),
        ],
      ).show(isHostContext: true).closed;
    } else if (!success) {
      // we're trusting that the parent SnackbarHost won't be disposed while waiting. SnackbarHost should live at the root of the widget tree for as long as the app lives.
      // ignore: use_build_context_synchronously
      final errorSubtitle = ApiProviderBuilder.getErrorSubtitle(snackbarHostContext, error, stackTrace);
      // ignore: use_build_context_synchronously
      await SnackBarFromZero(
        key: snackBarKey ?? ValueKey(data.hashCode),
        context: snackbarHostContext,
        type: SnackBarFromZero.error,
        icon: downloadSuccess
            ? null
            : ApiProviderBuilder.getErrorIcon(snackbarHostContext, error, stackTrace), // ignore: use_build_context_synchronously
        duration: const Duration(seconds: 6),
        title: Text(localizations.translate('download_fail')),
        message: Text(downloadSuccess
            ? localizations.translate('error_file')
            : ('${ApiProviderBuilder.getErrorTitle(snackbarHostContext, error, stackTrace)}${errorSubtitle==null ? '' : '\n$errorSubtitle'}'),), // ignore: use_build_context_synchronously
        actions: [
          if (onRetry!=null)
          SnackBarAction(
            label: localizations.translate('retry'),
            onPressed: () {
              retry = true;
            },
          ),
        ],
      ).show(isHostContext: true).closed;
    }
  }

  if (retry) {
    // we're trusting that the parent SnackbarHost won't be disposed while waiting. SnackbarHost should live at the root of the widget tree for as long as the app lives.
    // ignore: use_build_context_synchronously
    success = await saveFileFromZero(
      context: snackbarHostContext,
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
      isHostContext: true,
    );
  }

  return success;

}