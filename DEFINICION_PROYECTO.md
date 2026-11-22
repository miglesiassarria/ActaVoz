# ActaVoz — definición del proyecto

Seguimiento de temas pendientes de esta fase: [PENDIENTES_DOCUMENTACION.md](PENDIENTES_DOCUMENTACION.md).

## Visión

ActaVoz tendrá una aplicación de escritorio, principalmente para Mac, como primera fase. En una segunda fase se abordará un producto API independiente.

La experiencia de escritorio toma como referencia aplicaciones de notas para reuniones como Granola, con la propuesta de combinar captura, consultas en directo y síntesis posterior. La tecnología de la primera fase ya tiene una dirección acordada; quedan por evaluar sus componentes de transcripción y diarización.

## Productos y fases

El repositorio tendrá una carpeta por producto. La carpeta de la API REST se reservará para la segunda fase.

### Fase 1: aplicación de escritorio

Producto principal, pensado sobre todo para Mac. Ofrecerá la experiencia interactiva de reuniones y reflexiones descrita abajo: captura de audio, procesamiento en directo, preguntas durante la sesión e informes al finalizar.

### Fase 2: API REST

Producto independiente que se abordará en una fase posterior. Su definición y desarrollo quedan fuera de la fase actual.

## Experiencia de escritorio

### Dirección tecnológica

- La aplicación de escritorio se desarrollará para macOS en **Swift**, con **SwiftUI** para la interfaz.
- La captura será nativa: **ScreenCaptureKit** para el audio del sistema y las herramientas de audio de Apple para el micrófono.
- Se conservarán ambas fuentes separadas y sincronizadas durante el procesamiento, en vez de mezclarlas al capturarlas. Esto puede ayudar a distinguir la voz local de las voces remotas y reducir atribuciones erróneas.
- La captura de audio es una función del sistema operativo. La transcripción y la diarización son tareas distintas, realizadas localmente en el Mac con modelos de reconocimiento de voz y de identificación de turnos de habla.
- **SpeechAnalyzer** es la primera opción a evaluar para transcripción en directo en Swift. **FluidAudio/Core ML** es una candidata para diarización en el dispositivo. La calidad, latencia e idiomas admitidos deberán validarse con reuniones reales antes de cerrar estas dependencias.
- La primera versión tendrá español e inglés como idiomas de transcripción. Cada sesión permitirá elegir español, inglés o detección automática entre ambos; el español estará seleccionado por defecto.
- El audio se procesará, transcribirá y diarizará localmente. No se enviará audio al LLM. Para preguntas, resúmenes y análisis se enviará la transcripción —con el contexto necesario— al modelo seleccionado.
- ActaVoz debe evitar que una transcripción supere el límite del modelo. No recortará contenido en silencio. Si el límite se supera, bloqueará esa solicitud y mostrará un mensaje con el máximo aceptado por el modelo, el tamaño de la solicitud y cuánto se excede.

### Modelos de lenguaje y proveedores

La síntesis, el análisis semántico, la extracción de tareas y las preguntas sobre la reunión se apoyarán en un modelo de lenguaje (LLM). La aplicación no traerá ningún proveedor preconfigurado: en el primer inicio preguntará cuál quiere conectar la persona. Desde Ajustes se podrán añadir y gestionar proveedores y elegir el modelo activo, con opciones locales, remotas y personalizadas.

La arquitectura permitirá añadir proveedores mediante adaptadores. En el primer inicio se ofrecerá elegir y configurar uno, sin dejar ninguno activo por defecto. El catálogo inicial incluirá:

- **OpenAI / ChatGPT**, con conexión mediante API key o mediante OAuth.
- **Anthropic / Claude**, mediante API key.
- **OpenCode Go**, mediante su API key.
- **Ollama**, para modelos locales.
- **Proveedor genérico**, para introducir la URL del endpoint, token de acceso e identificador del modelo.

Desde Ajustes se podrán añadir y gestionar conexiones, cambiar el modelo activo y editar la configuración del proveedor genérico. Su compatibilidad dependerá del formato de API que admita el endpoint.

Las API keys se introducirán una vez y se guardarán localmente en el Llavero de macOS para reutilizarlas sin volver a pedirlas en cada uso. ChatGPT ofrecerá API key u OAuth; los demás proveedores con credenciales usarán API key. La app solicitará renovar o corregir la credencial si caduca, se revoca o deja de funcionar. Las credenciales OAuth también se conservarán en el Llavero para mantener la sesión. La compatibilidad con servicios distintos no se dará por supuesta: cada proveedor puede tener formatos de API y capacidades diferentes. El usuario confirma que OpenCode Go permite usar API keys y que ya lo utiliza desde otras aplicaciones; por tanto, se contempla como proveedor configurable de ActaVoz. El acceso a la API de OpenAI requiere configurarla y facturarla por separado de una suscripción de ChatGPT.

### Ubicaciones de datos en macOS

- Las grabaciones y demás archivos de sesión (notas, transcripciones y análisis) se guardarán por defecto bajo `~/.ActaVoz`, una carpeta oculta dentro del home del usuario.
- En el primer arranque de ActaVoz, tras instalarla y abrirla por primera vez, la app comprobará si existe esa carpeta; si no existe, la creará junto con la estructura de subcarpetas que necesite.
- La configuración de ActaVoz se guardará en las ubicaciones de **Library** recomendadas por macOS. Las credenciales se guardarán en el Llavero y las cachés regenerables en **Caches**.
- Las exportaciones se guardarán en la ubicación que elija la persona.
- Esta carpeta de sesiones es una preferencia explícita del proyecto. La distribución prevista es una app de Mac descargable en DMG y arrastrable a Aplicaciones. Para crear `~/.ActaVoz` automáticamente sin pedir al usuario que elija la carpeta, la dirección propuesta es distribuirla fuera del Mac App Store y sin App Sandbox, con firma y notarización de Apple.
- También queda por definir cuánto tiempo se conservan las notas y los resultados, cómo se borran y qué ocurre si la persona cierra la app sin responder al aviso del audio.

Los LLM no son necesarios para todas las funciones. Capturar audio, mantener tiempos, separar fuentes, detectar actividad de voz, transcribir y organizar interlocutores son tareas que se procesarán localmente con frameworks y modelos especializados. Un LLM aporta valor cuando hay que interpretar la transcripción, responder preguntas con contexto, resumir o redactar conclusiones.

### Durante la sesión

- La vista de grabación tomará como referencia las capturas de Granola aportadas por la persona: un espacio central amplio para escribir notas, con título y datos de la sesión, y controles discretos en la zona inferior para la grabación y las preguntas. La transcripción en directo se podrá consultar en un panel desplegable, como en la segunda captura. La disposición y el comportamiento concretos se terminarán de definir.
- El desplegable de la zona inferior izquierda mostrará en tiempo real la transcripción de lo que se captura. La barra de chat permitirá formular preguntas durante la grabación. Los adjuntos quedan fuera de la definición actual.
- Al pulsar la barra de chat se abrirá un panel compacto sobre la vista de la sesión, con las preguntas y respuestas. Al pulsar fuera, el panel se ocultará y quedará visible la barra para volver a abrirlo. La captura aportada es la referencia para esta interacción.
- Al pulsar el botón persistente «Nueva nota», se abrirá un panel breve previo a la grabación. Desde ahí se podrá elegir el idioma de esa sesión y si se guardan sus perfiles de voz para reconocer a esos interlocutores en reuniones futuras; «Empezar» iniciará la captura.
- En ese panel, «Guardar perfiles de voz» estará seleccionado por defecto. La persona podrá desmarcarlo para una sesión concreta.
- Cuando esté activado guardar perfiles, solo se guardarán los de interlocutores cuyo nombre haya sido confirmado por la persona, para facilitar su reconocimiento en futuras reuniones.
- Los perfiles con nombre confirmado se guardarán al terminar el procesamiento de la reunión. Si se confirma otro nombre después, también se guardará su perfil cuando esté disponible. ActaVoz intentará deducir y proponer nombres automáticamente a partir de indicios claros de la conversación; la persona deberá confirmarlos o corregirlos.
- En Ajustes habrá una sección para consultar los perfiles de voz guardados, cambiarles el nombre y eliminarlos.
- El idioma seguirá las opciones acordadas: español, inglés o detección automática entre ambos, con español seleccionado por defecto.
- La persona inicia una sesión para grabar una reunión o una reflexión en solitario.
- ActaVoz captura y procesa el audio de forma continua, mostrando el avance de la sesión.
- La grabación se podrá pausar y reanudar dentro de la misma sesión. Durante la pausa no se capturará audio.
- Si la grabación se interrumpe inesperadamente, ActaVoz conservará lo capturado y transcrito hasta ese momento. Al abrir de nuevo la aplicación, mostrará la sesión interrumpida y ofrecerá reanudarla o darla por terminada.
- El sistema intentará distinguir las voces y asignar intervenciones a cada interlocutor. Si encuentra indicios claros de un nombre, lo propondrá para que la persona lo confirme o corrija. Mientras no se confirme, usará etiquetas neutrales como «Interlocutor 1» e «Interlocutor 2».
- La transcripción mostrará el nombre o etiqueta de cada interlocutor junto a sus intervenciones. Al pulsarlo, la persona podrá corregirlo y aplicar el cambio a todas las intervenciones atribuidas a ese interlocutor en la sesión.
- Mientras la captura continúa, la persona puede escribir preguntas en un cuadro de texto. Para cada pregunta, ActaVoz enviará al LLM toda la transcripción acumulada hasta ese momento y responderá sin interrumpir la grabación.

El flujo acordado para iniciar una grabación es pulsar «Nueva nota», revisar las opciones en el panel breve y pulsar «Empezar».

### Al finalizar

La persona detiene la captura y, cuando termine el procesamiento, podrá pulsar un botón para generar el resumen. Este y la información de la reunión aparecerán en el espacio central. Para generar los resultados finales, ActaVoz enviará al LLM la transcripción completa de la sesión. También podrá solicitar resultados específicos, como:

- Transcripción, con intervenciones atribuidas a interlocutores.
- Análisis de la reunión o de la reflexión.
- Tareas y compromisos que hayan surgido.
- Puntos importantes y temas de interés.
- Reflexiones y otras síntesis útiles.

Tras detener la captura, ActaVoz mostrará «Procesando la reunión» con un indicador de progreso. Cuando termine el procesamiento, aparecerá el botón «Generar resumen».

Las capturas aportadas sirven de referencia para presentar el resultado como un documento central con título, encabezados por tema y puntos agrupados. También muestran un selector de plantillas para distintos tipos de reunión, opciones para buscar y crear plantillas, y una vista de notas propias diferenciada del contenido generado. Se quieren incorporar estas posibilidades; queda por concretar su funcionamiento y alcance. Las capturas incluyen además controles para fecha, participantes, organización en carpetas y compartir, cuyo comportamiento aún no se ha acordado.

Cada sesión tendrá dos vistas separadas: «Mis notas», donde la persona podrá escribir y editar sus propias notas, y «Resumen», con el contenido generado. Regenerar el resumen al cambiar de plantilla no modificará las notas propias.

Las notas propias se podrán escribir y editar durante la sesión y después de terminar la transcripción. El resumen principal se generará inicialmente sin tener en cuenta esas notas. En «Mis notas» se podrá generar un segundo resumen que combine el acta o resumen de la reunión con las notas escritas; aparecerá al final de esa vista, claramente identificado como contenido generado por inteligencia artificial. Las notas personales, este segundo resumen y el resumen principal conservarán espacios diferenciados.

Un botón «Generar síntesis» permitirá crear esa segunda síntesis. Si después cambian las notas o el resumen principal, se mostrará un aviso de que puede actualizarse; al pulsar «Actualizar síntesis», la nueva sustituirá a la anterior.

ActaVoz incluirá plantillas de resumen preparadas y permitirá crear y editar plantillas propias. Las plantillas iniciales acordadas son:

- **Resumen general:** temas y puntos importantes.
- **Reunión de trabajo:** decisiones, tareas y responsables cuando se mencionen.
- **Reunión individual:** temas tratados, acuerdos y seguimiento.
- **Reflexión personal:** ideas, conclusiones y posibles acciones.

En Ajustes se podrá elegir una plantilla predeterminada para generar los resúmenes. Una vez generado el resumen de una sesión, se podrá elegir otra plantilla y regenerarlo con ella, usando los datos conservados de la sesión, incluida la transcripción completa. El nuevo resumen sustituirá al anterior; no se guardará un historial de versiones por plantilla.

Al crear una plantilla propia se podrá indicar su nombre, las instrucciones para generar el resumen y los apartados que se quieran incluir.

La persona podrá editar directamente el resumen generado. Si después lo regenera con otra plantilla, el nuevo resumen sustituirá al anterior, incluidos sus cambios manuales.

Los cambios en «Mis notas» y en el resumen editable se guardarán automáticamente mientras la persona escribe.

En Ajustes se podrá elegir cómo tratar el audio original al terminar el procesamiento: preguntar en cada sesión, guardarlo siempre o borrarlo siempre. El valor inicial será guardarlo siempre. Si se elige preguntar, ActaVoz mostrará un aviso al terminar el procesamiento. La política solo afecta al archivo de audio; las notas, transcripción y análisis siguen siendo el contenido de la sesión.

Las notas, transcripciones, resúmenes y demás resultados se conservarán hasta que la persona los elimine manualmente. Esta política es independiente de la decisión de guardar o borrar el audio original.

### Biblioteca de sesiones

- Las capturas aportadas sirven de referencia para mostrar una lista de sesiones agrupadas por fecha y abrir una sesión en una vista amplia con su título y contenido. En esa vista se mantendrán las opciones acordadas para notas, resumen y chat.
- El apartado de próximos eventos y la integración de calendario que aparecen en la captura quedan fuera del alcance actual.
- La ventana principal tendrá una barra lateral izquierda donde se mostrarán los directorios creados por la persona.
- Al seleccionar un directorio, el panel central mostrará su contenido.
- El contenido podrá incluir elementos de las sesiones, como audios, resúmenes, transcripciones y análisis.
- Habrá un botón persistente en la zona inferior derecha para iniciar una grabación o crear una nota nueva.
- Al terminar, la nota quedará sin carpeta asignada. La persona podrá moverla a un directorio o dejarla sin organizar.
- Los directorios creados por la persona serán carpetas reales, agrupadas dentro de `~/.ActaVoz/Directorios` para mantener ordenada la raíz.
- En la primera versión, los directorios se podrán crear, renombrar y borrar; no habrá directorios anidados.
- Las sesiones se podrán abrir para revisar sus resultados, reproducir el audio si se conservó, renombrar, mover a otro directorio, exportar y borrar definitivamente tras confirmación.
- Borrar una sesión eliminará toda su carpeta y contenido: audio si se conservó, transcripción, resumen y análisis.
- Borrar un directorio borrará también las sesiones y archivos que contiene. Antes, la app mostrará un aviso claro y pedirá confirmación.
- Las sesiones nuevas sin directorio se guardarán bajo `~/.ActaVoz/Notas/`. Si se organizan después, su carpeta completa se moverá bajo `~/.ActaVoz/Directorios/<nombre-del-directorio>/`.
- Cada sesión tendrá una carpeta propia, nombrada con fecha, hora e identificador único corto, por ejemplo `2026-11-20_15-42-09_7K4M2P/`. El título visible se guardará en sus metadatos y podrá cambiar sin depender del nombre de la carpeta.
- El título visible inicial será la fecha y hora de inicio de la nota o reunión. La persona podrá editarlo libremente, por ejemplo añadiendo una descripción al principio.
- Dentro de la carpeta de sesión se guardarán `sesion.json` (metadatos), `transcripcion.json` (texto con marcas de tiempo e interlocutores), `resumen.md` y, si se conserva, `audio.m4a`. El análisis u otros resultados se añadirán cuando se generen.

## Usuarios y contextos

- Personas que participan en reuniones y quieren consultar lo hablado sin dejar de atender a la conversación.
- Personas que hablan o piensan en voz alta y quieren conservar y sintetizar sus reflexiones.

## Objetivo inicial

Definir una primera versión de escritorio que permita iniciar una sesión, capturar audio, hacer preguntas durante la captura y obtener una transcripción y una síntesis al terminar. La API REST se contempla como una segunda fase y un producto independiente.

## Decisiones tomadas

- El proyecto se llama **ActaVoz**.
- Debe servir tanto para reuniones como para reflexiones individuales.
- La consulta en directo debe poder convivir con la captura de audio.
- Cada pregunta en directo enviará al LLM la transcripción completa acumulada hasta el momento de la pregunta.
- En Ajustes habrá tres políticas para el audio al terminar el procesamiento: preguntar en cada sesión, guardar siempre o borrar siempre. La opción inicial será guardar siempre.
- Las notas, transcripciones, resúmenes y demás resultados se conservarán hasta que la persona los elimine manualmente; esta regla es independiente de la política del audio.
- La biblioteca permitirá crear directorios en una barra lateral izquierda y mostrar el contenido del directorio seleccionado en el panel central, incluyendo audios y resultados de las sesiones.
- Borrar una sesión será definitivo: tras confirmación, se eliminarán su audio guardado y todos sus resultados.
- Un botón persistente en la zona inferior derecha iniciará una nota nueva; las notas nuevas quedarán sin carpeta hasta que la persona decida organizarlas.
- La app de escritorio se desarrollará en Swift para macOS, con SwiftUI para la interfaz.
- La captura incluirá tanto el audio del sistema como el micrófono y mantendrá sus fuentes separadas y sincronizadas.
- La transcripción y la diarización se tratarán como componentes de modelos independientes de la captura; SpeechAnalyzer y FluidAudio/Core ML son candidatos iniciales, pendientes de validación.
- Los idiomas iniciales de transcripción serán español e inglés. El idioma se elegirá por sesión, con español por defecto y detección automática entre ambos como opción.
- El audio se procesará, transcribirá e identificará localmente; a los LLM se enviará texto de la transcripción para preguntas, resúmenes y análisis, no el audio.
- Cada pregunta en directo enviará la transcripción completa acumulada hasta ese momento. Si supera el límite del modelo, ActaVoz mostrará un error con el máximo aceptado, el tamaño requerido y el exceso, sin truncar silenciosamente. Se espera que esto sea excepcional.
- Los modelos de lenguaje para preguntas y análisis serán configurables desde Ajustes, con una arquitectura ampliable a proveedores locales y remotos.
- No habrá un proveedor LLM preconfigurado: el primer inicio preguntará cuál quiere conectar la persona.
- El catálogo inicial ofrecerá OpenAI/ChatGPT por API key u OAuth, Anthropic/Claude por API key, OpenCode Go por API key, Ollama para modelos locales y un proveedor genérico configurable con URL, token e identificador de modelo.
- Las API keys se guardarán localmente en el Llavero de macOS tras introducirlas una vez y se reutilizarán sin pedirlas en cada uso; ChatGPT tendrá la opción adicional de OAuth.
- Los archivos de sesión se guardarán por defecto en la carpeta oculta `~/.ActaVoz`; configuración en Library, credenciales en el Llavero y cachés regenerables en Caches.
- Los directorios creados por la persona se agruparán bajo `~/.ActaVoz/Directorios`.
- En el primer arranque, la app creará `~/.ActaVoz` y las subcarpetas que necesite si aún no existen.
- Se prevé distribuir la app directamente como DMG fuera del Mac App Store y sin App Sandbox para poder crear esa carpeta automáticamente; la app deberá estar firmada y notarizada.
- La identificación de interlocutores puede ser aproximada. El sistema sugerirá nombres solo cuando haya indicios claros y la persona deberá confirmarlos o corregirlos; mientras tanto, se usarán etiquetas neutrales.
- Antes de grabar, la persona podrá elegir si guardar perfiles de voz de los interlocutores de esa sesión para reconocerlos en el futuro.
- El proyecto tendrá una carpeta separada para la API REST, reservada para la segunda fase.
- La aplicación de escritorio es la primera fase y el producto principal.
- La API REST se definirá y desarrollará en la segunda fase.

## Por definir

- Versión mínima de macOS y selección final de frameworks/librerías de transcripción y diarización.
- Detalles de experiencia y autorización para conectar ChatGPT mediante OAuth.
- Qué análisis podrán ejecutarse con modelos locales y qué requisitos de hardware tendrán.
- Política de retención y borrado de las notas y resultados.
- Estructura interna de carpetas y archivos de sesión dentro de `~/.ActaVoz`.
- Idiomas y condiciones de uso en entornos ruidosos o con varias voces.
- Formato y nivel de detalle de las transcripciones y análisis.
- Qué perfiles de voz se guardan y cómo se gestionan o eliminan.
- Alcance concreto de la primera versión y criterios de éxito.
