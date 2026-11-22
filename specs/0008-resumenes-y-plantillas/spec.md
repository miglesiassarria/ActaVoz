# 0008 · Resúmenes y plantillas

- **Estado:** design
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

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
| AC8 | **Confirmación de sobrescritura:** antes de regenerar un resumen con ediciones manuales pedir confirmación; si no tiene ediciones manuales, no mostrarla. Cancelar conserva el resumen. | Regenerar en casos con y sin edición manual; cancelar y confirmar en el primero y verificar contenido y avisos. | pendiente |
| AC9 | **Fallo de regeneración:** conservar intacto el resumen anterior si falla la regeneración, mostrar el error y ofrecer reintentar; sustituirlo solo al finalizar correctamente. | Simular fallo del proveedor tras iniciar regeneración y comprobar que el resumen anterior persiste; reintentar con éxito y verificar la sustitución. | pendiente |
| AC10 | **Eliminar plantilla propia:** permitir eliminarla desde Ajustes tras confirmación; cancelar conserva la plantilla. | Crear una plantilla de prueba, cancelar su eliminación y después confirmarla; comprobar que solo desaparece tras confirmar. | pendiente |
| AC11 | **Plantillas predefinidas:** conservar las cuatro originales sin modificar y permitir duplicarlas como plantillas propias editables. | Duplicar una plantilla predefinida, editar la copia y comprobar que la original permanece intacta. | pendiente |
| AC12 | **Análisis y tareas:** obtenerlos mediante plantillas o el chat, sin generar archivos independientes de análisis; conservar el resumen como resultado principal. | Solicitar análisis mediante una plantilla y mediante el chat con proveedor simulado; comprobar el resumen y el historial, y que no se cree un archivo de análisis independiente. | pendiente |

## Decisiones previas a aprobación

- No quedan decisiones de producto identificadas para esta spec; comprobar dependencias y viabilidad antes de solicitar su aprobación.

## Fuera de alcance

- Sin historial de versiones por plantilla.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** la implementación de la sustitución atómica del resumen y la persistencia de plantillas requiere diseño. AC9 ya establece conservar el resumen anterior ante fallo; la calidad semántica necesita evaluación.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La sustitución debe preservar las ediciones manuales anteriores si la regeneración falla. Los criterios semánticos requieren mediciones de 0011.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
