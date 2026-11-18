import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_support.dart';

Future<String> savePlantImage(XFile image) async {
  try {
    final bytes = await image.readAsBytes();
    return 'data:${image.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
  } on Exception catch (error) {
    throw ImageStorageException(error.toString());
  }
}

ImageProvider<Object>? plantImageProvider(String path) {
  if (!path.startsWith('data:')) return null;
  final separator = path.indexOf(',');
  if (separator < 0) return null;
  try {
    return MemoryImage(base64Decode(path.substring(separator + 1)));
  } on FormatException {
    return null;
  }
}
