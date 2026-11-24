# 0012 · Viabilidad captura transcripción y voz local

- **Estado:** superseded
- **Creada:** 2026-11-22
- **Aprobación:** no aplica
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Captura, transcripción y perfiles locales. Registrar evidencia y resolver incógnitas antes de aprobar las especificaciones dependientes.

## Comportamiento esperado

La viabilidad local quedó demostrada el 2026-11-24 para captura, transcripción y diarización. Esta unidad se cierra como superseded: la captura vive en 0004 y las decisiones de voz, idioma y perfiles pasan al diseño de 0005. La evidencia se conserva en discovery.md.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | Registrar fuentes, pruebas, resultados y límites de la investigación. | Inspeccionar discovery.md y reproducir cada experimento con datos controlados. | cumplido (2026-11-24): captura, transcripción, diarización y perfiles con evidencia reproducible |

## Fuera de alcance

- Código de producción y acceso a credenciales o datos personales sin autorización.

## Supuestos

- La viabilidad local está demostrada en macOS 27.2.1/arm64; macOS 26 no se ha probado.
- La detección automática de idioma no la ofrece SpeechAnalyzer y queda como decisión de diseño de 0005.

## Riesgos

- Las pruebas pueden revelar incompatibilidad o requisitos de producto no resueltos.

## Invariantes aplicables

- AGENTS.md, docs/sdd.md y privacidad local de audio.

## Aprendizajes durante la implementación

- SpeechAnalyzer transcribe español e inglés con red saliente bloqueada; FluidAudio Offline VBx separa 4/4 hablantes con DER 5,8–10,3 % en AMI real.
- Los embeddings del mismo hablante entre reuniones alcanzan 0,93–0,97 de similitud, frente a 0,03–0,34 entre hablantes distintos.
- La diarización y la detección de idioma no están cubiertas por SpeechAnalyzer; se decide en 0005.
