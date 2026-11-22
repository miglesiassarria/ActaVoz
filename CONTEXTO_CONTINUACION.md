# ActaVoz — contexto para continuar

Este documento permite retomar el trabajo desde el punto actual aunque se cierre la conversación. Resume el estado de la documentación, las decisiones acordadas y el siguiente paso recomendado.

## Estado actual

- Estamos en la **fase de definición y documentación** del proyecto.
- Todavía no se ha empezado la implementación de la aplicación.
- La prioridad inmediata es seguir cerrando decisiones de la aplicación de escritorio para Mac.

## Proyecto acordado

ActaVoz será primero una aplicación de escritorio para Mac, inspirada en aplicaciones de notas de reuniones como Granola. Debe permitir grabar reuniones o reflexiones individuales, consultar lo dicho mientras la sesión continúa y obtener una transcripción y análisis al terminar.

### Dirección tecnológica decidida hasta ahora

- Aplicación de macOS en **Swift**, con **SwiftUI** para la interfaz.
- Capturar el audio del sistema y el micrófono, manteniendo ambas fuentes separadas y sincronizadas.
- La captura se hará con frameworks de Apple; es independiente de los modelos de transcripción y diarización.
- Todo el procesamiento de audio, la transcripción y la diarización se harán localmente en el Mac; el audio no se enviará a proveedores LLM.
- **SpeechAnalyzer** es la primera opción a evaluar para transcripción en directo.
- **FluidAudio/Core ML** es candidata para diarización local.
- Estas librerías/modelos aún deben validarse por precisión, latencia e idiomas con audio real.
- Idiomas de transcripción: español e inglés. Cada sesión permitirá elegir español, inglés o detección automática entre ambos; español será el predeterminado.
- El LLM (local o remoto, según configuración) recibirá texto de la transcripción para preguntas, resúmenes y análisis semánticos.
- En cada pregunta en directo se enviará la transcripción completa acumulada hasta ese momento; para los resultados finales, se enviará la transcripción completa de la sesión.
- ActaVoz debe evitar que la sesión supere el límite del modelo. Si aun así una solicitud excede el contexto, no se truncará en silencio: mostrará el máximo aceptado, el tamaño requerido y cuánto se excede. Es un caso que se espera que sea excepcional.
- La diarización usará etiquetas neutrales mientras no se confirme un nombre. ActaVoz solo sugerirá nombres con indicios claros y la persona podrá confirmarlos o corregirlos.
- Al pulsar el botón persistente «Nueva nota», se abrirá un panel breve antes de grabar. Permitirá elegir el idioma de la sesión y si guardar los perfiles de voz de esa sesión; «Guardar perfiles de voz» estará seleccionado por defecto y se podrá desactivar para una sesión concreta. «Empezar» inicia la captura.
- La grabación se podrá pausar y reanudar dentro de la misma sesión; durante la pausa no se capturará audio.
- Ante una interrupción inesperada se conservará lo capturado y transcrito hasta entonces. Al reabrir la aplicación, se mostrará la sesión y se podrá reanudar o dar por terminada.

### Biblioteca de sesiones

- La ventana principal tendrá una barra lateral izquierda con directorios que crea la persona.
- Al seleccionar un directorio, el panel central muestra lo que contiene: audios, resúmenes y otros resultados de las sesiones.
- Habrá un botón persistente abajo a la derecha para grabar o crear una nota nueva.
- Una nota nueva quedará sin carpeta asignada; después se podrá mover a un directorio o dejar sin organizar.
- Los directorios del usuario serán carpetas reales bajo `~/.ActaVoz/Directorios`, para mantener ordenada la raíz. El nombre **Directorios** ya está acordado.
- Las notas nuevas sin directorio se guardan bajo `~/.ActaVoz/Notas/` y se pueden mover después a `Directorios/<nombre>/`.
- Cada sesión tiene su carpeta, nombrada con fecha, hora e identificador único corto, por ejemplo `2026-11-20_15-42-09_7K4M2P/`. Su título visible se guarda en metadatos, así puede cambiar sin cambiar la identidad de la carpeta.
- El título visible inicial es la fecha y hora de inicio de la nota o reunión; se puede editar libremente, por ejemplo añadiendo una descripción al principio.
- Contenido previsto: `sesion.json` (metadatos), `transcripcion.json` (texto, tiempos e interlocutores), `resumen.md` y `audio.m4a` si se conserva. Otros análisis se añaden al generarse.
- En la primera versión se podrán crear, renombrar y borrar directorios, sin anidarlos. Borrar un directorio borra también sus sesiones y archivos, tras un aviso claro y confirmación.
- Las sesiones se podrán abrir para revisar resultados, reproducir el audio si se conservó, renombrar, mover, exportar y borrar definitivamente tras confirmación; se eliminará la carpeta de sesión completa y todos sus archivos.
- El formato de resultados adicionales y algunas interacciones de biblioteca aún se pueden precisar.

### Proveedores de LLM

- No habrá proveedor activo por defecto. En el primer inicio se preguntará cuál configurar.
- Catálogo previsto: OpenAI/ChatGPT por API key u OAuth, Anthropic/Claude por API key, OpenCode Go por API key, Ollama y un proveedor genérico con endpoint, token e identificador de modelo.
- Las API keys se introducirán una vez, se guardarán localmente en el Llavero de macOS y se reutilizarán sin pedirlas en cada uso. ChatGPT ofrece API key u OAuth; los demás proveedores con credenciales usan API key. Se pedirán de nuevo si caducan, se revocan o dejan de funcionar.
- La suscripción de ChatGPT y la API de OpenAI tienen configuración y facturación distintas.

### Almacenamiento en macOS

- Los archivos de sesión (audio, notas, transcripciones y análisis) se guardarán por defecto en la carpeta oculta `~/.ActaVoz` dentro del home del usuario.
- En el primer arranque tras instalar y abrir la app, ActaVoz debe crear esa carpeta y las subcarpetas necesarias si no existen.
- La configuración seguirá las ubicaciones de Library; credenciales en el Llavero; cachés regenerables en Caches; exportaciones en una ubicación elegida por la persona.
- La carpeta oculta es una preferencia explícita del usuario, aunque no sea la convención estándar de Library para datos gestionados por apps.
- Distribución prevista: DMG directo para arrastrar la app a Aplicaciones. Para crear `~/.ActaVoz` automáticamente sin pedir al usuario que elija carpeta, se propone distribución fuera del Mac App Store y sin App Sandbox, con firma y notarización.
- Falta definir la estructura interna de carpetas/archivos y la retención y borrado de notas/resultados.
- Política de audio decidida: en Ajustes habrá tres opciones: preguntar en cada sesión, guardar siempre o borrar siempre; por defecto será guardar siempre. Solo el modo de pregunta mostrará un aviso al terminar el procesamiento. Las notas, transcripción y análisis quedan como contenido de la sesión.
- Las notas, transcripciones, resúmenes y demás resultados se conservarán hasta que la persona los elimine manualmente; esto es independiente de la política del audio.

### API REST

- La API REST queda para una fase posterior. No definirla ni desarrollarla hasta que el usuario lo pida.
- Se creó `ActaVoz-API/README.md` con una descripción mínima de su propósito futuro.
- Se retiraron de la lista de pendientes actual los detalles de la API.

## Archivos de documentación

- [DEFINICION_PROYECTO.md](DEFINICION_PROYECTO.md): definición viva del producto y decisiones acordadas.
- [PENDIENTES_DOCUMENTACION.md](PENDIENTES_DOCUMENTACION.md): lista priorizada con casillas. Marcar una casilla significa que el punto quedó documentado y acordado, no implementado.
- [ActaVoz-API/README.md](ActaVoz-API/README.md): nota breve de la carpeta reservada a la fase 2.

## Pendientes de documentación abiertos

La lista principal está en `PENDIENTES_DOCUMENTACION.md`. Sus asuntos de mayor prioridad son:

1. Privacidad: definir el comportamiento al borrar sesiones/resultados. El audio se procesa localmente y no se envía; se decidió enviar la transcripción completa en cada pregunta y para los resultados finales.
2. Flujo de uso de escritorio desde el inicio de sesión hasta la revisión posterior.
3. Precisión esperada, cómo mostrar/corregir atribuciones, y qué perfiles de voz se guardan y cómo se gestionan. Los idiomas, el panel previo a la grabación y el valor inicial activado para guardar perfiles ya están acordados.
4. Configuración y uso de los proveedores LLM.
5. Contenido y formato de los resultados de cada sesión.
6. Criterios de éxito para transcripción, diarización, latencia y resúmenes.

También quedan pendientes el alcance de la primera versión estable, permisos y limitaciones de audio, modo local/remoto y OAuth de ChatGPT. La API REST no debe añadirse a esta lista durante la fase actual.

En la conversación se sugirió añadir temas sobre biblioteca y gestión de sesiones, pausa y recuperación ante errores, avisos de captura y pantallas principales. Todavía no se incorporaron a la lista; revisarlos con el usuario antes de añadirlos.

## Siguiente paso recomendado

**Punto de parada actual:** se decidió que audio, transcripción y diarización se procesan localmente, y que cada pregunta en directo envía al LLM la transcripción completa acumulada hasta ese momento; los resultados finales también usan la transcripción completa. Si se supera el límite del modelo, la app mostrará el máximo aceptado, el tamaño requerido y el exceso, sin truncar en silencio; se espera que sea excepcional. Las notas y resultados se conservan hasta su eliminación manual. Las sesiones se borran definitivamente tras confirmación, junto con todo su contenido. También se decidió que los nombres de interlocutores se sugieren cuando hay indicios claros y se confirman o corrigen manualmente.

**Decisión recién cerrada:** el botón «Nueva nota» abre un panel breve antes de grabar para elegir idioma y si guardar perfiles de voz; guardar perfiles queda activado por defecto y puede desactivarse para una sesión. Para la vista durante la grabación, la persona aportó capturas de Granola: espacio central para notas, controles inferiores y transcripción consultable en un panel desplegable. Falta concretar cómo se abre y se muestra ese panel.

**Última precisión:** el desplegable inferior izquierdo muestra la transcripción en directo y la barra de chat permite hacer preguntas. Al detener la grabación y terminar el procesamiento, aparecerá un botón para generar el resumen, que se mostrará en el espacio central. Los adjuntos quedan fuera de la definición actual por decisión de la persona usuaria.

**Panel de chat:** al pulsar la barra se abre un mini chat sobre la vista de la sesión con preguntas y respuestas. Al pulsar fuera, el panel se oculta y queda visible la barra para abrirlo de nuevo.

**Referencia más reciente:** la persona aportó capturas de un resumen organizado por temas, un selector con plantillas y opciones para buscarlas o crearlas, y una vista separada de notas propias. Quiere incorporar estas ideas; queda por concretar cómo funcionan. También aparecen controles de fecha, participantes, carpetas y compartir, pendientes de comentar sin dar por decidido su comportamiento.

**Plantillas:** se acordó incluir plantillas preparadas y permitir crear y editar plantillas propias. Las cuatro iniciales serán resumen general, reunión de trabajo, reunión individual y reflexión personal. Quedan por decidir su configuración y cómo se aplican a una sesión.

**Aplicación de plantillas:** se podrá elegir una plantilla predeterminada en Ajustes para generar los resúmenes. Después se podrá seleccionar otra plantilla y regenerar el resumen a partir de los datos conservados de la sesión, incluida la transcripción completa. El nuevo resumen sustituirá al anterior sin guardar historial de versiones por plantilla, aunque el audio se haya borrado.

**Configuración de plantillas propias:** se podrá indicar un nombre, las instrucciones para generar el resumen y los apartados que se quieran incluir.

**Edición del resumen:** se podrá editar directamente. Al regenerarlo con otra plantilla, el nuevo resumen sustituirá al anterior, incluidos los cambios manuales.

**Guardado:** los cambios en «Mis notas» y en el resumen editable se guardarán automáticamente mientras se escribe.

**Notas y resumen:** cada sesión tendrá dos vistas separadas: «Mis notas», editable por la persona, y «Resumen», generado. Regenerar el resumen no modificará las notas propias.

**Síntesis adicional:** las notas pueden escribirse o editarse durante la sesión y también después de la transcripción. El resumen principal se genera inicialmente sin las notas. En «Mis notas» se podrá generar una segunda síntesis que combine el acta de la reunión y las notas; aparecerá al final de esa vista, diferenciada e identificada como generada por IA. Se creará con «Generar síntesis»; si cambian las notas o el resumen principal, un aviso ofrecerá actualizarla. La nueva síntesis sustituirá a la anterior.

**Siguiente punto:** continuar cerrando el flujo principal de escritorio. Presentar opciones concretas y una recomendación para el paso siguiente, manteniendo abierta la gestión de perfiles de voz.

## Forma de avanzar

Al abordar cada nuevo punto de documentación, presentar opciones concretas y una recomendación, y permitir que la persona elija varias, haga preguntas o proponga otra alternativa.

Mantener `PENDIENTES_DOCUMENTACION.md` como lista previa de decisiones: preparar casillas sin marcar para los puntos por tratar y, al acordar y documentar cada uno, marcar la casilla existente en su lugar. No añadir casillas ya marcadas para aparentar avance. Si surge un tema nuevo, añadirlo como pendiente sin marcar y comunicarlo; conservar los acuerdos históricos y evitar reordenar la lista sin motivo.

## Instrucción para retomar

Seguir trabajando solo en la documentación de la fase 1 de escritorio. No empezar a implementar. Mantener la API REST reservada para la fase 2 hasta recibir una petición explícita del usuario.
