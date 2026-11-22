# 0008 · Diseño: Resúmenes y plantillas

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0003, 0005 y 0006. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

SummaryService solicita generación al adaptador de 0006 con transcripción completa y plantilla elegida; editor persiste resumen.md mediante repositorio.

## Superficies propuestas

`Summaries/SummaryService.swift; Summaries/TemplateRepository.swift; Summaries/SummaryView.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Cuatro plantillas base inmutables; duplicados propios editables con nombre, instrucciones y apartados. Estado de edición manual persistido para confirmación. Preparar resultado en archivo temporal y sustituir solo tras éxito; fallos y cancelación preservan versión anterior.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
