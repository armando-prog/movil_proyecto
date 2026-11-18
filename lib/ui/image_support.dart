export 'image_support_io.dart'
    if (dart.library.js_interop) 'image_support_web.dart';

class ImageStorageException implements Exception {
  const ImageStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}
