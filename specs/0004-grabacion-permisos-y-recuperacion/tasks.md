# 0004 · Tareas: Captura y recuperación

Estado: `build`. Captura real, pausa, cierre, recuperación con dos tramos y audio pendiente verificados en la app real. Suite: 88 pruebas, 0 fallos. Queda AC6 (recuperación nativa de fuentes). Detalles y capturas en docs/evidencia/0004/README.md. Los resultados históricos de abajo se conservan; no implican cierre de recuperación, selección de dispositivo, contexto sin red ni repregunta de audio.

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
| AC2 | cumplido (2026-11-24) | Explicación visible; «Solicitar permisos» mostró el diálogo de micrófono y verificó audio del sistema; ambos Permitido. Con firma estable los permisos sobreviven a recompilar y volver a firmar. Si TCC no responde, la interfaz se libera a los 8 s. |
| AC3 | cumplido (2026-11-24) | Captura real de 16 s con CAF separados; correlación de envolventes 0,8946 y desfase micrófono-sistema de +51,1 ms (trayecto acústico). |
| AC4 | cumplido | Sin ninguna fuente disponible, «Empezar» deshabilitado y aviso; pruebas de fuente única. |
| AC5 | cumplido con matiz | Pausa real: contador 00:20 y CAF sin crecer; reanuda hasta 00:24. Los dispositivos siguen activos y se descartan muestras durante la pausa. |
| AC6 | parcial | Detección verificada con cambio real de entrada: aviso «Se perdió la fuente: Micrófono.» y continuación con el sistema. La recuperación automática al volver el dispositivo sigue sin implementarse; no se rota el archivo. |
| AC7 | cumplido (2026-11-24) | Caída real con dos tramos: aviso automático, reanudación, terminación con exportación de 21,89 s y tramos en orden; corregidos cola CAF y orden por UUID. |
| AC8 | cumplido | Grabación real de 105,7 s: estado Procesada y botón Generar resumen; m4a estéreo con RMS 0,1411. |
| AC9 | cumplido | Tres políticas probadas con datos temporales; por defecto guardar. |
| AC10 | cumplido (2026-11-24) | App lanzada con sandbox-exec y deny network-outbound; conexión de prueba denegada; grabación de 11,692 s, 2 canales, RMS 0,1048 y estado Procesada. |
| AC11 | cumplido (2026-11-24) | Fuentes separadas durante el procesamiento y un único audio.m4a combinado de 15,838 s, 2 canales, RMS 0,1431. |
| AC12 | cumplido (2026-11-24) | Cmd+Q mostró confirmación y «Seguir grabando» mantuvo el contador; «Detener y cerrar» exportó 19,37 s y terminó el proceso; en pausa exportó 11,43 s y también cerró. |
| AC13 | cumplido | Al reabrir: diálogo de audio pendiente; Guardar combinó un CAF de 3 s y eliminó marcador; Borrar eliminó CAF y marcador sin crear m4a. |
| AC14 | cumplido (2026-11-24) | Micrófono denegado con TCC real: aviso «Sin permiso para Micrófono. Se grabará con el resto.», botón Abrir Ajustes y exportación solo de sistema de 15,19 s. |
