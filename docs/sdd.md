# Desarrollo dirigido por especificaciones

## Propósito

El flujo SDD de ActaVoz convierte un cambio relevante en comportamiento verificable antes de construirlo. Los documentos son el registro durable de decisiones y evidencia; no sustituyen las pruebas.

## Estados

`discovery`, `spec`, `design`, `tasks`, `build`, `done`, `blocked`, `discarded` y `superseded`.

```text
discovery → spec --aprobación explícita--> design → tasks → build → done
                  ^                         |        |       |
                  +------ cambio material ---+--------+-------+
```

`discovery` sirve para producto, viabilidad y decisiones técnicas aún inciertas. No autoriza código de producción. `blocked` conserva el estado real y el dato necesario para avanzar. `discarded` y `superseded` explican por qué ya no se continúa.

## Puertas de fase

### Discovery

Registrar el problema, evidencia disponible, hipótesis, experimentos seguros y decisión pendiente. Termina creando una spec o documentando un descarte o ADR. Los resultados de un experimento no son una promesa de producto.

### Spec

Describir el problema y el comportamiento observable. Cada criterio de aceptación incluye una comprobación reproducible. Completar alcance, fuera de alcance, supuestos, riesgos e invariantes. La metadata debe indicar **Aprobación: pendiente** hasta la aprobación explícita de la persona usuaria.

### Design

Solo puede empezar con **Aprobación: aprobada**. Nombrar archivos y contratos reales, alternativas, seguridad, privacidad, compatibilidad, reversión, riesgos y ADR necesarios. Si cambia el comportamiento aprobado, volver a `spec`.

### Tasks y build

Descomponer el diseño en tareas pequeñas. Cada una declara objetivo, archivos, verificación y evidencia. Ejecutar y registrar la verificación inmediatamente después de cada tarea. No marcar una tarea si falla o no se ejecutó.

### Done

Exige tareas cerradas, verificación completa del repositorio, criterios de aceptación comprobados individualmente, documentación estable actualizada y revisión del diff. Ejecutar el validador estricto y la auditoría antes de actualizar el estado.

## Evidencia

Usar este formato debajo de cada tarea y criterio:

```text
- Método: comando, prueba manual reproducible o inspección concreta.
- Resultado: salida esencial y código de salida, si existe.
- Fecha: AAAA-MM-DD.
- Commit: SHA o «sin commit».
```

Una afirmación se marca como **observada**, **confirmada**, **inferida**, **supuesto** o **desconocida**. Las inferencias indican su base. Una comprobación anterior deja de ser evidencia suficiente cuando cambia el código, la configuración o el entorno que la afecta.

## ADR y documentación estable

Crear o actualizar un ADR cuando cambien invariantes, contratos, límites entre componentes, persistencia, seguridad, compatibilidad o decisiones difíciles de revertir. Tras cerrar una spec, trasladar a `docs/` el conocimiento que siga vigente.
