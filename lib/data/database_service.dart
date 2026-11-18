import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DatabaseService {
  DatabaseService({Database? testDatabase, this.databasePathOverride})
    : _database = testDatabase;

  static final DatabaseService instance = DatabaseService();
  static const _databaseName = 'brote.db';
  static const _databaseVersion = 1;
  static final _passwordAlgorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );

  Database? _database;
  final String? databasePathOverride;
  Database? get testDatabase => _database;

  Future<void> open() async {
    if (_database != null) return;
    if (kIsWeb) {
      throw UnsupportedError(
        'Brote guarda sus datos localmente en SQLite y requiere Android o iOS.',
      );
    }

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final path =
        databasePathOverride ??
        (isDesktop
            ? p.join(
                (await getApplicationSupportDirectory()).path,
                _databaseName,
              )
            : p.join(await getDatabasesPath(), _databaseName));
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL COLLATE NOCASE UNIQUE,
            password_hash TEXT NOT NULL,
            password_salt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
            location TEXT NOT NULL,
            water_every_days INTEGER NOT NULL,
            last_watered_at TEXT NOT NULL,
            light TEXT NOT NULL,
            notes TEXT NOT NULL,
            image_path TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE care_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            plant_id INTEGER NOT NULL,
            plant_name TEXT NOT NULL,
            action TEXT NOT NULL,
            note TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
            FOREIGN KEY (plant_id) REFERENCES plants (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX plants_by_owner ON plants (user_id, name)',
        );
        await db.execute(
          'CREATE INDEX logs_by_owner ON care_logs (user_id, created_at)',
        );
      },
    );
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) return;
    await database.close();
    _database = null;
  }

  Database get _db {
    final database = _database;
    if (database == null) throw StateError('DatabaseService.open() required');
    return database;
  }

  Future<BroteUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AuthException('Ya existe una cuenta con ese correo.');
    }

    final salt = Uint8List.fromList(
      List.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final passwordHash = await _hashPassword(password, salt);
    final userId = await _db.insert('users', {
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'password_salt': base64UrlEncode(salt),
    });
    final user = BroteUser(
      id: userId,
      name: name.trim(),
      email: normalizedEmail,
    );
    await _addStarterPlants(userId);
    return user;
  }

  Future<BroteUser> signIn({
    required String email,
    required String password,
  }) async {
    final rows = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    final account = rows.first;
    final salt = base64Url.decode(account['password_salt'] as String);
    final candidate = await _hashPassword(password, salt);
    if (candidate != account['password_hash']) {
      throw const AuthException('Correo o contraseña incorrectos.');
    }
    return BroteUser.fromMap(account);
  }

  Future<BroteUser?> getUser(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : BroteUser.fromMap(rows.first);
  }

  Future<BroteUser> updateUserName(BroteUser user, String name) async {
    await _db.update(
      'users',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return BroteUser(id: user.id, name: name.trim(), email: user.email);
  }

  Future<String> _hashPassword(String password, List<int> salt) async {
    final key = await _passwordAlgorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return base64UrlEncode(await key.extractBytes());
  }

  Future<void> _addStarterPlants(int userId) async {
    final now = DateTime.now();
    final examples = [
      Plant(
        userId: userId,
        name: 'Monstera',
        species: 'Monstera deliciosa',
        location: 'Sala',
        waterEveryDays: 7,
        lastWateredAt: now.subtract(const Duration(days: 8)),
        light: 'Indirecta brillante',
        notes: 'Gira la maceta cada semana para que crezca pareja.',
      ),
      Plant(
        userId: userId,
        name: 'Pilea',
        species: 'Pilea peperomioides',
        location: 'Escritorio',
        waterEveryDays: 6,
        lastWateredAt: now.subtract(const Duration(days: 3)),
        light: 'Luz suave',
        notes: 'Revisa que la tierra esté seca antes de regar.',
      ),
      Plant(
        userId: userId,
        name: 'Sansevieria',
        species: 'Dracaena trifasciata',
        location: 'Dormitorio',
        waterEveryDays: 14,
        lastWateredAt: now.subtract(const Duration(days: 10)),
        light: 'Tolera poca luz',
        notes: 'Evita el exceso de agua.',
      ),
    ];
    for (final plant in examples) {
      await _db.insert('plants', plant.toMap()..remove('id'));
    }
  }

  Future<List<Plant>> getPlants(int userId) async {
    final rows = await _db.query(
      'plants',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Plant.fromMap).toList();
  }

  Future<int> savePlant(Plant plant) async {
    final values = plant.toMap()..remove('id');
    if (plant.id == null) return _db.insert('plants', values);
    await _db.update(
      'plants',
      values,
      where: 'id = ? AND user_id = ?',
      whereArgs: [plant.id, plant.userId],
    );
    return plant.id!;
  }

  Future<void> deletePlant(Plant plant) async {
    await _db.delete(
      'plants',
      where: 'id = ? AND user_id = ?',
      whereArgs: [plant.id, plant.userId],
    );
  }

  Future<void> waterPlant(Plant plant, {String note = ''}) async {
    final now = DateTime.now();
    await _db.update(
      'plants',
      {'last_watered_at': now.toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [plant.id, plant.userId],
    );
    await _db.insert('care_logs', {
      'user_id': plant.userId,
      'plant_id': plant.id,
      'plant_name': plant.name,
      'action': 'Riego',
      'note': note,
      'created_at': now.toIso8601String(),
    });
  }

  Future<int> addCareLog({
    required int userId,
    required int plantId,
    required String plantName,
    required String action,
    String note = '',
  }) => _db.insert('care_logs', {
    'user_id': userId,
    'plant_id': plantId,
    'plant_name': plantName,
    'action': action,
    'note': note,
    'created_at': DateTime.now().toIso8601String(),
  });

  Future<List<CareLog>> getCareLogs(int userId) async {
    final rows = await _db.query(
      'care_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(CareLog.fromMap).toList();
  }

  Future<void> deleteCareLog(int id, int userId) async {
    await _db.delete(
      'care_logs',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
