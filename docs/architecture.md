# Arquitectura

## Estado observado

El repositorio contiene desde el 2026-11-23 un proyecto Swift para la unidad 0002: app SwiftUI en `ActaVoz/ActaVoz.xcodeproj` y paquete `ActaVozCore` con rutas, configuración y arranque. La app compila los fuentes del núcleo como grupo del proyecto y el paquete se usa para ejecutar sus pruebas; la decisión y sus límites están en [ADR 0001](adr/0001-persistencia-de-sesiones.md). El resto de componentes descritos abajo sigue sin implementar y sus dependencias no están validadas.

## Dirección técnica confirmada

| Área | Decisión o dirección | Estado |
| --- | --- | --- |
| Aplicación | macOS con Swift y SwiftUI | Confirmada para fase 1 |
| Captura | ScreenCaptureKit para audio del sistema y APIs de audio de Apple para micrófono | Dirección confirmada; integración pendiente |
| Persistencia de sesiones | `~/.ActaVoz`, con directorios del usuario en `Directorios/` y nuevas notas en `Notas/` | Confirmada; detalles de implementación pendientes |
| Configuración y secretos | Library, Caches y Llavero de macOS según el tipo de dato | Confirmada |
| Distribución | DMG directo, firmado y notarizado, fuera del Mac App Store y sin App Sandbox | Dirección prevista; entrega pendiente |
| API REST | Producto separado de fase 2 | Fuera del alcance actual |

## Componentes propuestos que requieren validación

- Un componente de captura conserva fuentes y marcas de tiempo separadas.
- Un componente de transcripción en directo evaluará SpeechAnalyzer con audio real.
- Un componente de diarización evaluará FluidAudio/Core ML con reuniones reales.
- Adaptadores de proveedores encapsularán autenticación, modelos y formatos de API.
- La biblioteca de sesiones opera sobre la estructura local de `~/.ActaVoz`.

No hay interfaces, esquemas ni módulos implementados todavía. Cada decisión que convierta estos componentes en contratos estables debe tener una spec y, si afecta a un límite duradero, un ADR.
