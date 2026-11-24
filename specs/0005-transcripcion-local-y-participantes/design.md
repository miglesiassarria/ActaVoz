# 0005 · Diseño: Voz y participantes

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0003 y 0004 cerradas, 0012 superseded con evidencia, 0006 opcional. Decisiones de pila en ADR 0004. El idioma automático sigue siendo una decisión abierta que debe resolverse en tareas antes de construir. Las rutas siguientes son propuestas, no archivos existentes; si cambia comportamiento aprobado, volver a spec.

## Enfoque

SpeechPipeline recibe los CAF y la línea temporal de 0004. El audio del sistema se normaliza a 16 kHz mono y se diariza con FluidAudio Offline VBx; el micrófono se etiqueta «Yo» por defecto. SpeechAnalyzer transcribe cada fuente con el locale de la sesión. Los segmentos se ordenan por tiempo de sesión y se guardan con etiquetas de interlocutor separadas de los nombres confirmados.

La detección automática de idioma no existe en Speech: se evaluará ejecutar los locales candidatos y elegir por confianza/calidad, o usar un detector local sobre audio. Hasta validarlo, «automático» no se considera implementado.

## Superficies propuestas

`Speech/SpeechPipeline.swift; Speech/SpeakerRepository.swift; Speech/TranscriptView.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Persistir `transcripcion.json` versionado con segmentos `{source, start, end, text, speakerLabel, confidence}` y una tabla de interlocutores separada de los nombres confirmados. Reasignar segmento o fusionar identidad mediante operaciones explícitas.

Los perfiles se guardan como embeddings normalizados de 256 dimensiones, nunca como audio. La comparación es coseno; por debajo del umbral se propone una coincidencia y se exige confirmación. Los datos temporales de voz se purgan tras confirmar, borrar o vencer la retención. Guardar únicamente perfiles confirmados.

Nunca enviar audio al LLM; solo texto. Las pruebas de reconocimiento no equivalen a precisión garantizada. Si el usuario desactiva «Yo», se decidirá si el micrófono entra en la diarización o se mantiene como fuente separada sin etiqueta.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

- FluidAudio añade modelos CoreML y una descarga inicial; el procesamiento debe funcionar sin red después de instalarlos.
- El DER medido en AMI (5,8–10,3 %) no garantiza la calidad sobre la captura dual de ActaVoz; hay que repetirlo con audio propio.
- La detección automática de idioma puede elegir mal o degradar el texto; si no se valida, se ofrecerá elección explícita.
- Los umbrales de perfil, el audio borrado y el reconocimiento entre reuniones requieren pruebas con voces autorizadas.
- macOS 26 no se ha probado; la evidencia es macOS 27.2.1/arm64.
- La integración y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen extremo a extremo. Cada criterio conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

[ADR 0004](../../docs/adr/0004-voz-local-speechanalyzer-y-fluidaudio.md) registra la elección de SpeechAnalyzer y FluidAudio, sus límites y la revisión pendiente. No marcar decisiones de discovery como verificadas sin evidencia.
