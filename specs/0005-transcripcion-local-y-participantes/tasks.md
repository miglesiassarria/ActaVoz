# 0005 · Tareas: Voz y participantes

Estado: done.

- [x] **T1. Modelos y edición de transcripción**
  - Objetivo: AC3, AC4, AC12, AC13, AC14.
  - Verificación: swift test (TranscriptEditingTests, SessionProcessingTests, SessionEditingPersistenceTests).
  - Evidencia:
    - Método: pruebas de renombrar, reasignar, fusionar, etiquetar «Yo» y persistir; UI con «Usar Ana».
    - Resultado: edición y persistencia en verde; sugerencias Ana/Luis y confirmación observadas.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2 y posteriores.

- [x] **T2. Perfiles, retención y borrado**
  - Objetivo: AC5, AC6, AC8, AC10, AC11.
  - Verificación: swift test (SpeakerProfilesTests) y Ajustes reales.
  - Evidencia:
    - Método: guardar, renombrar, eliminar, emparejar y confirmar tarde sin audio; operaciones en Ajustes.
    - Resultado: consultar, renombrar y eliminar verificados; perfil tardío creado y temporal eliminado; propuesta no confirma sola.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2 y posteriores.

- [x] **T3. ASR local y diarización**
  - Objetivo: AC2, AC3, AC9.
  - Verificación: swift test (SpeechRecognition, AutomaticLanguage, Diarization) y build de la app.
  - Evidencia:
    - Método: frases sintéticas ES/EN; AMI real; sandbox-exec con deny network-outbound; app con FluidAudio 0.18.4.
    - Resultado: ASR correcto; 116 pruebas con red saliente denegada; app compila y diariza.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2.

- [x] **T4. Interfaz de sesión y vista previa**
  - Objetivo: AC1, AC3, AC4, AC6, AC12, AC13, AC14, AC15.
  - Verificación: build firmado y prueba manual de grabación.
  - Evidencia:
    - Método: grabación real, panel en directo, procesado, apertura de sesión y Ajustes.
    - Resultado: panel con texto parcial y cierre X; sesión con «Yo» y system-S1; sugerencias y perfiles operativos.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2 y posteriores.

- [x] **T5. Verificación de aceptación**
  - Objetivo: AC1, AC3, AC6, AC7, AC14 y AC15.
  - Verificación: UI con fixture de nombres, Ajustes, lsof y suite con red denegada.
  - Evidencia:
    - Método: sesión controlada «Me llamo Ana»/«Soy Luis»; consultar, renombrar y eliminar perfiles; lsof -a -p PID -i.
    - Resultado: sugerencias y confirmación visibles; perfiles gestionados; sin conexiones de ActaVoz; 116 pruebas con red denegada.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2 y posteriores.

- [x] **T6. Cierre**
  - Objetivo: actualizar resultados, índice, verificación, ADR y ejecutar validadores.
  - Evidencia:
    - Método: validate_sdd --strict, audit_sdd, build firmado y revisión del diff.
    - Resultado: instalación SDD válida; build correcto; spec e índice en done.
    - Fecha: 2026-11-24.
    - Commit: 3bf1dc2 y cierre de 0005.
