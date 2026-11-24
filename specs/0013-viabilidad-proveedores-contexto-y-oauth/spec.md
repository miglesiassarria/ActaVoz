# 0013 · Viabilidad proveedores contexto y OAuth

- **Estado:** superseded
- **Creada:** 2026-11-22
- **Aprobación:** no aplica
- **Aprobada por:** —
- **Fecha de aprobación:** —

## Problema

Proveedores, OAuth y contexto. Registrar evidencia y resolver incógnitas antes de aprobar las especificaciones dependientes.

## Comportamiento esperado

La viabilidad quedó resuelta: OAuth de terceros no está disponible; API key, Ollama y proveedor genérico son viables. La implementación pasa a 0006.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | Registrar fuentes, pruebas, resultados y límites de la investigación. | Inspeccionar discovery.md y reproducir cada experimento con datos controlados. | cumplido (2026-11-24): OAuth descartado; contratos y contexto documentados |

## Fuera de alcance

- Código de producción y acceso a credenciales o datos personales sin autorización.

## Supuestos

- OAuth de terceros no está disponible; API key, Ollama y proveedor genérico son viables.

## Riesgos

- Las pruebas pueden revelar incompatibilidad o requisitos de producto no resueltos.

## Invariantes aplicables

- AGENTS.md, docs/sdd.md y privacidad local de audio.

## Aprendizajes durante la implementación

- Ninguno todavía.
