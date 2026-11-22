# Especificaciones

Cada cambio sustancial vive en `specs/NNNN-slug/` y sigue el flujo de [docs/sdd.md](../docs/sdd.md).

| # | Título | Estado | Siguiente paso | Notas |
| --- | --- | --- | --- | --- |
| [0001](0001-sistema-sdd/spec.md) | Sistema SDD independiente del modelo | `done` | Revisar mejoras del piloto al usar la primera feature | Instalación inicial verificada |
| [0002](0002-aplicacion-instalacion-y-configuracion-inicial/spec.md) | Base de aplicación y configuración inicial | `spec` | Completar la spec y obtener aprobación explícita | |
| [0003](0003-biblioteca-y-persistencia-de-sesiones/spec.md) | Biblioteca y persistencia de sesiones | `spec` | Completar la spec y obtener aprobación explícita | |
| [0004](0004-grabacion-permisos-y-recuperacion/spec.md) | Grabación permisos y recuperación | `spec` | Completar la spec y obtener aprobación explícita | |
| [0005](0005-transcripcion-local-y-participantes/spec.md) | Transcripción local y participantes | `spec` | Completar la spec y obtener aprobación explícita | |
| [0006](0006-proveedores-modelos-y-credenciales/spec.md) | Proveedores modelos y credenciales | `spec` | Completar la spec y obtener aprobación explícita | |
| [0007](0007-chat-de-sesion-y-consultas/spec.md) | Chat de sesión y consultas | `spec` | Completar la spec y obtener aprobación explícita | |
| [0008](0008-resumenes-y-plantillas/spec.md) | Resúmenes y plantillas | `spec` | Completar la spec y obtener aprobación explícita | |
| [0009](0009-notas-personales-y-sintesis/spec.md) | Notas personales y síntesis | `spec` | Completar la spec y obtener aprobación explícita | |
| [0010](0010-exportacion-y-reproduccion/spec.md) | Exportación y reproducción | `spec` | Completar la spec y obtener aprobación explícita | |
| [0011](0011-calidad-y-entrega-estable/spec.md) | Calidad y entrega estable | `spec` | Completar la spec y obtener aprobación explícita | |
| [0012](0012-viabilidad-captura-transcripcion-y-voz-local/spec.md) | Viabilidad captura transcripción y voz local | `discovery` | Cerrar decisión o crear una spec aprobable | |
| [0013](0013-viabilidad-proveedores-contexto-y-oauth/spec.md) | Viabilidad proveedores contexto y OAuth | `discovery` | Cerrar decisión o crear una spec aprobable | |
<!-- spec-driven-development:index-end -->

## Mapa de la primera versión

Las unidades 0002–0011 son propuestas en `spec`, pendientes de aprobación explícita. Las unidades 0012 y 0013 están en `discovery`: recogen evidencia parcial e hipótesis y experimentos todavía pendientes. Los criterios de las specs incluyen métodos de verificación futuros, no resultados observados. El orden siguiente expresa dependencias de capacidades, no autoriza el diseño ni la implementación:

1. **0012 → 0002 → 0003:** investigar primero la versión mínima y el acceso a la carpeta del usuario; después refinar la base de aplicación y la persistencia. 0003 se verifica aisladamente con datos y puntos de entrada de prueba; las integraciones completas se comprueban en sus propias unidades. La conexión efectiva de proveedores pertenece a 0006.
2. **0012 → 0004 y 0005:** investigar primero captura y voz local; después refinar las specs de captura, transcripción, atribuciones y perfiles con la evidencia.
3. **0013 → 0006:** investigar protocolos, contexto y OAuth; después refinar la spec de conexiones y modelos.
4. **0007, 0008 y 0009:** chat, resúmenes y plantillas, notas y síntesis; dependen de sesiones, transcripción y proveedor configurado.
5. **0010:** reproducción y exportación de contenidos conservados; los formatos concretos aún no están decididos.
6. **0011:** evaluación conjunta y entrega estable; los umbrales se decidirán con evidencia de grabaciones, en ambos idiomas.

Antes de aprobar cada unidad deben resolverse los desconocidos materiales de su alcance, usando `discovery` cuando corresponda. La aprobación de una spec permite pasar a su diseño; después se preparan tareas y evidencias antes de construir. La API REST permanece en fase posterior.

## Referencias de documentación

`DEFINICION_PROYECTO.md` recoge los acuerdos de producto vigentes; `PENDIENTES_DOCUMENTACION.md` registra decisiones abiertas; cada `spec.md` concreta los criterios de su capacidad y su aprobación. Si se contradicen, no elegir silenciosamente: identificar el acuerdo más reciente, corregir los documentos afectados y volver a aprobación si cambia materialmente la spec. `docs/` contiene el protocolo y resúmenes de producto y arquitectura; no introduce decisiones por su cuenta.

## Reglas

- El estado de la tabla y el de `spec.md` deben coincidir.
- No pasar de `spec` a `design` sin **Aprobación: aprobada**.
- `done` requiere evidencia por tarea, criterios comprobados y verificación completa.
- Crear una unidad con `python3 scripts/new-spec.py "Título"` o añadir `--state discovery`.
