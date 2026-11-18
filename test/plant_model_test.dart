import 'package:brote/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates watering due dates and copies only requested fields', () {
    final plant = Plant(
      userId: 1,
      name: 'Pilea',
      species: 'Pilea peperomioides',
      location: 'Estudio',
      waterEveryDays: 5,
      lastWateredAt: DateTime.now().subtract(const Duration(days: 6)),
      light: 'Suave',
      notes: '',
    );

    expect(plant.needsWatering, isTrue);
    expect(plant.copyWith(name: 'Pilea nueva').species, plant.species);
    expect(plant.copyWith(name: 'Pilea nueva').name, 'Pilea nueva');
  });
}
