# ActaVoz — pendientes de documentación

## Fase actual

Estamos definiendo y documentando el producto. Esta lista registra decisiones y especificaciones que todavía hay que completar en la documentación. Marcaremos cada casilla cuando el punto quede documentado y acordado; el check no significa que esté implementado.

Los pendientes se pueden añadir, dividir, reordenar o cambiar de prioridad según avance la conversación. La fase de implementación tendrá su propia lista de seguimiento cuando empecemos a construir el producto.

**Forma de mantener esta lista:** las decisiones por tratar se enumeran por adelantado como casillas sin marcar. Al acordar y documentar una decisión, se marca su casilla existente en el mismo lugar y se refleja el detalle en la definición del proyecto. No crear casillas ya marcadas para simular avance. Se podrán añadir nuevas casillas sin marcar cuando surjan necesidades nuevas, indicándolo expresamente; no se reordenarán ni eliminarán puntos sin motivo. Las casillas ya cerradas recogen acuerdos históricos y siguen visibles.

## Decisiones acordadas y documentadas

- [x] **Datos y almacenamiento:** crear `~/.ActaVoz` al primer arranque; configuración en Library y credenciales en el Llavero.
- [x] **Conservación:** mantener notas, transcripciones y resultados hasta su eliminación manual. Para el audio, ofrecer guardar siempre, borrar siempre o preguntar; guardar siempre será la opción inicial.
- [x] **Borrado y biblioteca:** directorios reales sin anidar bajo `~/.ActaVoz/Directorios` y sesiones nuevas en `~/.ActaVoz/Notas/`; al borrar un directorio o sesión se eliminan sus contenidos tras confirmación. Se podrán renombrar, mover, revisar y exportar sesiones y reproducir el audio conservado.
- [x] **Estructura de sesión:** carpeta con fecha, hora e identificador, metadatos, transcripción, resumen y audio opcional.
- [x] **Título de la sesión:** inicialmente mostrará la fecha y hora de inicio; se podrá editar libremente, por ejemplo para añadir una descripción al principio.
- [x] **Inicio de grabación:** «Nueva nota» abre un panel donde elegir idioma y conservación de perfiles; «Empezar» inicia la captura. Guardar perfiles estará activado por defecto.
- [x] **Pausa de grabación:** se podrá pausar y reanudar dentro de la misma sesión; durante la pausa no se capturará audio.
- [x] **Interrupción inesperada:** conservar lo capturado y transcrito hasta la interrupción; al reabrir ActaVoz, mostrar la sesión y ofrecer reanudarla o darla por terminada.
- [x] **Idiomas e interlocutores:** español e inglés, con español por defecto y detección automática como opción. Se sugieren nombres cuando hay indicios claros y se confirman o corrigen manualmente.
- [x] **Procesamiento y consultas:** audio, transcripción y diarización en local; cada pregunta envía al LLM la transcripción completa acumulada y los resultados finales usan la transcripción completa. Si se supera el contexto se informa del límite, tamaño y exceso, sin truncar.
- [x] **Vista de sesión:** referencia visual de Granola, con notas centrales, transcripción en directo desplegable abajo a la izquierda y chat para preguntas. Tras detener y procesar la grabación, un botón genera el resumen en el centro. Los adjuntos quedan fuera de la definición actual.
- [x] **Plantillas:** incluir resumen general, reunión de trabajo, reunión individual y reflexión personal; permitir crear y editar plantillas propias.
- [x] **Aplicación de plantillas:** elegir la predeterminada en Ajustes y permitir cambiarla tras generar el resumen. Al regenerar se usan los datos conservados, incluida la transcripción completa, y el resultado sustituye al anterior sin historial.
- [x] **Configuración básica de plantillas propias:** indicar nombre, instrucciones para el resumen y apartados que se quieran incluir.
- [x] **Edición del resumen:** se podrá editar directamente; al regenerarlo con otra plantilla, el resultado nuevo sustituirá al anterior, incluidos sus cambios manuales.
- [x] **Guardado de ediciones:** los cambios en «Mis notas» y en el resumen editable se guardarán automáticamente mientras se escribe.
- [x] **Notas propias y resumen:** cada sesión tendrá vistas separadas de «Mis notas», que se pueden escribir y editar, y «Resumen». Regenerar el resumen no modificará las notas propias.
- [x] **Síntesis de notas y reunión:** las notas se podrán escribir y editar durante la sesión o después de la transcripción. El resumen principal se generará inicialmente sin ellas; en «Mis notas» se podrá generar una segunda síntesis que combine el acta de la reunión con las notas, al final de la vista y claramente identificada como generada por IA.
- [x] **Generación y actualización de la síntesis de notas:** un botón la genera; si cambian las notas o el resumen principal, un aviso ofrecerá actualizarla. La síntesis actualizada sustituirá a la anterior.
- [x] **Proveedores y credenciales:** ofrecer OpenAI/ChatGPT, Claude, OpenCode Go, Ollama y un proveedor genérico; sin proveedor activo por defecto. Guardar las credenciales localmente en el Llavero; ChatGPT tendrá opciones de API key y OAuth.

## Lista de decisiones por tratar: prioridad alta

- [ ] **Vista de grabación:** concretar las restantes interacciones de la pantalla durante la captura.
  - [x] **Panel de chat:** al pulsar la barra se abre un mini chat con preguntas y respuestas; al pulsar fuera se oculta y queda visible la barra.
- [x] **Parada y procesamiento:** mostrar «Procesando la reunión» con un indicador de progreso tras detener la captura; cuando termine, mostrar «Generar resumen».
- [x] **Revisión de la sesión:** tomar como referencia las capturas: lista de sesiones agrupadas por fecha y apertura de una sesión en una vista amplia con título y contenido, junto con las vistas de notas, resumen y chat ya acordadas. Los próximos eventos y la integración de calendario quedan fuera del alcance actual.
- [x] **Atribuciones:** mostrar el nombre o etiqueta junto a cada intervención; al pulsarlo se podrá corregir y aplicar el cambio a todas las intervenciones atribuidas a ese interlocutor en la sesión.
- [x] **Perfiles de voz guardados:** cuando esté activada la opción, guardar únicamente los perfiles de interlocutores cuyo nombre haya confirmado la persona.
  - [x] Guardar los perfiles con nombre confirmado al terminar el procesamiento; si se confirma otro nombre después, guardar también su perfil cuando esté disponible. Intentar proponer nombres automáticamente a partir de indicios claros, sujetos a confirmación o corrección.
- [x] **Gestión de perfiles de voz:** en Ajustes se podrán consultar los perfiles guardados, cambiarles el nombre y eliminarlos.
- [ ] **Configuración inicial de proveedores:** detallar cómo se elige y conecta un proveedor al primer inicio.
- [ ] **Varios proveedores:** decidir si se pueden mantener varias conexiones configuradas.
- [ ] **Modelos por función:** decidir si se pueden elegir modelos distintos para preguntas, resúmenes y otras funciones.
- [ ] **Contenido de resultados:** concretar el contenido esperado de resúmenes, tareas, decisiones y compromisos.
- [ ] **Búsqueda de plantillas:** concretar cómo se encuentran y seleccionan las plantillas disponibles.
- [ ] **Ejemplos de resultados:** acordar ejemplos del formato esperado para las plantillas iniciales.
- [ ] **Fecha y participantes:** concretar los controles y datos que se muestran en la sesión.
- [ ] **Compartir:** decidir qué opciones de compartir o exportar se ofrecerán y cómo funcionarán.
- [ ] **Calidad de transcripción:** acordar cómo medir y qué nivel de precisión se espera.
- [ ] **Calidad de diarización:** acordar cómo medir y qué nivel de separación de interlocutores se espera.
- [ ] **Latencia y resúmenes:** acordar cómo evaluar el tiempo de respuesta y la utilidad de los resúmenes.
- [ ] **Borrado de resultados individuales:** decidir si se pueden borrar por separado y cómo se comporta la aplicación.

## Lista de decisiones por tratar: prioridad media

- [ ] **Primera versión estable:** acordar las funciones imprescindibles para considerarla terminada.
- [ ] **Permisos de audio:** documentar los permisos de macOS y el flujo para concederlos.
- [ ] **Fuentes de audio:** concretar selección, disponibilidad y limitaciones del micrófono y del audio del sistema.
- [ ] **Interrupciones de audio:** concretar qué ocurre si una fuente deja de estar disponible durante una sesión.
- [ ] **Uso sin conexión:** definir qué funciones están disponibles sin conexión.
- [ ] **Costes y límites:** decidir cómo informar de costes y límites de los proveedores.
- [ ] **Prevención del exceso de contexto:** definir cómo evitar que sesiones habituales excedan el límite del modelo.
- [ ] **OAuth de ChatGPT:** comprobar su viabilidad y definir el flujo de conexión, gestión y revocación.
- [ ] **Correcciones de identidad:** definir cómo se conserva una corrección de nombre dentro de la sesión.

## Decisiones para la documentación

- [x] Mantener esta lista separada de la definición general del proyecto.
- [x] Usar casillas para marcar un pendiente cuando su documentación esté acordada.
- [x] Crear una lista distinta para la implementación al comenzar esa fase.
- [x] Dejar el trabajo de definición de la API REST para una fase posterior.
- [x] Crear `~/.ActaVoz` en el primer arranque de la app si aún no existe; se prevé distribución directa en DMG sin App Sandbox.
