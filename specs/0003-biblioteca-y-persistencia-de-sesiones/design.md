# 0003 · Diseño de biblioteca y persistencia

## Estado y dependencias

Diseño propuesto para la spec aprobada. La aplicación base 0002 y la validación de plataforma 0012 siguen pendientes: rutas de código nuevas aquí son propuestas, no archivos existentes. No iniciar build hasta que las dependencias y contratos compartidos se resuelvan. La persistencia de perfiles de voz pertenece a 0005.

## Enfoque

Un repositorio de sesiones con raíz inyectable gestiona directorios reales y carpetas de sesión. La interfaz SwiftUI consulta ese repositorio; las funciones de grabación, chat y generación se conectarán mediante puntos de entrada, con dobles para verificar la biblioteca aisladamente. La raíz de producción es `~/.ActaVoz`; todas las verificaciones usan una raíz temporal aislada.

## Superficies propuestas

| Superficie | Responsabilidad | Criterios |
| --- | --- | --- |
| `ActaVoz/Library/SessionRepository.swift` | Enumerar, crear, mover, renombrar y eliminar dentro de raíz inyectada | AC2–AC8, AC11, AC13 |
| `ActaVoz/Library/SessionModels.swift` | Identidad, fechas, título, participantes y contenidos opcionales | AC3–AC5, AC10, AC13 |
| `ActaVoz/Library/LibrarySearch.swift` | Buscar en título, transcripción, notas y resumen | AC12 |
| `ActaVoz/Library/LibraryView.swift` y `SessionView.swift` | Barra lateral, lista por fecha, detalle y confirmaciones | AC1, AC7, AC9–AC11 |
| `ActaVozTests/Library/` | Pruebas con archivos ficticios y directorios temporales | AC1–AC13 |

Los nombres exactos se reconciliarán con el proyecto Swift real de 0002 antes de construir; todavía no existen.

## Contratos y decisiones

- `SessionRepository` recibe URL de raíz y ofrece listado por directorio o sin organizar, lectura/escritura de sesión, operaciones de directorios y sesión. No acepta nombres con separadores, `.` o `..`; resolver rutas y rechazar enlaces que salgan de la raíz. La UI presenta errores sin afirmar éxito.
- Sesiones bajo `Notas` o `Directorios/<nombre>`; carpeta con fecha, hora e ID corto. El ID y título se guardan en `sesion.json`; cambiar título no renombra carpeta. La fecha de inicio es dato persistido y el título inicial la muestra con hora local. Evitar colisiones creando una carpeta exclusiva y reintentando con otro ID.
- Mantener `sesion.json`, `transcripcion.json`, `resumen.md`, `notas.md`, `sintesis.md`, `chat.json` y `audio.m4a` cuando correspondan. Los esquemas concretos de transcripción y chat deben coordinarse con 0005 y 0007; esta unidad conserva archivos desconocidos al mover y no los elimina salvo borrado confirmado de toda la sesión.
- Escrituras de metadatos y texto mediante archivo temporal en el mismo directorio y reemplazo atómico cuando sea posible. Serializar operaciones por sesión; informar errores y conservar la última versión válida. No sobrescribir un destino existente al mover o renombrar.
- Borrado de sesión o directorio: confirmación explícita con alcance; cancelar no altera archivos. Confirmar elimina recursivamente la carpeta seleccionada únicamente tras validar que permanece bajo la raíz. Al fallar, informar del resultado y refrescar la biblioteca; no prometer transacción completa de una operación parcial.
- Búsqueda local por coincidencia de texto en título, transcripción, notas y resumen, incluyendo sesiones organizadas y sin organizar. Leer la transcripción JSON estructurada mediante el contrato de 0005; no indexar secretos ni audio. La actualización del índice, si se introduce, es regenerable y no sustituye los archivos.
- Barra lateral con «Sin organizar» y directorios; lista agrupada por fecha de inicio. Detalle con título editable, fecha y participantes; controles de notas, resumen y chat mediante vistas base de prueba. Botón persistente «Nueva nota» invoca una interfaz de inicio que implementará 0004.

## Riesgos y verificaciones

| Riesgo | Mitigación y comprobación |
| --- | --- |
| Fallo durante escritura, movimiento o eliminación | Inyectar errores de E/S en raíz temporal y comprobar preservación e información clara. |
| Enlaces simbólicos o nombres maliciosos | Probar rutas fuera de raíz y enlaces; rechazar la operación antes de modificar datos externos. |
| Duplicados o cambios concurrentes | Crear sesiones simultáneas de prueba y simular colisiones y escrituras serializadas. |
| Contratos de otras specs aún no diseñados | Usar fixtures mínimos y dobles; verificar integración real en las unidades correspondientes. |

## ADR

Crear ADR de persistencia antes de cerrar diseño: límites de raíz, contratos versionados y política de reemplazo atómico. Detalles de datos de voz y migraciones requieren coordinación con 0005; no asumir esquema no acordado.
