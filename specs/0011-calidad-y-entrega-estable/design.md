# 0011 · Diseño: Calidad y entrega

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0002–0010, 0012 y 0013. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

QualityRunner documenta corpus autorizado, referencias, entorno, tiempos y resultados; el artefacto real se distribuye en DMG firmado y notarizado.

## Superficies propuestas

`docs/verification.md; scripts/quality/; docs/evidence/` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Acordar umbrales después de primeras mediciones, sin marcar estabilidad antes de alcanzarlos. Ejecutar pruebas con recursos locales previamente instalados y red desconectada en entorno de prueba. Registrar hardware, macOS, versiones de modelos, datos y evidencia sin secretos.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
