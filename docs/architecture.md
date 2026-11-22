# Arquitectura

## Estado observado

El repositorio está en fase de definición. A fecha de esta instalación no contiene proyecto Swift, `Package.swift`, `.xcodeproj`, `.xcworkspace`, pruebas ni código de producción. La arquitectura descrita aquí separa dirección acordada de dependencias aún no validadas.

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
