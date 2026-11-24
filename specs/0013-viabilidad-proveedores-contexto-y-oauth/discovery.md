# 0013 · Proveedores, OAuth y contexto

## Pregunta o decisión

Determinar la viabilidad de la capacidad y registrar evidencia para el diseño de las specs dependientes, aprobadas por la persona usuaria.

## Hechos y fuentes

- **Confirmado por producto:** acceso mediante claves, proveedor genérico y deseo de OAuth para ChatGPT; sin control de costes ni límites propios; usar transcripción completa.
- **Observado en documentación, 2026-11-22:** [OpenCode Go](https://opencode.ai/docs/console/go/) describe API keys y endpoints; no se ha probado desde ActaVoz ni se ha resuelto su contrato para este producto.
- **Observado en documentación, 2026-11-22:** [OpenCode modelos](https://opencode.ai/docs/console/api/models/) describe un listado público Go y [OpenCode conexiones](https://opencode.ai/docs/console/harnesses) describe variantes de protocolo y el identificador de sesión exigido por Go. No se han probado inferencia ni streaming autenticados.
- **Observado en documentación, 2026-11-22:** [OpenAI distingue facturación de ChatGPT y API](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform); [compartir el plan con otras aplicaciones](https://help.openai.com/en/articles/20001542-using-your-chatgpt-plan-in-other-apps-and-sites) se describe para aplicaciones participantes. La elegibilidad y el flujo autorizado de ActaVoz no están demostrados.
- **Desconocido:** autorización y compatibilidad de OAuth para una app de terceros, protocolo y compatibilidad del endpoint genérico, y comportamiento ante rechazo de contexto largo.

## Hipótesis y desconocidos

- **Supuesto:** los componentes candidatos podrían cumplir los requisitos; no está demostrado para ActaVoz.
- **Desconocido:** resultados, límites, integración y riesgos descritos arriba.

## Experimentos seguros

| Experimento | Resultado esperado | Límite seguro | Evidencia |
| --- | --- | --- | --- |
| Revisar documentación oficial de OAuth y condiciones para terceros | Identificar flujo compatible o ausencia de uno | Sin credenciales reales ni accesos no autorizados | Parcial: fuentes oficiales consultadas; autorización y flujo para ActaVoz sin demostrar |
| Probar OpenCode Go y proveedor genérico con credencial de prueba autorizada | Registrar formatos, errores y compatibilidad real | No registrar tokens ni datos personales | No ejecutado |
| Probar transcripciones largas y rechazo de contexto | Comparar estrategias de una o varias llamadas sin descartar texto ni prometer contexto equivalente | Proveedor controlado y texto sintético | Parcial: cobertura exacta con proveedor simulado; falta evaluar síntesis y contexto con proveedores reales |
| Comprobar listado y selección de modelos y streaming por proveedor | Registrar capacidades y diferencias entre lista dinámica e identificador manual | Servicios simulados o credenciales autorizadas sin registrar secretos | Parcial: catálogo público Go consultado; selección autenticada y streaming sin probar |
| Comprobar acceso al Llavero en compilaciones locales y firmadas | Registrar si aparecen avisos repetidos y en qué condiciones | Llavero y credenciales de prueba, sin exponer secretos | No ejecutado |

### Evidencia parcial: catálogo público de OpenCode Go

- **Método:** `curl -fsS https://opencode.ai/inference/go/v1/models` y análisis JSON para mostrar únicamente el tipo de respuesta y número de modelos; sin credencial ni inferencia.
- **Resultado:** HTTP 200, objeto `list` con 30 modelos en el momento de la consulta. No demuestra acceso de la cuenta del usuario, generación ni streaming.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

### Evidencia parcial: fragmentación ante rechazo

- **Método:** `python3 specs/0013-viabilidad-proveedores-contexto-y-oauth/experimentos/contexto.py`.
- **Resultado:** salida 0. Un proveedor simulado rechazó texto sobre su límite; la división recursiva procesó 16 partes cuya concatenación coincide exactamente con la entrada y propagó un rechazo irreducible. La prueba usa límites de caracteres artificiales; no simula tokens, historia, instrucciones, streaming ni solicitudes reales. No demuestra que los resultados parciales puedan combinarse dentro del contexto disponible ni equivalencia semántica.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

## Evidencia: OAuth de terceros (2026-11-24)

- **Método:** revisar la documentación de OpenAI sobre facturación ChatGPT/API y uso del plan ChatGPT en otras aplicaciones; contrastar con la ausencia de un flujo OAuth público autorizado para una app de escritorio de terceros.
- **Resultado:** no hay un flujo OAuth público que ActaVoz pueda ofrecer con garantías. La integración de ChatGPT con otras apps es para aplicaciones participantes y no autoriza a ActaVoz. No se usaron cuentas ni credenciales.
- **Decisión:** 0006 ofrecerá API key para OpenAI, Claude, OpenCode Go, Ollama y proveedor genérico; OAuth quedará visible como no disponible, desactivado y explicado. No se promete OAuth.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente.

## Evidencia: contratos y contexto (2026-11-24)

- **Método:** revisar endpoints de OpenAI-compatible, Anthropic Messages, Ollama y el contrato Go; ejecutar `experimentos/contexto.py`.
- **Resultado:** los proveedores por clave encajan en un contrato común de mensajes; el proveedor genérico exige URL, token y modelo. La división recursiva cubrió exactamente la entrada en 16 partes y propagó el rechazo irreducible. No se probó semántica, streaming ni tokens reales.
- **Consecuencia:** 0006 implementará clientes por clave, selección de modelo y división solo tras rechazo por longitud; los resultados parciales se combinarán localmente y se probarán con servidor simulado.
- **Fecha:** 2026-11-24.
- **Commit:** pendiente.

## Resultado y siguiente paso

La viabilidad queda resuelta: OAuth no está disponible para esta app; API key, Ollama y proveedor genérico sí son viables. 0013 se cierra como superseded por 0006; la implementación y las pruebas de contexto pertenecen a 0006.
