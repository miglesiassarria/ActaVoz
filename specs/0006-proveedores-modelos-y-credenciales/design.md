# 0006 · Diseño: Proveedores, modelos y credenciales

## Estado y dependencias

Diseño implementado sobre spec aprobada; dependencias 0002 y 0013 cerradas. Decisión de OAuth en 0013: no hay flujo público autorizado para esta app.

## Enfoque

- Núcleo Providers.swift: catálogo de tipos, conexiones, configuración versionada, selección de modelos y Llavero.
- ProviderHTTP.swift: contrato LanguageProvider, transporte inyectable y clientes OpenAI-compatible, Claude y Ollama.
- ProviderContext.swift: envía la transcripción completa; solo divide si el proveedor rechaza por longitud y combina las partes.
- App: ProvidersSettingsView para catálogo, conexiones, modelos y comprobación de conexión.

## Decisiones

- OpenAI, Claude, OpenCode Go y genérico usan clave; Ollama no requiere clave; OAuth queda desactivado y explicado.
- Secretos exclusivamente en Llavero (app.actavoz.providers); el JSON solo guarda id, nombre, tipo, URL, modelos y selección.
- No se impone un límite propio de contexto. La división se activa tras rechazo y cubre la transcripción completa.
- Una conexión activa define el modelo principal; preguntas y resúmenes pueden sobrescribirlo. Nombres y respaldo usan el principal.
- Sin proveedor activo, las funciones locales siguen disponibles y Ajustes ofrece configurarlo.

## Contratos y errores

- ProviderConfiguration con schemaVersion, conexiones, activeConnectionID, chatModel y summaryModel.
- Errores: credencial ausente o rechazada, longitud, no disponible, respuesta inválida y rechazo. Ningún mensaje incluye la clave.
- Contexto: resultado con parts; si una parte no se puede procesar, se propaga el error y no se inventa cobertura.

## Seguridad y límites

- Pruebas con transporte simulado y servidor local; sin claves reales.
- OAuth no se promete. macOS 26 no se ha probado.
- No se declara equivalencia semántica entre una llamada y varias.
