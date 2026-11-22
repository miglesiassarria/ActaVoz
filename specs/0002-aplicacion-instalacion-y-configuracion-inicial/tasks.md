# 0002 · Tareas propuestas

Ninguna tarea se ha ejecutado. Las rutas son propuestas y se ajustarán al proyecto real.

- [ ] **T1. Crear aplicación base**
  - Objetivo: proyecto SwiftUI compilable y ventana principal en macOS 26/arm64.
  - Archivos: `ActaVoz/ActaVoz.xcodeproj`, `ActaVozApp.swift` y pruebas.
  - Verificación: compilar proyecto real y abrir la ventana; comprobar ajuste de despliegue y arquitectura. AC1 y AC5.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T2. Preparar ubicaciones sin pérdida de datos**
  - Objetivo: inicializar `~/.ActaVoz` y subcarpetas con rutas inyectables; resolver Library y Caches.
  - Archivos: `StorageLocations.swift`, `AppBootstrap.swift` y pruebas.
  - Verificación: en raíz temporal crear dos veces, mantener centinela, simular error de escritura; reiniciar y verificar configuración y cachés. AC2 y AC3.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T3. Primer inicio opcional**
  - Objetivo: ofrecer configuración sin proveedor y permitir omitirla, con punto de integración para 0006.
  - Archivos: `FirstRunView.swift`, `AppSettings.swift` y pruebas.
  - Verificación: perfil aislado sin proveedor; comprobar acceso a configuración y continuación sin configurar con doble. AC4.
  - Evidencia: método, resultado, fecha y commit pendientes.
- [ ] **T4. Verificar plataforma de entrega**
  - Objetivo: comprobar funcionamiento en macOS 26 sobre Apple Silicon; registrar límites de distribución.
  - Archivos: documentación de evidencia y configuración del proyecto.
  - Verificación: ejecutar build real en entorno macOS 26, registrar versión, arquitectura, comando y resultado. AC5. Firma y DMG se verifican en 0011.
  - Evidencia: método, resultado, fecha y commit pendientes.

## Cierre

- [ ] Registrar evidencia de cada tarea y criterio; revisar diff y alcance.
- [ ] Actualizar `docs/verification.md` con comandos reales y ADR de persistencia.
- [ ] Ejecutar verificación completa, validador estricto y auditoría SDD.
- [ ] Cambiar estado e índice solo tras completar todas las verificaciones.
