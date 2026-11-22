# 0003 · Biblioteca y persistencia de sesiones

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Organizar y conservar sesiones en carpetas reales recuperables.

## Comportamiento esperado

La biblioteca enumera sesiones por fecha y directorio, permite organizar carpetas reales y abrir cada sesión para consultar sus contenidos. Las notas sin organizar se guardan en Notas; su acceso visual exacto sigue por decidir.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Biblioteca:** Barra lateral de directorios y listado central de sesiones agrupadas por fecha; abrir sesión con título, notas, resumen y chat. | Crear sesiones de prueba en disco en varias fechas y directorios, navegar y abrir una vista base con sus datos; utilizar contenido de prueba sin exigir las funciones de 0007–0009. | pendiente |
| AC2 | **Directorios:** Crear y renombrar directorios reales bajo Directorios, sin anidamiento. | Crear y renombrar un directorio de prueba y comprobar la carpeta en disco. | pendiente |
| AC3 | **Sesión nueva:** Guardar nuevas sesiones sin directorio bajo Notas; cada carpeta usa fecha, hora e identificador corto único. | Crear dos sesiones con fecha próxima y comprobar carpetas distintas. | pendiente |
| AC4 | **Contenido:** Conservar metadatos en sesion.json, transcripción estructurada en transcripcion.json, resumen en resumen.md y audio.m4a si se conserva. | Crear sesión con resultados y verificar archivos y marcas temporales de transcripción. | pendiente |
| AC5 | **Título:** El título inicial contiene fecha y hora de inicio y se puede editar sin renombrar la carpeta de identidad. | Cambiar título, reabrir y comparar nombre de carpeta. | pendiente |
| AC6 | **Mover:** Mover una sesión completa a un directorio o entre directorios preservando su contenido. | Mover sesión de prueba y verificar identidad y archivos antes y después. | pendiente |
| AC7 | **Borrar:** Pedir confirmación antes de borrar una sesión o un directorio; el borrado confirmado elimina todos los archivos y sesiones contenidos. Cancelar no cambia datos. | Usar carpetas temporales con contenido; cancelar y confirmar por separado y comprobar disco. | pendiente |
| AC8 | **Persistencia:** Guardar notas, transcripción y resultados hasta borrado manual; conservarlos tras reinicio. | Reabrir aplicación y comparar contenido guardado. | pendiente |
| AC9 | **Nueva nota:** mostrar un botón persistente en la zona inferior derecha para iniciar el flujo de nueva nota. | Navegar entre la biblioteca y directorios y comprobar que el botón invoca un punto de entrada de prueba; el flujo real se verifica en 0004. | pendiente |
| AC10 | **Cabecera:** al abrir una sesión, mostrar fecha y participantes debajo del título y permitir revisar y corregir sus nombres. | Abrir una sesión de prueba, corregir un nombre y reabrirla para verificar que persiste. | pendiente |

## Decisiones previas a aprobación

- Cómo acceder a sesiones sin organizar y si existe búsqueda.
- Si «Nueva nota» permite notas sin audio; dónde y cómo se conservan notas, síntesis y posible historial de chat.
- Representación del audio final y conservación de datos de voz sin audio; se coordina con 0004 y 0005.

## Fuera de alcance

- Sin directorios anidados; el formato de archivos de notas, síntesis y posible chat figura en decisiones previas.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Concurrencia de escritura, conflictos de nombres y recuperación de errores de disco requieren diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los fallos de escritura y los conflictos al mover o renombrar pueden comprometer la persistencia; el diseño debe preservar datos.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
