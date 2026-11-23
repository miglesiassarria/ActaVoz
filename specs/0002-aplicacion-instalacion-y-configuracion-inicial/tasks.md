# 0002 · Tareas

Estado: `done`. Base implementada y verificada el 2026-11-23. Límites registrados: macOS 26 no se prueba por falta de equipo y el acceso a carpetas solo se comprobó en la cuenta actual.

- [x] **T1. Crear aplicación base**
  - Objetivo: proyecto SwiftUI compilable y ventana principal en macOS 26/arm64.
  - Archivos: `ActaVoz/ActaVoz.xcodeproj`, `ActaVoz/ActaVoz/ActaVozApp.swift`, `ActaVoz/ActaVoz/AppShell.swift`, `ActaVoz/ActaVoz/FirstRunView.swift`, `ActaVoz/ActaVoz/AppBootstrap.swift`; núcleo en `ActaVoz/ActaVozCore/Sources/ActaVozCore/`.
  - Verificación: compilar el proyecto real y abrir la ventana; comprobar despliegue y arquitectura. AC1 y AC5.
  - Evidencia:
    - Método: `xcodebuild -project ActaVoz/ActaVoz.xcodeproj -scheme ActaVoz -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS,arch=arm64' build`; ejecución del binario y consulta de `CGWindowListCopyWindowInfo` filtrada por el proceso.
    - Resultado: BUILD SUCCEEDED. Bundle `app.actavoz.ActaVoz`, Mach-O thin arm64, firma ad-hoc, `MACOSX_DEPLOYMENT_TARGET = 26.0`. Ventana on-screen de 1078×706 y, tras los cambios de 0003, de 1100×720.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
- [x] **T2. Preparar ubicaciones sin pérdida de datos**
  - Objetivo: inicializar `~/.ActaVoz` y subcarpetas con rutas inyectables; resolver Library y Caches.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/StorageLocations.swift`, `AppSettings.swift`, `Bootstrap.swift`; pruebas en `ActaVozCore/Tests/ActaVozCoreTests/`.
  - Verificación: en raíz temporal crear dos veces, mantener centinela, simular error de escritura; reiniciar y verificar configuración y cachés. AC2 y AC3.
  - Evidencia:
    - Método: `./scripts/test-core.sh` con `testPrepareIsIdempotentAndKeepsExistingContent`, `testRootThatIsAFileIsRejectedWithoutDeletingIt`, `testUnwritableParentIsReportedAsCannotCreateDirectory`, `testSaveAndLoadRoundTrip` y `testCorruptedFileIsReportedInsteadOfSilentlyResetting`; en el equipo de la persona usuaria, apertura real, `centinela.txt` en `~/.ActaVoz/Notas`, cierre y segunda apertura.
    - Resultado: 43 pruebas, 0 fallos en el núcleo. La app creó `~/.ActaVoz/Notas` y `Directorios` (20:36), el centinela escrito a las 20:48 seguía intacto tras reabrir a las 21:36, y `config.json` conservó `hasCompletedFirstRun: true`.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
  - Límite: la comprobación real se hizo solo en la cuenta actual, no en una segunda cuenta de usuario.
- [x] **T3. Primer inicio opcional**
  - Objetivo: ofrecer configuración sin proveedor y permitir omitirla, con punto de integración para 0006.
  - Archivos: `FirstRunView.swift`, `AppShell.swift`, `AppBootstrap.swift` y `AppSettings.swift`.
  - Verificación: perfil aislado sin proveedor; comprobar acceso a configuración y continuación sin configurar. AC4.
  - Evidencia:
    - Método: primer arranque sin `config.json`, pantalla de bienvenida y elección de «Continuar sin proveedor» por la persona usuaria; segundo arranque con `open ActaVoz.app` sin argumentos y lectura de `config.json`.
    - Resultado: el primer arranque ofreció configurar un proveedor o continuar sin él; el segundo abrió directamente la biblioteca vacía sin repetir la bienvenida, con `hasCompletedFirstRun: true` guardado.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
- [x] **T4. Verificar plataforma de entrega**
  - Objetivo: comprobar funcionamiento en la plataforma objetivo; registrar límites de distribución y de versión.
  - Archivos: documentación de evidencia y configuración del proyecto.
  - Verificación: build real con despliegue 26.0 y arm64; ejecución en la versión de macOS disponible; registrar que macOS 26 no se prueba.
  - Evidencia:
    - Método: build Debug con `MACOSX_DEPLOYMENT_TARGET = 26.0`, `sw_vers`, `uname -m` y arranque de la app.
    - Resultado: compila con despliegue 26.0, Mach-O thin arm64 y funciona en macOS 27.2.1/arm64. No hay equipo con macOS 26; el riesgo quedó aceptado y declarado el 2026-11-23.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.

## Cierre

- [x] Registrar evidencia de cada tarea y criterio; revisar diff y alcance.
- [x] Actualizar `docs/verification.md` con comandos reales.
- [x] ADR de persistencia revisado con 0003 (`docs/adr/0001-persistencia-de-sesiones.md` y `0002-esquema-de-sesion.md`).
- [x] Ejecutar verificación completa, validador estricto y auditoría SDD.
- [x] Cambiar estado a `done` tras completar las verificaciones.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | Build Debug arm64, bundle firmado ad-hoc y ventana on-screen (2026-11-23). |
| AC2 | cumplido | Creación real de `~/.ActaVoz/Notas` y `Directorios`, centinela intacto tras reabrir y cero sesiones alteradas. Solo cuenta actual. |
| AC3 | cumplido | `config.json` real en Application Support; persistió tras cerrar y reabrir sin repetir la bienvenida. |
| AC4 | cumplido | Primer inicio con oferta de proveedor y opción de omitir; la app abrió la biblioteca sin proveedor. |
| AC5 | cumplido con límite | Compila con despliegue 26.0, arm64 y funciona en macOS 27.2.1; macOS 26 no se prueba por falta de equipo, aceptado el 2026-11-23. |
