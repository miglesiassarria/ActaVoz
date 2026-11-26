# Verificación del repositorio

## Estado actual

Existe un proyecto Swift para la unidad 0002: app SwiftUI en `ActaVoz/ActaVoz.xcodeproj` y paquete `ActaVozCore` con rutas, configuración y arranque. No hay todavía DMG, firma de distribución ni notarización; la firma actual es ad-hoc para desarrollo y no acredita la entrega.

## Comandos ejecutados

- **Compilar la app** (2026-11-23, salida 0):
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ActaVoz/ActaVoz.xcodeproj -scheme ActaVoz -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS,arch=arm64' build`
- **Probar el núcleo** (2026-11-26, 147 pruebas y 0 fallos):
  `./scripts/test-core.sh`, equivalente a `cd ActaVoz/ActaVozCore && swift test --disable-sandbox` con `TMPDIR` y `CLANG_MODULE_CACHE_PATH` dentro de `build/`.
- **Biblioteca de ejemplo** para revisar la interfaz sin datos reales:
  `cd ActaVoz/ActaVozCore && swift run --disable-sandbox ActaVozFixtures ../../build/fixtures --reset`, y después `ActaVoz.app/Contents/MacOS/ActaVoz -ActaVozRoot <ruta>` (solo en compilaciones de depuración). Sin `--reset` se niega a escribir sobre una ruta con contenido.
- **Composición de audio real** (2026-11-24): `./scripts/test-audio-composition.sh` genera dos fuentes con frecuencias distinguibles y un tramo recuperado; comprueba duración de 5 s, mezcla simultánea y ausencia de solape posterior.
- **Transcripción local y diarización** (2026-11-24): `swift test` incluye ASR real ES/EN con `say`, detección automática, perfiles, edición y pipeline. La misma suite se ejecutó con `sandbox-exec -p "(version 1)(allow default)(deny network-outbound)"` sobre el bundle compilado: 116 pruebas, 0 fallos.
- **App con FluidAudio 0.18.4** (2026-11-24): `xcodebuild ... CODE_SIGN_IDENTITY="ActaVoz Development"` compila y firma; una grabación real mostró panel en directo con texto parcial y una sesión con «Yo» y `system-S1`. La UI mostró sugerencias «Ana»/«Luis» y Ajustes permitió consultar, renombrar y eliminar un perfil. `lsof -a -p PID -i` no mostró conexiones de la app.
- **Resúmenes, síntesis y exportación** (2026-11-26): 13 pruebas nuevas (SummaryTests, SynthesisTests, ExportTests); generación con proveedor local y archivos resumen.md/sintesis.md; reproductor y menú Exportar.
- **Chat de sesión** (2026-11-26): `ChatTests` cubre contexto completo, historial, cola, error y chat.json ISO8601. Prueba manual con proveedor local y pregunta durante una grabación activa.
- **Proveedores** (2026-11-24): `ProviderTests` cubre OpenAI, Claude, Ollama, Llavero, selección de modelos, contexto y errores sin secretos; Ajustes se probó con un servidor local simulado (`OK: conexión correcta con Mock`).
- **Validación documental:** `python3 scripts/validate_sdd.py --strict` y `python3 scripts/audit_sdd.py`.

Notas de entorno: `-derivedDataPath` mantiene los artefactos dentro del repositorio. `--disable-sandbox` solo es necesario cuando la sesión del agente ejecuta SwiftPM dentro de una jaula que impide su sandbox interno; en un terminal normal basta `swift test`.

## Límite conocido

La captura real se comprobó con exportación de 24 s, pero lanzando el ejecutable desde el agente: NO verifica la atribución ni persistencia TCC del bundle abierto por Finder. Abrir/activar el panel solo consulta estados pasivos y no solicita permisos. ScreenCaptureKit se invoca por acción explícita. La firma actual es ad hoc con requisito cdhash, variable entre compilaciones; no hay identidades de firma válidas en el equipo según security find-identity. Actualización: Core Audio taps reemplaza ScreenCaptureKit para audio-only (ADR 0003). La copia fija ad hoc abierta por LaunchServices grabó dos veces con micrófono desactivado y reapertura entre ellas, sin nueva solicitud. Una identidad estable NO es requisito de esta alternativa. La ruta Debug se verificó tras recompilar (nuevo cdhash): capturó 12,01 s estéreo con señal no nula y sin el aviso falso de permiso. Se corrigió el cálculo que marcaba «sin permiso» antes de confirmar el arranque. La captura sin internet se verificó el 2026-11-24 con toda la salida de red denegada al proceso: 11,69 s grabados y procesados localmente. Quedan pendientes instalación descargada/otro Mac, garantía de TCC en compilaciones futuras, reconexión física de fuentes y sincronización entre dispositivos.

No se dispone de un equipo con macOS 26 (confirmado por la persona usuaria el 2026-11-23). El proyecto fija `MACOSX_DEPLOYMENT_TARGET = 26.0` y se ejecuta en macOS 27.2.1/arm64. La compatibilidad con macOS 26 no se comprueba y no debe declararse validada en ninguna evidencia.

## Entorno de prueba seguro

No introducir claves de proveedores, tokens OAuth, grabaciones personales ni datos de reuniones en el repositorio o en salidas de pruebas. Las pruebas de captura y de proveedores usarán datos controlados, directorios temporales y credenciales de prueba cuando se definan. Las pruebas actuales usan raíces temporales y no escriben en el home real.

## Evidencia de cierre

Cada tarea y criterio registra método, resultado, fecha y commit. Una spec terminada aporta además la salida de la verificación completa y una revisión del diff contra su fuera de alcance.
