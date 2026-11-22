# 0002 · Aplicación, instalación y configuración inicial

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Una persona necesita instalar y abrir ActaVoz y preparar su entorno local.

## Comportamiento esperado

La capacidad debe cumplir los criterios observables siguientes. La definición de producto y los acuerdos de la conversación son la fuente de alcance; las decisiones no acordadas se registran como riesgos, no como hechos. Las pruebas usan datos controlados y no registran secretos ni reuniones personales.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Distribución:** La primera versión es una app macOS Swift/SwiftUI distribuida en DMG para arrastrar a Aplicaciones, firmada y notarizada. | En un Mac de prueba instalar el DMG, abrir la app y comprobar firma y notarización. | pendiente |
| AC2 | **Primer arranque:** Crear si faltan ~/.ActaVoz y las subcarpetas necesarias, incluidas Notas y Directorios; no destruir datos existentes. | Con un usuario de prueba abrir dos veces, verificar carpetas y conservar un archivo centinela. | pendiente |
| AC3 | **Ubicación:** Configuración en Library, secretos en Llavero y cachés regenerables en Caches. | Modificar configuración con credencial ficticia e inspeccionar ubicaciones sin imprimir el secreto. | pendiente |
| AC4 | **Configuración inicial:** Sin proveedor activo, mostrar selección de proveedor, datos y modelo y opción para comprobar conexión. | Con perfil limpio completar el flujo usando un servicio simulado y verificar conexión y selección. | pendiente |
| AC5 | **Sin conexión:** Permitir grabar, transcribir, identificar interlocutores y revisar sesiones locales sin internet; preguntas y resúmenes requieren modelo local accesible. | Desconectar la red y ejecutar el recorrido local con modelos ya disponibles. | pendiente |

## Fuera de alcance

- API REST de fase 2, adjuntos en chat, calendario y control de costes.
- Código de producción, diseño y tareas de implementación durante la fase de especificación.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** Versión mínima de macOS y requisitos de hardware pendientes de validar; disponibilidad de modelos locales antes de trabajar sin red.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Los componentes propuestos y comportamientos de proveedores requieren validación antes de garantizar el resultado.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
