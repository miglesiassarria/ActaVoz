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
- [x] **Procesamiento y consultas:** audio, transcripción y diarización en local; cada pregunta envía al LLM la transcripción completa acumulada y los resultados finales usan la transcripción completa. Sin control ni límites propios de contexto.
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

- [ ] **Vista de grabación:** revisar los casos de cierre, permisos denegados e interrupciones recogidos en las casillas de auditoría; lo ya acordado incluye cerrar el panel de transcripción con su control o al pulsar fuera.
  - [x] **Panel de chat:** al pulsar la barra se abre un mini chat con preguntas y respuestas; al pulsar fuera se oculta y queda visible la barra.
  - [x] **Indicador de grabación:** mostrar abajo el estado de grabación, el tiempo transcurrido y los controles de pausa y parada.
  - [x] **Contador durante la pausa:** detenerlo al pausar y reanudarlo al continuar, para mostrar el tiempo de audio capturado.
- [x] **Parada y procesamiento:** mostrar «Procesando la reunión» con un indicador de progreso tras detener la captura; cuando termine, mostrar «Generar resumen».
- [x] **Revisión de la sesión:** tomar como referencia las capturas: lista de sesiones agrupadas por fecha y apertura de una sesión en una vista amplia con título y contenido, junto con las vistas de notas, resumen y chat ya acordadas. Los próximos eventos y la integración de calendario quedan fuera del alcance actual.
- [x] **Atribuciones:** mostrar el nombre o etiqueta junto a cada intervención; al pulsarlo se podrá corregir y aplicar el cambio a todas las intervenciones atribuidas a ese interlocutor en la sesión.
- [x] **Perfiles de voz guardados:** cuando esté activada la opción, guardar únicamente los perfiles de interlocutores cuyo nombre haya confirmado la persona.
  - [x] Guardar los perfiles con nombre confirmado al terminar el procesamiento; si se confirma otro nombre después, guardar también su perfil cuando esté disponible. Intentar proponer nombres automáticamente a partir de indicios claros, sujetos a confirmación o corrección.
- [x] **Gestión de perfiles de voz:** en Ajustes se podrán consultar los perfiles guardados, cambiarles el nombre y eliminarlos.
- [x] **Configuración inicial de proveedores:** pantalla para elegir proveedor, introducir sus datos y seleccionar modelo, con opción de comprobar la conexión antes de continuar.
- [x] **Varios proveedores:** mantener varias conexiones configuradas y elegir la activa desde Ajustes, sin volver a introducir los datos al cambiar.
- [x] **Modelos por función:** elegir un modelo principal para todas las funciones y permitir asignar opcionalmente modelos específicos a funciones como preguntas o resúmenes.
- [x] **Contenido de resultados:** concretados los apartados de las cuatro plantillas iniciales.
  - [x] **Reunión de trabajo:** incluir temas y puntos importantes, decisiones y acuerdos, tareas y compromisos con responsable y fecha cuando se mencionen, y cuestiones pendientes o de seguimiento.
  - [x] **Resumen general:** incluir síntesis breve, temas tratados con puntos importantes y conclusiones y próximos pasos mencionados.
  - [x] **Reunión individual:** incluir temas y puntos importantes, acuerdos y compromisos de cada persona cuando se mencionen, y cuestiones pendientes y seguimiento.
  - [x] **Reflexión personal:** incluir ideas y temas principales, reflexiones y conclusiones, preguntas abiertas y posibles acciones mencionadas.
- [x] **Búsqueda de plantillas:** elegirlas en un menú desplegable con buscador por nombre.
- [x] **Ejemplos de resultados:** acordados los [ejemplos ficticios](EJEMPLOS_PLANTILLAS.md) para las cuatro plantillas iniciales.
  - [x] **Formato base:** encabezados, puntos y subpuntos, con títulos y apartados adaptados a cada plantilla.
- [x] **Fecha y participantes:** mostrar la fecha y los participantes bajo el título; permitir revisar y corregir sus nombres.
- [x] **Compartir:** permitir exportar la transcripción, el resumen o las notas como archivos y copiar su texto para pegarlo en otra aplicación.
- [ ] **Calidad de transcripción:** acordar el nivel mínimo después de revisar los resultados.
  - [x] **Método de evaluación:** comparar la transcripción con lo dicho en grabaciones de reuniones reales o preparadas en español e inglés.
- [ ] **Calidad de diarización:** acordar el nivel mínimo de separación de interlocutores.
  - [x] **Método de evaluación:** comprobar en las mismas grabaciones cuántas intervenciones se atribuyen a la persona correcta y detectar problemas con voces solapadas.
- [ ] **Latencia y resúmenes:** acordar umbrales concretos de rapidez y utilidad.
  - [x] **Método de evaluación:** medir los tiempos de transcripción, respuesta del chat y generación del resumen; revisar que este recoja decisiones y tareas correctamente y sin inventarlas.
- [x] **Borrado de resultados individuales:** permitir borrar el resumen generado y la síntesis de «Mis notas» por separado, tras confirmación, conservando la transcripción y las notas propias.

## Lista de decisiones por tratar: prioridad media

- [x] **Primera versión estable:** incluir las funciones de escritorio acordadas: grabación y recuperación, transcripción e identificación local, biblioteca, chat, resúmenes, notas, plantillas y proveedores configurables. Comprobar el funcionamiento con reuniones reales y acordar los niveles mínimos de calidad pendientes.
- [x] **Permisos de audio:** antes de la primera grabación, explicar la necesidad de acceso al micrófono y al audio del sistema y mostrar las solicitudes correspondientes de macOS.
- [ ] **Fuentes de audio:** concretar disponibilidad y limitaciones del micrófono y del audio del sistema.
  - [x] **Selección de fuentes:** ambas activadas por defecto; antes de grabar se podrá elegir el micrófono y desactivar cualquiera para la sesión.
  - [x] **Fuente no disponible al iniciar:** mostrar cuál falta y permitir empezar con la otra si hay al menos una fuente disponible.
- [x] **Interrupciones de audio:** avisar y continuar grabando con la fuente disponible; reanudar la captura de la fuente interrumpida cuando vuelva.
  - [x] **Pérdida de ambas fuentes:** pausar automáticamente, mostrar un aviso y permitir reanudar cuando vuelva alguna fuente.
- [x] **Uso sin conexión:** permitir grabar, transcribir, identificar interlocutores y consultar sesiones guardadas; preguntas y resúmenes estarán disponibles si hay un modelo local configurado y accesible.
- [x] **Costes y límites:** dejar el control y las estimaciones de costes para una fase posterior. No se controlarán costes ni límites propios de contexto en la fase actual.
- [x] **Prevención del exceso de contexto:** no implementar control ni avisos preventivos de contexto; utilizar toda la transcripción mediante una o varias llamadas según corresponda.
- [x] **OAuth de ChatGPT:** comprobar su compatibilidad durante el desarrollo y, si está disponible, permitir conectar y desconectar la cuenta desde Ajustes.
- [x] **Correcciones de identidad:** guardar automáticamente la corrección del nombre con la sesión para conservarla al cerrarla y volverla a abrir.

## Decisiones nuevas identificadas por la auditoría

Estas casillas se han añadido sin marcar porque la auditoría detectó decisiones que aún no constaban en la lista. Se resolverán antes de aprobar las specs afectadas.

- [ ] **Modelo por función adicional:** decidir cómo se asigna el modelo de deducción de nombres, si se utiliza un LLM. (0005, 0006)
  - [x] **Modelo para síntesis de notas:** usar el modelo de resúmenes o, si no hay uno específico, el modelo principal. (0006, 0009)
- [x] **Confirmación de sobrescritura:** pedir confirmación antes de regenerar un resumen con ediciones manuales; sin ediciones manuales, no preguntar. (0008)
- [x] **Chat: persistencia y contexto:** las preguntas enviadas mientras hay una respuesta en curso quedan en espera y se envían cuando termina la anterior, manteniendo el orden. (0007)
  - [x] **Historial y contexto:** guardar las preguntas y respuestas con la sesión; cada consulta utiliza la transcripción completa disponible y los turnos previos del chat.
- [x] **Sin proveedor:** se podrá omitir la configuración inicial y usar funciones locales, incluidas grabación, transcripción y notas. Al intentar usar una función que requiera proveedor, ActaVoz ofrecerá configurarlo. (0002, 0006)
- [ ] **Contexto del modelo:** decidir el comportamiento ante rechazo por longitud y la estrategia para una o varias llamadas sin eliminar texto ni imponer límites propios. (0006, 0013)
- [x] **Archivos de sesión:** guardar notas en `notas.md`, síntesis en `sintesis.md` e historial de chat en `chat.json`, dentro de la carpeta de cada sesión. (0003, 0007, 0009)
- [ ] **Audio y perfiles tardíos:** decidir cómo se conserva el audio separado o mezclado y qué datos de voz permanecen si se borra el audio antes de confirmar un nombre. (0004, 0005)
- [ ] **Corrección de voces:** decidir si habrá identificación del usuario local, fusión de interlocutores o reasignación de una intervención individual. (0005)
- [x] **Resultados adicionales:** obtener análisis y tareas mediante plantillas o el chat, conservando el resumen como resultado principal sin archivos independientes de análisis. (0008)
- [x] **Biblioteca:** «Nueva nota» siempre abre el flujo de grabación; no se contempla crear una nota exclusivamente de texto mediante ese botón. (0003)
  - [x] **Notas sin organizar:** acceso mediante una opción fija «Sin organizar» en la barra lateral.
  - [x] **Búsqueda de sesiones:** buscar por título y por texto de la transcripción, las notas o el resumen.
- [ ] **Cierre y permisos:** decidir comportamiento al cerrar durante la grabación, al cerrar sin responder sobre el audio y ante permisos denegados. (0004)
- [x] **Plantillas y fallo de regeneración:** las predefinidas se conservarán sin modificar y se podrán duplicar para crear versiones propias editables. (0008)
  - [x] **Fallo de regeneración:** conservar intacto el resumen anterior, mostrar el error y permitir reintentar; sustituirlo solo al terminar correctamente.
  - [x] **Eliminar plantillas propias:** permitirlo desde Ajustes con confirmación previa.
- [x] **Síntesis de notas:** se podrá editar directamente; al actualizarla, la nueva sustituirá a la anterior, incluidas las ediciones manuales. (0009)
  - [x] **Sin resumen principal:** indicar que primero hay que generarlo antes de generar la síntesis.
- [x] **Exportación y reproducción:** el audio conservado tendrá controles de reproducir y pausar, y una barra para avanzar o retroceder y ver el tiempo. (0010)
  - [x] **Formatos:** exportar transcripción, resumen y notas en Markdown o texto plano.
  - [x] **Transcripción exportada:** incluir nombre o etiqueta del interlocutor y marca de tiempo en cada intervención.
  - [x] **Exportación de notas:** elegir si se exportan solo las notas o también la síntesis generada, claramente diferenciada, cuando exista.

## Decisiones para la documentación

- [x] Mantener esta lista separada de la definición general del proyecto.
- [x] Usar casillas para marcar un pendiente cuando su documentación esté acordada.
- [x] Crear una lista distinta para la implementación al comenzar esa fase.
- [x] Dejar el trabajo de definición de la API REST para una fase posterior.
- [x] Crear `~/.ActaVoz` en el primer arranque de la app si aún no existe; se prevé distribución directa en DMG sin App Sandbox.
