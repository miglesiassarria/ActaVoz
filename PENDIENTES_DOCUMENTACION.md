# ActaVoz — pendientes de documentación

## Fase actual

Estamos definiendo y documentando el producto. Esta lista registra decisiones y especificaciones que todavía hay que completar en la documentación. Marcaremos cada casilla cuando el punto quede documentado y acordado; el check no significa que esté implementado.

Los pendientes se pueden añadir, dividir, reordenar o cambiar de prioridad según avance la conversación. La fase de implementación tendrá su propia lista de seguimiento cuando empecemos a construir el producto.

## Decisiones acordadas y documentadas

- [x] **Datos y almacenamiento:** crear `~/.ActaVoz` al primer arranque; configuración en Library y credenciales en el Llavero.
- [x] **Conservación:** mantener notas, transcripciones y resultados hasta su eliminación manual. Para el audio, ofrecer guardar siempre, borrar siempre o preguntar; guardar siempre será la opción inicial.
- [x] **Borrado y biblioteca:** directorios reales sin anidar bajo `~/.ActaVoz/Directorios` y sesiones nuevas en `~/.ActaVoz/Notas/`; al borrar un directorio o sesión se eliminan sus contenidos tras confirmación. Se podrán renombrar, mover, revisar y exportar sesiones y reproducir el audio conservado.
- [x] **Estructura de sesión:** carpeta con fecha, hora e identificador, metadatos, transcripción, resumen y audio opcional.
- [x] **Inicio de grabación:** «Nueva nota» abre un panel donde elegir idioma y conservación de perfiles; «Empezar» inicia la captura. Guardar perfiles estará activado por defecto.
- [x] **Idiomas e interlocutores:** español e inglés, con español por defecto y detección automática como opción. Se sugieren nombres cuando hay indicios claros y se confirman o corrigen manualmente.
- [x] **Procesamiento y consultas:** audio, transcripción y diarización en local; cada pregunta envía al LLM la transcripción completa acumulada y los resultados finales usan la transcripción completa. Si se supera el contexto se informa del límite, tamaño y exceso, sin truncar.
- [x] **Vista de sesión:** referencia visual de Granola, con notas centrales, transcripción en directo desplegable abajo a la izquierda y chat para preguntas. Tras detener y procesar la grabación, un botón genera el resumen en el centro. Los adjuntos quedan fuera de la definición actual.
- [x] **Plantillas:** incluir resumen general, reunión de trabajo, reunión individual y reflexión personal; permitir crear y editar plantillas propias.
- [x] **Aplicación de plantillas:** elegir la predeterminada en Ajustes y permitir cambiarla tras generar el resumen. Al regenerar se usan los datos conservados, incluida la transcripción completa, y el resultado sustituye al anterior sin historial.
- [x] **Proveedores y credenciales:** ofrecer OpenAI/ChatGPT, Claude, OpenCode Go, Ollama y un proveedor genérico; sin proveedor activo por defecto. Guardar las credenciales localmente en el Llavero; ChatGPT tendrá opciones de API key y OAuth.

## Pendientes de prioridad alta

- [ ] **Flujo de escritorio:** concretar el recorrido completo de captura, preguntas, parada, procesamiento, política de audio y revisión, incluidas las interacciones de la vista.
- [ ] **Transcripción y diarización:** definir precisión esperada, presentación y corrección de atribuciones, qué perfiles se guardan y cómo se gestionan o eliminan.
- [ ] **Proveedores de IA:** detallar el flujo inicial y Ajustes; decidir si se pueden configurar varios y elegir modelos distintos por función.
- [ ] **Resultados y plantillas:** concretar contenido, configuración y búsqueda de plantillas, notas propias frente al resultado generado y ejemplos de formato. Revisar los controles de fecha, participantes, carpetas y compartir que aparecen en las capturas.
- [ ] **Criterios de éxito:** acordar cómo juzgar la calidad de transcripción, separación de interlocutores, latencia y resúmenes.
- [ ] **Borrado de resultados:** concretar si se podrán borrar resultados individuales y su comportamiento; el borrado completo de sesiones y directorios ya está acordado.

## Pendientes de prioridad media

- [ ] **Alcance de la primera versión estable:** cerrar las funciones imprescindibles.
- [ ] **Audio y permisos:** detallar permisos de macOS, interrupciones y limitaciones de las fuentes.
- [ ] **Uso local y remoto:** definir funciones disponibles sin conexión, información sobre costes y límites, y cómo prevenir que las sesiones habituales excedan el contexto.
- [ ] **OAuth de ChatGPT:** describir el flujo esperado, gestión y revocación de la conexión, y comprobar su viabilidad.
- [ ] **Identidad y correcciones:** especificar cómo editar nombres y conservar correcciones para una sesión.

## Decisiones para la documentación

- [x] Mantener esta lista separada de la definición general del proyecto.
- [x] Usar casillas para marcar un pendiente cuando su documentación esté acordada.
- [x] Crear una lista distinta para la implementación al comenzar esa fase.
- [x] Dejar el trabajo de definición de la API REST para una fase posterior.
- [x] Crear `~/.ActaVoz` en el primer arranque de la app si aún no existe; se prevé distribución directa en DMG sin App Sandbox.
