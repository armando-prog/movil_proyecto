# Propuesta de proyecto: Brote

**Asignatura:** Fundamentos de Desarrollo Móvil (2239)
**Plataforma elegida:** Flutter (Dart), aplicación híbrida para Android e iOS
**Nombre:** Brote — bitácora verde

## Descripción

Brote es una aplicación móvil para organizar el cuidado cotidiano de plantas de interior. Ayuda a recordar cuándo revisar cada planta y permite conservar su ficha, una fotografía y un historial breve de riegos y observaciones. Su intención es acompañar un hábito, no sustituir el criterio de quien cuida la planta con recordatorios rígidos.

## Objetivo

Diseñar e implementar una aplicación móvil adaptativa que integre autenticación, persistencia local, operaciones CRUD, navegación táctil y uso de la cámara del dispositivo, en un producto pequeño y útil para una colección personal.

## Usuarios

- **Persona registrada:** crea una cuenta local, administra su jardín, registra cuidados y modifica su nombre de perfil.
- **Persona sin cuenta:** puede registrarse o iniciar sesión; la colección queda asociada a su cuenta en el dispositivo.

La primera cuenta inicia con tres fichas de ejemplo editables y eliminables para que se pueda recorrer la aplicación desde el primer acceso.

## Módulos principales

La aplicación se organiza en cinco módulos: acceso y registro, inicio, jardín, bitácora y cuenta. La ficha de una planta y su formulario se abren como una ruta secundaria desde el jardín.

1. **Acceso y registro**
   - Registro con nombre, correo y contraseña de al menos ocho caracteres.
   - Validación de campos, confirmación de contraseña y mensajes de error.
   - Inicio de sesión y restauración de la sesión en el dispositivo.
2. **Hoy**
   - Saludo personalizado, resumen de la colección y plantas que requieren revisión.
   - Accesos directos para registrar un riego o añadir una planta.
3. **Mi jardín**
   - Búsqueda por nombre, especie o ubicación; filtro de plantas que necesitan agua.
   - Consulta, alta, edición y eliminación de fichas.
   - Ficha con especie, lugar, luz, frecuencia, último riego, notas y foto.
4. **Bitácora**
   - Historial cronológico de riegos y notas de observación, poda, abono o trasplante.
   - Alta y eliminación de registros.
5. **Tu cuenta**
   - Consulta y cambio de nombre, resumen de actividad y cierre de sesión.

## Datos y persistencia

SQLite local contiene las tablas `users`, `plants` y `care_logs`. Las plantas y entradas se relacionan con su cuenta y se eliminan en cascada cuando se elimina su entidad padre. Las contraseñas no se almacenan en texto legible: se deriva una clave PBKDF2-HMAC-SHA256 con 120 000 iteraciones y una sal aleatoria por cuenta. La sesión conserva solo el identificador de usuario en las preferencias privadas de la aplicación.

Las imágenes se capturan o eligen desde el dispositivo y se guardan en el almacenamiento privado de la aplicación; en navegador, se conservan como datos asociados a la ficha. La información no se sincroniza con la nube ni sale del dispositivo.

## Interacción y hardware

- En Android e iOS, el control de fotografía invoca la cámara con `image_picker`; la foto se asocia a la ficha de la planta.
- En navegador, la versión demostrativa usa SQLite/WebAssembly con IndexedDB, conserva los datos y las fotos en el almacenamiento local y permite elegir una fotografía.
- En Windows, usado como entorno de desarrollo, ese control abre el selector de archivos.
- La colección y la bitácora admiten el gesto de deslizar para iniciar la eliminación; la ficha pide confirmación antes de eliminar una planta.
- Controles, botones y navegación respetan gestos táctiles y muestran estados de foco y selección.

## Adaptabilidad y diseño

La interfaz usa Flutter Material 3, componentes con áreas táctiles amplias y desplazamiento vertical. Los formularios reorganizan sus campos según el ancho disponible; la navegación inferior de teléfono cambia a navegación lateral en pantallas amplias. Las listas, estados vacíos, fichas y formularios se desplazan sin depender de una altura fija, de modo que siguen siendo utilizables en orientación vertical y horizontal.

La dirección visual de Brote es editorial y cálida: fondo de papel, verde profundo, acentos arcilla, jerarquía tipográfica contenida y pequeñas ilustraciones botánicas generadas en la propia interfaz. No utiliza una plantilla de tienda ni imágenes remotas.

## Tecnología y alcance

- Flutter / Dart y Material 3.
- `sqflite` en Android/iOS; `sqflite_common_ffi` en Windows y `sqflite_common_ffi_web` (SQLite/WebAssembly e IndexedDB) en navegador.
- `image_picker` para fotografías y `path_provider` para guardarlas localmente.
- `cryptography` para el hash de contraseñas y `shared_preferences` para restaurar la sesión.

El proyecto no incluye venta de productos, compras, pagos, servidor, sincronización entre dispositivos ni notificaciones del sistema. Los avisos de riego se calculan y muestran dentro de la aplicación a partir de la fecha del último riego y el intervalo configurado.
