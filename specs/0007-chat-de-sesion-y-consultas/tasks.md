# 0007 · Tareas: Chat de sesión

Estado: done.

- [x] **T1. Interfaz, consultas y captura**
  - Objetivo: AC1–AC6.
  - Evidencia:
    - Método: barra y panel en sesión; pregunta con proveedor local; panel abierto durante grabación.
    - Resultado: barra visible, panel se oculta al tocar fuera, respuesta simulada y captura continúa (00:05 → 00:12).
    - Fecha: 2026-11-26.
    - Commit: 3ef4091 y cierre de 0007.

- [x] **T2. Historial, contexto y cola**
  - Objetivo: AC7–AC9.
  - Evidencia:
    - Método: ChatTests con SpyResponder; chat.json; reapertura de la sesión.
    - Resultado: 5 pruebas; transcripción completa, historial previo, orden de cola y persistencia ISO8601.
    - Fecha: 2026-11-26.
    - Commit: 3ef4091 y cierre de 0007.

- [x] **T3. Cierre**
  - Objetivo: validar, documentar y fusionar.
  - Evidencia:
    - Método: swift test, build firmado, validate_sdd --strict y audit_sdd.
    - Resultado: 132 pruebas; build correcto; validador correcto.
    - Fecha: 2026-11-26.
    - Commit: 3ef4091 y cierre de 0007.
