# 0002 · Diseño de la aplicación base

## Estado y alcance

Spec aprobada por la persona usuaria. App nativa Swift/SwiftUI, macOS 26 o posterior y Apple Silicon. El repositorio aún no contiene proyecto Swift: las rutas y nombres siguientes son propuestas. La compatibilidad real en macOS 26 requiere un equipo o entorno que lo ejecute; las pruebas actuales corresponden a otro macOS.

## Estructura y arranque

- Crear `ActaVoz/ActaVoz.xcodeproj` y fuentes propuestas bajo `ActaVoz/ActaVoz/`: `ActaVozApp.swift`, `AppBootstrap.swift`, `StorageLocations.swift`, `FirstRunView.swift`, `AppSettings.swift`; pruebas bajo `ActaVoz/ActaVozTests/`.
- `ActaVozApp` crea dependencias y presenta ventana; `AppBootstrap` recibe URLs inyectables y prepara raíz y configuración antes de habilitar acciones dependientes de disco.
- Usar `FileManager.homeDirectoryForCurrentUser` para `.ActaVoz`, crear `Notas` y `Directorios` con creación idempotente; verificar errores y presentar aviso comprensible sin borrar ni sobrescribir contenido. En pruebas inyectar un directorio temporal, nunca el home real.
- Configuración básica en ubicaciones de Library resueltas mediante `FileManager`; cachés regenerables en Caches. La spec 0006 implementa claves en Llavero y la configuración real de proveedores. Ninguna credencial se guarda en configuración básica ni logs.
- Sin proveedor activo, presentar acceso a configuración y opción de omitir. Definir interfaz inyectable para apertura de ajustes y estado del proveedor; usar doble en 0002 y sustituirlo por integración real en 0006. Omitir permite entrar a la ventana; las funciones locales reales pertenecen a sus respectivas specs.

## Compatibilidad y contratos

Configurar despliegue macOS 26 e incluir arquitectura arm64. Distribución DMG, firma y notarización pertenecen a 0011. No configurar App Sandbox para distribución directa prevista; validar la elección y permisos reales en la entrega. No instalar componentes ni configurar proveedor por defecto. Si un componente futuro requiere datos nuevos, versionar sus contratos y definir migración antes de escribir datos existentes.

## Riesgos y verificación

- La prueba actual de home real usa ejecutable local sin sandbox en macOS 27.2.1, no una app instalada ni macOS 26; AC5 requiere evidencia en macOS 26.
- Probar raíz inaccesible, repetición y centinela en raíz temporal; no declarar éxito si falla la escritura. Evitar dependencias de capturas, proveedores o credenciales reales para cerrar 0002.
- El contrato compartido de rutas con 0003 debe usar la misma raíz inyectada; registrar un ADR de persistencia antes de cerrar la implementación.
