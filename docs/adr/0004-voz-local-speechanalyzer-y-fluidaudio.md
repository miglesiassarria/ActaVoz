# ADR 0004: Transcripción y diarización locales

- **Estado:** proposed
- **Fecha:** 2026-11-24
- **Spec relacionada:** 0005 y 0012

## Contexto

0005 necesita transcribir español e inglés, separar interlocutores y reutilizar perfiles sin enviar audio a proveedores. La investigación 0012 verificó:

- SpeechAnalyzer transcribe español e inglés con modelos instalados y red saliente bloqueada.
- SpeechAnalyzer exige locale explícito; `SpeechDetector` solo detecta actividad de voz y `SpeechTranscriber` no expone hablante ni idioma.
- FluidAudio Offline VBx separó 4/4 hablantes en AMI-SDM real con DER 10,25 %/5,8 % y RTFx 120,2×/116,2×.
- Los embeddings de 256 dimensiones del mismo hablante entre reuniones dieron similitud 0,927–0,968; entre hablantes distintos, 0,029–0,339.

## Decisión

- **ASR:** usar `SpeechAnalyzer`/`SpeechTranscriber` de Apple, en el dispositivo, con locale explícito por sesión.
- **Idioma automático:** no hay API de detección en Speech. El diseño de 0005 debe elegir entre ejecutar locales candidatos con una heurística de calidad/confianza o un detector local sobre audio. No se declara resuelto.
- **Diarización:** usar `OfflineDiarizerManager` de FluidAudio (VBx) sobre el audio del sistema normalizado a 16 kHz mono. El micrófono se etiqueta «Yo» por defecto; si se desactiva esa etiqueta, se decidirá en 0005 si se incorpora a la diarización.
- **Perfiles:** almacenar embeddings normalizados de 256 dimensiones, no audio, y comparar por similitud coseno. El umbral se calibra con 0005; una coincidencia por debajo del umbral se propone, no se confirma.
- **Privacidad:** audio y modelos permanecen en el Mac; solo texto puede enviarse al LLM. Los modelos de FluidAudio son Apache 2.0 y se descargan de HuggingFace; tras instalarlos, el procesamiento funciona sin red.
- **Integración:** consumir los CAF y la línea temporal de 0004; no cambiar el contrato de captura.

## Alternativas descartadas

- **Solo SpeechAnalyzer:** no ofrece diarización ni detección de idioma.
- **Diarización propia desde cero:** riesgo y coste desproporcionados frente a una librería con evidencia.
- **Servicios en la nube:** incumplen la privacidad local del audio.
- **FluidAudio streaming como primera opción:** más complejo; el modo offline es suficiente para procesar tras la grabación. Streaming queda para una fase posterior si se necesita tiempo real.

## Consecuencias

- Se añade una dependencia Apache 2.0 y modelos CoreML que ocupan espacio y requieren una descarga inicial.
- La calidad medida es sobre AMI (audio de reunión real), no sobre la captura dual de ActaVoz; 0005 debe repetir la medición con su propio audio.
- La detección automática de idioma, los umbrales de perfil y el tratamiento de audio borrado siguen siendo decisiones de 0005.
- macOS 26 no se ha probado; la evidencia es macOS 27.2.1/arm64.

## Verificación y revisión

La decisión se revisa si 0005 no alcanza la calidad de diarización esperada con la captura dual, si el coste de los modelos es inaceptable, o si aparece una API de Apple que cubra diarización o idioma. La evidencia de 0012 está en `specs/0012-viabilidad-captura-transcripcion-y-voz-local/discovery.md`.
