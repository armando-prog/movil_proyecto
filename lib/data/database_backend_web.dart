import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<String> databasePath(String name, {String? override}) async =>
    override ?? name;

Future<Database> openBroteDatabase(
  String path, {
  required int version,
  required OnDatabaseCreateFn onCreate,
  OnDatabaseConfigureFn? onConfigure,
}) => databaseFactoryFfiWeb.openDatabase(
  path,
  options: OpenDatabaseOptions(
    version: version,
    onCreate: onCreate,
    onConfigure: onConfigure,
  ),
);
