# 0013 · Tareas: Proveedores, contexto y OAuth

Estado: superseded por 0006.

- [x] **T1. OAuth y catálogo**
  - Objetivo: determinar si existe un flujo OAuth autorizado para ActaVoz.
  - Evidencia:
    - Método: revisión de la documentación de OpenAI y de integración de terceros.
    - Resultado: no hay flujo OAuth público autorizado; se descarta para la primera versión.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y posteriores.

- [x] **T2. Contexto y contratos**
  - Objetivo: validar cobertura ante rechazo por longitud y contratos de proveedores.
  - Evidencia:
    - Método: experimento de división recursiva y revisión de endpoints OpenAI-compatible, Anthropic, Ollama y Go.
    - Resultado: cobertura exacta en 16 partes y rechazo irreducible propagado; contratos por clave viables; OAuth no.
    - Fecha: 2026-11-24.
    - Commit: 3ef4091 y posteriores.

## Resultado

La implementación y las pruebas de proveedores pasan a 0006. Esta unidad no produce código de producción.
