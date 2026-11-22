# 0006 · Proveedores, modelos y credenciales

- **Estado:** spec
- **Creada:** 2026-11-22
- **Aprobación:** pendiente
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Permitir elegir y cambiar modelos locales o remotos sin vincular el producto a un proveedor.

## Comportamiento esperado

La persona configura proveedores, credenciales y modelos; la aplicación usa la transcripción completa según la función solicitada.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Catálogo:** Ofrecer OpenAI por clave y OAuth sujeto a compatibilidad, Claude, OpenCode Go, Ollama y proveedor genérico con URL, token y modelo. | Recorrer opciones con servicios simulados; contrastar OAuth con documentación y prueba autorizada. | pendiente |
| AC2 | **Múltiples conexiones:** Configurar varias conexiones y seleccionar una activa sin introducir de nuevo datos. | Guardar dos conexiones ficticias, alternarlas y reabrir Ajustes. | pendiente |
| AC3 | **Credenciales:** Guardar claves y credenciales OAuth en Llavero local, reutilizarlas y solicitar corrección cuando dejen de funcionar. | Configurar clave de prueba, reiniciar y simular rechazo sin registrar secretos. | pendiente |
| AC4 | **Selección de modelo:** Elegir modelo principal y permitir asignar opcionalmente modelos específicos para preguntas y resúmenes. | Configurar opciones y verificar modelo recibido por proveedor simulado. | pendiente |
| AC5 | **Conexión:** Permitir comprobar la conexión y mostrar errores comprensibles sin exponer credenciales. | Simular éxito, credencial inválida y servicio inaccesible. | pendiente |
| AC6 | **OAuth:** Comprobar compatibilidad del flujo de terceros antes de prometerlo; si está disponible permitir conectar y desconectar en Ajustes. | Registrar evidencia de autorización y ejecutar conexión y revocación con cuenta de prueba si procede. | pendiente |
| AC7 | **Contexto:** No imponer control o límite propio de contexto; utilizar toda la transcripción, con una o varias llamadas según corresponda. | Proveedor simulado registra solicitudes; verificar cobertura completa y comportamiento ante rechazo. | pendiente |
| AC8 | **Sin proveedor:** permitir usar las funciones locales sin proveedor configurado y ofrecer configurarlo al intentar hacer preguntas o generar resultados que lo requieran. | Sin proveedor, probar funciones locales y solicitar una pregunta y un resumen; comprobar la oferta de configuración. | pendiente |
| AC9 | **Modelo para síntesis:** usar el modelo configurado para resúmenes o el principal si no se configuró uno específico. | Con proveedor simulado, generar síntesis con y sin modelo de resúmenes y comprobar el modelo solicitado. | pendiente |
| AC10 | **Modelo para nombres:** cuando un LLM ayude a proponer nombres, usar el modelo principal configurado. | Con proveedor simulado y modelos distintos configurados, solicitar ayuda para nombres y comprobar que se usa el principal. | pendiente |
| AC11 | **Rechazo de solicitud:** mostrar un error comprensible y permitir reintentar o cambiar de modelo, conservando la transcripción y los contenidos guardados. | Simular un rechazo del proveedor, comprobar el aviso y ambas opciones y verificar que los contenidos de la sesión permanecen. | pendiente |
| AC12 | **Rechazo por longitud:** intentar procesar toda la transcripción mediante varias llamadas; si no se completa, mostrar error y ofrecer reintentar o cambiar de modelo, sin eliminar texto. | Con un proveedor simulado que rechace una solicitud larga, verificar cobertura íntegra en las llamadas posteriores; simular otro fallo y comprobar el error y conservación de datos. | pendiente |

## Decisiones previas a aprobación

- Resolver protocolos y validar la estrategia de varias llamadas ante rechazo por longitud en la investigación 0013, incluyendo sus efectos sobre el contexto.

## Fuera de alcance

- Control de costes y límites propios de contexto excluidos; OAuth sujeto a compatibilidad.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** OAuth de ChatGPT y compatibilidad de endpoints no están verificados; decidir en diseño qué hacer ante rechazo por contexto sin perder contenido. Costes fuera de alcance.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- La viabilidad y autorización de OAuth, contratos de proveedores y rechazo por contexto se investigan en 0013; el tratamiento sin proveedor y la estrategia de múltiples llamadas siguen pendientes.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
