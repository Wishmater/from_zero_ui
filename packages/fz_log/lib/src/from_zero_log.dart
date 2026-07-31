import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mlog/mlog.dart';

/// Override this for custom logging, including logs from from_zero
void Function(
  LgLvl level,
  String? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  Map<String, Object>? data,
  int extraTraceLineOffset,
  FlutterErrorDetails? details,
})
log = defaultLog;

void defaultLog(
  LgLvl level,
  String? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  Map<String, Object>? data,
  int extraTraceLineOffset = 0,
  FlutterErrorDetails? details,
}) {
  final message = defaultLogGetString(
    level,
    msg,
    type: type,
    e: e,
    st: st,
    extraTraceLineOffset: extraTraceLineOffset + 1,
    details: details,
  );
  if (message != null) {
    print(message); //ignore: avoid_print
  }
}

String? defaultLogGetMap(
  JsonMessageBuilder messageBuilder,
  LgLvl level,
  String msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  Map<String, Object>? data,
  int extraTraceLineOffset = 0,
  FlutterErrorDetails? details,
}) {
  if (level.value > LogOptions.instance.getLvlForType(type).value) {
    return null;
  }

  final logBuilder = LogBuilder(
    level: level,
    message: msg,
    error: e,
    stackTrace: st,
    type: type,
    extra: data,
    extraTraceLineOffset: extraTraceLineOffset + 1,
    messageBuilder: messageBuilder,
  );

  if (e is DioException) {
    msg +=
        ' (${e.type})'
        '\n  ${e.requestOptions.uri}'
        '${e.response == null ? '' : '  ${e.response!.statusCode} - ${_parseDioErrorResponse(e.response!.data)}'}';

    logBuilder
      ..setExtra('data_dio_url', e.requestOptions.uri.toString())
      ..setExtra('data_dio_error_type', e.type.toString());

    if (e.response != null) {
      if (e.response!.statusCode != null) {
        logBuilder.setExtra(
          "data_dio_response_status_code",
          e.response!.statusCode!,
        );
      }
      logBuilder.setExtra(
        'data_dio_response_data',
        _parseDioErrorResponse(e.response!.data),
      );
    }
  }
  if (details != null) {
    logBuilder.setExtra(
      'data_flutter_error_details',
      getFlutterDetailsString(details),
    );
  }
  logBuilder.message = msg;

  return logBuilder.buildMessage();
}

String? defaultLogGetString(
  LgLvl level,
  String? msg, {
  Object? type,
  Object? e,
  StackTrace? st,
  Map<String, Object>? data,
  int extraTraceLineOffset = 0,
  FlutterErrorDetails? details,
  MessageBuilder? messageBuilder,
}) {
  if (level.value > LogOptions.instance.getLvlForType(type).value) {
    return null;
  }
  if (e is DioException) {
    msg ??= '';
    msg +=
        ' (${e.type})'
        '\n  ${e.requestOptions.uri}'
        '${e.response == null ? '' : '  ${e.response!.statusCode} - ${_parseDioErrorResponse(e.response!.data)}'}';
  }
  String message = LogBuilder(
    level: level,
    message: msg,
    error: e,
    stackTrace: st,
    type: type,
    extra: data,
    extraTraceLineOffset: extraTraceLineOffset + 1,
    messageBuilder: messageBuilder,
  ).buildMessage();
  if (details != null) {
    message = addFlutterDetailsToMlog(message, details);
  }
  return message;
}

String _parseDioErrorResponse(dynamic data) {
  if (data is List<int>) return utf8.decode(data, allowMalformed: true);
  return data.toString();
}

String getFlutterDetailsString(FlutterErrorDetails details) {
  return TextTreeRenderer(
    wrapWidthProperties: 100,
    maxDescendentsTruncatableNode: 5,
  ).render(details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error)).trimRight();
}

String addFlutterDetailsToMlog(String msg, FlutterErrorDetails details) {
  String detailsString = '\n${getFlutterDetailsString(details)}';
  detailsString = detailsString.splitMapJoin(
    '\n',
    onNonMatch: (e) {
      return '    $e';
    },
  );
  if (msg.length <= 3) return detailsString;
  return msg.substring(0, msg.length - 2) + detailsString + msg.substring(msg.length - 2);
}

enum FzLgType {
  routing('fzRouting', '[FZ_ROUTING]'),
  appUpdate('fzAppUpdate', '[FZ_APP_UPDATE]'),
  dao('fzDao', '[FZ_DAO]'),
  network('network', '[NETWORK]');

  final String name;
  final String print;
  const FzLgType(this.name, this.print);

  @override
  String toString() => print;

  /// Dado un string [s] devuelve un [FzLgType] opcional
  static FzLgType fromString(String s) {
    for (final type in FzLgType.values) {
      if (type.name == s) {
        return type;
      }
    }
    throw ArgumentError("String not matching", "s");
  }
}
