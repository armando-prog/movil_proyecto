class BroteUser {
  const BroteUser({this.id, required this.name, required this.email});

  final int? id;
  final String name;
  final String email;

  factory BroteUser.fromMap(Map<String, Object?> map) => BroteUser(
    id: map['id'] as int,
    name: map['name'] as String,
    email: map['email'] as String,
  );
}

class Plant {
  const Plant({
    this.id,
    required this.userId,
    required this.name,
    required this.species,
    required this.location,
    required this.waterEveryDays,
    required this.lastWateredAt,
    required this.light,
    required this.notes,
    this.imagePath,
  });

  final int? id;
  final int userId;
  final String name;
  final String species;
  final String location;
  final int waterEveryDays;
  final DateTime lastWateredAt;
  final String light;
  final String notes;
  final String? imagePath;

  DateTime get nextWatering =>
      lastWateredAt.add(Duration(days: waterEveryDays));

  bool get needsWatering =>
      !nextWatering.isAfter(DateTime.now()) ||
      _sameDay(nextWatering, DateTime.now());

  Plant copyWith({
    int? id,
    int? userId,
    String? name,
    String? species,
    String? location,
    int? waterEveryDays,
    DateTime? lastWateredAt,
    String? light,
    String? notes,
    String? imagePath,
    bool clearImage = false,
  }) => Plant(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    species: species ?? this.species,
    location: location ?? this.location,
    waterEveryDays: waterEveryDays ?? this.waterEveryDays,
    lastWateredAt: lastWateredAt ?? this.lastWateredAt,
    light: light ?? this.light,
    notes: notes ?? this.notes,
    imagePath: clearImage ? null : imagePath ?? this.imagePath,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'species': species,
    'location': location,
    'water_every_days': waterEveryDays,
    'last_watered_at': lastWateredAt.toIso8601String(),
    'light': light,
    'notes': notes,
    'image_path': imagePath,
  };

  factory Plant.fromMap(Map<String, Object?> map) => Plant(
    id: map['id'] as int,
    userId: map['user_id'] as int,
    name: map['name'] as String,
    species: map['species'] as String,
    location: map['location'] as String,
    waterEveryDays: map['water_every_days'] as int,
    lastWateredAt: DateTime.parse(map['last_watered_at'] as String),
    light: map['light'] as String,
    notes: map['notes'] as String,
    imagePath: map['image_path'] as String?,
  );
}

class CareLog {
  const CareLog({
    this.id,
    required this.plantId,
    required this.plantName,
    required this.action,
    required this.note,
    required this.createdAt,
  });

  final int? id;
  final int plantId;
  final String plantName;
  final String action;
  final String note;
  final DateTime createdAt;

  factory CareLog.fromMap(Map<String, Object?> map) => CareLog(
    id: map['id'] as int,
    plantId: map['plant_id'] as int,
    plantName: map['plant_name'] as String,
    action: map['action'] as String,
    note: map['note'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
