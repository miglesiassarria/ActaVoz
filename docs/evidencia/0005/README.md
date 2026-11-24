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
- El panel inferior izquierdo mostró texto parcial durante la grabación; se cerró con el botón X. El cierre al tocar fuera está implementado.
- Al detener, el pipeline escribió `transcripcion.json` con segmentos de micrófono (`me`) y sistema (`system-S1`), sin duplicados, y conservó `VozTemporal/system-S1.json` para una confirmación posterior.
- La app permaneció estable tras corregir la conversión de audio.

## Verificación de nombres y perfiles

- Sesión controlada con «Me llamo Ana» y «Soy Luis»: la UI mostró `Usar «Ana»` y `Usar «Luis»`; al confirmar Ana, el interlocutor quedó confirmado y persistido.
- Ajustes: se consultó, renombró y eliminó un perfil de prueba; el archivo quedó en `[]`.
- La sesión de prueba y el perfil temporal se eliminaron después.

## Privacidad local

- `lsof -nP -a -p <PID> -i` durante la app no mostró conexiones de ActaVoz.
- La suite completa funciona con red saliente denegada; el audio y los modelos permanecen en el Mac.

## Límites declarados

- La diarización real se midió en AMI (0012); en la captura de ActaVoz se detectó un interlocutor de sistema.
- El cierre al tocar fuera comparte gesto con el panel; la vía verificada es el botón X.
- macOS 26 no se ha probado; la evidencia es macOS 27.2.1/arm64.
