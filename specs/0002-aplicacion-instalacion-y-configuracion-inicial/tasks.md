# 0002 · Tareas

Estado: `build`. T1, T2 y T4 están verificadas; T3 tiene la lógica y la compilación verificadas pero falta el clic en la interfaz. AC2 y AC3 siguen parciales porque la app no se ha ejecutado fuera de la jaula del agente.

- [x] **T1. Crear aplicación base**
  - Objetivo: proyecto SwiftUI compilable y ventana principal en macOS 26/arm64.
  - Archivos: `ActaVoz/ActaVoz.xcodeproj`, `ActaVoz/ActaVoz/ActaVozApp.swift`, `ActaVoz/ActaVoz/AppShell.swift`, `ActaVoz/ActaVoz/FirstRunView.swift`, `ActaVoz/ActaVoz/AppBootstrap.swift`; núcleo en `ActaVoz/ActaVozCore/Sources/ActaVozCore/`.
  - Verificación: compilar el proyecto real y abrir la ventana; comprobar despliegue y arquitectura. AC1 y AC5.
  - Evidencia:
    - Método: `xcodebuild -project ActaVoz/ActaVoz.xcodeproj -scheme ActaVoz -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS,arch=arm64' build`; ejecución del binario `ActaVoz.app/Contents/MacOS/ActaVoz` y consulta de `CGWindowListCopyWindowInfo` filtrada por el proceso.
    - Resultado: BUILD SUCCEEDED. Bundle `app.actavoz.ActaVoz`, Mach-O thin arm64, firma ad-hoc, `MACOSX_DEPLOYMENT_TARGET = 26.0`. Una ventana on-screen de 1078×706. No se inspeccionó visualmente ni se interactuó con ella.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
- [x] **T2. Preparar ubicaciones sin pérdida de datos**
  - Objetivo: inicializar `~/.ActaVoz` y subcarpetas con rutas inyectables; resolver Library y Caches.
  - Archivos: `ActaVozCore/Sources/ActaVozCore/StorageLocations.swift`, `AppSettings.swift`, `Bootstrap.swift`; pruebas en `ActaVozCore/Tests/ActaVozCoreTests/`.
  - Verificación: en raíz temporal crear dos veces, mantener centinela, simular error de escritura; reiniciar y verificar configuración y cachés. AC2 y AC3.
  - Evidencia:
    - Método: `./scripts/test-core.sh`; casos `testPrepareCreatesSessionsConfigurationAndCaches`, `testPrepareIsIdempotentAndKeepsExistingContent`, `testRootThatIsAFileIsRejectedWithoutDeletingIt`, `testUnwritableParentIsReportedAsCannotCreateDirectory`, `testSaveAndLoadRoundTrip`, `testCorruptedFileIsReportedInsteadOfSilentlyResetting`.
    - Resultado: 13 pruebas, 0 fallos. Creación repetida sin borrar el centinela; raíz que es un archivo rechazada como `pathIsNotDirectory` conservando su contenido; padre no escribible informado como `cannotCreateDirectory`; configuración guardada con reemplazo atómico y recuperada en un arranque nuevo.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
  - Límite: las pruebas usan raíces temporales. La app lanzada desde esta sesión no pudo escribir en el home real porque la jaula del agente lo impide; falta comprobarlo abriéndola fuera de la jaula y en una cuenta distinta.
- [ ] **T3. Primer inicio opcional**
  - Objetivo: ofrecer configuración sin proveedor y permitir omitirla, con punto de integración para 0006.
  - Archivos: `FirstRunView.swift`, `AppShell.swift`, `AppBootstrap.swift` y `AppSettings.swift`; pruebas `BootstrapTests`.
  - Verificación: perfil aislado sin proveedor; comprobar acceso a configuración y continuación sin configurar con doble. AC4.
  - Evidencia parcial:
    - Método: `BootstrapTests.testConfigurationSurvivesARelaunch` y compilación del flujo; no se pulsó el botón en la interfaz.
    - Resultado: 3 pruebas correctas; `hasCompletedFirstRun` persiste y un arranque nuevo lo recupera. El botón «Continuar sin proveedor» está conectado a ese mismo camino, pero el clic real no se comprobó.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.
- [x] **T4. Verificar plataforma de entrega**
  - Objetivo: comprobar funcionamiento en la plataforma objetivo; registrar límites de distribución y de versión.
  - Archivos: documentación de evidencia y configuración del proyecto.
  - Verificación: build real con despliegue 26.0 y arm64; ejecución en la versión de macOS disponible; registrar que macOS 26 no se prueba. Firma y DMG se verifican en 0011.
  - Evidencia:
    - Método: `xcodebuild … -destination 'platform=macOS,arch=arm64' build` con `MACOSX_DEPLOYMENT_TARGET = 26.0`; ejecución del binario y consulta de `CGWindowListCopyWindowInfo`; `sw_vers` y `uname -m` para la versión del equipo.
    - Resultado: compila con despliegue 26.0, Mach-O thin arm64 y abre ventana en macOS 27.2.1/arm64. La persona usuaria confirma el 2026-11-23 que no dispone de un equipo con macOS 26 y acepta que esa versión no se compruebe: el desarrollo apunta a ella y el riesgo queda declarado, no validado.
    - Fecha: 2026-11-23.
    - Commit: 0276b39.

## Cierre

- [ ] Registrar evidencia de cada tarea y criterio; revisar diff y alcance.
- [x] Actualizar `docs/verification.md` con comandos reales.
- [ ] ADR de persistencia: borrador redactado en `docs/adr/0001-persistencia-de-sesiones.md`; falta revisión con 0003.
- [ ] Ejecutar verificación completa, validador estricto y auditoría SDD.
- [ ] Cambiar estado a `done` solo tras completar todas las verificaciones.

## Resultado de criterios de aceptación

| Criterio | Resultado | Evidencia |
| --- | --- | --- |
| AC1 | cumplido | Build Debug arm64, bundle firmado ad-hoc y una ventana on-screen de 1078×706 (2026-11-23). |
| AC2 | parcial | Pruebas con raíz temporal: creación idempotente, centinela y errores de E/S. Falta home real fuera de la jaula y cuenta distinta. |
| AC3 | parcial | Configuración en directorio inyectable con reemplazo atómico y recarga tras reinicio. Falta comprobar la ruta real de Library. |
| AC4 | parcial | Lógica y persistencia verificadas; falta comprobar el clic real de omitir y el acceso a configuración. |
| AC5 | cumplido con límite | Compila con despliegue 26.0, arm64 y funciona en macOS 27.2.1; macOS 26 no se prueba por falta de equipo, aceptado por la persona usuaria el 2026-11-23. |
