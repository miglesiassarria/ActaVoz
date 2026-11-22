# 0007 · Chat de sesión y consultas

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Consultar lo hablado sin interrumpir la captura y revisar respuestas en la sesión.

## Comportamiento esperado

El mini chat muestra consultas y respuestas durante la grabación y en la sesión abierta, utilizando la transcripción disponible en el momento de la pregunta.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Panel:** Barra inferior abre mini chat con preguntas y respuestas; clic fuera oculta panel y conserva barra. | Abrir, hacer clic fuera y volver a abrir durante y después de una sesión. | pendiente |
| AC2 | **Directo:** Permitir preguntas mientras continúa captura y transcripción. | Iniciar grabación, enviar pregunta a proveedor simulado y verificar que audio sigue capturándose. | pendiente |
| AC3 | **Contexto completo:** Cada pregunta usa toda la transcripción acumulada al momento de preguntar; no enviar audio al LLM. | Con segmentos conocidos y proveedor espía verificar texto previo completo y ausencia de audio. | pendiente |
| AC4 | **Modelo:** Usar el modelo configurado para preguntas o el principal si no hay específico. | Comparar solicitudes simuladas con y sin modelo específico. | pendiente |
| AC5 | **Errores:** Mostrar error comprensible si falla el proveedor, sin detener la captura ni fingir respuesta. | Simular fallo durante grabación y verificar aviso y continuidad. | pendiente |
| AC6 | **Sin adjuntos:** No ofrecer adjuntar archivos en la fase actual. | Inspeccionar controles del chat. | pendiente |

## Decisiones previas a aprobación

- Decidir persistencia del historial, inclusión de turnos anteriores y tratamiento de preguntas simultáneas. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.

## Fuera de alcance

- Los adjuntos quedan fuera.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Persistencia del historial del chat y tratamiento de preguntas simultáneas no están acordados; aclarar antes de diseño si afectan al alcance.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Una respuesta puede fallar sin detener la grabación; el proveedor puede rechazar contexto largo y debe definirse cómo informar sin perder contenido.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
