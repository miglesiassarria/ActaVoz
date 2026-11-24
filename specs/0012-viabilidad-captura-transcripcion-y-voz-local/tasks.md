# 0012 · Tareas

Estado: `superseded` por 0004 (captura) y 0005 (voz). La evidencia se conserva en discovery.md.

- [x] **T1. Captura dual, permisos y recuperación**
  - Objetivo: comprobar que micrófono y sistema llegan separados, sincronizados y se recuperan.
  - Archivos: implementación y evidencia de 0004.
  - Verificación: captura real, correlación de tono y cambio de dispositivo.
  - Evidencia:
    - Método: pruebas de 0004 con audio controlado y cambio USB↔integrado.
    - Resultado: CAF separados, desfase +51,1 ms, audio combinado de 32,81 s tras recuperación.
    - Fecha: 2026-11-24.
    - Commit: `d799552`.

- [x] **T2. Transcripción local español/inglés sin red saliente**
  - Objetivo: comprobar SpeechAnalyzer con modelos instalados.
  - Archivos: `experimentos/transcribir.swift`, `experimentos/idiomas.swift`.
  - Verificación: dos audios sintéticos, locale explícito y `deny network-outbound`.
  - Evidencia:
    - Método: `say` + `sandbox-exec` + `transcribir.swift`.
    - Resultado: frases correctas en ambos idiomas; 13 locales es/en instalados.
    - Fecha: 2026-11-24.
    - Commit: `77e0351`.

- [x] **T3. Diarización y perfiles con AMI real**
  - Objetivo: medir separación de hablantes y reutilización de embeddings.
  - Archivos: `build/FluidAudio` (evaluación, no código de ActaVoz).
  - Verificación: AMI-SDM ES2004a/b y comparación de centroides por hablante.
  - Evidencia:
    - Método: `fluidaudiocli diarization-benchmark --mode offline` y exportación de embeddings.
    - Resultado: DER 10,25 %/5,8 %, 4/4 hablantes, RTFx 120,2×/116,2×; similitud misma voz 0,927–0,968.
    - Fecha: 2026-11-24.
    - Commit: `77e0351`.

- [x] **T4. Decisión y límites**
  - Objetivo: cerrar viabilidad y traspasar decisiones a 0005.
  - Archivos: `spec.md`, `discovery.md`.
  - Verificación: revisión de evidencia y límites declarados.
  - Evidencia:
    - Método: revisión de AC1 y de los experimentos.
    - Resultado: SpeechAnalyzer para ASR; FluidAudio Offline VBx para diarización; detección automática de idioma y perfiles quedan en diseño de 0005.
    - Fecha: 2026-11-24.
    - Commit: pendiente de este commit.

## Cierre

- [x] Todas las tareas tienen verificación y evidencia ejecutada.
- [x] Cada criterio de `spec.md` tiene resultado y evidencia.
- [x] Se revisó el alcance y se preservaron cambios ajenos.
- [x] Se actualizó la documentación estable.
- [x] `spec.md` y el índice muestran el mismo estado.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | `discovery.md` y experimentos de AMI/Speech |
