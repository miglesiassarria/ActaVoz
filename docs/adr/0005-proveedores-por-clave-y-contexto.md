# ADR 0005: Proveedores por clave y contexto dividido tras rechazo

- **Estado:** accepted
- **Fecha:** 2026-11-24
- **Spec relacionada:** 0006 y 0013

## Contexto

0006 necesita conectar OpenAI, Claude, OpenCode Go, Ollama y un proveedor genérico sin acoplar el producto a uno. 0013 descartó OAuth de terceros por falta de un flujo público autorizado. El contexto de una reunión puede superar el límite del proveedor.

## Decisión

- Usar API key para OpenAI, Claude, OpenCode Go y genérico; Ollama sin clave.
- Guardar secretos solo en el Llavero; la configuración JSON no contiene credenciales.
- No prometer OAuth: la UI lo muestra como no disponible.
- Enviar la transcripción completa. Si el proveedor rechaza por longitud, dividirla y combinar las partes; no imponer un límite propio.
- Mantener una conexión activa con modelo principal y overrides opcionales para preguntas y resúmenes; nombres usan el principal.

## Alternativas descartadas

- OAuth de ChatGPT para la app: no hay flujo autorizado.
- Límite propio de contexto: contradice la spec y pierde texto.
- Guardar claves en JSON o preferencias: expone secretos.

## Consecuencias

- Dependencia de la disponibilidad y del contrato de cada proveedor.
- La división no garantiza equivalencia semántica con una sola llamada.
- El coste de comprobar Claude puede consumir una llamada mínima; OpenAI y Ollama usan listado.

## Verificación y revisión

Se revisa si aparece un OAuth autorizado, si un proveedor cambia su contrato o si la división degrada resultados de forma inaceptable. Evidencia en docs/evidencia/0006/README.md.
