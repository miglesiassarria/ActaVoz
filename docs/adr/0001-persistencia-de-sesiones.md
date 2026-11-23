# ADR 0001: Persistencia y módulo de núcleo

- **Estado:** accepted
- **Fecha:** 2026-11-23
- **Spec relacionada:** 0002 y 0003

## Contexto

La definición del proyecto fija `~/.ActaVoz` para sesiones, Library para configuración y Caches para datos regenerables, con distribución directa sin App Sandbox. La unidad 0002 necesitaba una base implementable y verificable sin depender todavía de la biblioteca de 0003. Además, la compilación dentro de una sesión de agente no puede resolver paquetes Swift con Xcode porque su resolvedor escribe en el `~/Library` real, fuera del espacio permitido.

## Decisión

- Raíz de sesiones `~/.ActaVoz`, con `Notas/` y `Directorios/`; configuración en `Application Support/ActaVoz` y cachés en `Caches/ActaVoz`.
- Todas las rutas se construyen desde un `StorageLocations` inyectable. Ninguna prueba escribe en el home real: usan `StorageLocations.testing(root:)` con un directorio temporal.
- La creación de carpetas es idempotente y no borra ni sobrescribe contenido. Si una ruta existe y no es carpeta, se rechaza con `StorageError.pathIsNotDirectory`; los fallos de creación se informan como `cannotCreateDirectory`.
- La configuración se guarda como JSON con `Data.write(options: .atomic)` y se rechaza un archivo corrupto con `SettingsError.invalidContents` en lugar de reiniciarlo en silencio.
- El núcleo lógico vive en el paquete SwiftPM `ActaVoz/ActaVozCore` y sus pruebas se ejecutan con `swift test`. La app compila esos mismos fuentes como grupo sincronizado del proyecto, sin dependencia de paquete, para que el build no requiera resolución de paquetes.
- Sin App Sandbox y sin credenciales en la configuración básica.

## Alternativas descartadas

- **Añadir el paquete como dependencia del proyecto:** el resolvedor de Xcode escribe en `~/Library`; falló con la jaula de la sesión y obligaría a permisos ampliados para compilar.
- **Duplicar la lógica en la app:** habría dos fuentes de verdad para rutas, configuración y errores.
- **Guardar la configuración junto a las sesiones:** contradice la separación acordada entre Library, Llavero y Caches.
- **Reemplazo por borrado y escritura:** puede perder la versión válida anterior ante un fallo intermedio.

## Consecuencias

- Ventaja: build y pruebas reproducibles sin acceso al home real ni a la red.
- Coste: el proyecto compila dos veces el núcleo (app y paquete de pruebas) y hay que mantener coherentes sus ajustes de plataforma.
- Riesgo aceptado: la escritura real en `~/.ActaVoz` y en Library no está verificada dentro de la jaula del agente; debe comprobarse abriendo la app fuera de ella y en una cuenta distinta.

## Verificación y revisión

Revisar este ADR si 0003 define un esquema de sesión que cambie la raíz o el contrato de rutas, si se adopta App Sandbox, o si el proyecto pasa a depender del paquete como módulo. La señal que lo invalidaría es que la app no pueda crear `~/.ActaVoz` en la distribución prevista.
