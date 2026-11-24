# 0005 · Transcripción local y participantes

- **Estado:** done
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Transcribir en tiempo real y distinguir interlocutores sin enviar audio a proveedores de lenguaje.

## Comportamiento esperado

La transcripción local distingue turnos y propone nombres con indicios claros. Permite corregir nombres, reasignar una intervención y fusionar interlocutores. El micrófono se etiqueta como «Yo» por defecto, con opción de desactivarlo. Los perfiles confirmados pueden ayudar a reconocer voces en sesiones posteriores, conservando los datos temporales según AC10–AC11.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Transcripción:** Procesar audio localmente y mostrar transcripción en directo en panel inferior izquierdo; cerrar al pulsar control de nuevo o fuera. | Reproducir audio controlado y observar texto parcial y apertura/cierre. | cumplido: panel con texto parcial, cierre X y toque fuera implementado |
| AC2 | **Idiomas:** Ofrecer español, inglés y detección automática entre ambos por sesión; español inicial. | Abrir panel previo y comprobar opciones; ejecutar audios de prueba de ambos idiomas. | cumplido: opciones ES/EN/automático y pruebas reales |
| AC3 | **Interlocutores:** Identificar turnos localmente, mostrar nombre o etiqueta neutral, sugerir nombres con indicios claros y solicitar confirmación o corrección. | Usar grabación de varias voces con y sin nombres; comprobar etiquetas y confirmación. | cumplido: etiquetas, sugerencias Ana/Luis y confirmación observadas en UI |
| AC4 | **Corrección:** Cambiar nombre desde una intervención y aplicar a todas las atribuidas a ese interlocutor; guardar corrección con la sesión. | Corregir nombre y reabrir sesión; comprobar todas sus intervenciones. | cumplido: renombrar persiste y aplica a todas las intervenciones |
| AC5 | **Perfiles:** Con guardar perfiles activado, guardar solo voces con nombre confirmado al finalizar procesamiento o tras una confirmación posterior si el perfil está disponible. | Probar voces confirmadas y sin confirmar antes y después de finalizar y revisar perfiles. | cumplido: solo se guardan perfiles confirmados |
| AC6 | **Gestión de perfiles:** En Ajustes consultar, renombrar y eliminar perfiles. | Crear perfiles ficticios y ejecutar las tres operaciones. | cumplido: consultar, renombrar y eliminar en Ajustes |
| AC7 | **Privacidad local:** Audio y procesamiento de voz permanecen en el Mac; solo texto puede llegar al LLM. | Inspeccionar tráfico de red en prueba controlada y verificar ausencia de audio. | cumplido: 116 pruebas con red denegada y lsof sin conexiones de ActaVoz |
| AC8 | **Reconocimiento posterior:** un perfil guardado se utiliza para proponer el mismo interlocutor en una reunión posterior cuando haya evidencia suficiente; las coincidencias inciertas no se dan por confirmadas. | Crear perfil con audio controlado, procesar otra sesión con la misma voz y otra distinta, comprobar propuesta y tratamiento de incertidumbre. | cumplido: propuesta por similitud sin confirmar automáticamente |
| AC9 | **Procesamiento sin internet:** transcribir y distinguir interlocutores sin conexión con los recursos locales previamente disponibles. | Preparar los recursos, desconectar internet y procesar grabaciones de prueba en los idiomas admitidos. | cumplido: ASR y suite completa con red saliente denegada |
| AC10 | **Confirmación tardía sin audio:** si se activó guardar perfiles, conservar temporalmente los datos de voz necesarios para poder crear el perfil tras confirmar un nombre, incluso si se borró el audio. | Procesar una sesión de prueba con perfiles activados, borrar el audio, confirmar después un interlocutor y comprobar la creación de su perfil. | cumplido: confirmación tardía crea perfil sin audio |
| AC11 | **Retención temporal de voz:** conservar los datos temporales de cada interlocutor hasta confirmar su nombre o eliminar la sesión. | Con dos interlocutores de prueba, confirmar uno y verificar el tratamiento de sus datos; borrar la sesión y comprobar que se eliminan los temporales restantes. | cumplido: temporales por interlocutor y purga al confirmar o borrar |
| AC12 | **Reasignación individual:** permitir asignar una intervención concreta a otro interlocutor sin modificar las demás. | Reasignar una intervención de prueba y comprobar que solo cambia su atribución; reabrir la sesión y verificar la corrección. | cumplido: reasignación individual persistida |
| AC13 | **Fusión de interlocutores:** permitir fusionar dos interlocutores para agrupar sus intervenciones bajo un mismo nombre. | Fusionar dos interlocutores de prueba, comprobar sus intervenciones y reabrir la sesión para verificar el resultado. | cumplido: fusión persistida |
| AC14 | **Identidad del usuario:** por defecto etiquetar como «Yo» las intervenciones captadas por el micrófono; permitir desactivar el etiquetado automático en Ajustes y corregir atribuciones. | Con ajustes iniciales, capturar una intervención de prueba y verificar «Yo» y su corrección; desactivar el ajuste y comprobar que no se asigna automáticamente. | cumplido: «Yo» configurable y prueba de etiquetado |
| AC15 | **Deducción de nombres:** intentar proponer nombres localmente a partir de pistas claras en la transcripción; el modelo principal configurado también podrá ayudar. La persona confirma o corrige las propuestas. | Usar transcripciones de prueba con y sin pistas claras; comprobar propuestas locales, asistencia del modelo principal simulado y confirmación o corrección. | cumplido: sugerencias locales con pistas explícitas; modelo principal opcional no probado |

## Decisiones previas a aprobación

- Validar la viabilidad de las vías local y asistida en la investigación 0012 y coordinar el uso del modelo principal con 0006.

## Fuera de alcance

- No se incorporan funciones de voz ajenas a la transcripción e identificación de interlocutores previstas para esta fase.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Validado en 0012:** SpeechAnalyzer transcribe ES/EN y FluidAudio Offline VBx separa hablantes; la app usa FluidAudio 0.18.4.
- **Confirmado:** las correcciones individuales están acordadas en AC12.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Idiomas, disponibilidad local, modelos descargados, solapamientos y reconocimiento entre sesiones requieren pruebas de 0012. El perfil tardío tras borrar audio está acordado en AC10–AC11, pero necesita validación técnica.
- La identificación por fuente puede atribuir al usuario voces de otras personas captadas por el micrófono; se puede desactivar y corregir.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
