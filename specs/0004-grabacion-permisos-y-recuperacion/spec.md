# 0004 · Grabación, permisos y recuperación

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Capturar reuniones y reflexiones sin perder el progreso ante interrupciones.

## Comportamiento esperado

La persona prepara las fuentes, concede permisos, graba y puede pausar o recuperar una sesión. Tras detener, se procesa el contenido y se aplica la política de audio acordada.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Preparación:** Botón Nueva nota abre panel previo con idioma, perfiles, fuentes y Empezar; español y guardar perfiles activados inicialmente. | Abrir panel con configuración inicial y verificar controles y valores. | pendiente |
| AC2 | **Permisos:** Antes de primera grabación explicar acceso a micrófono y audio del sistema y solicitar permisos de macOS. | En usuario de prueba sin permisos ejecutar el flujo y observar explicación y solicitudes. | pendiente |
| AC3 | **Fuentes:** Micrófono y sistema activados por defecto, con elección de micrófono y posibilidad de desactivar cualquiera para la sesión; mantener fuentes separadas y sincronizadas durante el procesamiento. | Capturar señales distintas y verificables de ambas fuentes y comparar tiempos. | pendiente |
| AC4 | **Inicio degradado:** Si una fuente falta, indicar cuál y permitir iniciar con otra disponible; sin ninguna fuente no iniciar captura. | Desconectar fuentes sucesivamente y comprobar advertencia e inicio. | pendiente |
| AC5 | **Controles:** Mostrar abajo estado, tiempo, pausa y parada; pausar no captura audio y detiene contador; reanudar continúa en misma sesión. | Grabar, pausar y reanudar con señal controlada; verificar tiempo y ausencia de audio durante pausa. | pendiente |
| AC6 | **Interrupciones:** Si falla una fuente avisar y continuar con la otra; al volver recuperarla. Si se pierden ambas, pausar y permitir reanudar cuando vuelva alguna. | Simular pérdida y recuperación de una y ambas fuentes y observar estados. | pendiente |
| AC7 | **Recuperación:** Tras cierre inesperado conservar lo capturado y transcrito disponible; al reabrir ofrecer reanudar o terminar sesión. | Interrumpir proceso de prueba tras grabar, reabrir y probar ambas opciones en copias. | pendiente |
| AC8 | **Finalización:** Tras detener mostrar Procesando la reunión con progreso; al terminar mostrar Generar resumen. | Finalizar grabación y observar secuencia hasta disponibilidad del botón. | pendiente |
| AC9 | **Audio:** Aplicar tras procesar política guardar siempre por defecto, borrar siempre o preguntar cada sesión; el aviso solo aparece en preguntar y no borra textos. | Repetir con cada política en datos temporales; inspeccionar audio y textos. | pendiente |
| AC10 | **Captura sin internet:** grabar y conservar audio local sin conexión a internet. | Preparar el entorno, desconectar internet y grabar señales controladas; comprobar los archivos locales. | pendiente |
| AC11 | **Audio final:** cuando se conserve, guardar un único archivo combinado para reproducción, con las fuentes separadas durante el procesamiento. | Capturar señales distinguibles de ambas fuentes, conservar el audio y comprobar el archivo combinado y su reproducción. | pendiente |
| AC12 | **Cierre durante grabación:** al intentar cerrar ActaVoz mientras graba, mostrar un aviso para continuar grabando o detener la sesión y cerrar. | Iniciar grabación, intentar cerrar y probar cada opción en sesiones de prueba; comprobar continuidad o parada y cierre. | pendiente |

## Decisiones previas a aprobación

- Decidir qué ocurre al cerrar sin responder al aviso de audio; tratamiento de permisos denegados y acceso a Ajustes del Sistema. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.

## Fuera de alcance

- La transcripción y diarización pertenecen a 0005; distribución y firma a 0011.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Recuperación tras apagado depende de persistencia efectiva; comportamiento ante fallo de escritura y cierre del aviso de audio debe precisarse en diseño.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La captura del sistema, permisos, cambios de dispositivo y apagados requieren evidencia en 0012; quedan por decidir cierre voluntario, denegación de permisos y cierre del aviso de audio.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
