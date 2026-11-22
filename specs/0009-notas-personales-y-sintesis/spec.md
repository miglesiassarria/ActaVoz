# 0009 · Notas personales y síntesis

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

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

## Decisiones previas a aprobación

- Decidir qué ocurre si no existe resumen principal y si la síntesis generada es editable. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.

## Fuera de alcance

- La síntesis no sustituye las notas ni el resumen principal.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Ubicación concreta de notas y síntesis dentro de la carpeta de sesión y comportamiento si no existe resumen principal requieren diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La persistencia y los fallos de generación deben evitar pérdidas; se requiere acordar qué hacer sin resumen principal.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
