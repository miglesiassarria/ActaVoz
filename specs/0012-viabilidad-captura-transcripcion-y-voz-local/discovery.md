# 0012 · Captura, transcripción y perfiles locales

## Pregunta o decisión

Determinar la viabilidad de la capacidad y registrar evidencia antes de aprobar las specs dependientes.

## Hechos y fuentes

- **Confirmado por producto:** captura separada de micrófono y sistema; voz y audio locales; español e inglés y opción automática.
- **Observado en documentación, 2026-11-22:** [ScreenCaptureKit](https://developer.apple.com/documentation/ScreenCaptureKit) documenta captura de audio y permiso de grabación de pantalla. [FluidAudio](https://github.com/FluidInference/FluidAudio) documenta diarización y extracción de representaciones de voz; no acredita nuestro caso de uso.
- **Observado en documentación, 2026-11-22:** [AssetInventory de Apple](https://developer.apple.com/documentation/speech/assetinventory) indica que los modelos necesarios para SpeechAnalyzer se descargan y gestionan por el sistema. Su disponibilidad en una instalación sin red debe verificarse tras preparar los recursos.
- **Observado en documentación, 2026-11-22:** [Core Audio taps](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps) permite capturar audio de procesos y describe una solicitud de permiso para audio del sistema; el ejemplo exige macOS 14.2 o posterior. Esto no fija la versión mínima de ActaVoz.
- **Desconocido:** macOS y hardware mínimos, disponibilidad sin red e idiomas de SpeechAnalyzer, compatibilidad de FluidAudio, captura simultánea con auriculares Bluetooth, reinicio de permisos y reconocimiento entre reuniones.

## Hipótesis y desconocidos

- **Supuesto:** los componentes candidatos podrían cumplir los requisitos; no está demostrado para ActaVoz.
- **Desconocido:** resultados, límites, integración y riesgos descritos arriba.

## Experimentos seguros

| Experimento | Resultado esperado | Límite seguro | Evidencia |
| --- | --- | --- | --- |
| Probar captura dual y sincronización | Ambas señales llegan separadas con tiempos comparables | Datos sintéticos en Mac de prueba | No ejecutado |
| Probar permisos, reconexión y Bluetooth | Identificar interrupciones y recuperación por versión de macOS | Sin datos personales | No ejecutado |
| Probar transcripción en español, inglés y detección automática sin red | Medir disponibilidad y resultados con modelos previamente instalados | Audio preparado y autorizado | No ejecutado |
| Probar diarización y perfiles entre reuniones, incluso tras borrar audio | Medir reconocimiento, solapamiento y condiciones de persistencia | Voces sintéticas o consentidas; almacenamiento temporal | No ejecutado |
| Verificar disponibilidad de SpeechAnalyzer y recursos por versión de macOS e idioma; evaluar alternativa si no encaja | Registrar versión mínima, recursos sin red y alternativa viable, incluida detección de idioma | Documentación oficial y pruebas en Mac de prueba | No ejecutado |
| Comparar ScreenCaptureKit y Core Audio taps | Registrar permisos, disponibilidad, captura simultánea y necesidad de reinicio en macOS objetivo | Señales sintéticas y cuenta de prueba | No ejecutado |
| Verificar creación de ~/.ActaVoz sin App Sandbox | Confirmar acceso y ausencia de sobrescritura en macOS objetivo | Home de usuario de prueba con archivo centinela | No ejecutado |
| Evaluar deducción de nombres en local o con LLM | Documentar opciones y efectos sobre uso sin conexión | Transcripciones sintéticas; sin envío de audio | No ejecutado |

## Resultado y siguiente paso

Condiciona la versión mínima y el acceso a carpetas de 0002, y la aprobación técnica de 0004 y 0005. Faltan evidencias y decisiones; no se ha elegido versión mínima ni librería definitiva.
