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
| AC1 | **Reproducir:** permitir reproducir y pausar el audio conservado, con barra para avanzar o retroceder y ver el tiempo; no ofrecer reproducción como disponible si fue borrado. | Probar sesiones con y sin audio; reproducir, pausar y desplazarse con la barra y comprobar el tiempo. | pendiente |
| AC2 | **Exportar:** exportar transcripción, resumen y notas como archivos Markdown o de texto plano a una ubicación elegida. | Exportar cada contenido en ambos formatos con datos ficticios y comparar archivo con pantalla. | pendiente |
| AC3 | **Copiar:** Copiar el texto de transcripción, resumen o notas para pegarlo en otra aplicación. | Copiar cada contenido y pegarlo en un destino de prueba. | pendiente |
| AC4 | **Transcripción exportada:** incluir el nombre o etiqueta del interlocutor y la marca de tiempo de cada intervención. | Exportar en ambos formatos una transcripción de prueba con varios interlocutores y tiempos; comprobar cada intervención. | pendiente |
| AC5 | **Notas exportadas:** si existe síntesis, permitir exportar solo las notas o incluir también la síntesis claramente diferenciada. | Exportar notas de prueba con ambas opciones y en ambos formatos; comprobar la inclusión o ausencia de síntesis y su identificación. | pendiente |

## Decisiones previas a aprobación

- Ninguna decisión de producto identificada pendiente para los controles básicos acordados; revisar cualquier dependencia técnica durante el diseño.

## Fuera de alcance

- La exportación no implica compartir mediante enlaces.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Formatos de exportación y tratamiento de marcas de tiempo e interlocutores pendientes de decisión; no inventar formatos obligatorios.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La fidelidad de los archivos exportados debe verificarse antes de declarar terminada la implementación.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
