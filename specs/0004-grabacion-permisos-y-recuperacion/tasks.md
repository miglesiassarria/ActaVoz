# 0004 · Tareas: Captura y recuperación

Estado: `build`. Núcleo y panel verificados; falta la captura real con permisos de macOS. El diseño y los criterios que dependen de hardware conservan su resultado parcial.

- [ ] **T1. Preparación y permisos**
  - Objetivo: cumplir AC1–AC4 de la spec.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/CaptureModels.swift`, `RecordingController.swift`; `ActaVoz/RecordingFlow.swift`, `ActaVoz/SystemCaptureDriver.swift`; pruebas `RecordingControllerTests`.
  - Verificación: dobles de fuentes y permisos; comprobar valores iniciales, denegaciones y ausencia de ambas fuentes.
  - Evidencia parcial:
    - Método: captura y clics con CUA sobre la app real (`docs/evidencia/0004/01-panel-preparacion.webp`); pruebas `testStartRecordsBothSourcesAndWritesMarker`, `testDeniedMicrophoneWarnsAndRecordsOnlySystem` y `testNoAvailableSourceFailsWithoutStartingDriver`.
    - Resultado: el panel abre con español, perfiles activados y ambas fuentes; sin permiso, «Empezar» queda deshabilitado y se muestra el aviso. Las pruebas confirman que se graba con la fuente permitida, se avisa de la que falta y no se inicia sin ninguna. AC1 y AC4 verificados; AC2 queda parcial porque el diálogo de macOS no se pudo confirmar; AC3 requiere captura real.
    - Fecha: 2026-11-23.
    - Commit: sin commit.
- [ ] **T2. Grabación, pausas y recuperación**
  - Objetivo: cumplir AC5–AC7 y AC10 de la spec.
  - Archivos: coordinador, `RecordingFlow.swift` y pruebas.
  - Verificación: señal controlada, interrupción del proceso y red desconectada; verificar archivos y contador.
  - Evidencia parcial:
    - Método: `testPauseFreezesElapsedAndResumeContinuesWithoutCountingPause`, `testLosingAllSourcesPausesAndRecoveryResumes`, `testPausedStateIsPersistedForRecovery`.
    - Resultado: la pausa detiene el contador y no procesa fragmentos; la pérdida de una fuente avisa y continúa; la pérdida de ambas pausa; la recuperación reanuda; el marcador `grabacion.json` guarda estado y tiempo. Sin captura real ni interrupción del proceso, AC5 y AC7 quedan parciales y AC10 sin verificar.
    - Fecha: 2026-11-23.
    - Commit: sin commit.
- [ ] **T3. Finalización y conservación**
  - Objetivo: cumplir AC8–AC9 y AC11–AC14 de la spec.
  - Archivos: coordinador, `RecordingFlow.swift`, `SystemCaptureDriver.swift` y pruebas.
  - Verificación: simular procesamiento, tres políticas, cierre y fallos; verificar audio combinado y textos conservados.
  - Evidencia parcial:
    - Método: `testStopKeepsCombinedAudioAndClearsMarker`, `testStopDeletesAudioWhenPolicySaysSo`, `testAskPolicyWaitsForDecisionAndKeepsOrDeletes`, `testAskPolicyCanDiscardPendingAudio`; aviso de cierre con `NSApplicationDelegate`; combinador con `AVMutableComposition`.
    - Resultado: las tres políticas se comportan como se acordó en datos temporales y el marcador de audio pendiente se escribe. El aviso de cierre y el combinador están implementados y compilan. AC8, AC11, AC12, AC13 y AC14 conservan comprobaciones reales pendientes.
    - Fecha: 2026-11-23.
    - Commit: sin commit.

## Cierre

- [ ] Conceder permisos de micrófono y grabación de pantalla y completar una grabación real de 30 segundos con ambas fuentes.
- [ ] Verificar AC3, AC8, AC10, AC11, AC12, AC13 y AC14 en el equipo.
- [ ] Revisar el diff, actualizar ADR si cambia el contrato y pasar spec e índice a `done`.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | Panel con idioma, perfiles, fuentes, dispositivo y «Empezar»; captura 01. |
| AC2 | parcial | Explicación y solicitud lanzadas; el diálogo de macOS no se pudo confirmar. |
| AC3 | sin verificar | Requiere captura real con permisos. |
| AC4 | cumplido | Sin ninguna fuente disponible, «Empezar» deshabilitado y aviso; pruebas de fuente única. |
| AC5 | parcial | Pausa, contador y reanudación probados con dobles; falta audio real. |
| AC6 | cumplido | Pérdida y recuperación de una y ambas fuentes probadas. |
| AC7 | parcial | Marcador y oferta de reanudar/terminar implementados; falta interrupción real. |
| AC8 | parcial | UI de procesado y botón implementados; no ejecutado de extremo a extremo. |
| AC9 | cumplido | Tres políticas probadas con datos temporales; por defecto guardar. |
| AC10 | sin verificar | Requiere red desconectada y captura real. |
| AC11 | parcial | Combinador implementado y probado con dobles; falta señal real. |
| AC12 | implementado | Aviso de cierre con dos opciones; falta comprobarlo con clic real. |
| AC13 | parcial | Marcador de audio pendiente implementado; falta repreguntar al reabrir la sesión. |
| AC14 | parcial | Mensajes y acceso a Ajustes implementados; falta denegar y grabar con la otra fuente. |
