# 0001 · Tareas

- [x] **T1. Crear la skill local y las reglas de entrada neutrales respecto al modelo**
  - Objetivo: establecer una única fuente local para los agentes de ActaVoz.
  - Archivos: `AGENTS.md`, `.agents/skills/spec-driven-development/SKILL.md`.
  - Verificación: `rg -n "name: spec-driven-development" .agents/skills/spec-driven-development/SKILL.md`.
  - Evidencia:
    - Método: comando de búsqueda ejecutado en la raíz del repositorio.
    - Resultado: encontró `name: spec-driven-development` en la línea 2; salida 0.
    - Fecha: 2026-11-20.
    - Commit: sin commit.

- [x] **T2. Añadir workflow, fases y plantillas SDD**
  - Objetivo: documentar discovery, aprobación, diseño, tareas y evidencia verificable.
  - Archivos: `docs/`, `specs/README.md`, `specs/TEMPLATE/`.
  - Verificación: `python3 scripts/validate_sdd.py --strict`.
  - Evidencia:
    - Método: validador estricto ejecutado en la raíz del repositorio.
    - Resultado: `OK: instalación SDD válida; 0 aviso(s)`; salida 0.
    - Fecha: 2026-11-20.
    - Commit: sin commit.

- [x] **T3. Implementar validación y auditoría de estado**
  - Objetivo: detectar inconsistencias de estructura, estados, aprobación, índice y cierre.
  - Archivos: `scripts/validate_sdd.py`, `scripts/audit_sdd.py`.
  - Verificación: `python3 scripts/audit_sdd.py`.
  - Evidencia:
    - Método: auditoría ejecutada antes de cerrar esta spec.
    - Resultado: informó la spec 0001 en estado build y activa; salida 0.
    - Fecha: 2026-11-20.
    - Commit: sin commit.

- [x] **T4. Añadir sugerencias seguras de verificación, incluidas Swift y Xcode**
  - Objetivo: preparar la futura app macOS sin inventar comandos de build.
  - Archivos: `scripts/suggest_verification.py`, `docs/verification.md`.
  - Verificación: `python3 scripts/suggest_verification.py`.
  - Evidencia:
    - Método: detector ejecutado en la raíz del repositorio.
    - Resultado: no detectó manifiestos ni sugirió comandos inexistentes; salida 0.
    - Fecha: 2026-11-20.
    - Commit: sin commit.

## Cierre

- [x] Todas las tareas tienen verificación y evidencia ejecutada.
- [x] Pasa la verificación completa de `docs/verification.md`.
- [x] Cada criterio de `spec.md` tiene resultado y evidencia.
- [x] Se revisó el diff contra el alcance y se preservaron cambios ajenos.
- [x] Se actualizó documentación estable y ADR cuando correspondía.
- [x] `spec.md` y el índice muestran el mismo estado.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | búsqueda de la skill, salida 0, 2026-11-20 |
| AC2 | cumplido | validador estricto, salida 0, 2026-11-20 |
| AC3 | cumplido | auditoría, salida 0, 2026-11-20 |
| AC4 | cumplido | detector de manifiestos, salida 0, 2026-11-20 |
