# 0005 · Transcripción local y participantes

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Transcribir en tiempo real y distinguir interlocutores sin enviar audio a proveedores de lenguaje.

## Comportamiento esperado

La capacidad debe cumplir los criterios observables siguientes. La definición de producto y los acuerdos de la conversación son la fuente de alcance; las decisiones no acordadas se registran como riesgos, no como hechos. Las pruebas usan datos controlados y no registran secretos ni reuniones personales.

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

## Fuera de alcance

- API REST de fase 2, adjuntos en chat, calendario y control de costes.
- Código de producción, diseño y tareas de implementación durante la fase de especificación.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** SpeechAnalyzer y FluidAudio/Core ML son candidatos, no dependencias validadas; precisión, idiomas, solapamiento y perfiles posteriores requieren experimentos; correcciones de atribución errónea por intervención no especificadas.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los componentes propuestos y comportamientos de proveedores requieren validación antes de garantizar el resultado.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
