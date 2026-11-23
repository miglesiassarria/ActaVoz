# 0003 · Biblioteca y persistencia de sesiones

- **Estado:** build
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Organizar y conservar sesiones en carpetas reales recuperables.

## Comportamiento esperado

La biblioteca enumera sesiones por fecha y directorio, permite organizar carpetas reales y abrir cada sesión para consultar sus contenidos. Las notas sin organizar se guardan en Notas y se muestran desde la opción fija «Sin organizar» de la barra lateral.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Biblioteca:** Barra lateral de directorios y listado central de sesiones agrupadas por fecha; abrir sesión con título, notas, resumen y chat. | Crear sesiones de prueba en disco en varias fechas y directorios, navegar y abrir una vista base con sus datos; utilizar contenido de prueba sin exigir las funciones de 0007–0009. | implementado; modelos probados. Falta comprobar la interfaz con clics (2026-11-23) |
| AC2 | **Directorios:** Crear y renombrar directorios reales bajo Directorios, sin anidamiento. | Crear y renombrar un directorio de prueba y comprobar la carpeta en disco. | cumplido (2026-11-23) |
| AC3 | **Sesión nueva:** Guardar nuevas sesiones sin directorio bajo Notas; cada carpeta usa fecha, hora e identificador corto único. | Crear dos sesiones con fecha próxima y comprobar carpetas distintas. | cumplido (2026-11-23) |
| AC4 | **Contenido:** Conservar metadatos en sesion.json, transcripción estructurada en transcripcion.json, resumen en resumen.md y audio.m4a si se conserva. | Crear sesión con resultados y verificar archivos y marcas temporales de transcripción. | cumplido (2026-11-23) |
| AC5 | **Título:** El título inicial contiene fecha y hora de inicio y se puede editar sin renombrar la carpeta de identidad. | Cambiar título, reabrir y comparar nombre de carpeta. | cumplido (2026-11-23) |
| AC6 | **Mover:** Mover una sesión completa a un directorio o entre directorios preservando su contenido. | Mover sesión de prueba y verificar identidad y archivos antes y después. | cumplido (2026-11-23) |
| AC7 | **Borrar:** Pedir confirmación antes de borrar una sesión o un directorio; el borrado confirmado elimina todos los archivos y sesiones contenidos. Cancelar no cambia datos. | Usar carpetas temporales con contenido; cancelar y confirmar por separado y comprobar disco. | lógica cumplida; falta comprobar el clic de confirmación en la interfaz (2026-11-23) |
| AC8 | **Persistencia:** Guardar notas, transcripción y resultados hasta borrado manual; conservarlos tras reinicio. | Reabrir aplicación y comparar contenido guardado. | cumplido en repositorio y modelos (2026-11-23) |
| AC9 | **Nueva nota:** mostrar un botón persistente en la zona inferior derecha que inicia el flujo de grabación, sin opción de crear una nota exclusivamente de texto mediante ese botón. | Navegar entre la biblioteca y directorios y comprobar que el botón invoca un punto de entrada de prueba; el flujo real se verifica en 0004. | botón con aviso de 0004; falta comprobar el clic (2026-11-23) |
| AC10 | **Cabecera:** al abrir una sesión, mostrar fecha y participantes debajo del título y permitir revisar y corregir sus nombres. | Abrir una sesión de prueba, corregir un nombre y reabrirla para verificar que persiste. | persistencia probada; falta editar en la interfaz (2026-11-23) |
| AC11 | **Sin organizar:** la barra lateral ofrece una opción fija que muestra las notas sin directorio asignado. | Preparar sesiones organizadas y sin organizar en disco y comprobar que la vista muestra las correspondientes sin directorio. | modelo probado; falta comprobar la vista (2026-11-23) |
| AC12 | **Búsqueda:** encontrar sesiones por coincidencias en título, transcripción, notas o resumen. | Crear sesiones de prueba con términos exclusivos en cada campo y comprobar que cada búsqueda devuelve la sesión correspondiente. | cumplido (2026-11-23) |
| AC13 | **Archivos adicionales:** conservar notas personales en `notas.md`, síntesis en `sintesis.md` e historial del chat en `chat.json` dentro de la carpeta de sesión cuando existan. | Preparar contenido de prueba, guardar y reabrir la sesión; verificar los tres archivos y su contenido. | cumplido (2026-11-23) |

## Decisiones previas a aprobación

- No quedan decisiones de producto abiertas identificadas en esta unidad. La ubicación y representación técnica de datos temporales de voz se coordinarán en diseño con 0005, respetando su retención acordada; validar acceso al directorio en 0012.

## Fuera de alcance

- Sin directorios anidados. Los archivos de notas, síntesis y chat están definidos en AC13.
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
