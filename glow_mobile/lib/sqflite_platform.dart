import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initSqfliteForPlatform() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
