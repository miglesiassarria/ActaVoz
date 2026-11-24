# 0012 · Captura, transcripción y perfiles locales

> **Estado:** superseded por 0004 (captura) y 0005 (voz). Evidencia conservada; decisiones pendientes de producto pasan a 0005.

## Pregunta o decisión

Determinar la viabilidad de la capacidad y registrar evidencia para los diseños de las specs dependientes, aprobadas por la persona usuaria.

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
| Probar captura dual y sincronización | Ambas señales llegan separadas con tiempos comparables | Datos sintéticos en Mac de prueba | Ejecutado en 0004: CAF separados, desfase +51,1 ms y recuperación tras pérdida de fuente |
| Probar permisos, reconexión y Bluetooth | Identificar interrupciones y recuperación por versión de macOS | Sin datos personales | Parcial: TCC real y cambio USB↔integrado con recuperación; Bluetooth no probado |
| Probar transcripción en español, inglés y detección automática sin red | Medir disponibilidad y resultados con modelos previamente instalados | Audio preparado y autorizado | Parcial: español e inglés exactos con red saliente denegada; Speech 27.2 no expone detección automática de idioma |
| Probar diarización y perfiles entre reuniones, incluso tras borrar audio | Medir reconocimiento, solapamiento y condiciones de persistencia | Voces sintéticas o consentidas; almacenamiento temporal | Ejecutado con AMI-SDM real: DER 10,3 % y 5,8 %, 4/4 hablantes; embeddings del mismo hablante entre reuniones 0,93–0,97 |
| Verificar disponibilidad de SpeechAnalyzer y recursos por versión de macOS e idioma; evaluar alternativa si no encaja | Registrar versión mínima, recursos sin red y alternativa viable, incluida detección de idioma | Documentación oficial y pruebas en Mac de prueba | Parcial: disponible; 13 locales es/en admitidos y los 13 instalados en este equipo. Falta macOS 26 y alternativa si Speech no cubre diarización |
| Comparar ScreenCaptureKit y Core Audio taps | Registrar permisos, disponibilidad, captura simultánea y necesidad de reinicio en macOS objetivo | Señales sintéticas y cuenta de prueba | Resuelto por ADR 0003 y 0004: Core Audio taps, sin captura de pantalla |
| Verificar creación de ~/.ActaVoz sin App Sandbox | Confirmar acceso y ausencia de sobrescritura en macOS objetivo | Home de usuario de prueba con archivo centinela | Parcial: probado en home simulado y home real de la cuenta actual con ejecutable local sin sandbox; falta cuenta de prueba independiente y entorno de distribución |
| Evaluar deducción de nombres en local o con LLM | Documentar opciones y efectos sobre uso sin conexión | Transcripciones sintéticas; sin envío de audio | No ejecutado |

### Evidencia parcial: transcripción de un archivo en español

- **Método:** generar `/tmp/actavoz_prueba_es.aiff` con `say -v Monica`, con la frase «Hola, esta es una reunión de prueba. Mañana revisaremos las tareas del proyecto.»; compilar `experimentos/transcribir.swift` con Xcode y ejecutar el binario con dicho archivo.
- **Resultado:** salida 0; SpeechAnalyzer devolvió exactamente la frase de prueba. El experimento usa una voz sintética, un único archivo corto y el idioma español seleccionado explícitamente; no se desconectó la red y no se midieron latencia, calidad en reuniones, inglés ni detección automática.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

### Evidencia parcial: inglés y restricción de red del proceso

- **Método:** generar audio sintético inglés con `say -v Samantha`, compilar `experimentos/transcribir.swift`, ejecutar con `en_US --instalar` y repetir español e inglés mediante `sandbox-exec -p '(version 1) (allow default) (deny network*)'`, sin modificar la conexión global del Mac.
- **Resultado:** salida 0 en ambos idiomas; los textos transcritos coincidieron con las frases sintéticas. En inglés, AssetInventory pasó de `supported` a `installed` tras la descarga; la consulta de estado del módulo español informó `supported` y aun así produjo texto. La restricción se aplicó al proceso cliente, no garantiza que los servicios de macOS no accedieran a la red. No prueba uso completamente desconectado, detección automática ni calidad en reuniones.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

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

### Evidencia: captura dual y reconexión (0004)

- **Método:** la spec 0004 verificó captura simultánea de micrófono y audio del sistema, midió el desfase por correlación de un tono de 440 Hz y probó un cambio real de entrada USB↔integrado con recuperación.
- **Resultado:** CAF separados; desfase +51,1 ms; audio combinado de 32,81 s tras pérdida y recuperación; permisos TCC reales. Evidencia completa en `docs/evidencia/0004/README.md`.
- **Fecha:** 2026-11-24.
- **Commit:** `d799552`.

### Evidencia: transcripción local ES/EN con red saliente bloqueada (2026-11-24)

- **Método:** generar dos audios sintéticos con `say -v Monica` (español) y `say -v Samantha` (inglés); compilar `experimentos/transcribir.swift` con Xcode 27.2; ejecutar ambos con `sandbox-exec -p '(version 1)(allow default)(deny network-outbound)'` y el locale explícito.
- **Resultado:** salida 0. Español: «Hola, esta es una reunión de prueba. Mañana revisaremos las tareas del proyecto.» Inglés: dos resultados parciales que componen la frase completa. Los 13 locales es/en aparecen instalados en este equipo.
- **Límite:** la restricción se aplica al proceso cliente, no a los servicios de macOS; no prueba desconexión total de la máquina, calidad en reuniones ni detección automática.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente de este commit.

### Evidencia: límites del SDK para detección y diarización (2026-11-24)

- **Método:** inspeccionar `Speech.swiftinterface` del SDK macOS 27.2.
- **Resultado:** `SpeechDetector` solo expone actividad de voz (`speechDetected`); `SpeechTranscriber` requiere un locale explícito y sus atributos son tiempo y confianza, sin identificador de hablante ni detección de idioma. Por tanto, la detección automática y la diarización no se cubren con SpeechAnalyzer tal cual.
- **Consecuencia:** para 0005 habrá que diseñar la selección de idioma (ejecutar locales candidatos o detector externo) y evaluar FluidAudio para diarización/perfiles.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente de este commit.

### Evaluación documental de FluidAudio (2026-11-24)

- **Método:** clonar el repositorio en `build/FluidAudio` y leer `Documentation/Diarization/GettingStarted.md`, `Documentation/API.md` y `Documentation/Models.md`.
- **Resultado:** existe `OfflineDiarizerManager` (VBx, mejor calidad por lotes) y `DiarizerManager` (streaming, con `SpeakerManager` para identidades entre fragmentos). Los modelos se descargan de HuggingFace y se compilan para CoreML; la entrada se normaliza a 16 kHz mono. También hay alternativas Sortformer (máx. 4 hablantes) y LS-EEND (máx. 10). No se ejecutó ningún modelo ni se midió DER.
- **Límite:** las reglas del proyecto FluidAudio prohíben crear audio sintético de prueba; no usé los tonos de ActaVoz para diarización. Falta un corpus real multi-voz autorizado (por ejemplo AMI-SDM) y medir calidad, latencia, memoria y reconocimiento entre sesiones.
- **Siguiente experimento:** descargar un segmento real de AMI-SDM con el CLI de FluidAudio, ejecutar `OfflineDiarizerManager` y comprobar turnos, solapamientos y estabilidad de identidades; después evaluar si `SpeakerManager` permite reutilizar perfiles entre sesiones.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente de este commit.

### Evidencia: diarización y perfiles con AMI-SDM real (2026-11-24)

- **Método:** descargar el test set AMI-SDM (16 reuniones reales) con `fluidaudiocli download --dataset ami-sdm`; ejecutar `diarization-benchmark --mode offline --single-file ES2004a` y `ES2004b` con umbral 0,6; exportar embeddings de ambas reuniones con `process --export-embeddings`; agrupar los embeddings por hablante usando las anotaciones de palabras AMI y comparar los centroides normalizados con producto escalar.
- **Resultado diarización:** ES2004a DER **10,25 %**, JER **13,76 %**, miss 7,49 %, FA 1,55 %, 4/4 hablantes, RTFx **120,2×**, 8,73 s de proceso. ES2004b DER **5,8 %**, JER **7,0 %**, 4/4 hablantes, RTFx **116,2×**. Modelos descargados de HuggingFace y compilados para CoreML; primera inicialización 7,77 s.
- **Resultado perfiles:** similitud coseno del mismo hablante entre ES2004a y ES2004b: **0,927 / 0,939 / 0,960 / 0,968** para A/B/C/D; entre hablantes distintos, 0,029–0,339. Es evidencia de que los embeddings separan voces y permiten reutilizar perfiles, no un sistema de perfiles terminado.
- **Límite:** AMI es audio de reunión real pero no la captura dual de ActaVoz; el pipeline es offline por lotes, no streaming; no se probaron umbrales de perfil, nombres deducidos, audio borrado ni persistencia entre reuniones en la app.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente de este commit.

## Resultado y siguiente paso

### Dirección técnica provisional

El SDK consultado declara SpeechAnalyzer desde macOS 26 y Apple Silicon es el único hardware probado en esta investigación. La plataforma ya no es una pregunta abierta: se decidió el 2026-11-23. Lo que queda es evidencia pendiente, no una decisión pendiente.

Condiciona el acceso a carpetas de 0002 y los diseños de 0004 y 0005.

### Decisión de plataforma (2026-11-23)

- **Decidido por la persona usuaria:** el mínimo de la fase 1 es **macOS 26 o posterior en Apple Silicon**. No se declara soporte Intel.
- **Consecuencia:** el proyecto Swift de 0002 se configura con despliegue macOS 26 y arquitectura arm64. La pregunta no se reabre salvo incompatibilidad demostrada de un componente.
- **Límite aceptado (2026-11-23):** no hay un equipo con macOS 26 disponible, así que esa versión no se comprobará. El despliegue apunta a 26.0 y la evidencia se obtiene en macOS 27.2.1/arm64. Es un riesgo declarado, no una validación.
- **Evidencia ya disponible:** captura dual/reconexión (0004); transcripción ES/EN con red saliente bloqueada; diarización real con DER 10,3 %/5,8 % y perfiles entre reuniones con similitud 0,93–0,97; rendimiento 116–120× tiempo real.
- **Pendiente de evidencia:** detección automática de idioma, Bluetooth, deducción de nombres y persistencia de perfiles dentro de la app (incluido audio borrado).
- **Decisión de viabilidad:** SpeechAnalyzer cubre la transcripción local; FluidAudio Offline VBx cubre la diarización y los embeddings de voz. La detección automática de idioma no está en Speech y debe resolverse en el diseño de 0005 (ejecutar locales candidatos o detector externo).
- **Siguiente paso:** llevar estas decisiones al diseño de 0005, fijar umbrales de perfil y persistencia, y validar el flujo completo con la captura dual de ActaVoz. No se elige todavía una estrategia de detección automática de idioma.
