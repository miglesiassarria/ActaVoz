# 0005 · Transcripción local y participantes

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Transcribir en tiempo real y distinguir interlocutores sin enviar audio a proveedores de lenguaje.

## Comportamiento esperado

La transcripción local distingue turnos, propone nombres con indicios claros y permite corregirlos. Los perfiles confirmados pueden ayudar a reconocer voces en sesiones posteriores.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Transcripción:** Procesar audio localmente y mostrar transcripción en directo en panel inferior izquierdo; cerrar al pulsar control de nuevo o fuera. | Reproducir audio controlado y observar texto parcial y apertura/cierre. | pendiente |
| AC2 | **Idiomas:** Ofrecer español, inglés y detección automática entre ambos por sesión; español inicial. | Abrir panel previo y comprobar opciones; ejecutar audios de prueba de ambos idiomas. | pendiente |
| AC3 | **Interlocutores:** Identificar turnos localmente, mostrar nombre o etiqueta neutral, sugerir nombres con indicios claros y solicitar confirmación o corrección. | Usar grabación de varias voces con y sin nombres; comprobar etiquetas y confirmación. | pendiente |
| AC4 | **Corrección:** Cambiar nombre desde una intervención y aplicar a todas las atribuidas a ese interlocutor; guardar corrección con la sesión. | Corregir nombre y reabrir sesión; comprobar todas sus intervenciones. | pendiente |
| AC5 | **Perfiles:** Con guardar perfiles activado, guardar solo voces con nombre confirmado al finalizar procesamiento o tras una confirmación posterior si el perfil está disponible. | Probar voces confirmadas y sin confirmar antes y después de finalizar y revisar perfiles. | pendiente |
| AC6 | **Gestión de perfiles:** En Ajustes consultar, renombrar y eliminar perfiles. | Crear perfiles ficticios y ejecutar las tres operaciones. | pendiente |
| AC7 | **Privacidad local:** Audio y procesamiento de voz permanecen en el Mac; solo texto puede llegar al LLM. | Inspeccionar tráfico de red en prueba controlada y verificar ausencia de audio. | pendiente |
| AC8 | **Reconocimiento posterior:** un perfil guardado se utiliza para proponer el mismo interlocutor en una reunión posterior cuando haya evidencia suficiente; las coincidencias inciertas no se dan por confirmadas. | Crear perfil con audio controlado, procesar otra sesión con la misma voz y otra distinta, comprobar propuesta y tratamiento de incertidumbre. | pendiente |
| AC9 | **Procesamiento sin internet:** transcribir y distinguir interlocutores sin conexión con los recursos locales previamente disponibles. | Preparar los recursos, desconectar internet y procesar grabaciones de prueba en los idiomas admitidos. | pendiente |

## Decisiones previas a aprobación

- Decidir identidad del usuario local, fusión de interlocutores, reasignación individual y perfiles tardíos tras borrar audio. Consultar las casillas correspondientes en `PENDIENTES_DOCUMENTACION.md`.
- Decidir si la deducción de nombres utiliza un LLM y, en ese caso, qué modelo se asigna; coordinar con 0006 y la investigación 0012.

## Fuera de alcance

- No incluye funciones aún no aprobadas de identificación del usuario, fusión o reasignación.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** SpeechAnalyzer y FluidAudio/Core ML son candidatos, no dependencias validadas; precisión, idiomas, solapamiento y perfiles posteriores requieren experimentos; correcciones de atribución errónea por intervención no especificadas.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Idiomas, disponibilidad local, modelos descargados, solapamientos y reconocimiento entre sesiones requieren pruebas de 0012. El perfil tardío tras borrar audio sigue sin decidir.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
