# ActaVoz — contexto para continuar

## Estado actual

El proyecto está en documentación y descubrimiento de la primera versión de escritorio para macOS. No se ha iniciado la implementación. Las specs de producto 0002–0011 están en estado `spec` y aprobación pendiente; las investigaciones 0012 y 0013 están en `discovery`. El índice y dependencias están en [specs/README.md](specs/README.md).

## Fuentes y alcance

- [Definición del proyecto](DEFINICION_PROYECTO.md): visión y acuerdos de producto vigentes.
- [Lista de documentación](PENDIENTES_DOCUMENTACION.md): decisiones pendientes y acuerdos históricos con casillas.
- [Especificaciones](specs/README.md): requisitos verificables por capacidad y estado de aprobación; los borradores no prevalecen sobre acuerdos explícitos más recientes.
- `docs/`: convenciones SDD, resumen de producto y arquitectura; la arquitectura definitiva se decidirá tras aprobación de las specs.
- [Ejemplos de plantillas](EJEMPLOS_PLANTILLAS.md): ejemplos ficticios aceptados.

ActaVoz captura micrófono y audio del sistema, procesa voz localmente, permite preguntas con transcripción completa y ofrece biblioteca, notas, resumen, plantillas y proveedores configurables. Los detalles y excepciones están en la definición y las specs. La API REST, adjuntos, calendario y control de costes están fuera de la fase actual.

Las fuentes se mantienen separadas durante el procesamiento; si se conserva el audio final, se guardará un único archivo combinado para su reproducción.

Al intentar cerrar ActaVoz durante una grabación, aparecerá un aviso para continuar grabando o detener la sesión y cerrar.

Ante un permiso de audio denegado, ActaVoz explicará qué fuente no está disponible, ofrecerá abrir Ajustes del Sistema y permitirá grabar con la otra si tiene permiso. La detección concreta requiere validación técnica.

Si se cierra sin responder al aviso de conservación de audio, el audio quedará pendiente de decisión y se volverá a preguntar al abrir la sesión.

Si guardar perfiles estaba activado, se conservarán los datos de voz temporales de cada interlocutor hasta confirmar su nombre o eliminar la sesión, incluso si se borra el audio.

Se podrá reasignar una intervención concreta a otro interlocutor sin modificar las demás; sigue disponible la corrección del nombre para todas las intervenciones de un interlocutor en la sesión.

Se podrán fusionar dos interlocutores que correspondan a la misma persona para agrupar sus intervenciones bajo un mismo nombre.

La identificación del usuario local se podrá configurar en Ajustes. Por defecto, las intervenciones captadas por el micrófono se etiquetarán como «Yo», con posibilidad de corregir atribuciones; se podrá desactivar el etiquetado automático y tratar esas voces como las demás.

ActaVoz intentará deducir nombres localmente a partir de pistas claras de la transcripción; el modelo principal configurado también podrá ayudar. La persona confirmará o corregirá las propuestas. Ambas vías requieren validación.

Se podrá omitir la configuración inicial del proveedor y usar las funciones locales. Al intentar utilizar una función que lo requiera, se ofrecerá configurar un proveedor.

Si un proveedor rechaza una solicitud, ActaVoz mostrará un error comprensible y permitirá reintentar o cambiar de modelo; se conservarán la transcripción y los contenidos guardados.

La barra lateral tendrá una opción fija «Sin organizar» para acceder a las notas sin directorio asignado.

La biblioteca permitirá buscar sesiones por título y por el texto de la transcripción, las notas o el resumen.

La transcripción, el resumen y las notas se podrán exportar como Markdown o texto plano.

Los análisis y listas de tareas se obtendrán mediante plantillas o el chat, sin archivos independientes de análisis; el resumen es el resultado principal.

La transcripción exportada incluirá el nombre o etiqueta del interlocutor y la marca de tiempo de cada intervención.

Al exportar «Mis notas», si existe síntesis, se podrá elegir si incluirla claramente diferenciada o exportar solo las notas.

El audio conservado tendrá controles de reproducir y pausar, con una barra para avanzar o retroceder y ver el tiempo.

El historial del chat se guardará con la sesión. Cada consulta utilizará la transcripción completa disponible y los turnos previos del chat.

En la carpeta de cada sesión, las notas se guardarán en `notas.md`, la síntesis en `sintesis.md` y el historial de chat en `chat.json`.

Si se solicita la síntesis sin que exista el resumen principal, ActaVoz indicará que primero hay que generarlo.

Antes de regenerar un resumen con ediciones manuales se pedirá confirmación; si no tiene ediciones manuales no se preguntará.

Si falla la regeneración, se conserva intacto el resumen anterior, se muestra el error y se ofrece reintentar; solo se sustituye al terminar correctamente.

Las plantillas propias se podrán eliminar desde Ajustes con confirmación previa.

Las cuatro plantillas predefinidas se conservarán sin modificar y se podrán duplicar para crear versiones propias editables.

La síntesis se podrá editar; al actualizarla, la nueva sustituirá a la anterior, incluidas sus ediciones manuales.

Para la síntesis se usará el modelo de resúmenes o, si no hay uno específico, el modelo principal.

Las preguntas enviadas mientras se genera una respuesta quedarán en espera y se enviarán al terminar la anterior, manteniendo el orden.

«Nueva nota» siempre abre el flujo de grabación; no se contempla crear una nota exclusivamente de texto mediante ese botón.

## Auditoría y siguiente paso

La auditoría detectó dependencias circulares, contradicciones, decisiones sin cerrar y falta de investigación técnica. Se reorganizó la base 0002, se anotaron las decisiones abiertas en la lista y se crearon dos investigaciones: [voz local](specs/0012-viabilidad-captura-transcripcion-y-voz-local/discovery.md) y [proveedores](specs/0013-viabilidad-proveedores-contexto-y-oauth/discovery.md). Sus experimentos no se han ejecutado. El resultado debe revisarlo el auditor y las decisiones materiales deben resolverse antes de aprobar las specs afectadas.

## Forma de avanzar

Presentar opciones concretas con recomendación; tras acordar una decisión, documentarla, marcar su casilla existente y presentar la siguiente. Preparar por adelantado los puntos sin marcar y no añadir casillas ya marcadas para aparentar progreso. Mantener esta dinámica hasta indicación contraria. No comenzar diseño de una spec sin su aprobación explícita ni iniciar implementación durante discovery.
