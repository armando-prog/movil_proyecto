import 'dart:io';

import 'package:brote/data/database_service.dart';
import 'package:brote/data/models.dart';
import 'package:brote/ui/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporaryDirectory;
  late DatabaseService database;
  BroteUser? signedInUser;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'brote-auth-test-',
    );
    database = DatabaseService(
      databasePathOverride: p.join(temporaryDirectory.path, 'auth.db'),
    );
    await database.open();
    signedInUser = null;
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  testWidgets('validates sign-in and registration before saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(
          database: database,
          onSignedIn: (user) async => signedInUser = user,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);

    await tester.tap(find.text('¿Primera vez por aquí? Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Verde');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'corta');
    await tester.enterText(find.byType(TextFormField).at(3), 'distinta');
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(signedInUser, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
