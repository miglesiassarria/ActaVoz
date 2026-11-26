# 0007 · Diseño: Chat de sesión

## Estado y dependencias

Implementado sobre 0006 (proveedores y Llavero), 0005 (transcripción) y 0003 (sesión). OAuth no aplica.

## Enfoque

- SessionChatModel: cola serial, snapshot de transcripción al preguntar, historial y persistencia en chat.json.
- ProviderChatResponder: resuelve modelo de preguntas (o principal), recupera la clave y envía solo texto.
- ChatBar y ChatOverlay: barra inferior persistente; el panel se oculta al tocar fuera o con Cerrar.
- La misma barra y panel se usan durante la grabación y en la sesión abierta.

## Contratos y datos

- ChatHistory schema 1; fechas ISO8601 para que SessionRepository pueda releer chat.json.
- Cada solicitud incluye instrucciones, transcripción completa en el momento de preguntar, turnos previos y la pregunta.
- La cola conserva el orden; una segunda pregunta espera a que termine la anterior y recibe el historial actualizado.
- Error: se conserva la pregunta, se muestra el aviso con Reintentar y Cambiar modelo; no se inventa respuesta.
- No hay adjuntos ni envío de audio.

## Seguridad y límites

- Solo texto; claves en Llavero; pruebas con proveedor simulado y servidor local.
- No se prueba streaming. La equivalencia semántica de resúmenes largos pertenece a 0008.
- macOS 26 no se ha probado.
