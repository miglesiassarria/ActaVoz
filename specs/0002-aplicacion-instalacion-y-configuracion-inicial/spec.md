# 0002 · Base de aplicación y configuración inicial

- **Estado:** build
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Una persona necesita abrir ActaVoz y preparar su entorno local.

## Comportamiento esperado

La aplicación abre una ventana en macOS, prepara sus carpetas sin sobrescribir datos y ofrece la configuración inicial. La persona podrá omitirla y continuar con funciones locales. La conexión real de proveedores pertenece a 0006.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Base de aplicación:** app macOS Swift/SwiftUI ejecutable localmente y capaz de abrir su ventana principal. | Compilar el proyecto real y abrirlo en un Mac de prueba. | pendiente |
| AC2 | **Primer arranque:** Crear si faltan ~/.ActaVoz y las subcarpetas necesarias, incluidas Notas y Directorios; no destruir datos existentes. | Con un usuario de prueba abrir dos veces, verificar carpetas y conservar un archivo centinela. | pendiente |
| AC3 | **Ubicación:** la configuración básica se guarda en Library y las cachés regenerables en Caches. | Modificar configuración, reiniciar e inspeccionar ubicaciones con datos de prueba. | pendiente |
| AC4 | **Primer inicio:** identificar que no hay proveedor activo, ofrecer acceso a su configuración y permitir omitirla para acceder a las funciones locales. La selección, credenciales y prueba de conexión pertenecen a 0006. | Con perfil limpio comprobar la oferta de configuración y que se puede omitir y entrar en la aplicación sin proveedor. | pendiente |
| AC5 | **Plataforma objetivo:** macOS 26 o posterior en Apple Silicon. | Comprobar objetivo de compilación y ejecutar en equipo compatible; validar en macOS 26 cuando se disponga del entorno. | pendiente |


## Decisiones previas a aprobación

- Validar macOS 26, Apple Silicon y acceso a la carpeta del usuario mediante la investigación 0012.

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
