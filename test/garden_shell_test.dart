import 'dart:io';

import 'package:brote/data/database_service.dart';
import 'package:brote/data/models.dart';
import 'package:brote/ui/garden_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late DatabaseService database;
  late BroteUser user;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'brote-ui-test-',
    );
    database = DatabaseService(
      databasePathOverride: p.join(temporaryDirectory.path, 'garden.db'),
    );
    await database.open();
    user = await database.register(
      name: 'Ana Verde',
      email: 'ana@example.com',
      password: 'jardin-seguro-8',
    );
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  Future<void> showGarden(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: GardenShell(
          user: user,
          database: database,
          onSignedOut: () async {},
          onUserChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'The garden should finish loading from the SQLite test database.',
    );
  }

  testWidgets('navigates through all four primary sections', (tester) async {
    await showGarden(tester);
    expect(find.text('Hola, Ana.'), findsOneWidget);

    await tester.tap(find.text('Jardín'));
    await tester.pumpAndSettle();
    expect(find.text('Mi jardín'), findsOneWidget);
    expect(find.text('Monstera'), findsWidgets);

    await tester.tap(find.text('Bitácora'));
    await tester.pumpAndSettle();
    expect(find.text('Bitácora'), findsWidgets);
    expect(find.text('Una historia por empezar'), findsOneWidget);

    await tester.tap(find.text('Cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Tu cuenta'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('adds a plant and records an observation', (tester) async {
    await showGarden(tester);
    await tester.tap(find.text('Jardín'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Helecho nuevo');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Nephrolepis exaltata',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Balcón');
    await tester.ensureVisible(find.text('Añadir a mi jardín'));
    await tester.tap(find.text('Añadir a mi jardín'));
    await tester.pumpAndSettle();
    expect(find.text('Mi jardín'), findsOneWidget);
    final savedPlants = await tester.runAsync(
      () => database.getPlants(user.id!),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();
    expect(
      savedPlants!.any((plant) => plant.name == 'Helecho nuevo'),
      isTrue,
      reason: 'The editor should persist the submitted plant before returning.',
    );
    expect(find.text('Nueva planta'), findsNothing);
    expect(find.text('Helecho nuevo'), findsWidgets);

    await tester.tap(find.text('Bitácora'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Añadir nota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar en la bitácora'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('Observación'), findsOneWidget);
    final logs = await tester.runAsync(() => database.getCareLogs(user.id!));
    expect(logs, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
