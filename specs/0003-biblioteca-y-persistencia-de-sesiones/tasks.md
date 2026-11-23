# 0003 · Tareas de biblioteca y persistencia

Estado: `build`. T1, T2 y T5 están verificadas; T3 y T4 tienen la lógica implementada y probada pero falta comprobar los clics de la interfaz. Los esquemas están en [ADR 0002](../../docs/adr/0002-esquema-de-sesion.md).

- [x] **T1. Raíz y modelos**
  - Objetivo: raíz inyectable, identidad, fecha, título y participantes; creación exclusiva de sesión y escritura segura.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/SessionModels.swift`, `SessionRepository.swift`, `LibraryModel.swift`; pruebas `SessionRepositoryTests`, `ViewModelTests`.
  - Verificación: crear varias sesiones en raíz temporal, comprobar nombres únicos, título y fecha, y reabrir metadatos; simular colisión y fallo de escritura.
  - Evidencia:
    - Método: `./scripts/test-core.sh`; casos `testCreateSessionUsesDateAndShortIDUnderNotas`, `testTwoSessionsAtTheSameInstantGetDifferentFolders`, `testExistingFolderWithSameIdentityRetriesAnotherID`, `testUnwritableInboxReportsErrorWithoutCreatingSession`, `testTitleCanChangeWithoutRenamingTheFolder`, `testParticipantCorrectionsSurviveReopening`.
    - Resultado: 43 pruebas, 0 fallos. Carpetas `AAAA-MM-DD_HH-mm-ss_ID` únicas, reintento con otro identificador ante colisión y error de E/S informado sin crear sesión.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
- [x] **T2. Carpetas y movimiento**
  - Objetivo: crear y renombrar directorios sin anidar y mover sesiones completas sin sobrescribir ni salir de raíz.
  - Archivos: repositorio y pruebas de biblioteca.
  - Verificación: ejecutar AC2 y AC6; probar colisiones, enlaces simbólicos y errores con directorios temporales.
  - Evidencia:
    - Método: `./scripts/test-core.sh`; casos `testDirectoryCreateRenameAndNestingRejection`, `testMoveSessionKeepsIdentityAndContents`, `testMoveOntoExistingFolderIsRejected`, `testPathsOutsideRootAreRejected`, `testUnknownFilesSurviveAMove`.
    - Resultado: 0 fallos. Nombres con separador u ocultos rechazados, movimiento preserva notas y archivos desconocidos, destino existente produce `collision` y las rutas fuera de la raíz se rechazan.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
- [ ] **T3. Borrado y persistencia**
  - Objetivo: confirmación en UI, cancelación sin cambios y borrado completo de sesión o directorio confirmado.
  - Archivos: repositorio, `LibraryModel`, `LibraryView` y pruebas.
  - Verificación: ejecutar AC7–AC8 con contenido ficticio, cancelar y confirmar; simular error de disco y comprobar que no se toca contenido fuera de raíz.
  - Evidencia parcial:
    - Método: `testDeletionNeedsConfirmationAndCancelKeepsData`, `testDeletingDirectoryRemovesContainedSessions`, `testNotesSummarySynthesisAndChatRoundTrip`; compilación de `LibraryView` con la alerta de confirmación.
    - Resultado: cancelar deja la sesión y sus archivos; confirmar elimina la carpeta completa; el contenido persiste al recargar. No se pulsó la alerta en la interfaz ni se simuló un fallo de disco durante el borrado.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
- [ ] **T4. Vistas y navegación**
  - Objetivo: barra lateral, Sin organizar, lista por fecha, detalle, cabecera y botón Nueva nota con punto de entrada de prueba.
  - Archivos: `LibraryView.swift`, `SessionView.swift`, `LibraryModel.swift` y pruebas de modelos.
  - Verificación: ejecutar AC1, AC9–AC11 con fixtures y acciones simuladas; reabrir una corrección de participante.
  - Evidencia parcial:
    - Método: `swift run ActaVozFixtures build/fixtures`; `ActaVoz -ActaVozRoot build/fixtures`; `CGWindowListCopyWindowInfo`; `LibraryModelTests` y `SessionModelTests`.
    - Resultado: la app abre desde la biblioteca de ejemplo con una ventana de 1100×720 y sin errores en el registro. Los modelos filtran por directorio, «Sin organizar», búsqueda y confirman el borrado; guardar título, notas y participantes persiste en disco. No se inspeccionaron visualmente la barra lateral, la cabecera ni el botón, ni se pulsaron.
    - Fecha: 2026-11-23.
    - Commit: 42fb1e2.
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

- [x] Ejecutar verificaciones de T1, T2 y T5 y registrar método, resultado y fecha.
- [ ] Comprobar en la interfaz AC1, AC7, AC9, AC10 y AC11 (clics reales).
- [ ] Simular un fallo de disco durante el borrado y comprobar que no se toca contenido fuera de la raíz.
- [ ] Ejecutar verificación completa del repositorio, validador estricto y auditoría SDD tras las comprobaciones de interfaz.
- [ ] Actualizar spec e índice a `done` solo cuando el cierre esté completo.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | parcial | Vistas y modelos implementados; app abre con fixtures; falta comprobar la navegación con clics. |
| AC2 | cumplido | Crear, renombrar y rechazar anidamiento/duplicados probado en disco. |
| AC3 | cumplido | Carpetas únicas con fecha, hora e ID; colisión reintenta con otro ID. |
| AC4 | cumplido | `sesion.json`, `transcripcion.json` con tiempos y hablantes, `resumen.md` y `audio.m4a`. |
| AC5 | cumplido | Título editado persiste y la carpeta no cambia de nombre. |
| AC6 | cumplido | Mover conserva identidad, notas y archivos desconocidos. |
| AC7 | parcial | Cancelar y confirmar probados en el modelo; falta el clic de la alerta y un fallo de disco simulado. |
| AC8 | cumplido | Contenido releído tras cargar de nuevo la sesión en una instancia nueva. |
| AC9 | parcial | Botón persistente implementado con punto de entrada; falta comprobar el clic. |
| AC10 | parcial | Corrección de participantes persiste; falta editarla en la interfaz. |
| AC11 | parcial | El modelo muestra solo las sesiones sin organizar; falta comprobar la vista. |
| AC12 | cumplido | Búsqueda por título, transcripción, notas y resumen, insensible a acentos. |
| AC13 | cumplido | `notas.md`, `sintesis.md` y `chat.json` se guardan y releen. |
