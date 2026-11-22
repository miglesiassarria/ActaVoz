# 0002 · Base de aplicación y configuración inicial

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Una persona necesita abrir ActaVoz y preparar su entorno local.

## Comportamiento esperado

La aplicación abre una ventana en macOS, prepara sus carpetas sin sobrescribir datos e informa de la configuración inicial. La conexión real de proveedores pertenece a 0006; el comportamiento si se omite sigue pendiente.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Base de aplicación:** app macOS Swift/SwiftUI ejecutable localmente y capaz de abrir su ventana principal. | Compilar el proyecto real y abrirlo en un Mac de prueba. | pendiente |
| AC2 | **Primer arranque:** Crear si faltan ~/.ActaVoz y las subcarpetas necesarias, incluidas Notas y Directorios; no destruir datos existentes. | Con un usuario de prueba abrir dos veces, verificar carpetas y conservar un archivo centinela. | pendiente |
| AC3 | **Ubicación:** la configuración básica se guarda en Library y las cachés regenerables en Caches. | Modificar configuración, reiniciar e inspeccionar ubicaciones con datos de prueba. | pendiente |
| AC4 | **Primer inicio:** identificar que no hay proveedor activo y ofrecer acceso a su configuración. La selección, credenciales y prueba de conexión pertenecen a 0006. | Con perfil limpio comprobar que se informa de la ausencia y se ofrece el acceso a configuración sin depender de integraciones reales. | pendiente |


## Decisiones previas a aprobación

- Resolver si se puede omitir la configuración inicial del proveedor y utilizar funciones locales; consultar la lista de pendientes.
- Completar la investigación 0012 sobre versión mínima y acceso a la carpeta del usuario antes de fijar el objetivo de plataforma.

## Fuera de alcance

- Instalación en DMG, firma y notarización se verifican en 0011; grabación y capacidades sin conexión se verifican en sus unidades y en la prueba integral.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Versión mínima de macOS y acceso al directorio del usuario pendientes de validar en 0012.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La versión mínima de macOS y el acceso a la carpeta del usuario deben validarse en 0012; el arranque no debe borrar datos existentes.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
