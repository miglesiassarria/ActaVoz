# Protocolo operativo para agentes

Este protocolo reduce errores independientemente del modelo usado. No exige razonamientos internos extensos: exige decisiones, comandos y resultados observables.

## Estado de trabajo

Antes de una fase, reconstruir y mantener:

```text
FASE: discovery | spec | design | tasks | build | bug | trivial | audit
OBJETIVO: una frase
HECHOS: archivos, salidas o requisitos confirmados
SUPUESTOS: decisiones pendientes de verificar
RESTRICCIONES: AGENTS.md, ADR, alcance y cambios ajenos
SIGUIENTE ACCIÓN: una acción concreta
ÉXITO: evidencia que permite avanzar
BLOQUEOS: ninguno o lista explícita
```

El estado duradero debe quedar en specs, ADR, documentación o Git, no solo en la conversación.

## Bucle de trabajo

1. Orientar: releer objetivo, restricciones y archivos afectados.
2. Predecir: indicar el resultado esperado de la siguiente acción.
3. Actuar: completar una unidad coherente de trabajo.
4. Observar: revisar salida, código de salida y diff.
5. Comparar: contrastar el resultado con el criterio.
6. Corregir: investigar antes de ampliar cambios si difiere.
7. Registrar: actualizar evidencia, supuestos o documentos.
8. Avanzar: elegir la siguiente acción después del registro.

Tras tres intentos con la misma causa y sin evidencia nueva, usar `blocked` y dejar objetivo, acciones probadas, resultados y dato necesario para continuar.

## Control de alcance

Antes de editar, comprobar que el cambio está exigido por un criterio o tarea, es el mínimo necesario, no contradice una decisión estable y no sobrescribe trabajo ajeno. No instalar dependencias, publicar, borrar datos ni cambiar configuración externa sin autorización dentro del alcance.
