# Revisión de auditoría — 2026-11-22

## Alcance de esta revisión

Corrección de inconsistencias documentales tras la revisión externa. No representa aprobación de specs ni cierre de las investigaciones. Las decisiones de producto previas se conservan; no se escribieron componentes de producción.

## Observaciones atendidas

| Observación | Corrección | Referencia |
| --- | --- | --- |
| Archivos y voz sin audio presentados como decisiones abiertas | Archivos definidos en AC13; retención de voz referida al comportamiento acordado en 0005, con representación técnica pendiente de diseño | 0003/spec.md |
| Rechazo por contexto aún presentado como decisión de producto | AC11–AC12 son el comportamiento vigente; falta validar la estrategia técnica de varias llamadas | 0006/spec.md |
| Verificación sin proveedor incompleta | Incluye pregunta, resumen y síntesis | 0006 AC8 |
| Ubicación de notas y ausencia de resumen presentadas como desconocidas | Referencias a notas.md, sintesis.md y AC6; riesgos centrados en persistencia | 0009/spec.md |
| Formatos e interlocutores aún pendientes | Markdown y texto plano, tiempos e interlocutores y síntesis opcional ya acordados | 0010/spec.md y specs/README.md |
| Tablas de investigación desincronizadas | Filas de idiomas, catálogo y revisión documental OAuth marcadas como parciales; pruebas reales aún pendientes | 0012 y 0013/discovery.md |
| SDK anterior y nuevo sin aclaración | La consulta del SDK 26.2 se identifica como anterior a la actualización; Xcode 27.2 consta como entorno posterior | 0012/discovery.md |
| Resultado de idiomas demasiado general | Se enumeran las 13 variantes compatibles devueltas y las cuatro de español instaladas | 0012/discovery.md |
| Experimentos descritos como totalmente pendientes | Las fichas distinguen evidencia parcial de experimentos pendientes | 0012 y 0013/spec.md |
| Fallos aún pendientes de decisión en discovery | Se remite a AC11–AC12 y se mantiene pendiente la validación técnica | 0013/discovery.md |
| Casilla genérica de vista de grabación | Marcada tras comprobar que cierre, permisos e interrupciones ya están acordados | PENDIENTES_DOCUMENTACION.md |
| Análisis como archivos separados | Listas de contenidos y borrado usan los contenidos reales; los análisis se obtienen por plantillas/chat | DEFINICION_PROYECTO.md y docs/product.md |
| Riesgos de regeneración y descripción de voces anticuados | Se distingue el comportamiento acordado de su implementación; se resumen reasignación, fusión y etiqueta Yo | 0008 y 0005/spec.md |
| Continuidad vuelve a duplicar acuerdos | Sustituida por estado, referencias, evidencia, próximo trabajo y preferencias | CONTEXTO_CONTINUACION.md |

## Nueva evidencia ejecutada

El experimento `specs/0012-viabilidad-captura-transcripcion-y-voz-local/experimentos/carpetas.swift` se compiló y ejecutó con Xcode. Crea la estructura dos veces en un home simulado y verifica la conservación de un centinela; salida 0. La evidencia completa está en 0012. No se considera validado el home real, la firma o el DMG.

## Trabajo que sigue abierto

- Plataforma definitiva y validación en versiones y equipos objetivo; macOS 26 es un candidato por la disponibilidad declarada de SpeechAnalyzer, no una compatibilidad de ActaVoz ya probada.
- Captura dual, permisos, reconexión y Bluetooth.
- Transcripción real en ambos idiomas, selección automática, recursos y funcionamiento sin red.
- Diarización, reconocimiento entre reuniones y datos temporales para perfiles tardíos.
- OAuth autorizado para ActaVoz; llamadas autenticadas, selección de modelos, streaming y comportamiento del Llavero.
- Estrategia de varias llamadas con cobertura completa y evaluación de calidad; umbrales de estabilidad tras mediciones.

## Evidencia documental

La validación estructural no comprueba viabilidad de integraciones ni calidad semántica. Ninguna spec de producto se marca como aprobada o implementada por este informe.

- **Método:** `python3 scripts/validate_sdd.py --strict`.
- **Resultado:** salida 0; instalación SDD válida, cero avisos.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

- **Método:** `python3 scripts/audit_sdd.py`.
- **Resultado:** salida 0; 0001 en done, 0002–0011 en spec y 0012–0013 en discovery; ninguna aprobación nueva.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.

- **Método:** `git diff --check` y comprobación Python de numeración de criterios y ausencia de las frases contradictorias identificadas en 0003, 0009, 0010 e índice.
- **Resultado:** salida 0; diff sin errores de espacios y criterios AC1–ACn secuenciales en las doce unidades 0002–0013. La inspección de frases no sustituye una revisión semántica independiente.
- **Fecha:** 2026-11-22.
- **Commit:** sin commit.
