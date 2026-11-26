# Evidencia de 0007 · Chat de sesión

Fecha: 2026-11-26. Entorno: macOS 27.2.1/arm64.

## Pruebas automáticas

- swift test: 132 pruebas, 0 fallos (5 de chat).
- ChatTests verifica:
  - la pregunta recibe la transcripción completa y se guarda en chat.json;
  - al reabrir, el historial se recupera;
  - la segunda pregunta incluye la respuesta anterior y la transcripción nueva;
  - dos preguntas en cola se procesan en orden y la segunda ve el historial actualizado;
  - un fallo muestra error, conserva la pregunta y el reintento completa;
  - el proveedor recibe el modelo de preguntas y solo texto, sin audio.

## Prueba manual

- Sesión «Prueba de chat»: barra Preguntar, pregunta «¿Quién envía el informe?» y respuesta «respuesta simulada».
- chat.json con fechas ISO8601; al reabrir la sesión, el historial permanece.
- Tocar fuera del panel lo oculta y deja la barra Preguntar.
- Durante una grabación real: el temporizador pasó de 00:05 a 00:12 y la respuesta llegó con la captura activa.
- El servidor local registró solo mensajes de texto; no se envió audio.

## Límites

- Se usó un proveedor simulado local, no una cuenta real.
- No se probó streaming.
- AC9 se verificó con pruebas de cola, no manualmente con dos preguntas en la UI.
- macOS 26 no se ha probado.
