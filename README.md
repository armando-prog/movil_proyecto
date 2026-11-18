# Brote

**Brote** es una bitácora móvil para cuidar plantas sin convertirlo en otra lista de pendientes. Guarda tu colección, muestra qué plantas toca revisar y conserva cada riego y observación.

## Funcionalidades

- Registro e inicio de sesión local; las contraseñas se guardan con PBKDF2-HMAC-SHA256 y una sal única.
- Fichas de plantas con nombre, especie, ubicación, luz, frecuencia de riego, notas y fotografía.
- Altas, consultas, edición y eliminación persistentes en SQLite.
- Registro y eliminación de riegos, podas, abonos, trasplantes y observaciones.
- Búsqueda, filtro de plantas que necesitan agua, acciones táctiles y navegación adaptada a móvil y tablet.
- Los datos y las fotos permanecen en el dispositivo. No se requiere cuenta externa ni conexión a un servicio.

## Ejecutar

Requiere Flutter estable y Dart incluidos en el SDK.

```sh
flutter pub get
flutter run
```

En Windows también se puede ejecutar `flutter run -d windows`; la cámara se reemplaza por selección de una fotografía. En Android/iOS, **Añadir planta** abre la cámara. iOS solicita permiso con una explicación visible.

Para ver la aplicación en el navegador, ejecuta `flutter run -d edge` o `flutter run -d chrome`. La versión web también conserva sus datos en SQLite/WASM dentro de IndexedDB. El selector de archivos del navegador permite añadir fotos.

## Validar

```sh
flutter analyze
flutter test
```

La aplicación de producción está dirigida a Android e iOS. `sqflite_common_ffi` habilita el mismo esquema SQLite en Windows para desarrollo y pruebas.

La propuesta académica completa está en [PROPUESTA.md](PROPUESTA.md).
