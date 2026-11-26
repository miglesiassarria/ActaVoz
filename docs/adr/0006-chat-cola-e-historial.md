# ADR 0006: Chat con cola serial, snapshot e historial ISO8601

- **Estado:** accepted
- **Fecha:** 2026-11-26
- **Spec relacionada:** 0007

## Contexto

El chat debe funcionar durante la grabación y después, consultar la transcripción completa, conservar el historial y admitir otra pregunta mientras se responde sin romper el orden.

## Decisión

- SessionChatModel mantiene una cola serial. Cada pregunta guarda la transcripción disponible al enviarse.
- La pregunta se añade al historial cuando empieza a procesarse, no al encolarse, para que la segunda incluya la respuesta anterior.
- La persistencia usa chat.json con fechas ISO8601, compatible con SessionRepository.
- La UI usa una barra inferior persistente y un panel que se oculta al tocar fuera.
- Si falla el proveedor, se conserva la pregunta y se ofrecen Reintentar y Cambiar modelo; no se genera una respuesta falsa.

## Alternativas descartadas

- Enviar preguntas en paralelo: rompe el orden y el contexto conversacional.
- Encolar el texto pero no la transcripción: la pregunta usaría texto posterior, no el disponible al preguntar.
- Guardar fechas como número: SessionRepository no puede releer chat.json.

## Consecuencias

- Una respuesta lenta retrasa las siguientes; es el comportamiento acordado.
- No hay streaming ni adjuntos.
- La ventana de grabación se amplía para que el panel quepa.

## Verificación

ChatTests cubre texto completo, historial, cola, error y persistencia. Evidencia en docs/evidencia/0007/README.md.
