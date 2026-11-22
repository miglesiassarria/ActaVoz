# Verificación del repositorio

## Estado actual

El repositorio no contiene aún una aplicación Swift ni artefacto distribuible. Por tanto no hay comandos de build, tests, instalación, firma o notarización de ActaVoz que se puedan declarar válidos todavía.

## Comprobaciones disponibles ahora

- `python3 scripts/validate_sdd.py --strict`
- `python3 scripts/audit_sdd.py`

## Al introducir la aplicación macOS

La primera spec que añada un proyecto Swift debe sustituir esta sección por comandos realmente ejecutados. `python3 scripts/suggest_verification.py` reconoce `Package.swift`, `.xcodeproj` y `.xcworkspace` y puede sugerir verificaciones, pero no convierte sugerencias en evidencia.

La verificación de entrega deberá incluir el build del artefacto real, firma, notarización e instalación en un entorno seguro cuando esos elementos existan.

## Entorno de prueba seguro

No introducir claves de proveedores, tokens OAuth, grabaciones personales ni datos de reuniones en el repositorio o en salidas de pruebas. Las pruebas de captura y de proveedores usarán datos controlados, directorios temporales y credenciales de prueba cuando se definan.

## Evidencia de cierre

Cada tarea y criterio registra método, resultado, fecha y commit. Una spec terminada aporta además la salida de la verificación completa y una revisión del diff contra su fuera de alcance.
