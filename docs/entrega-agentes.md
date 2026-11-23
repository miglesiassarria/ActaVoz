# Entrega a agentes de desarrollo

## Estado y regla de ejecución

Las specs 0002–0011 cuentan con aprobación de producto, diseño y tareas propuestos. Permanecen en `design`; ninguna tarea ni criterio ha sido verificado como implementación. El proyecto Swift existe para 0002; las rutas de las demás unidades siguen siendo propuestas. Antes de comenzar una unidad, revisar su spec, diseño, tareas y dependencias, resolver los contratos que use y pasar por la fase `tasks` según `docs/sdd.md`. Si la evidencia obliga a cambiar comportamiento aprobado, volver a `spec`.

No ejecutar simultáneamente agentes que editen las mismas superficies o contratos sin coordinación. Usar datos ficticios y directorios temporales. Mantener la API REST, calendario, adjuntos y control de costes fuera de esta fase.

## Orden y condiciones de entrega

| Unidad | Entrada para el agente | Condición para construir o cerrar |
| --- | --- | --- |
| 0002 Aplicación base | `spec.md`, `design.md`, `tasks.md`; aprobación registrada; macOS 26/Apple Silicon objetivo | El proyecto se prepara y ejecuta con el SDK disponible en Apple Silicon. No hay equipo con macOS 26 (2026-11-23): el despliegue apunta a 26.0 y el límite se registra en la evidencia, sin declararlo validado. El acceso a carpetas en la cuenta actual está explorado; no equivale a instalación distribuida. |
| 0003 Biblioteca | Unidad 0002 y contratos de persistencia; fixtures y puntos de entrada de prueba | Definir y revisar contrato versionado de sesiones y ADR de persistencia; verificar aislamiento de rutas y E/S. Las integraciones reales se comprueban en sus unidades. |
| 0004 Grabación | 0002/0003 y resultados de 0012 | Validar captura dual, permisos, dispositivos, sincronización y recuperación con audio controlado; no tratar capacidades de frameworks como pruebas del producto. |
| 0005 Voz | 0003/0004, 0006 opcional y 0012 | Validar transcripción local, detección automática, diarización y perfiles con material controlado; resolver contratos y datos temporales según la spec. |
| 0006 Proveedores | 0002 y 0013 | Resolver protocolos y ensayar autenticación, Llavero, streaming y contexto largo; OAuth solo si se demuestra un mecanismo autorizado. |
| 0007 Chat | 0003/0005/0006 | Definir la instantánea de transcripción al enviar cada pregunta y el tratamiento ordenado de la cola; validar con proveedor doble y posteriormente integración real. |
| 0008 Resúmenes | 0003/0005/0006 | Definir persistencia de plantillas y sustitución segura; validar contexto largo y errores con dobles y proveedor real. |
| 0009 Notas | 0003/0006/0008 | Acordar contratos de guardado y versiones de fuentes; verificar síntesis y reemplazo sin pérdida. |
| 0010 Exportación | 0003/0005/0008/0009 | Contratos de transcripción, notas y síntesis disponibles; verificar los dos formatos y reproducción. |
| 0011 Entrega | 0002–0010 y resultados de 0012/0013 | Corpus autorizado, umbrales acordados a partir de mediciones y prueba de DMG firmado/notarizado en entorno seguro. |

El mapa describe requisitos de integración: un agente puede adelantar pruebas con dobles mientras otras capacidades se investigan, pero no marcar como terminado un criterio que exija la integración real.

## Contratos transversales a cerrar durante diseño

- **Sesión:** identidad estable, fecha de inicio y título editable; archivos `sesion.json`, `transcripcion.json`, `notas.md`, `resumen.md`, `sintesis.md`, `chat.json` y `audio.m4a` cuando correspondan. Precisar esquema versionado con 0003, 0005 y 0007 antes de que varios agentes escriban los mismos archivos.
- **Tiempo y atribución:** las fuentes se mantienen separadas y sincronizadas durante el procesamiento; la transcripción necesita marcas de tiempo y referencias estables a interlocutores corregibles. Precisar unidades, origen del reloj, pausas y recuperación entre 0004 y 0005.
- **Consultas:** cada pregunta utiliza la transcripción completa acumulada en el momento de preguntarla y los turnos anteriores del chat; las preguntas se procesan ordenadamente. Ante rechazo por longitud se intenta procesar toda la transcripción en varias llamadas, con error visible si falla; la equivalencia semántica no está demostrada.
- **Persistencia segura:** definir escrituras y recuperación ante fallo, migraciones, colisiones y validación de rutas. Borrados y reemplazos siguen las confirmaciones acordadas. El audio puede borrarse sin eliminar la transcripción y los datos de voz temporales tienen la retención acordada.
- **Privacidad:** audio y procesamiento de voz locales; secretos en Llavero; no imprimir credenciales o contenido sensible en evidencias. La transcripción puede enviarse al proveedor seleccionado.

## Comprobación de cobertura y cierre

Cada `tasks.md` relaciona tareas con criterios AC; el responsable de cada unidad debe comprobar esa cobertura al comenzar y añadir tareas si falta alguna, sin marcarlas como realizadas. Cada criterio necesita evidencia individual: método reproducible, resultado, fecha y commit. Al terminar: ejecutar las pruebas reales disponibles, `python3 scripts/validate_sdd.py --strict`, `python3 scripts/audit_sdd.py`, revisar el diff y actualizar documentación y ADR. No declarar una spec `done` por pasar únicamente los validadores estructurales.
