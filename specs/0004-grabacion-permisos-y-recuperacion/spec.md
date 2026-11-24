# 0004 · Grabación, permisos y recuperación

- **Estado:** build
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Capturar reuniones y reflexiones sin perder el progreso ante interrupciones.

## Comportamiento esperado

La persona prepara las fuentes, concede permisos, graba y puede pausar o recuperar una sesión. Tras detener, se procesa el contenido y se aplica la política de audio acordada.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Preparación:** Botón Nueva nota abre panel previo con idioma, perfiles, fuentes y Empezar; español y guardar perfiles activados inicialmente. | Abrir panel con configuración inicial y verificar controles y valores. | cumplido (2026-11-23) |
| AC2 | **Permisos:** Antes de primera grabación explicar acceso a micrófono y audio del sistema y solicitar permisos de macOS. | En usuario de prueba sin permisos ejecutar el flujo y observar explicación y solicitudes. | parcial: explicación y solicitud lanzadas; el diálogo del sistema no se confirmó |
| AC3 | **Fuentes:** Micrófono y sistema activados por defecto, con elección de micrófono y posibilidad de desactivar cualquiera para la sesión; mantener fuentes separadas y sincronizadas durante el procesamiento. | Capturar señales distintas y verificables de ambas fuentes y comparar tiempos. | sin verificar: requiere captura real |
| AC4 | **Inicio degradado:** Si una fuente falta, indicar cuál y permitir iniciar con otra disponible; sin ninguna fuente no iniciar captura. | Desconectar fuentes sucesivamente y comprobar advertencia e inicio. | cumplido (2026-11-23) |
| AC5 | **Controles:** Mostrar abajo estado, tiempo, pausa y parada; pausar no captura audio y detiene contador; reanudar continúa en misma sesión. | Grabar, pausar y reanudar con señal controlada; verificar tiempo y ausencia de audio durante pausa. | parcial: probado con dobles; falta audio real |
| AC6 | **Interrupciones:** Si falla una fuente avisar y continuar con la otra; al volver recuperarla. Si se pierden ambas, pausar y permitir reanudar cuando vuelva alguna. | Simular pérdida y recuperación de una y ambas fuentes y observar estados. | cumplido con dobles (2026-11-23) |
| AC7 | **Recuperación:** Tras cierre inesperado conservar lo capturado y transcrito disponible; al reabrir ofrecer reanudar o terminar sesión. | Interrumpir proceso de prueba tras grabar, reabrir y probar ambas opciones en copias. | cumplido (2026-11-23): kill -9 real, aviso automático, reanudar con audio y terminar sin borrar |
| AC8 | **Finalización:** Tras detener mostrar Procesando la reunión con progreso; al terminar mostrar Generar resumen. | Finalizar grabación y observar secuencia hasta disponibilidad del botón. | cumplido (2026-11-24): Procesada y botón tras 105,7 s de audio |
| AC9 | **Audio:** Aplicar tras procesar política guardar siempre por defecto, borrar siempre o preguntar cada sesión; el aviso solo aparece en preguntar y no borra textos. | Repetir con cada política en datos temporales; inspeccionar audio y textos. | cumplido con dobles (2026-11-23) |
| AC10 | **Captura sin internet:** grabar y conservar audio local sin conexión a internet. | Preparar el entorno, desconectar internet y grabar señales controladas; comprobar los archivos locales. | sin verificar |
| AC11 | **Audio final:** cuando se conserve, guardar un único archivo combinado para reproducción, con las fuentes separadas durante el procesamiento. | Capturar señales distinguibles de ambas fuentes, conservar el audio y comprobar el archivo combinado y su reproducción. | parcial: combinador implementado; falta señal real |
| AC12 | **Cierre durante grabación:** al intentar cerrar ActaVoz mientras graba, mostrar un aviso para continuar grabando o detener la sesión y cerrar. | Iniciar grabación, intentar cerrar y probar cada opción en sesiones de prueba; comprobar continuidad o parada y cierre. | implementado; falta comprobarlo con clic real |
| AC13 | **Aviso de audio sin respuesta:** al cerrar sin responder, conservar el audio pendiente y volver a preguntar al abrir la sesión. | Con la política de preguntar, cerrar sin responder, reabrir la sesión y comprobar que el audio existe y se vuelve a mostrar la pregunta. | cumplido (2026-11-24): repregunta al abrir; guardar combinó 3 s y borrar limpió marcador y CAF |
| AC14 | **Permiso denegado:** explicar qué fuente no está disponible, ofrecer abrir Ajustes del Sistema y permitir grabar con la otra si tiene permiso. | Denegar cada permiso en un entorno de prueba, comprobar el mensaje y acceso a Ajustes, y grabar con la fuente autorizada. | parcial: mensajes y acceso implementados; falta grabar con la otra fuente |

## Decisiones previas a aprobación

- Validar en 0012 cómo detectar las denegaciones y acceder a los ajustes correspondientes en las versiones de macOS compatibles.

## Fuera de alcance

- La transcripción y diarización pertenecen a 0005; distribución y firma a 0011.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** La recuperación tras apagado depende de persistencia efectiva; el comportamiento ante fallo de escritura debe precisarse en diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La captura del sistema, detección de permisos, cambios de dispositivo y apagados requieren evidencia en 0012.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
