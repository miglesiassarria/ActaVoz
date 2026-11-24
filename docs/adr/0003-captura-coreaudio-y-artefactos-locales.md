# ADR 0003: Captura solo audio y artefactos locales sin certificado

- **Estado:** accepted
- **Fecha:** 2026-11-23
- **Spec relacionada:** 0004, 0012 y 0011

## Contexto

La persona requiere descarga por GitHub sin App Store ni cuenta Apple. La captura por ScreenCaptureKit enumeraba pantallas y devolvía rechazo aun con interruptores visibles en Ajustes. La prueba de captura desde el binario hijo del agente no verificaba la atribución TCC del bundle abierto normalmente.

## Decisión

- Usar Core Audio Process Taps para audio del sistema y AVAudioEngine para micrófono. No solicitar ni enumerar pantallas para capturar solo audio.
- Declarar NSAudioCaptureUsageDescription y NSMicrophoneUsageDescription en el Info.plist efectivo (ActaVozInfo.plist), no solo en opciones de generación.
- Tap y agregado privados, salida sin silenciar, exclusión del propio bundle y limpieza de IO/agregado/tap al detener.
- Abrir el panel y volver de Ajustes solo consulta estados pasivos. Crear un tap no acredita autorización; el estado previo puede ser «Sin verificar». Empezar realiza el intento explícito; el éxito requiere muestras y un archivo no vacío.
- No crear certificados ni modificar Llavero para el artefacto de entrega. Mantener firma ad hoc y publicar artefactos fijos ZIP/DMG. scripts/package-local.sh crea ZIP local sin reemplazar una versión previa ni publicar en GitHub.
- **Actualización 2026-11-24 (solo desarrollo):** se creó una identidad autofirmada local «ActaVoz Development» para mantener TCC entre recompilaciones en este Mac. No se distribuye, no se incluye en el DMG y no cambia la decisión de entrega: el artefacto público sigue siendo ad-hoc y sin certificado.
- La versión de prueba validada se conserva sin recompilar en build/audio-only-v2/ActaVoz.app. Los cambios posteriores no deben presentarse como esa misma versión.

## Alternativas descartadas

- Certificado local autofirmado: no solicitado en la dirección final del usuario; importación previa bloqueada y no completada.
- ScreenCaptureKit como única entrada de audio: acopla audio al acceso a contenido visual y produjo el fallo observado.
- Ignorar TCC o modificar su base: no se admite. Los permisos son controles de macOS.

## Consecuencias

- La captura audio-only funcionó sin certificado Developer ID en esta máquina con bundle abierto por LaunchServices.
- Firma ad hoc no equivale a notarización: GitHub no elimina Gatekeeper y una nueva compilación puede requerir autorización otra vez. No se garantiza continuidad entre hashes diferentes.
- Siguen sin resolverse sincronización dual precisa, selección efectiva del dispositivo y reconexión física bajo carga. Pausa descarta muestras; no libera los dispositivos.

## Verificación y revisión

Mismo bundle ad hoc por open, micrófono desactivado, tono conocido, parar y medir AVAudioFile: 22.7733 s, estéreo, RMS 0.0863364; cerrar y reabrir sin recompilar y repetir: 17.3013 s, estéreo, RMS 0.104627. No hubo nuevas peticiones en la segunda captura. No acredita instalación descargada en otro Mac ni macOS 26 real.
