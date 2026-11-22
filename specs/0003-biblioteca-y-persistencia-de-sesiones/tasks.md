# 0003 · Tareas de biblioteca y persistencia

Dependencias previas: proyecto base 0002 disponible; diseño de acceso a raíz y contratos mínimos de transcripción/chat acordados. Archivos indicados son rutas propuestas y deben ajustarse al proyecto real sin ampliar el alcance. Ninguna tarea se ha ejecutado.

- [ ] **T1. Raíz y modelos**
  - Objetivo: raíz inyectable, identidad, fecha, título y participantes; creación exclusiva de sesión y escritura segura.
  - Archivos: `ActaVoz/Library/SessionModels.swift`, `SessionRepository.swift` y pruebas de biblioteca.
  - Verificación: crear varias sesiones en raíz temporal, comprobar nombres únicos, título y fecha, y reabrir metadatos; simular colisión y fallo de escritura. Cubre AC3, AC5 y parte de AC8.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T2. Carpetas y movimiento**
  - Objetivo: crear y renombrar directorios sin anidar y mover sesiones completas sin sobrescribir ni salir de raíz.
  - Archivos: repositorio y pruebas de biblioteca.
  - Verificación: ejecutar AC2 y AC6; probar colisiones, enlaces simbólicos y errores con directorios temporales.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T3. Borrado y persistencia**
  - Objetivo: confirmación en UI, cancelación sin cambios y borrado completo de sesión o directorio confirmado.
  - Archivos: repositorio, vistas de biblioteca y pruebas.
  - Verificación: ejecutar AC7–AC8 con contenido ficticio, cancelar y confirmar; simular error de disco y comprobar que no se toca contenido fuera de raíz.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T4. Vistas y navegación**
  - Objetivo: barra lateral, Sin organizar, lista por fecha, detalle, cabecera y botón Nueva nota con punto de entrada de prueba.
  - Archivos: `LibraryView.swift`, `SessionView.swift` y pruebas.
  - Verificación: ejecutar AC1, AC9–AC11 con fixtures y acciones simuladas; reabrir una corrección de participante.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T5. Archivos y búsqueda**
  - Objetivo: conservar archivos acordados y buscar por título, transcripción, notas y resumen.
  - Archivos: repositorio, `LibrarySearch.swift` y pruebas.
  - Verificación: ejecutar AC4, AC12–AC13 con un término exclusivo por campo y archivos opcionales; verificar supervivencia al mover y reabrir.
  - Evidencia: método, resultado, fecha y commit pendientes.

## Cierre

- [ ] Ejecutar verificaciones de todas las tareas y registrar método, resultado, fecha y commit.
- [ ] Verificar cada criterio AC1–AC13 individualmente, registrar evidencia y revisar el diff.
- [ ] Actualizar documentación estable y ADR de persistencia; ejecutar verificaciones completas del repositorio, validador estricto y auditoría SDD.
- [ ] Actualizar spec e índice al estado real solo cuando el cierre esté completo.
