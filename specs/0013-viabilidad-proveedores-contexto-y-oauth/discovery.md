# 0013 · Proveedores, OAuth y contexto

## Pregunta o decisión

Determinar la viabilidad de la capacidad y registrar evidencia antes de aprobar las specs dependientes.

## Hechos y fuentes

- **Confirmado por producto:** acceso mediante claves, proveedor genérico y deseo de OAuth para ChatGPT; sin control de costes ni límites propios; usar transcripción completa.
- **Observado en documentación, 2026-11-22:** [OpenCode Go](https://opencode.ai/docs/console/go/) describe API keys y endpoints; no se ha probado desde ActaVoz ni se ha resuelto su contrato para este producto.
- **Desconocido:** autorización y compatibilidad de OAuth para una app de terceros, protocolo y compatibilidad del endpoint genérico, y comportamiento ante rechazo de contexto largo.

## Hipótesis y desconocidos

- **Supuesto:** los componentes candidatos podrían cumplir los requisitos; no está demostrado para ActaVoz.
- **Desconocido:** resultados, límites, integración y riesgos descritos arriba.

## Experimentos seguros

| Experimento | Resultado esperado | Límite seguro | Evidencia |
| --- | --- | --- | --- |
| Revisar documentación oficial de OAuth y condiciones para terceros | Identificar flujo compatible o ausencia de uno | Sin credenciales reales ni accesos no autorizados | No ejecutado |
| Probar OpenCode Go y proveedor genérico con credencial de prueba autorizada | Registrar formatos, errores y compatibilidad real | No registrar tokens ni datos personales | No ejecutado |
| Probar transcripciones largas y rechazo de contexto | Comparar estrategias de una o varias llamadas sin descartar texto ni prometer contexto equivalente | Proveedor controlado y texto sintético | No ejecutado |
| Comprobar listado y selección de modelos y streaming por proveedor | Registrar capacidades y diferencias entre lista dinámica e identificador manual | Servicios simulados o credenciales autorizadas sin registrar secretos | No ejecutado |
| Comprobar acceso al Llavero en compilaciones locales y firmadas | Registrar si aparecen avisos repetidos y en qué condiciones | Llavero y credenciales de prueba, sin exponer secretos | No ejecutado |

## Resultado y siguiente paso

Bloquea el cierre de compatibilidad y estrategia de contexto en 0006; las decisiones de producto ante fallos deben revisarse con la persona.
