export 'web_compile_file_unsupported.dart'
if (dart.library.html) 'web_compile_file_web.dart'
if (dart.library.io) 'web_compile_file_native.dart';

