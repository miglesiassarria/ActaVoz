# 0008 · Resúmenes y plantillas

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Generar y adaptar resúmenes a cada tipo de reunión.

## Comportamiento esperado

La persona genera un resumen desde la transcripción y puede cambiar de plantilla, editarlo y borrar el resultado con confirmación. La regeneración acordada sustituye el resultado anterior.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Generar:** Tras detener y procesar, el botón Generar resumen usa transcripción completa y plantilla predeterminada; muestra resultado central. | Con transcripción de prueba generar y verificar entrada, plantilla y resultado en pantalla. | pendiente |
| AC2 | **Contenido:** Resumen principal inicialmente excluye notas propias; encabezados y listas se adaptan a plantilla. | Comparar entrada al proveedor con notas y transcripción ficticias y revisar resultado. | pendiente |
| AC3 | **Plantillas iniciales:** Incluir resumen general, reunión de trabajo, reunión individual y reflexión personal con apartados definidos en el documento de ejemplos. | Comprobar catálogo y generar cada tipo con proveedor controlado; comparar con EJEMPLOS_PLANTILLAS.md. | pendiente |
| AC4 | **Personalización:** Crear y editar plantillas con nombre, instrucciones y apartados; desplegable con búsqueda por nombre. | Crear, editar, buscar y seleccionar plantilla de prueba. | pendiente |
| AC5 | **Regeneración:** Elegir plantilla predeterminada en Ajustes; cambiar plantilla en sesión y regenerar sustituyendo resumen anterior y ediciones, sin historial de versiones por plantilla. | Editar resumen, regenerar con otra plantilla y verificar sustitución y transcripción intacta. | pendiente |
| AC6 | **Edición:** Permitir editar resumen y guardar automáticamente. | Editar, cerrar y reabrir sesión y comprobar cambios. | pendiente |
| AC7 | **Eliminar:** Permitir borrar resumen tras confirmación sin borrar transcripción ni notas. | Cancelar y confirmar borrado en sesión de prueba y comprobar archivos restantes. | pendiente |

## Decisiones previas a aprobación

- Decidir borrado de plantillas propias, edición de predefinidas, confirmación al sobrescribir ediciones y recuperación ante fallo de regeneración. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.
- Aclarar si análisis y otros resultados existen como archivos independientes o mediante plantillas y chat.

## Fuera de alcance

- Sin historial de versiones por plantilla.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Manejo de fallos de regeneración y persistencia de plantillas requiere diseño; no prometer calidad semántica sin evaluación.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Una regeneración fallida podría perder correcciones manuales; su comportamiento debe acordarse antes de aprobación. Los criterios semánticos requieren mediciones de 0011.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
