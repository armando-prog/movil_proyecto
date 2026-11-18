import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import 'components.dart';
import 'theme.dart';

class PlantFormPage extends StatefulWidget {
  const PlantFormPage({super.key, required this.userId, this.plant});
  final int userId;
  final Plant? plant;

  @override
  State<PlantFormPage> createState() => _PlantFormPageState();
}

class _PlantFormPageState extends State<PlantFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _location;
  late final TextEditingController _frequency;
  late final TextEditingController _notes;
  late final TextEditingController _light;
  DateTime? _lastWatered;
  String? _imagePath;
  bool _busy = false;

  bool get _isEditing => widget.plant != null;

  @override
  void initState() {
    super.initState();
    final plant = widget.plant;
    _name = TextEditingController(text: plant?.name ?? '');
    _species = TextEditingController(text: plant?.species ?? '');
    _location = TextEditingController(text: plant?.location ?? '');
    _frequency = TextEditingController(text: '${plant?.waterEveryDays ?? 7}');
    _notes = TextEditingController(text: plant?.notes ?? '');
    _light = TextEditingController(text: plant?.light ?? 'Indirecta brillante');
    _lastWatered = plant?.lastWateredAt ?? DateTime.now();
    _imagePath = plant?.imagePath;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _location.dispose();
    _frequency.dispose();
    _notes.dispose();
    _light.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final source = Platform.isAndroid || Platform.isIOS
          ? ImageSource.camera
          : ImageSource.gallery;
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 86,
      );
      if (image == null) return;
      final documents = await getApplicationDocumentsDirectory();
      final extension = p.extension(image.path).isEmpty
          ? '.jpg'
          : p.extension(image.path);
      final storedFile = await File(image.path).copy(
        p.join(
          documents.path,
          'plant-${DateTime.now().microsecondsSinceEpoch}$extension',
        ),
      );
      if (mounted) setState(() => _imagePath = storedFile.path);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'camera_access_denied'
                  ? 'Activa el permiso de cámara en la configuración del dispositivo.'
                  : 'No se pudo abrir la cámara o la galería: ${error.message ?? error.code}',
            ),
          ),
        );
      }
    } on FileSystemException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar la foto: ${error.message}'),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final existing = widget.plant;
    final plant = Plant(
      id: existing?.id,
      userId: widget.userId,
      name: _name.text.trim(),
      species: _species.text.trim(),
      location: _location.text.trim(),
      waterEveryDays: int.parse(_frequency.text),
      lastWateredAt: _lastWatered ?? DateTime.now(),
      light: _light.text,
      notes: _notes.text.trim(),
      imagePath: _imagePath,
    );
    if (mounted) Navigator.of(context).pop(plant);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ficha' : 'Nueva planta'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Guardar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                width > 700 ? 36 : 20,
                10,
                width > 700 ? 36 : 20,
                40,
              ),
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: _imagePath != null && File(_imagePath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.file(
                            File(_imagePath!),
                            height: 188,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 188,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E9D8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: forest,
                                size: 32,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                Platform.isAndroid || Platform.isIOS
                                    ? 'Toca para tomar una foto'
                                    : 'Toca para elegir una foto',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                const Eyebrow('LO ESENCIAL'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre cariñoso',
                    hintText: 'Ej. Monstera de la ventana',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ponle un nombre a tu planta.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _species,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Especie',
                    hintText: 'Ej. Monstera deliciosa',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe la especie.'
                      : null,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      TextFormField(
                        controller: _location,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Dónde vive',
                          hintText: 'Sala, balcón…',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe su ubicación.'
                            : null,
                      ),
                      TextFormField(
                        controller: _frequency,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Riego cada (días)',
                          suffixText: 'días',
                        ),
                        validator: (value) {
                          final days = int.tryParse(value ?? '');
                          return days == null || days < 1 || days > 90
                              ? 'Elige entre 1 y 90 días.'
                              : null;
                        },
                      ),
                    ];
                    if (constraints.maxWidth < 480) {
                      return Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 12),
                          fields[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: fields[0]),
                        const SizedBox(width: 12),
                        Expanded(child: fields[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _light,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Luz favorita',
                    hintText: 'Indirecta brillante',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notas para su cuidado',
                    alignLabelWithHint: true,
                    hintText: 'Un detalle que quieras recordar…',
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _lastWatered = DateTime.now()),
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Marcar como regada hoy'),
                  ),
                  if (_lastWatered != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Último riego: ${shortDate(_lastWatered!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: mutedInk, fontSize: 12),
                      ),
                    ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(
                      _isEditing ? 'Guardar cambios' : 'Añadir a mi jardín',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
