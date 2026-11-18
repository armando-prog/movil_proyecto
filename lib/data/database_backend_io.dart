import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<String> databasePath(String name, {String? override}) async {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  if (isDesktop) {
    sqfliteFfiInit();
  }
  if (override != null) return override;
  if (isDesktop) {
    return p.join((await getApplicationSupportDirectory()).path, name);
  }
  return p.join(await sqflite.getDatabasesPath(), name);
}

Future<Database> openBroteDatabase(
  String path, {
  required int version,
  required OnDatabaseCreateFn onCreate,
  OnDatabaseConfigureFn? onConfigure,
}) {
  final options = OpenDatabaseOptions(
    version: version,
    onCreate: onCreate,
    onConfigure: onConfigure,
  );
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return databaseFactoryFfi.openDatabase(path, options: options);
  }
  return sqflite.openDatabase(path, options: options);
}
