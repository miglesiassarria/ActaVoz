# 0001 · Diseño

## Enfoque

Crear una skill local y documentación estable neutrales respecto al modelo. Las specs se guardan bajo `specs/`, las reglas de entrada en `AGENTS.md` y los scripts locales validan estructura, puertas de fase, evidencia e índice.

## Superficies afectadas

| Archivo, módulo o contrato | Cambio previsto | Criterio relacionado |
| --- | --- | --- |
| `AGENTS.md` | Reglas de uso y puerta de aprobación | AC2 |
| `.agents/skills/spec-driven-development/` | Skill local independiente del modelo | AC1 |
| `docs/` y `specs/` | Flujo, protocolo, documentación estable y plantillas | AC2 |
| `scripts/validate_sdd.py` | Validación estructural y de estados | AC2 |
| `scripts/audit_sdd.py` | Resumen reanudable y consistencia | AC3 |
| `scripts/suggest_verification.py` | Detección de candidatos Swift/Xcode y otros manifiestos | AC4 |

## Decisiones

### D1. Skill local versionada

- **Decisión:** usar `.agents/skills/spec-driven-development/` como fuente operativa de ActaVoz.
- **Alternativa descartada:** depender de una skill global con nombre de un modelo.
- **Motivo:** las reglas viajan con el repositorio y funcionan con varios agentes.
- **Consecuencia:** promover mejoras a la base requiere una revisión consciente del diff.

### D2. Aprobación verificable en Markdown estructurado

- **Decisión:** mantener campos explícitos de estado, aprobación, aprobador y fecha en `spec.md`.
- **Alternativa descartada:** una frase libre que un agente interprete como aprobación.
- **Motivo:** el validador puede impedir fases de implementación sin una aprobación registrada.
- **Consecuencia:** al aprobar una spec hay que actualizar su metadata.

### D3. Discovery como estado formal

- **Decisión:** usar `discovery` para decisiones, investigación y experimentos seguros previos a una spec.
- **Alternativa descartada:** obligar a tratar toda incertidumbre como una funcionalidad lista para construir.
- **Motivo:** ActaVoz está cerrando producto y arquitectura antes del código.
- **Consecuencia:** discovery no permite código de producción.

## Datos, interfaces y compatibilidad

- **Datos o migraciones:** solo archivos Markdown y scripts locales; no hay datos de usuario.
- **Interfaces o contratos:** la metadata y la tabla de índice son contratos del validador.
- **Compatibilidad y reversión:** eliminar esta estructura revierte el cambio de proceso; no toca la aplicación.
- **Seguridad y privacidad:** los scripts no leen secretos ni llaman a red.
- **Rendimiento y observabilidad:** los scripts recorren únicamente `specs/` y archivos locales; la auditoría muestra estados activos.

## Riesgos

| Riesgo | Señal observable | Verificación o mitigación |
| --- | --- | --- |
| Índice y specs divergen | Error del validador | `validate_sdd.py --strict` |
| Se implementa sin aprobación | Error para estados design, tasks, build o done | `validate_sdd.py --strict` |
| Un comando sugerido se toma por válido | Falta evidencia en documentación | El detector solo imprime sugerencias |

## ADR

No se requiere ADR: el flujo de trabajo del repositorio es reversible y no cambia la arquitectura de producto.
