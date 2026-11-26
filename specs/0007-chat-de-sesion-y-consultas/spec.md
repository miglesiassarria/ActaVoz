# 0007 · Chat de sesión y consultas

- **Estado:** done
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Consultar lo hablado sin interrumpir la captura y revisar respuestas en la sesión.

## Comportamiento esperado

El mini chat muestra consultas y respuestas durante la grabación y en la sesión abierta, utilizando la transcripción disponible en el momento de la pregunta.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Panel:** Barra inferior abre mini chat con preguntas y respuestas; clic fuera oculta panel y conserva barra. | Abrir, hacer clic fuera y volver a abrir durante y después de una sesión. | cumplido: barra inferior y panel; se oculta al tocar fuera o con Cerrar |
| AC2 | **Directo:** Permitir preguntas mientras continúa captura y transcripción. | Iniciar grabación, enviar pregunta a proveedor simulado y verificar que audio sigue capturándose. | cumplido: pregunta durante grabación; temporizador 00:05 → 00:12 y respuesta |
| AC3 | **Contexto completo:** Cada pregunta usa toda la transcripción acumulada al momento de preguntar; no enviar audio al LLM. | Con segmentos conocidos y proveedor espía verificar texto previo completo y ausencia de audio. | cumplido: la solicitud incluye la transcripción completa y solo texto |
| AC4 | **Modelo:** Usar el modelo configurado para preguntas o el principal si no hay específico. | Comparar solicitudes simuladas con y sin modelo específico. | cumplido: modelo de preguntas o principal; verificado con proveedor simulado |
| AC5 | **Errores:** Mostrar error comprensible si falla el proveedor, sin detener la captura ni fingir respuesta. | Simular fallo durante grabación y verificar aviso y continuidad. | cumplido: error visible con Reintentar/Cambiar modelo; la captura continúa |
| AC6 | **Sin adjuntos:** No ofrecer adjuntar archivos en la fase actual. | Inspeccionar controles del chat. | cumplido: no hay control de adjuntos; el panel indica que no se envían archivos ni audio |
| AC7 | **Historial:** guardar preguntas y respuestas en `chat.json` dentro de la carpeta de sesión y recuperarlas al reabrirla. | Mantener un intercambio con un proveedor simulado, cerrar y reabrir la sesión y comprobar el historial y el archivo. | cumplido: chat.json y reapertura con historial |
| AC8 | **Contexto conversacional:** cada consulta incluye los turnos anteriores del chat junto con toda la transcripción disponible en ese momento. | Realizar dos preguntas y verificar en el proveedor simulado que la segunda solicitud incorpora los turnos previos y toda la transcripción acumulada. | cumplido: la segunda pregunta incluye turnos previos y transcripción nueva |
| AC9 | **Preguntas en espera:** permitir escribir y enviar otra pregunta mientras se responde; mantenerla en espera y enviarla cuando termine la respuesta anterior, conservando el orden. | Demorar una respuesta con un proveedor simulado, enviar otra pregunta y comprobar que se procesa después y con el historial previo. | cumplido: cola serial; orden e historial previo comprobados |

## Decisiones previas a aprobación

- Concretar en diseño el manejo de errores o cancelaciones de preguntas en espera sin alterar el orden acordado.

## Fuera de alcance

- Los adjuntos quedan fuera.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** El manejo de errores o cancelaciones de preguntas en espera requiere diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Una respuesta puede fallar sin detener la grabación; el proveedor puede rechazar contexto largo y debe definirse cómo informar sin perder contenido.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
