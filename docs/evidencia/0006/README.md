# Evidencia de 0006 · Proveedores, modelos y credenciales

Fecha: 2026-11-24. Entorno: macOS 27.2.1/arm64, Xcode 27.2.

## Pruebas automáticas

- swift test: 127 pruebas, 0 fallos (11 de proveedores).
- ProviderTests cubre:
  - petición OpenAI con Authorization, modelo y respuesta;
  - Claude en /v1/messages con x-api-key;
  - Ollama en /api/chat sin clave;
  - configuración con dos conexiones y selección activa;
  - fallback de preguntas/resúmenes/nombres al modelo principal;
  - contexto dividido solo tras rechazo, con cobertura exacta;
  - errores 401/500 sin filtrar la clave;
  - Llavero de prueba: guardar, leer y borrar.
- La UI se compiló y firmó con ActaVoz Development: BUILD SUCCEEDED.

## Prueba manual

- Servidor local simulado en 127.0.0.1:8765.
- Ajustes → Proveedores → Añadir conexión: Mock, OpenAI, URL local, modelo mock-model y clave de prueba.
- Guardar, comprobar conexión: «OK: conexión correcta con Mock.»
- proveedores.json no contiene la clave; security encuentra la cuenta en el Llavero con servicio app.actavoz.providers.
- OAuth aparece como no disponible.

## Límites

- No se probaron claves ni cuentas reales.
- OpenCode Go y genérico comparten el contrato OpenAI-compatible; solo se probó el contrato OpenAI con transporte simulado.
- No se probó streaming ni equivalencia semántica de la división.
- macOS 26 no se ha probado.

## Cierre 2026-11-26

- 147 pruebas, 0 fallos.
- Chat, resumen y síntesis consumen el proveedor configurado.
- NameSuggestionTests: propuesta con modelo principal y descarte de ids desconocidos.
- Chat y resumen ofrecen reintento y cambio de modelo; errores sin secretos.
- UI de errores de resumen añade Reintentar/Cambiar modelo.
