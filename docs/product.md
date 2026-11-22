# Producto

## Propósito

ActaVoz será una aplicación de escritorio para macOS que permite capturar reuniones y reflexiones, consultar lo dicho durante una sesión y revisar una transcripción y síntesis al terminar. La API REST es un producto independiente reservado para una segunda fase.

## Capacidades acordadas para la primera fase

- Iniciar y detener una sesión con audio de micrófono y del sistema, conservando ambas fuentes separadas y sincronizadas durante el procesamiento.
- Mostrar el progreso de captura, transcripción y consultas realizadas mientras la sesión continúa.
- Obtener transcripción, síntesis, análisis, tareas, compromisos y puntos importantes tras la sesión.
- Organizar sesiones en directorios reales bajo `~/.ActaVoz/Directorios`, con notas sin organizar hasta que la persona las mueva.
- Configurar un proveedor de IA en el primer inicio o en Ajustes. El catálogo previsto incluye OpenAI/ChatGPT, Anthropic/Claude, OpenCode Go, Ollama y un proveedor genérico.
- Guardar credenciales en el Llavero de macOS y aplicar al audio una política de preguntar, guardar siempre o borrar siempre; el valor inicial previsto es guardar siempre.

## Invariantes de producto

- Los archivos de sesión viven por defecto bajo `~/.ActaVoz`; configuración en Library, credenciales en el Llavero y cachés regenerables en Caches.
- Ningún proveedor de IA está activo por defecto.
- La API REST no forma parte de la primera fase y no debe definirse ni construirse sin una decisión explícita posterior.
- La atribución de interlocutores es aproximada: si no hay evidencia suficiente, se usan etiquetas neutrales.
- El audio original y los resultados de una sesión son contenidos distintos; la política de audio no elimina por sí sola notas, transcripción o análisis.

## Decisiones pendientes

Siguen abiertos la estructura interna de cada sesión, retención y borrado, idiomas y métricas de calidad, versión mínima de macOS, selección validada de transcripción y diarización, permisos de audio, alcance de la primera versión estable y flujo OAuth de ChatGPT. La fuente de detalle es `DEFINICION_PROYECTO.md` y la lista priorizada es `PENDIENTES_DOCUMENTACION.md`.
