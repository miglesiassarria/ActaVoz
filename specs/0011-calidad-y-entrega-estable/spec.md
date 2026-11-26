# 0011 · Calidad y entrega estable

- **Estado:** blocked
- **Creada:** 2026-11-22
- **Aprobación:** aprobada
- **Aprobada por:** persona usuaria
- **Fecha de aprobación:** 2026-11-22

## Problema

Comprobar las capacidades acordadas antes de considerar estable la primera versión.

## Comportamiento esperado

La versión estable solo se declara después de verificar sus capacidades de extremo a extremo, medir calidad con grabaciones y comprobar el artefacto final instalado.

## Criterios de aceptación

| # | Criterio observable | Verificación reproducible | Resultado final |
| --- | --- | --- | --- |
| AC1 | **Cobertura:** La versión estable incluye grabación y recuperación, transcripción e identificación local, biblioteca, chat, resúmenes, notas, plantillas y proveedores configurables. | Ejecutar un recorrido de extremo a extremo por cada capacidad y registrar evidencia. | cumplido: recorrido cubierto por 0002–0010 y 145 pruebas |
| AC2 | **Transcripción:** Comparar transcripción con referencias de reuniones reales o preparadas en español e inglés. | Usar grabaciones autorizadas o preparadas y registrar método y resultados por idioma. | cumplido con evidencia de 0012/0005: ASR ES/EN |
| AC3 | **Diarización:** Evaluar atribución correcta por intervención y casos de voces solapadas con las mismas grabaciones. | Comparar atribuciones contra referencia etiquetada y registrar resultados. | cumplido con evidencia de 0012: AMI DER 10,25/5,8 % y 4/4 interlocutores |
| AC4 | **Latencia y resumen:** Medir tiempos de transcripción, respuesta y resumen; revisar decisiones y tareas frente a la fuente y detectar invenciones. | Registrar tiempos y revisión de ejemplos con referencia conocida. | parcial: build y pruebas correctos; latencia y revisión semántica de reuniones nuevas no completas |
| AC5 | **Umbrales:** Acordar niveles mínimos tras revisar evidencia; no declarar estabilidad sin criterios aprobados y alcanzados. | Registrar umbrales acordados y comparación con mediciones. | bloqueado: umbrales no aprobados; no se declara estabilidad |
| AC6 | **Entrega:** Verificar instalación, firma, notarización y ejecución del DMG en entorno seguro. | Instalar artefacto real firmado y notarizado en Mac de prueba y registrar resultados. | bloqueado: sin Developer ID/notarización; spctl rechaza el DMG ad-hoc |
| AC7 | **Sin conexión:** con modelos locales previamente disponibles, grabar, transcribir, identificar y consultar sesiones; con un modelo local accesible, hacer preguntas y generar resúmenes. | Desconectar internet en un Mac de prueba, ejecutar el recorrido completo y registrar evidencia. | cumplido: app con red externa denegada y loopback permitido; consulta a Ollama local respondida |

## Fuera de alcance

- No fija por adelantado umbrales numéricos ni sustituye las verificaciones individuales de cada capacidad.
- La API REST, adjuntos en chat, calendario y control de costes quedan fuera de la primera fase.

## Supuestos y dependencias

- **Confirmado:** la fase inicial es escritorio macOS, con archivos locales y procesamiento de voz local.
- **Desconocido:** No hay aplicación ni mediciones actuales; los umbrales, hardware y condiciones de prueba siguen pendientes.
- Las demás capacidades necesarias se coordinan mediante el índice de dependencias de `specs/README.md`.

## Riesgos

- Sin corpus, medidas y umbrales aprobados no se puede afirmar estabilidad. La prueba integral offline requiere modelos previamente disponibles y proveedor local accesible.
- Las verificaciones de esta tabla describen métodos futuros; no se han ejecutado ni constituyen evidencia de implementación.

## Invariantes aplicables

- `AGENTS.md`, `docs/sdd.md`, `docs/verification.md` y `DEFINICION_PROYECTO.md`; no iniciar design sin aprobación explícita.
- No transmitir audio a proveedores de modelos de lenguaje; credenciales en el Llavero; sin proveedor activo por defecto.

## Aprendizajes durante la implementación

- Ninguno todavía.
