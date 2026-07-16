import 'dart:io' as io;

class Terminal {
  Terminal._();

  static void ok(String msg) => io.stdout.writeln('\x1B[32m[OK]\x1B[0m $msg');
  static void fail(String msg) => io.stdout.writeln('\x1B[31m[FAIL]\x1B[0m $msg');
  static void info(String msg) => io.stdout.writeln('\x1B[34m[INFO]\x1B[0m $msg');
  static void warn(String msg) => io.stdout.writeln('\x1B[33m[WARN]\x1B[0m $msg');
  static void section(String msg) => io.stdout.writeln('\x1B[1;36m$msg\x1B[0m');
}
