# Instrucciones para agentes

<!-- spec-driven-development:start -->
## Desarrollo dirigido por especificaciones

Este repositorio usa la skill local `.agents/skills/spec-driven-development/SKILL.md`. Es independiente del modelo y aplica a cualquier agente que trabaje aquí.

Antes de cambiar software, clasificar el trabajo y leer `docs/sdd.md`, `docs/agent-harness.md`, `specs/README.md`, los ADR relevantes y `docs/verification.md`.

- Un descubrimiento de producto, viabilidad o arquitectura empieza en `discovery`: puede producir evidencia y decisiones, pero no código de producción.
- Una funcionalidad, integración o cambio de comportamiento sigue `spec → design → tasks → build → done`.
- No pasar de `spec` a `design` sin que el campo **Aprobación** de la spec sea `aprobada`.
- Un fallo reproducible empieza por una prueba que falle; una errata o ajuste inequívocamente reversible se verifica de forma proporcional.

Cada criterio y tarea necesita una comprobación reproducible. Una evidencia debe registrar comando o método, resultado, fecha y commit cuando aplique. Ejecutar la comprobación antes de marcar trabajo. Conservar los cambios ajenos y actualizar los documentos cuando la realidad contradiga un supuesto.

Usar `python3 scripts/validate_sdd.py --strict` antes de declarar una spec terminada y `python3 scripts/audit_sdd.py` al retomar trabajo.

### Git trunk-based

`main` es la rama troncal y debe permanecer desplegable. Cada spec o funcionalidad se trabaja en una rama creada desde `main` actualizado, con nombre `spec/NNNN-slug` (o `fix/slug` para un fallo). Se integra mediante pull request y squash merge; no se hace commit directo a `main`. Tras el merge se elimina la rama en local y en GitHub, y no se reutiliza. El flujo completo, la limpieza y las excepciones están en `docs/sdd.md`.
<!-- spec-driven-development:end -->
