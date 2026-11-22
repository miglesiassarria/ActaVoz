# 0006 · Diseño: Proveedores y contexto

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0002 y 0013. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

ProviderRegistry mantiene conexiones y selección de modelo; cada adaptador implementa comprobación, catálogo y generación de texto. SecretStore encapsula Llavero.

## Superficies propuestas

`Providers/ProviderRegistry.swift; Providers/LanguageProvider.swift; Providers/SecretStore.swift; Providers/ContextProcessor.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Guardar secretos exclusivamente en Llavero y configuración sin secretos en Library; no registrar tokens. OAuth solo mediante vía oficial autorizada validada en 0013. Resolver solicitudes largas con estrategia de varias llamadas validada y preservar cobertura completa; si no se completa, error y datos previos intactos. No declarar equivalencia semántica entre una y varias llamadas.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
