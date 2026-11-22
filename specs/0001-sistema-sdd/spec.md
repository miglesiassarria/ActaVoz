# 0001 · Sistema SDD independiente del modelo

- **Estado:** done
- **Creada:** 2026-11-20
- **Aprobación:** aprobada
- **Aprobada por:** usuario
- **Fecha de aprobación:** 2026-11-20

## Problema

ActaVoz está en fase de definición y no tenía un proceso versionado para que distintos agentes documenten, aprueben, implementen y verifiquen cambios de forma coherente. La referencia disponible estaba ligada por nombre y documentación a un modelo concreto.

## Comportamiento esperado

El repositorio tendrá un sistema SDD local, independiente del modelo, con fases de descubrimiento e implementación, una aprobación estructurada, plantillas, verificación automatizada, auditoría y sugerencias para proyectos Swift/Xcode futuros.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | Existe una skill local denominada `spec-driven-development` sin dependencia de un modelo. | `rg -n "name: spec-driven-development" .agents/skills/spec-driven-development/SKILL.md` | cumplido: línea 2 encontrada, salida 0 |
| AC2 | Las specs tienen fases, aprobación estructurada y evidencia requerida; la estructura se valida. | `python3 scripts/validate_sdd.py --strict` | cumplido: instalación válida, 0 avisos, salida 0 |
| AC3 | La auditoría informa de la unidad activa y comprueba consistencia. | `python3 scripts/audit_sdd.py` | cumplido: informó 0001 en build antes del cierre, salida 0 |
| AC4 | El repositorio puede detectar de forma segura candidatos de verificación, incluidos Swift/Xcode. | `python3 scripts/suggest_verification.py` | cumplido: no encontró manifiestos y no sugirió comandos inexistentes, salida 0 |

## Fuera de alcance

- Implementar la aplicación macOS, la API REST o decidir dependencias de transcripción y diarización.
- Modificar la skill global situada fuera de ActaVoz.
- Crear comandos de build o pruebas de Swift antes de que exista un proyecto Swift.

## Supuestos

- La aprobación explícita del usuario para implementar todas las mejoras de esta conversación autoriza esta spec.
- La variante local es un piloto; las mejoras generalizables se promoverán a la skill base mediante una revisión posterior.

## Riesgos

- Las reglas pueden resultar demasiado estrictas durante la fase de definición. El estado `discovery` y la auditoría permiten registrar esa realidad sin fingir implementación.
- Las sugerencias de comandos pueden no coincidir con una configuración Xcode futura; se documentan como sugerencias y requieren ejecución antes de adoptarse.

## Invariantes aplicables

- La aplicación de escritorio sigue en fase de definición y la API REST queda fuera de la primera fase.
- Las verificaciones solo se declaran válidas después de ejecutarlas en este repositorio.

## Aprendizajes durante la implementación

- ActaVoz todavía no tiene un proyecto de aplicación; `docs/verification.md` solo declara comprobaciones SDD válidas y conserva el detector como sugerencia no probatoria.
