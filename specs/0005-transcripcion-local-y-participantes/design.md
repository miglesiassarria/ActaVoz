# 0005 · Diseño: Voz y participantes

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0003, 0004, 0006 opcional y 0012. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

SpeechPipeline recibe fuentes y tiempos de 0004; adaptadores locales producen segmentos de texto y atribuciones con identidad estable. SpeechAnalyzer y FluidAudio son candidatos pendientes de 0012.

## Superficies propuestas

`Speech/SpeechPipeline.swift; Speech/SpeakerRepository.swift; Speech/TranscriptView.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Persistir transcripcion.json con versiones y tiempos; separar etiquetas de nombres confirmados. Reasignar segmento o fusionar identidad mediante operaciones explícitas. Guardar únicamente perfiles confirmados, datos temporales por sesión mientras se permita, y purgar tras confirmación o borrado. Nunca enviar audio al LLM; pruebas de reconocimiento no equivalen a precisión garantizada.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
