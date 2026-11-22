# 0010 · Exportación y reproducción

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Permitir consultar el audio conservado y extraer contenidos de una sesión.

## Comportamiento esperado

La persona accede al audio conservado y puede exportar o copiar transcripción, resumen y notas.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Reproducir:** Permitir reproducir audio de sesión si se conservó; no ofrecer reproducción como disponible si fue borrado. | Probar sesiones con y sin audio y verificar controles. | pendiente |
| AC2 | **Exportar:** Exportar transcripción, resumen y notas como archivos a una ubicación elegida. | Exportar cada contenido con datos ficticios y comparar archivo con pantalla. | pendiente |
| AC3 | **Copiar:** Copiar el texto de transcripción, resumen o notas para pegarlo en otra aplicación. | Copiar cada contenido y pegarlo en un destino de prueba. | pendiente |

## Decisiones previas a aprobación

- Acordar formatos, marcas temporales e interlocutores, inclusión de síntesis en notas y controles mínimos de reproducción. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.

## Fuera de alcance

- La exportación no implica compartir mediante enlaces.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Formatos de exportación y tratamiento de marcas de tiempo e interlocutores pendientes de decisión; no inventar formatos obligatorios.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los formatos y la fidelidad de los archivos exportados deben definirse antes de aprobación; no dar por supuesta una exportación específica.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
