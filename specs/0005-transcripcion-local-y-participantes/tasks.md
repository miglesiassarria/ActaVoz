# 0005 · Tareas: Voz y participantes

Estado: build. Implementación local; quedan verificaciones manuales y el cierre.

- [x] **T1. Modelos y edición de transcripción**
  - Objetivo: AC3, AC4, AC12, AC13, AC14.
  - Verificación: swift test (TranscriptEditingTests, SessionProcessingTests, SessionEditingPersistenceTests).
  - Evidencia:
    - Método: pruebas de renombrar, reasignar, fusionar, etiquetar «Yo» y persistir.
    - Resultado: pruebas de edición y persistencia en verde; sin segmentos duplicados.
    - Fecha: 2026-11-24.
    - Commit: 362c109 y posteriores.

- [x] **T2. Perfiles, retención y borrado**
  - Objetivo: AC5, AC6, AC8, AC10, AC11.
  - Verificación: swift test (SpeakerProfilesTests) y revisión de Ajustes.
  - Evidencia:
    - Método: guardar, renombrar, eliminar, emparejar y confirmar tarde sin audio.
    - Resultado: perfil tardío creado y temporal eliminado; propuesta no confirma sola.
    - Fecha: 2026-11-24.
    - Commit: 362c109.

- [x] **T3. ASR local y diarización**
  - Objetivo: AC2, AC3, AC9.
  - Verificación: swift test (SpeechRecognition, AutomaticLanguage, Diarization) y build de la app.
  - Evidencia:
    - Método: frases sintéticas ES/EN; AMI real; sandbox-exec con deny network-outbound.
    - Resultado: ASR correcto; 116 pruebas con red saliente denegada; app compila con FluidAudio 0.18.4.
    - Fecha: 2026-11-24.
    - Commit: 362c109.

- [x] **T4. Interfaz de sesión y vista previa**
  - Objetivo: AC1, AC3, AC4, AC6, AC12, AC13, AC14, AC15.
  - Verificación: build firmado y prueba manual de grabación.
  - Evidencia:
    - Método: grabación real, panel en directo, procesado y apertura de la sesión.
    - Resultado: panel muestra texto parcial; sesión con «Yo» y system-S1; transcripción persistida.
    - Fecha: 2026-11-24.
    - Commit: 362c109 y posteriores.

- [ ] **T5. Verificación de aceptación pendiente**
  - Objetivo: AC1 (cierre fuera del panel), AC3 (sugerencias con voces reales), AC6 (tres operaciones en Ajustes), AC7 (tráfico de la app), AC14 (desactivar «Yo» en UI) y AC15 (modelo principal si aplica).
  - Evidencia: pendiente.

- [ ] **T6. Cierre**
  - Objetivo: actualizar resultados, índice, verificación, ADR y ejecutar validadores.
  - Evidencia: pendiente.
