# 0012 · Captura, transcripción y perfiles locales

## Pregunta o decisión

Determinar la viabilidad de la capacidad y registrar evidencia antes de aprobar las specs dependientes.

## Hechos y fuentes

- **Confirmado por producto:** captura separada de micrófono y sistema; voz y audio locales; español e inglés y opción automática.
- **Observado en documentación, 2026-11-22:** [ScreenCaptureKit](https://developer.apple.com/documentation/ScreenCaptureKit) documenta captura de audio y permiso de grabación de pantalla. [FluidAudio](https://github.com/FluidInference/FluidAudio) documenta diarización y extracción de representaciones de voz; no acredita nuestro caso de uso.
- **Observado en documentación, 2026-11-22:** [AssetInventory de Apple](https://developer.apple.com/documentation/speech/assetinventory) indica que los modelos necesarios para SpeechAnalyzer se descargan y gestionan por el sistema. Su disponibilidad en una instalación sin red debe verificarse tras preparar los recursos.
- **Observado en documentación, 2026-11-22:** [Core Audio taps](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps) permite capturar audio de procesos y describe una solicitud de permiso para audio del sistema; el ejemplo exige macOS 14.2 o posterior. Esto no fija la versión mínima de ActaVoz.
- **Observado antes de actualizar Xcode, 2026-11-22:** la interfaz Swift del SDK de macOS 26.2 declara `SpeechAnalyzer` y `SpeechTranscriber` disponibles desde macOS 26. Esto no establece el mínimo de ActaVoz ni demuestra compatibilidad con todos los equipos.
- **Observado en este Mac, 2026-11-22:** macOS 27.2.1, arquitectura arm64 y Xcode 27.2 con SDK de macOS 27.2. Tras la actualización y apertura de Xcode, la comprobación de primer inicio y la compilación del experimento de idiomas funcionan al seleccionarlo mediante `DEVELOPER_DIR`.
- **Observado en este Mac, 2026-11-22:** `SpeechTranscriber.isAvailable` devolvió verdadero; el listado de idiomas admitidos incluía variantes de español e inglés. Los recursos instalados declarados incluían variantes de español, sin variantes de inglés. Esto no verifica transcripción, calidad ni funcionamiento sin red.
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
| Verificar disponibilidad de SpeechAnalyzer y recursos por versión de macOS e idioma; evaluar alternativa si no encaja | Registrar versión mínima, recursos sin red y alternativa viable, incluida detección de idioma | Documentación oficial y pruebas en Mac de prueba | Parcial: disponibilidad e idiomas consultados; faltan transcripción, alternativa y validación en versiones objetivo |
| Comparar ScreenCaptureKit y Core Audio taps | Registrar permisos, disponibilidad, captura simultánea y necesidad de reinicio en macOS objetivo | Señales sintéticas y cuenta de prueba | No ejecutado |
| Verificar creación de ~/.ActaVoz sin App Sandbox | Confirmar acceso y ausencia de sobrescritura en macOS objetivo | Home de usuario de prueba con archivo centinela | Parcial: probado en home simulado y home real de la cuenta actual con ejecutable local sin sandbox; falta cuenta de prueba independiente y entorno de distribución |
| Evaluar deducción de nombres en local o con LLM | Documentar opciones y efectos sobre uso sin conexión | Transcripciones sintéticas; sin envío de audio | No ejecutado |

### Evidencia parcial: disponibilidad de idiomas

- **Método:** `swiftc -parse-as-library specs/0012-viabilidad-captura-transcripcion-y-voz-local/experimentos/idiomas.swift -o /tmp/actavoz_speech_probe && /tmp/actavoz_speech_probe`; consulta de versiones con `sw_vers`, `uname -m` y `xcrun --sdk macosx --show-sdk-version`.
- **Resultado:** compilación y ejecución correctas; disponible: sí; admitidos (13): `en_AU`, `en_CA`, `en_GB`, `en_IE`, `en_IN`, `en_NZ`, `en_SG`, `en_US`, `en_ZA`, `es_CL`, `es_ES`, `es_MX`, `es_US`; instalados: `es_CL`, `es_ES`, `es_MX`, `es_US`. Las listas indican el estado de este equipo en la fecha, no una garantía para otros.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

### Comprobación de Xcode tras la actualización

- **Método:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -checkFirstLaunchStatus`, consulta de versión y SDK, y compilación y ejecución de `experimentos/idiomas.swift` usando ese directorio.
- **Resultado:** Xcode 27.2, SDK 27.2 y comprobación de primer inicio con salida 0; compilación y ejecución correctas. El experimento volvió a informar disponibilidad e idiomas compatibles en español e inglés, con recursos de español instalados. No se alteró la selección global. La licencia había impedido compilar con la versión anterior; esa limitación ya no se reproduce.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

### Evidencia parcial: carpetas sin sobrescritura

- **Método:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -parse-as-library specs/0012-viabilidad-captura-transcripcion-y-voz-local/experimentos/carpetas.swift -o /tmp/actavoz_carpetas_probe && /tmp/actavoz_carpetas_probe`.
- **Resultado:** salida 0; creación repetida de `.ActaVoz/Notas` y `.ActaVoz/Directorios` en un home simulado dentro del directorio temporal, conservando un archivo centinela. El ejecutable no tiene App Sandbox. El experimento limpia únicamente su directorio temporal. No comprueba permisos sobre el home real, instalación DMG, firma ni otros sistemas operativos.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

### Evidencia parcial: acceso al home real

- **Método:** `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc -parse-as-library specs/0012-viabilidad-captura-transcripcion-y-voz-local/experimentos/home-real.swift -o /tmp/actavoz_home_real_probe && /tmp/actavoz_home_real_probe`.
- **Resultado:** salida 0; escritura en `.ActaVoz` del home real de la cuenta actual, creación repetida de subcarpetas en un directorio exclusivo de prueba y centinela intacto. La raíz no existía; el experimento elimina su subárbol exclusivo y utiliza `rmdir` para retirar la raíz solo si quedó vacía. No modifica ni elimina recursivamente contenido ajeno. No prueba firma, DMG, otro usuario ni otro macOS.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

## Resultado y siguiente paso

### Dirección técnica provisional

El SDK consultado declara SpeechAnalyzer desde macOS 26; si se mantiene ese componente, macOS 26 es el candidato mínimo a comprobar. Apple Silicon es el único hardware probado en esta investigación. No se declara soporte Intel ni se fija el mínimo definitivo sin comprobar los componentes de voz y las plataformas objetivo. Esta conclusión es una inferencia para orientar los experimentos, no una matriz de compatibilidad validada.

Condiciona la versión mínima y el acceso a carpetas de 0002, y la aprobación técnica de 0004 y 0005. Faltan evidencias y decisiones; no se ha elegido versión mínima ni librería definitiva.
