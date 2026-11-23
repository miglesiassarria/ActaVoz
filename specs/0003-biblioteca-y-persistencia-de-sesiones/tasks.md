# 0003 · Tareas de biblioteca y persistencia

Estado: `done`. Núcleo verificado con 43 pruebas y 0 fallos; interfaz verificada el 2026-11-23 con clics y capturas reales sobre la biblioteca de ejemplo. Las capturas están en [docs/evidencia/0003](../../docs/evidencia/0003/README.md).

- [x] **T1. Raíz y modelos**
  - Objetivo: raíz inyectable, identidad, fecha, título y participantes; creación exclusiva de sesión y escritura segura.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/SessionModels.swift`, `SessionRepository.swift`, `LibraryModel.swift`; pruebas `SessionRepositoryTests`, `ViewModelTests`.
  - Verificación: crear varias sesiones en raíz temporal, comprobar nombres únicos, título y fecha, y reabrir metadatos; simular colisión y fallo de escritura.
  - Evidencia:
    - Método: `./scripts/test-core.sh` con `testCreateSessionUsesDateAndShortIDUnderNotas`, `testTwoSessionsAtTheSameInstantGetDifferentFolders`, `testExistingFolderWithSameIdentityRetriesAnotherID`, `testUnwritableInboxReportsErrorWithoutCreatingSession`, `testTitleCanChangeWithoutRenamingTheFolder` y `testParticipantCorrectionsSurviveReopening`.
    - Resultado: 0 fallos. Carpetas `AAAA-MM-DD_HH-mm-ss_ID` únicas, reintento con otro identificador ante colisión y error de E/S sin crear sesión.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
- [x] **T2. Carpetas y movimiento**
  - Objetivo: crear y renombrar directorios sin anidar y mover sesiones completas sin sobrescribir ni salir de raíz.
  - Archivos: repositorio y pruebas de biblioteca.
  - Verificación: ejecutar AC2 y AC6; probar colisiones, enlaces simbólicos y errores con directorios temporales.
  - Evidencia:
    - Método: `testDirectoryCreateRenameAndNestingRejection`, `testMoveSessionKeepsIdentityAndContents`, `testMoveOntoExistingFolderIsRejected`, `testPathsOutsideRootAreRejected` y `testUnknownFilesSurviveAMove`.
    - Resultado: 0 fallos. Nombres con separador u ocultos rechazados, movimiento preserva notas y archivos desconocidos, destino existente produce `collision` y las rutas fuera de la raíz se rechazan.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
- [x] **T3. Borrado y persistencia**
  - Objetivo: confirmación en UI, cancelación sin cambios y borrado completo de sesión o directorio confirmado.
  - Archivos: repositorio, `LibraryModel`, `LibraryView` y pruebas.
  - Verificación: ejecutar AC7–AC8 con contenido ficticio, cancelar y confirmar; comprobar que el contenido sobrevive al reinicio.
  - Evidencia:
    - Método: `testDeletionNeedsConfirmationAndCancelKeepsData` y `testDeletingDirectoryRemovesContainedSessions`; en la interfaz, clic en la papelera, «Cancelar», recuento de sesiones, repetición, «Eliminar» y recuento en disco (`find … -name sesion.json | wc -l`).
    - Resultado: cancelar dejó las 2 sesiones y sus archivos; confirmar eliminó la carpeta y dejó 1; la lista se actualizó. Tras reiniciar, la sesión eliminada no reapareció. Capturas `06` y `08`.
    - Fecha: 2026-11-23.
    - Commit: 6e9070d.
- [x] **T4. Vistas y navegación**
  - Objetivo: barra lateral, Sin organizar, lista por fecha, detalle, cabecera y botón Nueva nota con punto de entrada de prueba.
  - Archivos: `LibraryView.swift`, `SessionView.swift`, `LibraryModel.swift` y pruebas de modelos.
  - Verificación: ejecutar AC1, AC9–AC11 con fixtures y acciones simuladas; reabrir una corrección de participante.
  - Evidencia:
    - Método: `ActaVozFixtures build/fixtures --reset`, app abierta con `-ActaVozRoot`, capturas y clics con CUA; `LibraryModelTests` y `SessionModelTests`.
    - Resultado: «Clientes» filtra a su sesión; «Sin organizar» muestra la lista agrupada; una sesión abre con título, fecha, participantes y las cuatro pestañas con contenido; la búsqueda filtra; «Nueva nota» abre un aviso; editar título y participante se guarda en `sesion.json` y sobrevive al reinicio. Capturas `01`–`05`, `07` y `08`.
    - Fecha: 2026-11-23.
    - Commit: 6e9070d.
- [x] **T5. Archivos y búsqueda**
  - Objetivo: conservar archivos acordados y buscar por título, transcripción, notas y resumen.
  - Archivos: repositorio, `LibrarySearch.swift` y pruebas.
  - Verificación: ejecutar AC4, AC12–AC13 con un término exclusivo por campo y archivos opcionales; verificar supervivencia al mover y reabrir.
  - Evidencia:
    - Método: `testTranscriptKeepsTimestampsAndSpeakers`, `testNotesSummarySynthesisAndChatRoundTrip`, `testAudioIsCopiedAndFlagged`, `testSearchFindsExclusiveTermsInEachField`, `testSearchCoversSummaryAndIsAccentInsensitive`.
    - Resultado: 0 fallos. Tiempos y hablantes conservados; `notas.md`, `resumen.md`, `sintesis.md` y `chat.json` se releen igual; audio copiado y marcado; búsqueda por cada campo e insensible a acentos y mayúsculas.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.

## Cierre

- [x] Ejecutar verificaciones de todas las tareas y registrar método, resultado y fecha.
- [x] Comprobar en la interfaz AC1, AC7, AC9, AC10 y AC11 con clics reales.
- [x] Verificar cada criterio AC1–AC13 individualmente y revisar el diff.
- [x] Ejecutar verificación completa del repositorio, validador estricto y auditoría SDD.
- [x] Actualizar documentación estable y ADR; pasar spec e índice a `done`.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | Sesión abierta con título, fecha, participantes y pestañas Notas/Resumen/Chat/Transcripción; capturas `01`–`04`. |
| AC2 | cumplido | Crear, renombrar y rechazar anidamiento/duplicados probado en disco. |
| AC3 | cumplido | Carpetas únicas con fecha, hora e ID; colisión reintenta con otro ID. |
| AC4 | cumplido | `sesion.json`, `transcripcion.json` con tiempos y hablantes, `resumen.md` y `audio.m4a`. |
| AC5 | cumplido | Título editado persiste y la carpeta no cambia de nombre. |
| AC6 | cumplido | Mover conserva identidad, notas y archivos desconocidos. |
| AC7 | cumplido | Cancelar conserva las sesiones; confirmar elimina la carpeta; captura `06` y recuento en disco. |
| AC8 | cumplido | Tras cerrar y reabrir se mantienen el título editado y la sesión borrada desaparecida; captura `08`. |
| AC9 | cumplido | Botón persistente que abre el aviso de 0004; captura `07`. |
| AC10 | cumplido | Título y participante editados se guardan y sobreviven al reinicio; capturas `03` y `08`. |
| AC11 | cumplido | «Sin organizar» y «Clientes» muestran sus sesiones; capturas `01` y `02`. |
| AC12 | cumplido | Búsqueda «presupuesto» devuelve solo la sesión correspondiente; captura `05`. |
| AC13 | cumplido | `notas.md`, `sintesis.md` y `chat.json` se guardan y releen. |
