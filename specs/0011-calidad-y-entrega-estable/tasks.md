# 0011 · Tareas: Calidad y entrega beta

Estado: done. Vía B1 aprobada por la persona usuaria.

- [x] **T1. Evaluación funcional y técnica**
  - Objetivo: AC1–AC4 y AC7.
  - Evidencia:
    - Método: 147 pruebas, build Release, métricas de 0012 y prueba offline con Ollama.
    - Resultado: cobertura funcional, red externa denegada y consulta local respondida.
    - Fecha: 2026-11-27.
    - Commit: beta ad-hoc.

- [x] **T2. Métricas beta**
  - Objetivo: AC5.
  - Evidencia:
    - Método: documentar métricas, límites y ausencia de SLA.
    - Resultado: release beta; no se declara estabilidad.
    - Fecha: 2026-11-27.
    - Commit: beta ad-hoc.

- [x] **T3. Entrega ad-hoc e integración offline**
  - Objetivo: AC6–AC7.
  - Evidencia:
    - Método: DMG ad-hoc, codesign, hdiutil verify, spctl esperado, SHA256 y prerelease GitHub.
    - Resultado: artefacto publicado como beta; Gatekeeper documentado.
    - Fecha: 2026-11-27.
    - Commit: beta ad-hoc.
