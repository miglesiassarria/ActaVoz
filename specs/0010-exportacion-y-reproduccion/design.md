# 0010 · Diseño: Exportación y reproducción

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0003, 0005, 0008 y 0009. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

ExportService transforma contenido de sesión en Markdown o texto plano; AudioPlayer usa reproducción local para audio conservado.

## Superficies propuestas

`Export/ExportService.swift; Playback/SessionAudioPlayer.swift; Export/ExportView.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Transcripción incluye interlocutores y tiempos. Exportar notas ofrece incluir síntesis identificada cuando exista. El usuario elige destino; manejar cancelación y error sin sobrescribir silenciosamente. Reproductor expone estado y posición; no disponible sin archivo.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
