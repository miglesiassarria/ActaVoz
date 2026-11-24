# Especificaciones

Cada cambio sustancial vive en `specs/NNNN-slug/` y sigue el flujo de [docs/sdd.md](../docs/sdd.md).

| # | Título | Estado | Siguiente paso | Notas |
| --- | --- | --- | --- | --- |
| [0001](0001-sistema-sdd/spec.md) | Sistema SDD independiente del modelo | `done` | Revisar mejoras del piloto al usar la primera feature | Instalación inicial verificada |
| [0002](0002-aplicacion-instalacion-y-configuracion-inicial/spec.md) | Base de aplicación y configuración inicial | `done` | Mantener | Cerrada el 2026-11-23; macOS 26 no probado por falta de equipo |
| [0003](0003-biblioteca-y-persistencia-de-sesiones/spec.md) | Biblioteca y persistencia de sesiones | `done` | Mantener | Cerrada el 2026-11-23 con pruebas y capturas en `docs/evidencia/0003` |
| [0004](0004-grabacion-permisos-y-recuperacion/spec.md) | Grabación permisos y recuperación | `done` | — | 89 pruebas; captura dual, sincronización 51 ms, cierre, TCC y recuperación de fuente verificados |
| [0005](0005-transcripcion-local-y-participantes/spec.md) | Transcripción local y participantes | `done` | — | Transcripción, diarización, perfiles y correcciones; 116 pruebas |
| [0006](0006-proveedores-modelos-y-credenciales/spec.md) | Proveedores modelos y credenciales | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0007](0007-chat-de-sesion-y-consultas/spec.md) | Chat de sesión y consultas | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0008](0008-resumenes-y-plantillas/spec.md) | Resúmenes y plantillas | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0009](0009-notas-personales-y-sintesis/spec.md) | Notas personales y síntesis | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0010](0010-exportacion-y-reproduccion/spec.md) | Exportación y reproducción | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0011](0011-calidad-y-entrega-estable/spec.md) | Calidad y entrega estable | `design` | Revisar diseño y resolver dependencias antes de build | Diseño y tareas propuestos |
| [0012](0012-viabilidad-captura-transcripcion-y-voz-local/spec.md) | Viabilidad captura transcripción y voz local | `superseded` | — | Evidencia completa de captura, ASR, diarización y perfiles; límites de idioma/nombres pasan a 0005 |
| [0013](0013-viabilidad-proveedores-contexto-y-oauth/spec.md) | Viabilidad proveedores contexto y OAuth | `superseded` | — | OAuth no disponible para terceros; 0006 usa claves, Ollama y genérico |
<!-- spec-driven-development:index-end -->

## Mapa de la primera versión

La [guía de entrega a agentes](../docs/entrega-agentes.md) reúne el orden de ejecución, las dependencias, los contratos transversales y las condiciones de verificación.

Las unidades 0002–0011 fueron aprobadas por la persona usuaria el 2026-11-22. Los diseños deben resolver las dependencias técnicas aplicables. La unidad 0012 quedó `superseded` con evidencia de captura, transcripción y diarización; 0013 quedó `superseded` al comprobar que OAuth de terceros no está disponible y que los proveedores por clave son viables. Los criterios de las specs incluyen métodos de verificación futuros, no resultados observados. El orden siguiente expresa dependencias de capacidades, no autoriza el diseño ni la implementación:

1. **0012 → 0002 → 0003:** investigar primero la versión mínima y el acceso a la carpeta del usuario; después refinar la base de aplicación y la persistencia. 0003 se verifica aisladamente con datos y puntos de entrada de prueba; las integraciones completas se comprueban en sus propias unidades. La conexión efectiva de proveedores pertenece a 0006.
2. **0012 → 0004 y 0005:** investigar primero captura y voz local; después refinar las specs de captura, transcripción, atribuciones y perfiles con la evidencia.
3. **0013 → 0006:** investigar protocolos, contexto y OAuth; después refinar la spec de conexiones y modelos.
4. **0007, 0008 y 0009:** chat, resúmenes y plantillas, notas y síntesis; dependen de sesiones, transcripción y proveedor configurado.
5. **0010:** reproducción del audio conservado y exportación en Markdown o texto plano, con interlocutores y tiempos en la transcripción y síntesis opcional al exportar notas.
6. **0011:** evaluación conjunta y entrega estable; los umbrales se decidirán con evidencia de grabaciones, en ambos idiomas.

La persona usuaria ha aprobado las specs de producto. Sus incógnitas técnicas materiales deben resolverse mediante `discovery` al elaborar los diseños afectados; si la evidencia obliga a cambiar el comportamiento aprobado, se volverá a la spec. Después se preparan tareas y evidencias antes de construir. La API REST permanece en fase posterior.

## Referencias de documentación

`DEFINICION_PROYECTO.md` recoge los acuerdos de producto vigentes; `PENDIENTES_DOCUMENTACION.md` registra decisiones abiertas; cada `spec.md` concreta los criterios de su capacidad y su aprobación. Si se contradicen, no elegir silenciosamente: identificar el acuerdo más reciente, corregir los documentos afectados y volver a aprobación si cambia materialmente la spec. `docs/` contiene el protocolo y resúmenes de producto y arquitectura; no introduce decisiones por su cuenta.

## Reglas

- El estado de la tabla y el de `spec.md` deben coincidir.
- No pasar de `spec` a `design` sin **Aprobación: aprobada**.
- `done` requiere evidencia por tarea, criterios comprobados y verificación completa.
- Crear una unidad con `python3 scripts/new-spec.py "Título"` o añadir `--state discovery`.
