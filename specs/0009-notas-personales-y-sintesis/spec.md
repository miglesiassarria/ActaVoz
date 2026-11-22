# 0009 · Notas personales y síntesis

- **Estado:** design
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Conservar notas editables y generar una síntesis independiente que combine notas y reunión.

## Comportamiento esperado

La persona escribe notas durante o después de la sesión y puede generar una síntesis separada del resumen principal; los cambios posteriores permiten actualizarla.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Vistas:** Cada sesión ofrece Mis notas y Resumen separados; notas editables durante y después de la sesión. | Editar notas durante captura y tras finalizar; navegar entre vistas. | pendiente |
| AC2 | **Guardado:** Guardar cambios de notas automáticamente y conservarlos tras reabrir. | Editar, cerrar y reabrir, verificando texto. | pendiente |
| AC3 | **Síntesis:** Botón Generar síntesis combina notas y acta/resumen y muestra resultado al final de Mis notas, identificado como generado por IA. | Con notas y resumen ficticios generar con proveedor simulado e inspeccionar entradas y presentación. | pendiente |
| AC4 | **Actualización:** Al cambiar notas o resumen indicar que síntesis puede actualizarse; acción Actualizar síntesis reemplaza anterior. | Generar, modificar cada fuente por separado y comprobar aviso y sustitución. | pendiente |
| AC5 | **Separación:** Regenerar resumen principal no modifica notas; eliminar síntesis tras confirmación conserva notas, transcripción y resumen. | Realizar ambas operaciones y verificar contenidos restantes. | pendiente |
| AC6 | **Resumen necesario:** si no existe el resumen principal, indicar que debe generarse antes de crear la síntesis. | Abrir una sesión sin resumen, solicitar la síntesis y comprobar el mensaje y que no se genera. | pendiente |
| AC7 | **Edición de síntesis:** permitir editar la síntesis; al actualizarla, la nueva sustituye a la anterior, incluidas sus ediciones manuales. | Editar una síntesis, actualizarla con un proveedor simulado y comprobar la sustitución. | pendiente |
| AC8 | **Modelo de síntesis:** usar el modelo asignado a resúmenes o, si no existe uno específico, el modelo principal. | Generar una síntesis con y sin modelo específico para resúmenes y verificar el modelo recibido por el proveedor simulado. | pendiente |

## Decisiones previas a aprobación

- Las notas se guardan en `notas.md` y la síntesis en `sintesis.md` dentro de la carpeta de sesión, según 0003. Coordinar la selección de modelo con 0006.

## Fuera de alcance

- La síntesis no sustituye las notas ni el resumen principal.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Confirmado:** las notas se guardan en notas.md y la síntesis en sintesis.md; AC6 establece el comportamiento sin resumen principal. La integración de persistencia y modelos depende de 0003 y 0006.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La persistencia y los fallos de generación deben evitar pérdidas; el diseño debe asegurar que una operación fallida no dañe notas ni contenidos guardados.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
