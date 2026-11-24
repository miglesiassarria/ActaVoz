# 0006 · Tareas: Proveedores, modelos y credenciales

Estado: done.

- [x] **T1. Configuración, conexiones y Llavero**
  - Objetivo: AC1, AC2, AC3, AC6, AC8.
  - Verificación: swift test (ProviderTests) y UI de Ajustes.
  - Evidencia:
    - Método: guardar dos conexiones, activar una, guardar clave en Llavero y comprobar éxito/errores con servidor local.
    - Resultado: 11 pruebas de proveedores en verde; JSON sin secretos; Llavero con la clave; conexión simulada OK.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y cierre de 0006.

- [x] **T2. Modelos, contexto y errores**
  - Objetivo: AC4, AC5, AC7, AC9, AC10, AC11, AC12.
  - Verificación: swift test (selección, Claude/Ollama/OpenAI, contexto y errores).
  - Evidencia:
    - Método: transporte simulado, selección principal/preguntas/resúmenes y división tras rechazo.
    - Resultado: 11 pruebas en verde; cobertura exacta en partes; errores sin secretos.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y cierre de 0006.

- [x] **T3. UI y evidencia**
  - Objetivo: AC1–AC6 y AC8 visibles en Ajustes.
  - Verificación: build firmado y prueba manual con servidor local.
  - Evidencia:
    - Método: app firmada, Ajustes → Proveedores, alta de Mock, comprobación y cierre.
    - Resultado: catálogo, conexión activa, modelos y mensaje OK observados.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y cierre de 0006.

- [x] **T4. Cierre**
  - Objetivo: actualizar resultados, índice, verificación y ADR.
  - Evidencia:
    - Método: validate_sdd --strict, audit_sdd y build.
    - Resultado: instalación SDD válida; 127 pruebas.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y cierre de 0006.
