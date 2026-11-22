# ActaVoz — pendientes de documentación

## Fase actual

Estamos definiendo y documentando el producto. Esta lista registra decisiones y especificaciones que todavía hay que completar en la documentación. Marcaremos cada casilla cuando el punto quede documentado y acordado; el check no significa que esté implementado.

Los pendientes se pueden añadir, dividir, reordenar o cambiar de prioridad según avance la conversación. La fase de implementación tendrá su propia lista de seguimiento cuando empecemos a construir el producto.

## Prioridad alta

- [ ] **Privacidad y datos:** las notas, transcripciones, resúmenes y resultados se conservarán hasta que la persona los elimine manualmente. El audio tendrá una política independiente en Ajustes —preguntar en cada sesión, guardar siempre o borrar siempre—, con «guardar siempre» como valor inicial. El audio se procesa y transcribe localmente; a los LLM se les envía texto de la transcripción completa, tanto para cada pregunta como para los resultados finales. Falta definir el comportamiento al borrar sesiones/resultados. Los archivos de sesión irán por defecto en `~/.ActaVoz`; configuración en Library, credenciales en el Llavero y cachés regenerables en Caches.
- [x] **Biblioteca y estructura de sesiones:** se acordaron directorios reales bajo `~/.ActaVoz/Directorios`, barra lateral izquierda, panel central, botón persistente para crear/grabar notas, notas nuevas bajo `~/.ActaVoz/Notas/` hasta organizarlas, y carpetas de sesión con fecha/hora/ID, metadatos, transcripción estructurada, resumen y audio opcional. En la primera versión se podrán crear, renombrar y borrar directorios (sin anidar); borrar un directorio eliminará sus sesiones y archivos tras confirmación. Las sesiones se podrán revisar, reproducir si conservan audio, renombrar, mover, exportar y borrar definitivamente tras confirmación, incluyendo todo el contenido de cada sesión.
- [ ] **Flujo principal de escritorio:** acordado que «Nueva nota» abre un panel breve previo a la grabación para elegir idioma y si se guardan perfiles de voz; «Empezar» inicia la captura. Para la vista durante la grabación se tomarán como referencia las capturas de Granola aportadas: notas en el centro y controles inferiores, con transcripción consultable en un panel desplegable. Falta concretar esa interacción y documentar el flujo completo: captura, preguntas, parada, procesamiento, política de audio y revisión posterior.
- [ ] **Transcripción y diarización:** español e inglés serán los idiomas iniciales; por sesión se podrá elegir español, inglés o detección automática entre ambos, con español por defecto. ActaVoz sugerirá nombres solo con indicios claros y pedirá confirmación o corrección. Antes de grabar se podrá elegir si guardar perfiles de voz de esa sesión para reconocer interlocutores en reuniones futuras; la opción estará activada por defecto. Falta acordar qué perfiles se guardan y cómo se gestionan o eliminan; también definir el nivel de precisión esperado y los detalles para mostrar/corregir atribuciones.
- [ ] **Proveedores de IA:** especificar el flujo inicial y los ajustes para ChatGPT por API key u OAuth, Claude, OpenCode Go, Ollama y el endpoint genérico; decidir si se pueden configurar varios y elegir modelos distintos por función. Las API keys se introducirán una vez, se guardarán localmente en el Llavero y se reutilizarán sin pedirlas en cada uso.
- [ ] **Resultados de una sesión:** usar las capturas aportadas como referencia para el resumen central por temas y puntos. Habrá plantillas preparadas y se podrán crear y editar plantillas propias. Las cuatro iniciales acordadas son resumen general, reunión de trabajo, reunión individual y reflexión personal. Concretar sus opciones y aplicación, el contenido, las notas propias diferenciadas del resultado generado y la búsqueda de plantillas. Revisar las opciones visibles de fecha, participantes, carpetas y compartir antes de cerrar su comportamiento; incluir ejemplos del formato deseado.
- [ ] **Criterios de éxito:** acordar cómo juzgaremos la calidad de transcripción, separación de interlocutores, latencia de respuestas y utilidad de los resúmenes.

## Prioridad media

- [ ] **Alcance de la primera versión estable:** cerrar qué funciones son imprescindibles para considerar la aplicación de escritorio estable y funcional.
- [ ] **Requisitos de audio y permisos:** documentar las fuentes disponibles, los permisos de macOS, el tratamiento de interrupciones y las limitaciones conocidas.
- [ ] **Modelo de uso local y remoto:** el procesamiento de audio, transcripción y diarización serán locales; el LLM podrá ser local o remoto y recibirá texto de la transcripción. Si se supera el límite de contexto, ActaVoz mostrará el límite del modelo, el tamaño de la solicitud y el exceso, sin truncar. Falta definir qué funciones quedan disponibles sin conexión, cómo se informa de costes/límites y cómo prevenir que las sesiones habituales excedan el contexto.
- [ ] **Configuración OAuth de ChatGPT:** describir el flujo esperado, la gestión de sesión y la forma de revocar la conexión.
- [ ] **Identidad y correcciones:** especificar cómo se editan nombres de interlocutores y cómo se conserva una corrección para la sesión.

## Decisiones para la documentación

- [x] Mantener esta lista separada de la definición general del proyecto.
- [x] Usar casillas para marcar un pendiente cuando su documentación esté acordada.
- [x] Crear una lista distinta para la implementación al comenzar esa fase.
- [x] Dejar el trabajo de definición de la API REST para una fase posterior.
- [x] Crear `~/.ActaVoz` en el primer arranque de la app si aún no existe; se prevé distribución directa en DMG sin App Sandbox.
