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

Se podrá omitir la configuración inicial del proveedor y usar las funciones locales. Al intentar utilizar una función que lo requiera, se ofrecerá configurar un proveedor.

La barra lateral tendrá una opción fija «Sin organizar» para acceder a las notas sin directorio asignado.

La biblioteca permitirá buscar sesiones por título y por el texto de la transcripción, las notas o el resumen.

El historial del chat se guardará con la sesión. Cada consulta utilizará la transcripción completa disponible y los turnos previos del chat.

Las preguntas enviadas mientras se genera una respuesta quedarán en espera y se enviarán al terminar la anterior, manteniendo el orden.

«Nueva nota» siempre abre el flujo de grabación; no se contempla crear una nota exclusivamente de texto mediante ese botón.

## Auditoría y siguiente paso

La auditoría detectó dependencias circulares, contradicciones, decisiones sin cerrar y falta de investigación técnica. Se reorganizó la base 0002, se anotaron las decisiones abiertas en la lista y se crearon dos investigaciones: [voz local](specs/0012-viabilidad-captura-transcripcion-y-voz-local/discovery.md) y [proveedores](specs/0013-viabilidad-proveedores-contexto-y-oauth/discovery.md). Sus experimentos no se han ejecutado. El resultado debe revisarlo el auditor y las decisiones materiales deben resolverse antes de aprobar las specs afectadas.

## Forma de avanzar

Presentar opciones concretas con recomendación; tras acordar una decisión, documentarla, marcar su casilla existente y presentar la siguiente. Preparar por adelantado los puntos sin marcar y no añadir casillas ya marcadas para aparentar progreso. Mantener esta dinámica hasta indicación contraria. No comenzar diseño de una spec sin su aprobación explícita ni iniciar implementación durante discovery.
