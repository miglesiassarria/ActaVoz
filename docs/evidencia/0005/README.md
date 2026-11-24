# Evidencia de 0005 · Voz y participantes

Fecha: 2026-11-24. Entorno: macOS 27.2.1/arm64, Xcode 27.2, FluidAudio 0.18.4.

## Pruebas automáticas

- `cd ActaVoz/ActaVozCore && swift test`: **116 pruebas, 0 fallos**.
- La suite compilada se ejecutó con salida de red denegada al proceso:
  `sandbox-exec -p "(version 1)(allow default)(deny network-outbound)" /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents/xctest .build/out/Products/Debug/ActaVozCoreTests.xctest`
  Resultado: **116 pruebas, 0 fallos**, incluidas ASR ES/EN, detección automática y diarización simulada.
- `xcodebuild ... CODE_SIGN_IDENTITY="ActaVoz Development"`: **BUILD SUCCEEDED**.

## Prueba manual de la app

- Se grabó audio del sistema durante 10–40 s con `say` y audio de fondo.
- El panel inferior izquierdo mostró texto parcial durante la grabación; se cerró con el botón X y se añadió cierre al tocar fuera.
- Al detener, el pipeline escribió `transcripcion.json` con segmentos de micrófono (`me`) y sistema (`system-S1`), sin duplicados, y conservó `VozTemporal/system-S1.json` para una confirmación posterior.
- La app permaneció estable tras corregir la conversión de audio.

## Límites registrados

- AC1: el texto parcial se observó con audio de fondo; falta una prueba con voz limpia y comprobar el cierre al tocar fuera de forma aislada.
- AC3/AC15: las sugerencias locales están cubiertas por pruebas; falta una grabación real con «me llamo …».
- AC6: consulta y renombrado se observaron en Ajustes; la eliminación está cubierta por la prueba del almacén, pero no se repitió en la interfaz.
- AC7: la suite completa funciona con red saliente denegada, pero no se inspeccionó el tráfico de la app con un sniffer.
- La diarización real se midió en AMI (0012); en la captura de ActaVoz se detectó un interlocutor de sistema.
