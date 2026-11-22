# Especificaciones

Cada cambio sustancial vive en `specs/NNNN-slug/` y sigue el flujo de [docs/sdd.md](../docs/sdd.md).

| # | Título | Estado | Siguiente paso | Notas |
| --- | --- | --- | --- | --- |
| [0001](0001-sistema-sdd/spec.md) | Sistema SDD independiente del modelo | `done` | Revisar mejoras del piloto al usar la primera feature | Instalación inicial verificada |
<!-- spec-driven-development:index-end -->

## Reglas

- El estado de la tabla y el de `spec.md` deben coincidir.
- No pasar de `spec` a `design` sin **Aprobación: aprobada**.
- `done` requiere evidencia por tarea, criterios comprobados y verificación completa.
- Crear una unidad con `python3 scripts/new-spec.py "Título"` o añadir `--state discovery`.
