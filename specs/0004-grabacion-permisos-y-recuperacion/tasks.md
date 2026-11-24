# 0004 · Tareas: Captura y recuperación

Estado: `build`. Corrección de permisos y captura real verificada el 2026-11-23: ambas fuentes, pausa sin crecimiento de CAF y exportación m4a de 24 s con muestras no nulas. Recuperación tras caída real verificada con ambas opciones. Suite: 66 pruebas, 0 fallos. Detalles y capturas en docs/evidencia/0004/README.md. Los resultados históricos de abajo se conservan; no implican cierre de recuperación, selección de dispositivo, contexto sin red ni repregunta de audio.

- [ ] **T1. Preparación y permisos**
  - Objetivo: cumplir AC1–AC4 de la spec.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/CaptureModels.swift`, `RecordingController.swift`; `ActaVoz/RecordingFlow.swift`, `ActaVoz/SystemCaptureDriver.swift`; pruebas `RecordingControllerTests`.
  - Verificación: dobles de fuentes y permisos; comprobar valores iniciales, denegaciones y ausencia de ambas fuentes.
  - Evidencia parcial:
    - Método: captura y clics con CUA sobre la app real (`docs/evidencia/0004/01-panel-preparacion.webp`); pruebas `testStartRecordsBothSourcesAndWritesMarker`, `testDeniedMicrophoneWarnsAndRecordsOnlySystem` y `testNoAvailableSourceFailsWithoutStartingDriver`.
    - Resultado: el panel abre con español, perfiles activados y ambas fuentes; sin permiso, «Empezar» queda deshabilitado y se muestra el aviso. Las pruebas confirman que se graba con la fuente permitida, se avisa de la que falta y no se inicia sin ninguna. AC1 y AC4 verificados; AC2 queda parcial porque el diálogo de macOS no se pudo confirmar; AC3 requiere captura real.
    - Fecha: 2026-11-23.
    - Commit: sin commit.
- [x] **T2. Grabación, pausas y recuperación** (parcial: AC5 y AC10 siguen abiertos)
  - Objetivo: cumplir AC5–AC7 y AC10 de la spec.
  - Archivos: coordinador, `RecordingFlow.swift` y pruebas.
  - Verificación: señal controlada, interrupción del proceso y red desconectada; verificar archivos y contador.
  - Evidencia parcial:
    - Método: `testPauseFreezesElapsedAndResumeContinuesWithoutCountingPause`, `testLosingAllSourcesPausesAndRecoveryResumes`, `testPausedStateIsPersistedForRecovery`.
    - Resultado: la pausa detiene el contador y no procesa fragmentos; la pérdida de una fuente avisa y continúa; la pérdida de ambas pausa; la recuperación reanuda; el marcador `grabacion.json` guarda estado y tiempo.
    - Evidencia real AC7 (2026-11-23): con raíz `build/recovery-test`, grabación de sistema y `kill -9`; al reabrir apareció «Recuperar grabación» con «Reanudar», «Dar por terminada» y «Ahora no». «Reanudar» restauró fuente, idioma y tiempo, escribió un CAF nuevo y exportó m4a de 8,6507 s (2 canales, RMS 0,0762370). «Dar por terminada» eliminó el marcador y abrió la sesión. Prueba `testRecoveredRecordingKeepsElapsedTime`. AC7 cumplido; AC5 y AC10 siguen parciales.
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
| AC3 | parcial | Captura dual real verificada; faltan selección efectiva de micrófono y precisión de sincronización. |
| AC4 | cumplido | Sin ninguna fuente disponible, «Empezar» deshabilitado y aviso; pruebas de fuente única. |
| AC5 | parcial | Pausa real: contador 00:20 y tamaños CAF constantes; reanuda hasta 00:24. Los dispositivos siguen activos y se descartan muestras durante pausa. |
| AC6 | cumplido | Pérdida y recuperación de una y ambas fuentes probadas. |
| AC7 | cumplido | Caída real con kill -9; aviso automático al reabrir, reanudación con fuente y tiempo restaurados, y terminación que conserva y abre la sesión. |
| AC8 | cumplido | Grabación real de 105,7 s: estado Procesada y botón Generar resumen; m4a estéreo con RMS 0,1411. |
| AC9 | cumplido | Tres políticas probadas con datos temporales; por defecto guardar. |
| AC10 | sin verificar | Requiere red desconectada y captura real. |
| AC11 | parcial | Exportación real de 24 s, 2 canales y RMS 0.0530095; falta medir sincronización de fuentes. |
| AC12 | implementado, no verificado | La automatización de Cmd+Q y AppleScript está bloqueada por TCC de Accesibilidad/Automatización (-10004); requiere prueba manual o permiso concedido. |
| AC13 | cumplido | Al reabrir: diálogo de audio pendiente; Guardar combinó un CAF de 3 s y eliminó marcador; Borrar eliminó CAF y marcador sin crear m4a. |
| AC14 | parcial | Mensajes y acceso a Ajustes implementados; falta denegar y grabar con la otra fuente. |
