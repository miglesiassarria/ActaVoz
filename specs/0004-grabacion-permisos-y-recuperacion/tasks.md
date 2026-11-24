# 0004 · Tareas: Captura y recuperación

Estado: `build`. Captura real, pausa, cierre, recuperación con dos tramos y audio pendiente verificados en la app real. Suite: 84 pruebas, 0 fallos. Quedan AC2, AC3 (sincronización física), AC6 nativo y AC14. Detalles y capturas en docs/evidencia/0004/README.md. Los resultados históricos de abajo se conservan; no implican cierre de recuperación, selección de dispositivo, contexto sin red ni repregunta de audio.

- [ ] **T1. Preparación y permisos**
  - Objetivo: cumplir AC1–AC4 de la spec.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/CaptureModels.swift`, `RecordingController.swift`; `ActaVoz/RecordingFlow.swift`, `ActaVoz/SystemCaptureDriver.swift`; pruebas `RecordingControllerTests`.
  - Verificación: dobles de fuentes y permisos; comprobar valores iniciales, denegaciones y ausencia de ambas fuentes.
  - Evidencia parcial:
    - Método: captura y clics con CUA sobre la app real (`docs/evidencia/0004/01-panel-preparacion.webp`); pruebas `testStartRecordsBothSourcesAndWritesMarker`, `testDeniedMicrophoneWarnsAndRecordsOnlySystem` y `testNoAvailableSourceFailsWithoutStartingDriver`.
    - Resultado: el panel abre con español, perfiles activados y ambas fuentes; sin permiso, «Empezar» queda deshabilitado y se muestra el aviso. Las pruebas confirman que se graba con la fuente permitida, se avisa de la que falta y no se inicia sin ninguna. AC1 y AC4 verificados; AC2 queda parcial porque el diálogo de macOS no se pudo confirmar; AC3 requiere captura real.
    - Fecha: 2026-11-23.
    - Commit: sin commit.
- [ ] **T2. Grabación, pausas y recuperación** (parcial: AC6 abierto)
  - Objetivo: cumplir AC5–AC7 y AC10 de la spec.
  - Archivos: coordinador, `RecordingFlow.swift` y pruebas.
  - Verificación: señal controlada, interrupción del proceso y red desconectada; verificar archivos y contador.
  - Evidencia parcial:
    - Método: `testPauseFreezesElapsedAndResumeContinuesWithoutCountingPause`, `testLosingAllSourcesPausesAndRecoveryResumes`, `testPausedStateIsPersistedForRecovery`.
    - Resultado: la pausa detiene el contador y no procesa fragmentos; la pérdida de una fuente avisa y continúa; la pérdida de ambas pausa; la recuperación reanuda; el marcador `grabacion.json` guarda estado y tiempo.
    - Evidencia real AC7 (2026-11-23): con raíz `build/recovery-test`, grabación de sistema y `kill -9`; al reabrir apareció «Recuperar grabación» con «Reanudar», «Dar por terminada» y «Ahora no». «Reanudar» restauró fuente, idioma y tiempo, escribió un CAF nuevo y exportó m4a de 8,6507 s (2 canales, RMS 0,0762370). «Dar por terminada» eliminó el marcador y abrió la sesión. Prueba `testRecoveredRecordingKeepsElapsedTime`. Resultado histórico; AC5 y AC10 se verificaron después.
    - Evidencia real AC7 (2026-11-24): grabación de sistema, tono 440 Hz, `kill -9`, reapertura, «Reanudar» con segundo tramo y «Dar por terminada». El m4a final duró 21,8888 s con el tramo 2,9055–10,0095 y el segundo 12,7901–21,8888 en orden, separados por el hueco real. Se corrigieron la cola CAF posterior al checkpoint y el orden por UUID.
    - Fecha: 2026-11-24.
    - Commit: pendiente.
- [ ] **T3. Finalización y conservación**
  - Objetivo: cumplir AC8–AC9 y AC11–AC14 de la spec.
  - Archivos: coordinador, `RecordingFlow.swift`, `SystemCaptureDriver.swift` y pruebas.
  - Verificación: simular procesamiento, tres políticas, cierre y fallos; verificar audio combinado y textos conservados.
  - Evidencia parcial:
    - Método: `testStopKeepsCombinedAudioAndClearsMarker`, `testStopDeletesAudioWhenPolicySaysSo`, `testAskPolicyWaitsForDecisionAndKeepsOrDeletes`, `testAskPolicyCanDiscardPendingAudio`; aviso de cierre con `NSApplicationDelegate`; combinador con `AVMutableComposition`.
    - Resultado: AC8, AC9, AC12 y AC13 verificados en la app real; AC11 verificado con composición sintética y recuperación real; AC14 solo con dobles y mensajes.
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
| AC2 | parcial | Explicación y solicitud lanzadas; el diálogo de macOS no se confirma. Si TCC no responde, la interfaz se libera a los 8 s en vez de quedar bloqueada (verificado en app real). |
| AC3 | parcial | Captura dual real verificada; faltan selección efectiva de micrófono y precisión de sincronización. |
| AC4 | cumplido | Sin ninguna fuente disponible, «Empezar» deshabilitado y aviso; pruebas de fuente única. |
| AC5 | cumplido con matiz | Pausa real: contador 00:20 y CAF sin crecer; reanuda hasta 00:24. Los dispositivos siguen activos y se descartan muestras durante la pausa. |
| AC6 | parcial | Monitor nativo: 4 s sin buffers marca pérdida, cierra el tramo, reinicia fuentes y solo anuncia recuperación tras un búfer válido; probado a nivel de controlador y compilación. Falta desconexión física real. |
| AC7 | cumplido (2026-11-24) | Caída real con dos tramos: aviso automático, reanudación, terminación con exportación de 21,89 s y tramos en orden; corregidos cola CAF y orden por UUID. |
| AC8 | cumplido | Grabación real de 105,7 s: estado Procesada y botón Generar resumen; m4a estéreo con RMS 0,1411. |
| AC9 | cumplido | Tres políticas probadas con datos temporales; por defecto guardar. |
| AC10 | cumplido (2026-11-24) | App lanzada con sandbox-exec y deny network-outbound; conexión de prueba denegada; grabación de 11,692 s, 2 canales, RMS 0,1048 y estado Procesada. |
| AC11 | parcial | Composición real reproducible: 5 s, 440+880 simultáneos y 1320 posterior, sin fuga (3e-9); recuperación real de 21,89 s. Falta medir desfase entre dos dispositivos físicos. |
| AC12 | cumplido (2026-11-24) | Cmd+Q mostró confirmación y «Seguir grabando» mantuvo el contador; «Detener y cerrar» exportó 19,37 s y terminó el proceso; en pausa exportó 11,43 s y también cerró. |
| AC13 | cumplido | Al reabrir: diálogo de audio pendiente; Guardar combinó un CAF de 3 s y eliminó marcador; Borrar eliminó CAF y marcador sin crear m4a. |
| AC14 | parcial | Mensajes y acceso a Ajustes implementados; falta denegar y grabar con la otra fuente. |
