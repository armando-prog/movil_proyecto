import 'dart:io';

import 'package:brote/data/database_service.dart';
import 'package:brote/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late DatabaseService database;
  late BroteUser user;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('brote-test-');
    database = DatabaseService(
      databasePathOverride: p.join(temporaryDirectory.path, 'test.db'),
    );
    await database.open();
    user = await database.register(
      name: 'Ana Verde',
      email: '  ANA@example.com ',
      password: 'jardin-seguro-8',
    );
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('registers, normalizes email, and verifies the password', () async {
    expect(user.email, 'ana@example.com');
    expect(
      (await database.signIn(
        email: 'Ana@Example.com',
        password: 'jardin-seguro-8',
      )).id,
      user.id,
    );
    await expectLater(
      database.signIn(email: user.email, password: 'incorrecta'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      database.register(
        name: 'Otra Ana',
        email: 'ana@example.com',
        password: 'otra-clave-segura',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('creates, reads, updates and removes plant and care records', () async {
    final initialPlants = await database.getPlants(user.id!);
    expect(initialPlants, hasLength(3));

    final plant = Plant(
      userId: user.id!,
      name: 'Helecho',
      species: 'Nephrolepis exaltata',
      location: 'Balcón',
      waterEveryDays: 4,
      lastWateredAt: DateTime.now().subtract(const Duration(days: 5)),
      light: 'Indirecta',
      notes: 'Le gusta la humedad.',
    );
    final id = await database.savePlant(plant);
    final saved = (await database.getPlants(user.id!))
        .singleWhere((item) => item.id == id);
    expect(saved.needsWatering, isTrue);

    await database.savePlant(saved.copyWith(name: 'Helecho nuevo'));
    expect(
      (await database.getPlants(user.id!))
          .singleWhere((item) => item.id == id)
          .name,
      'Helecho nuevo',
    );

    await database.waterPlant(saved);
    final logs = await database.getCareLogs(user.id!);
    expect(logs, hasLength(1));
    expect(logs.single.plantName, 'Helecho');

    await database.deleteCareLog(logs.single.id!, user.id!);
    expect(await database.getCareLogs(user.id!), isEmpty);
    await database.deletePlant(saved);
    expect(
      (await database.getPlants(user.id!)).any((item) => item.id == id),
      isFalse,
    );
  });

  test('keeps plant records separate for different accounts', () async {
    final otherUser = await database.register(
      name: 'Luis',
      email: 'luis@example.com',
      password: 'otra-clave-segura',
    );
    expect(await database.getPlants(otherUser.id!), hasLength(3));
    expect(await database.getCareLogs(otherUser.id!), isEmpty);
  });
}
