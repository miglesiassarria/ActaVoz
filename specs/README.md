# Especificaciones

Cada cambio sustancial vive en `specs/NNNN-slug/` y sigue el flujo de [docs/sdd.md](../docs/sdd.md).

| # | Título | Estado | Siguiente paso | Notas |
| --- | --- | --- | --- | --- |
| [0001](0001-sistema-sdd/spec.md) | Sistema SDD independiente del modelo | `done` | Revisar mejoras del piloto al usar la primera feature | Instalación inicial verificada |
| [0002](0002-aplicacion-instalacion-y-configuracion-inicial/spec.md) | Aplicación instalación y configuración inicial | `spec` | Completar la spec y obtener aprobación explícita | |
| [0003](0003-biblioteca-y-persistencia-de-sesiones/spec.md) | Biblioteca y persistencia de sesiones | `spec` | Completar la spec y obtener aprobación explícita | |
| [0004](0004-grabacion-permisos-y-recuperacion/spec.md) | Grabación permisos y recuperación | `spec` | Completar la spec y obtener aprobación explícita | |
| [0005](0005-transcripcion-local-y-participantes/spec.md) | Transcripción local y participantes | `spec` | Completar la spec y obtener aprobación explícita | |
| [0006](0006-proveedores-modelos-y-credenciales/spec.md) | Proveedores modelos y credenciales | `spec` | Completar la spec y obtener aprobación explícita | |
| [0007](0007-chat-de-sesion-y-consultas/spec.md) | Chat de sesión y consultas | `spec` | Completar la spec y obtener aprobación explícita | |
| [0008](0008-resumenes-y-plantillas/spec.md) | Resúmenes y plantillas | `spec` | Completar la spec y obtener aprobación explícita | |
| [0009](0009-notas-personales-y-sintesis/spec.md) | Notas personales y síntesis | `spec` | Completar la spec y obtener aprobación explícita | |
| [0010](0010-exportacion-y-reproduccion/spec.md) | Exportación y reproducción | `spec` | Completar la spec y obtener aprobación explícita | |
| [0011](0011-calidad-y-entrega-estable/spec.md) | Calidad y entrega estable | `spec` | Completar la spec y obtener aprobación explícita | |
<!-- spec-driven-development:index-end -->

## Mapa de la primera versión

Las unidades 0002–0011 son propuestas en `spec`, pendientes de aprobación explícita. Los criterios incluyen métodos de verificación futuros, no resultados observados. El orden siguiente expresa dependencias de capacidades, no autoriza el diseño ni la implementación:

1. **0002 y 0003:** aplicación, instalación, configuración inicial y persistencia de sesiones.
2. **0004 y 0005:** captura y recuperación; transcripción local, atribuciones y perfiles. La integración de ambos componentes y su disponibilidad sin red necesitan validación.
3. **0006:** conexiones de proveedores y modelos; el OAuth de ChatGPT queda sujeto a verificación de compatibilidad.
4. **0007, 0008 y 0009:** chat, resúmenes y plantillas, notas y síntesis; dependen de sesiones, transcripción y proveedor configurado.
5. **0010:** reproducción y exportación de contenidos conservados; los formatos concretos aún no están decididos.
6. **0011:** evaluación conjunta y entrega estable; los umbrales se decidirán con evidencia de grabaciones, en ambos idiomas.

Antes de aprobar cada unidad deben resolverse los desconocidos materiales de su alcance, usando `discovery` cuando corresponda. La aprobación de una spec permite pasar a su diseño; después se preparan tareas y evidencias antes de construir. La API REST permanece en fase posterior.

## Reglas

- El estado de la tabla y el de `spec.md` deben coincidir.
- No pasar de `spec` a `design` sin **Aprobación: aprobada**.
- `done` requiere evidencia por tarea, criterios comprobados y verificación completa.
- Crear una unidad con `python3 scripts/new-spec.py "Título"` o añadir `--state discovery`.
