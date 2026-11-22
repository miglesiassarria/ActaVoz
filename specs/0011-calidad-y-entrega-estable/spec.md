# 0011 · Calidad y entrega estable

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Comprobar las capacidades acordadas antes de considerar estable la primera versión.

## Comportamiento esperado

La capacidad debe cumplir los criterios observables siguientes. La definición de producto y los acuerdos de la conversación son la fuente de alcance; las decisiones no acordadas se registran como riesgos, no como hechos. Las pruebas usan datos controlados y no registran secretos ni reuniones personales.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Cobertura:** La versión estable incluye grabación y recuperación, transcripción e identificación local, biblioteca, chat, resúmenes, notas, plantillas y proveedores configurables. | Ejecutar un recorrido de extremo a extremo por cada capacidad y registrar evidencia. | pendiente |
| AC2 | **Transcripción:** Comparar transcripción con referencias de reuniones reales o preparadas en español e inglés. | Usar grabaciones autorizadas o preparadas y registrar método y resultados por idioma. | pendiente |
| AC3 | **Diarización:** Evaluar atribución correcta por intervención y casos de voces solapadas con las mismas grabaciones. | Comparar atribuciones contra referencia etiquetada y registrar resultados. | pendiente |
| AC4 | **Latencia y resumen:** Medir tiempos de transcripción, respuesta y resumen; revisar decisiones y tareas frente a la fuente y detectar invenciones. | Registrar tiempos y revisión de ejemplos con referencia conocida. | pendiente |
| AC5 | **Umbrales:** Acordar niveles mínimos tras revisar evidencia; no declarar estabilidad sin criterios aprobados y alcanzados. | Registrar umbrales acordados y comparación con mediciones. | pendiente |
| AC6 | **Entrega:** Verificar instalación, firma, notarización y ejecución del DMG en entorno seguro. | Instalar artefacto real firmado y notarizado en Mac de prueba y registrar resultados. | pendiente |

## Fuera de alcance

- API REST de fase 2, adjuntos en chat, calendario y control de costes.
- Código de producción, diseño y tareas de implementación durante la fase de especificación.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** No hay aplicación ni mediciones actuales; los umbrales, hardware y condiciones de prueba siguen pendientes.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los componentes propuestos y comportamientos de proveedores requieren validación antes de garantizar el resultado.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
