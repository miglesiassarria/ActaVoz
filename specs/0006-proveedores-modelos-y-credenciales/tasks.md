# 0006 · Tareas: Proveedores, modelos y credenciales

Estado: done.

- [x] **T1. Configuración, conexiones y Llavero**
  - Objetivo: AC1–AC3 y AC6.
  - Evidencia:
    - Método: ProviderTests, UI con servidor local y Llavero.
    - Resultado: 11 pruebas; JSON sin secretos; una conexión simulada OK; OAuth no ofrecido.
    - Fecha: 2026-11-26.
    - Commit: 9c5889c y cierre.

- [x] **T2. Modelos, contexto y errores**
  - Objetivo: AC4, AC5, AC7 y AC11–AC12.
  - Evidencia:
    - Método: transporte simulado, contexto y errores; chat/resumen.
    - Resultado: modelo de preguntas/resumen; cobertura exacta; reintento y cambio de modelo.
    - Fecha: 2026-11-26.
    - Commit: 9c5889c y cierre.

- [x] **T3. Consumo y nombres**
  - Objetivo: AC8–AC10.
  - Evidencia:
    - Método: chat, resumen y síntesis; NameSuggestionTests.
    - Resultado: consumo real; nombres con IA usan el principal y descartan ids desconocidos.
    - Fecha: 2026-11-26.
    - Commit: cierre.

- [x] **T4. Verificación de extremo a extremo**
  - Objetivo: comprobar UI y persistencia.
  - Evidencia:
    - Método: 147 pruebas, build firmado, servidor local y validadores.
    - Resultado: 147/147; build correcto.
    - Fecha: 2026-11-26.
    - Commit: cierre.
