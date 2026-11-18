import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_support.dart';

Future<String> savePlantImage(XFile image) async {
  try {
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
    return storedFile.path;
  } on FileSystemException catch (error) {
    throw ImageStorageException(error.message);
  }
}

ImageProvider<Object>? plantImageProvider(String path) {
  final file = File(path);
  return file.existsSync() ? FileImage(file) : null;
}
