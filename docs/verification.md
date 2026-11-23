# Verificación del repositorio

## Estado actual

Existe un proyecto Swift para la unidad 0002: app SwiftUI en `ActaVoz/ActaVoz.xcodeproj` y paquete `ActaVozCore` con rutas, configuración y arranque. No hay todavía DMG, firma de distribución ni notarización; la firma actual es ad-hoc para desarrollo y no acredita la entrega.

## Comandos ejecutados

- **Compilar la app** (2026-11-23, salida 0):
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ActaVoz/ActaVoz.xcodeproj -scheme ActaVoz -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS,arch=arm64' build`
- **Probar el núcleo** (2026-11-23, 13 pruebas y 0 fallos):
  `./scripts/test-core.sh`, equivalente a `cd ActaVoz/ActaVozCore && swift test --disable-sandbox` con `TMPDIR` y `CLANG_MODULE_CACHE_PATH` dentro de `build/`.
- **Validación documental:** `python3 scripts/validate_sdd.py --strict` y `python3 scripts/audit_sdd.py`.

Notas de entorno: `-derivedDataPath` mantiene los artefactos dentro del repositorio. `--disable-sandbox` solo es necesario cuando la sesión del agente ejecuta SwiftPM dentro de una jaula que impide su sandbox interno; en un terminal normal basta `swift test`. La ejecución en macOS 26 sigue pendiente.

## Entorno de prueba seguro

No introducir claves de proveedores, tokens OAuth, grabaciones personales ni datos de reuniones en el repositorio o en salidas de pruebas. Las pruebas de captura y de proveedores usarán datos controlados, directorios temporales y credenciales de prueba cuando se definan. Las pruebas actuales usan raíces temporales y no escriben en el home real.

## Evidencia de cierre

Cada tarea y criterio registra método, resultado, fecha y commit. Una spec terminada aporta además la salida de la verificación completa y una revisión del diff contra su fuera de alcance.
