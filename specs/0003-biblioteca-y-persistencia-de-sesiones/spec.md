# 0003 · Biblioteca y persistencia de sesiones

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Organizar y conservar sesiones en carpetas reales recuperables.

## Comportamiento esperado

La capacidad debe cumplir los criterios observables siguientes. La definición de producto y los acuerdos de la conversación son la fuente de alcance; las decisiones no acordadas se registran como riesgos, no como hechos. Las pruebas usan datos controlados y no registran secretos ni reuniones personales.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Biblioteca:** Barra lateral de directorios y listado central de sesiones agrupadas por fecha; abrir sesión con título, notas, resumen y chat. | Crear sesiones en varias fechas y directorios y navegar por el listado. | pendiente |
| AC2 | **Directorios:** Crear y renombrar directorios reales bajo Directorios, sin anidamiento. | Crear y renombrar un directorio de prueba y comprobar la carpeta en disco. | pendiente |
| AC3 | **Sesión nueva:** Guardar nuevas sesiones sin directorio bajo Notas; cada carpeta usa fecha, hora e identificador corto único. | Crear dos sesiones con fecha próxima y comprobar carpetas distintas. | pendiente |
| AC4 | **Contenido:** Conservar metadatos en sesion.json, transcripción estructurada en transcripcion.json, resumen en resumen.md y audio.m4a si se conserva. | Crear sesión con resultados y verificar archivos y marcas temporales de transcripción. | pendiente |
| AC5 | **Título:** El título inicial contiene fecha y hora de inicio y se puede editar sin renombrar la carpeta de identidad. | Cambiar título, reabrir y comparar nombre de carpeta. | pendiente |
| AC6 | **Mover:** Mover una sesión completa a un directorio o entre directorios preservando su contenido. | Mover sesión de prueba y verificar identidad y archivos antes y después. | pendiente |
| AC7 | **Borrar:** Pedir confirmación antes de borrar una sesión o un directorio; el borrado confirmado elimina todos los archivos y sesiones contenidos. Cancelar no cambia datos. | Usar carpetas temporales con contenido; cancelar y confirmar por separado y comprobar disco. | pendiente |
| AC8 | **Persistencia:** Guardar notas, transcripción y resultados hasta borrado manual; conservarlos tras reinicio. | Reabrir aplicación y comparar contenido guardado. | pendiente |

## Fuera de alcance

- API REST de fase 2, adjuntos en chat, calendario y control de costes.
- Código de producción, diseño y tareas de implementación durante la fase de especificación.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Concurrencia de escritura, conflictos de nombres y recuperación de errores de disco requieren diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los componentes propuestos y comportamientos de proveedores requieren validación antes de garantizar el resultado.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
