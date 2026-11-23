# ADR 0002: Esquema versionado de sesión

- **Estado:** accepted
- **Fecha:** 2026-11-23
- **Spec relacionada:** 0003, con contratos compartidos de 0005 y 0007

## Contexto

La biblioteca guarda cada sesión en una carpeta real bajo `~/.ActaVoz`. Varias unidades (0005 transcripción, 0007 chat, 0008 resumen, 0009 notas) escriben en la misma carpeta, así que el formato debe fijarse antes de que más de un componente lo consuma. Los esquemas concretos no estaban definidos.

## Decisión

Cada sesión es una carpeta `AAAA-MM-DD_HH-mm-ss_ID` con estos archivos:

- `sesion.json`: `schemaVersion` (1), `id` corto estable, `title`, `startDate` ISO 8601 en UTC, `language` (`spanish` | `english` | `automatic`) y `participants` con `id` y `name` editables.
- `transcripcion.json`: `schemaVersion` (1), `language` y `segments` con `id`, `start` y `end` en segundos desde el inicio, `speakerId` y `text`.
- `chat.json`: `schemaVersion` (1) y `messages` con `id`, `role` (`user` | `assistant`), `text` y `createdAt`.
- `notas.md`, `resumen.md` y `sintesis.md`: Markdown en texto plano, sin JSON envolvente.
- `audio.m4a`: audio combinado si se conserva.

Reglas:

- El identificador y la fecha de inicio viven en `sesion.json`; el nombre de la carpeta no cambia al editar el título ni los participantes.
- Las escrituras usan `Data.write(options: .atomic)` y JSON con claves ordenadas.
- Los archivos que el repositorio no conoce se conservan y se mueven con la carpeta; nunca se borran salvo el borrado confirmado de toda la sesión.
- Un campo nuevo exige subir `schemaVersion` y prever lectura del valor anterior; no se cambia el significado de un campo existente.
- Un `sesion.json` inválido se informa como error, no se reinicia en silencio. Un `transcripcion.json` o `chat.json` inválido también se informa al abrir la sesión.

## Alternativas descartadas

- **Un único archivo por sesión:** dificulta que 0005 y 0007 escriban sin pisarse y pierde la lectura humana directa.
- **Base de datos:** contradice las carpetas reales acordadas en el producto.
- **Borrar archivos desconocidos al mover:** rompería datos de unidades futuras.

## Consecuencias

- Ventaja: cada unidad escribe su archivo y puede evolucionar su `schemaVersion` sin bloquear a las demás.
- Coste: hay que mantener tres decodificadores y migraciones cuando cambie un esquema.
- Riesgo aceptado: la búsqueda lee todos los archivos de cada sesión; con bibliotecas grandes hará falta un índice regenerable (0003 lo prevé como caché, no como fuente de verdad).

## Verificación y revisión

Revisar si 0005 (diarización y perfiles) o 0007 (chat en espera) necesitan campos que obliguen a subir `schemaVersion`, o si 0010 requiere exportar datos que hoy no se guardan.
