# 0009 · Diseño: Notas y síntesis

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0003, 0006 y 0008. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

NotesController guarda notas.md y gestiona sintesis.md por separado del resumen; la síntesis combina las instantáneas de notas y resumen usando el modelo de resúmenes.

## Superficies propuestas

`Notes/NotesController.swift; Notes/NotesView.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Autoguardado serializado con sustitución segura y errores visibles. Guardar huellas o versiones de entradas para detectar cambios tras generar; sin resumen mostrar aviso. Actualizar sustituye síntesis y ediciones; el diseño de fallos no debe alterar notas ni resumen.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
