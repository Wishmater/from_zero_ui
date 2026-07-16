import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fz_test_repl/src/terminal.dart';

class TestRepl {
  final WidgetTester tester;
  bool _running = true;

  TestRepl(this.tester);

  Future<void> run() async {
    Terminal.section('══════════════════════════════════════════════');
    Terminal.section('  fz_test_repl — Flutter Interactive Test REPL');
    Terminal.section('  Type "help" for available commands.');
    Terminal.section('══════════════════════════════════════════════');

    await _pumpIfNeeded();

    io.stdout.write('> ');

    await for (final line in _lineStream()) {
      if (!_running) break;

      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        io.stdout.write('> ');
        continue;
      }

      if (trimmed.startsWith('#')) {
        io.stdout.write('> ');
        continue;
      }

      await _dispatch(trimmed);

      if (_running) {
        io.stdout.write('> ');
      }
    }
  }

  Stream<String> _lineStream() {
    return io.stdin.transform(utf8.decoder).transform(const LineSplitter());
  }

  Future<void> _dispatch(String line) async {
    final parts = line.split(' ');
    final cmd = parts[0].toLowerCase();
    final rest = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      switch (cmd) {
        case 'tap':
          await _cmdTap(rest);
        case 'long_press':
          await _cmdLongPress(rest);
        case 'enter':
          await _cmdEnter(rest);
        case 'find':
          await _cmdFind(rest);
        case 'assert':
          await _cmdAssert(rest);
        case 'assert_no':
          await _cmdAssertNo(rest);
        case 'screenshot':
          await _cmdScreenshot(rest);
        case 'wait':
          await _cmdWait(rest);
        case 'settle':
          await _cmdSettle();
        case 'dump':
          await _cmdDump();
        case 'back':
          await _cmdBack();
        case 'help':
          _cmdHelp();
        case 'quit':
        case 'exit':
          _cmdQuit();
        default:
          Terminal.warn('Unknown command: $cmd. Type "help" for available commands.');
      }
    } on Exception catch (e) {
      Terminal.fail('Command failed: $e');
    }
  }

  Future<void> _pumpIfNeeded() async {
    try {
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } on Exception {
      // App might still be loading/animating — that's fine
    }
  }

  // ─── Commands ────────────────────────────────────────────────

  Future<void> _cmdTap(String text) async {
    if (text.isEmpty) {
      Terminal.warn('Usage: tap <text>');
      return;
    }
    try {
      await tester.tap(find.text(text));
      await _pumpIfNeeded();
      Terminal.ok('Tapped "$text"');
    } on Exception {
      try {
        await tester.tap(find.ancestor(of: find.text(text), matching: find.byType(ElevatedButton)));
        await _pumpIfNeeded();
        Terminal.ok('Tapped "$text" (via ElevatedButton)');
      } on Exception {
        try {
          await tester.tap(find.ancestor(of: find.text(text), matching: find.byType(TextButton)));
          await _pumpIfNeeded();
          Terminal.ok('Tapped "$text" (via TextButton)');
        } on Exception {
          try {
            await tester.tap(find.ancestor(of: find.text(text), matching: find.byType(InkWell)));
            await _pumpIfNeeded();
            Terminal.ok('Tapped "$text" (via InkWell)');
          } on Exception {
            try {
              await tester.tap(find.ancestor(of: find.text(text), matching: find.byType(OutlinedButton)));
              await _pumpIfNeeded();
              Terminal.ok('Tapped "$text" (via OutlinedButton)');
            } on Exception {
              Terminal.fail('Could not tap "$text" — widget not found or not tappable');
            }
          }
        }
      }
    }
  }

  Future<void> _cmdLongPress(String text) async {
    if (text.isEmpty) {
      Terminal.warn('Usage: long_press <text>');
      return;
    }
    try {
      await tester.longPress(find.text(text));
      await _pumpIfNeeded();
      Terminal.ok('Long-pressed "$text"');
    } on Exception {
      Terminal.fail('Could not long-press "$text"');
    }
  }

  Future<void> _cmdEnter(String args) async {
    final firstSpace = args.indexOf(' ');
    if (firstSpace < 0) {
      Terminal.warn('Usage: enter <label> <text>');
      return;
    }
    final label = args.substring(0, firstSpace);
    final text = args.substring(firstSpace + 1);

    try {
      await tester.enterText(find.widgetWithText(TextField, label), text);
      await _pumpIfNeeded();
      Terminal.ok('Entered "$text" into "$label"');
    } on Exception {
      try {
        await tester.enterText(find.widgetWithText(TextFormField, label), text);
        await _pumpIfNeeded();
        Terminal.ok('Entered "$text" into "$label"');
      } on Exception {
        Terminal.fail('Could not find TextField with label "$label"');
      }
    }
  }

  Future<void> _cmdFind(String text) async {
    if (text.isEmpty) {
      Terminal.warn('Usage: find <text>');
      return;
    }
    try {
      final widgets = tester.widgetList(find.text(text));
      final count = widgets.length;
      if (count == 0) {
        Terminal.info('No widgets found with text "$text"');
      } else {
        Terminal.info('Found $count widget${count == 1 ? '' : 's'} with text "$text"');
      }
    } on Exception {
      Terminal.info('No widgets found with text "$text"');
    }
  }

  Future<void> _cmdAssert(String text) async {
    if (text.isEmpty) {
      Terminal.warn('Usage: assert <text>');
      return;
    }
    try {
      final widgets = tester.widgetList(find.text(text));
      if (widgets.isNotEmpty) {
        Terminal.ok('"$text" is present (${widgets.length} match${widgets.length == 1 ? '' : 'es'})');
      } else {
        Terminal.fail('"$text" is NOT present');
      }
    } on Exception {
      Terminal.fail('"$text" is NOT present');
    }
  }

  Future<void> _cmdAssertNo(String text) async {
    if (text.isEmpty) {
      Terminal.warn('Usage: assert_no <text>');
      return;
    }
    try {
      final widgets = tester.widgetList(find.text(text));
      if (widgets.isEmpty) {
        Terminal.ok('"$text" is NOT present (as expected)');
      } else {
        Terminal.fail('"$text" IS present (${widgets.length} match${widgets.length == 1 ? '' : 'es'}) but should not be');
      }
    } on Exception {
      Terminal.ok('"$text" is NOT present (as expected)');
    }
  }

  Future<void> _cmdScreenshot(String args) async {
    final dir = io.Directory('screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final filename = args.isNotEmpty ? args : 'repl_${_timestamp()}.png';
    final path = filename.startsWith('screenshots/') ? filename : 'screenshots/$filename';

    try {
      // integration_test binding supports takeScreenshot(String)
      // ignore: avoid_dynamic_calls
      await (tester.binding as dynamic).takeScreenshot(path);
      Terminal.ok('Screenshot saved to $path');
      return;
    } on NoSuchMethodError {
      // fall through to byte approach
    }

    try {
      // ignore: avoid_dynamic_calls
      final bytes = await (tester.binding as dynamic).takeScreenshot();
      if (bytes != null) {
        await io.File(path).writeAsBytes(bytes);
        Terminal.ok('Screenshot saved to $path');
      } else {
        Terminal.fail('Screenshot returned null bytes');
      }
    } on Exception catch (_) {
      Terminal.fail('Screenshots require integration_test binding.');
    }
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _cmdWait(String args) async {
    final ms = int.tryParse(args) ?? 1000;
    Terminal.info('Waiting ${ms}ms...');
    await tester.pump(Duration(milliseconds: ms));
    await _pumpIfNeeded();
  }

  Future<void> _cmdSettle() async {
    Terminal.info('Settling...');
    try {
      await tester.pumpAndSettle(const Duration(seconds: 10));
      Terminal.ok('Settled');
    } on Exception {
      Terminal.warn('Settle timed out — app may have perpetual animation');
    }
  }

  Future<void> _cmdDump() async {
    final allTexts = <String>[];
    try {
      final textWidgets = tester.widgetList(find.byType(Text));
      for (final widget in textWidgets) {
        final textWidget = widget as Text;
        final data = textWidget.data;
        if (data != null && data.trim().isNotEmpty) {
          allTexts.add(data.trim());
        }
      }
    } on Exception {
      // fall through
    }

    if (allTexts.isEmpty) {
      Terminal.info('No text widgets found on screen');
      return;
    }

    Terminal.section('─── Text on screen (${allTexts.length} widgets) ───');
    for (final t in allTexts) {
      io.stdout.writeln('  "$t"');
    }
    Terminal.section('─── End dump ───');
  }

  Future<void> _cmdBack() async {
    try {
      await tester.tap(find.byIcon(Icons.arrow_back));
      await _pumpIfNeeded();
      Terminal.ok('Navigated back (via arrow_back icon)');
    } on Exception {
      try {
        await tester.tap(find.byIcon(Icons.arrow_back_ios));
        await _pumpIfNeeded();
        Terminal.ok('Navigated back (via arrow_back_ios icon)');
      } on Exception {
        try {
          await tester.tap(find.byType(BackButton));
          await _pumpIfNeeded();
          Terminal.ok('Navigated back (via BackButton)');
        } on Exception {
          Terminal.fail('Could not find back button');
        }
      }
    }
  }

  void _cmdHelp() {
    Terminal.section('─── Available Commands ───');
    io.stdout.writeln('  tap <text>               Tap widget containing text');
    io.stdout.writeln('  long_press <text>        Long-press widget containing text');
    io.stdout.writeln('  enter <label> <text>     Enter text into field with label');
    io.stdout.writeln('  find <text>              Count widgets containing text');
    io.stdout.writeln('  assert <text>            Verify text is present on screen');
    io.stdout.writeln('  assert_no <text>         Verify text is NOT present');
    io.stdout.writeln('  screenshot [filename]    Save a screenshot (screenshots/)');
    io.stdout.writeln('  wait [ms]                Wait milliseconds (default 1000)');
    io.stdout.writeln('  settle                   Wait for all animations to complete');
    io.stdout.writeln('  dump                     List all text widgets on screen');
    io.stdout.writeln('  back                     Navigate back (find and tap back)');
    io.stdout.writeln('  help                     Show this help');
    io.stdout.writeln('  quit, exit               Exit the REPL');
    Terminal.section('───');
  }

  void _cmdQuit() {
    _running = false;
    Terminal.info('Exiting REPL.');
  }
}
