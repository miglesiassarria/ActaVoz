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

## Git y trunk-based

`main` es la única rama troncal y debe permanecer desplegable. Todo cambio relevante entra por una rama corta y una pull request; no se trabaja directamente sobre `main`.

### Ramas

- `spec/NNNN-slug` para una spec o funcionalidad. Usar el mismo `NNNN-slug` que `specs/NNNN-slug/`.
- `fix/slug` para un fallo reproducible y `chore/slug` para mantenimiento sin cambio de comportamiento.
- Una rama por entrega. Si una spec grande necesita varias entregas, cada una usa `spec/NNNN-slug-<porcion>` y se elimina al integrarse; nunca se mantiene una rama viva después del merge.
- Crear siempre desde `main` actualizado:

```bash
git switch main
git pull --ff-only
git switch -c spec/NNNN-slug
```

- Hacer commits pequeños y atómicos, en español y con el formato `tipo(NNNN): resumen`. El cuerpo debe referenciar los AC o tareas afectadas.
- Trabajar y commitear en local. **No publicar la rama hasta que la entrega esté terminada y validada.** No se suben commits parciales, trabajo en curso ni pull requests en borrador; GitHub no se usa como copia de seguridad.
- Publicar solo al cerrar la entrega: AC y tareas con evidencia, validadores en verde y diff revisado. En ese momento, `git push -u origin spec/NNNN-slug` y abrir la pull request. La única excepción es una petición explícita de la persona usuaria para subir cambios antes de terminar.

### Integración

- Mantener la rama local al día con `git fetch origin && git rebase origin/main`; resolver conflictos y repetir la verificación. No reescribir ramas compartidas ni hacer force-push a `main`.
- Antes de publicar: tareas y AC verificados, evidencia registrada, `python3 scripts/validate_sdd.py --strict`, `python3 scripts/audit_sdd.py` y revisión del diff contra el fuera de alcance. Si algo falla, se corrige en local; no se publica para «ver si pasa».
- La pull request explica la spec, los AC cubiertos, los comandos de verificación, los resultados y los riesgos.
- Estrategia por defecto: **squash merge** a `main`, para conservar un historial lineal y un commit por entrega. No se integra una rama con comprobaciones rojas ni una spec a medias.
- Si una spec necesita varias entregas, cada porción debe ser verificable y dejar `main` desplegable; no se mezcla comportamiento parcialmente verificado.

### Limpieza tras el merge

Activar en GitHub la eliminación automática de la rama de cabecera al fusionar. Después del merge, limpiar también la copia local:

```bash
git switch main
git pull --ff-only
git branch -d spec/NNNN-slug
git push origin --delete spec/NNNN-slug   # si no se borró automáticamente
git fetch --prune
```

- No reutilizar una rama ya fusionada: el siguiente trabajo empieza con una rama nueva desde `main`.
- Si una pull request se cierra sin fusionar, borrar igualmente la rama local y remota. El trabajo queda recuperable por sus commits, pero no se deja basura.
- Un hotfix sigue el mismo flujo con `fix/slug`; no se salta la pull request salvo emergencia explícita, y aun así se documenta y se limpia la rama.

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
