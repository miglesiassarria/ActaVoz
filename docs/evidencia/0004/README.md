# Evidencia de interfaz — 0004

Captura del panel previo de «Nueva nota» tomada el 2026-11-23 por el agente con el control de accesibilidad (CUA) sobre la app compilada, con la biblioteca real vacía del equipo.

| Archivo | Qué muestra | Criterio |
| --- | --- | --- |
| `01-panel-preparacion.webp` | Idioma «Español», perfiles de voz activados, micrófono y audio del sistema activados, selector de micrófono, aviso de permisos y «Empezar» deshabilitado | AC1, AC4 |

Lo que se comprobó en vivo:

- El panel abre desde el botón «Nueva nota» y muestra los valores iniciales acordados.
- Con el audio del sistema denegado y el micrófono sin solicitar, «Empezar» está deshabilitado y aparece el aviso de que concede permiso.
- Al pulsar «Solicitar permisos» se lanza la petición de micrófono y la de grabación de pantalla. El diálogo del sistema no pertenece a la ventana de la app, así que el agente no puede verlo ni pulsarlo: quedó a la espera de la persona.

## Corrección y grabación real (2026-11-23)

La evidencia inicial anterior no demostraba captura. Tras el fallo reportado por la persona se encontraron una clasificación concluyente basada solo en CGPreflightScreenCaptureAccess, un AudioBufferList insuficiente para estéreo planar y esperas síncronas durante exportación.

- Método: tres pruebas de permisos fallaron con la lógica anterior (57 pruebas, 3 fallos); tras la corrección, suite de 58 pruebas con 0 fallos, incluida copia de PCM interleaved y planar. Build Debug arm64 correcto.
- Método real: app lanzada con ACTAVOZ_ROOT apuntando a build/capture-regression; CUA mostró ambas fuentes «Permitido» sin cambiar ajustes. Grabación con tono sintético de 660 Hz, pausa, reanudación y parada.
- Resultado: se escribieron CAF distintos de micrófono y sistema; durante pausa mantuvieron exactamente 7 671 808 y 7 599 616 bytes, contador 00:20 sin avanzar. Tras reanudar, finalizó en 00:24 y «Procesada». El audio.m4a se decodificó con AVAudioFile: 24.0 s, 2 canales, 1 152 000 frames, RMS 0.0530095 y pico 0.256081. Esto verifica audio no nulo, no precisión de sincronización ni recuperación de dispositivos.
- Capturas: 02-permisos-corregidos.webp, 03-pausa-real.webp y 04-audio-procesado.webp.
- Fecha: 2026-11-23.
- Commit: sin commit (corrección local).

Límites: siguen sin validarse desconexión global de internet, recuperación real tras caída, selección efectiva del micrófono, reconexión de dispositivos y repregunta de audio pendiente al reabrir. La spec permanece en build. Audio de prueba solo en build/ (ignorado por Git), no se adjunta a la evidencia versionada.

## Bucle de permisos y firma (2026-11-23, 22:40–22:45)

La prueba de 24 s se lanzó directamente como proceso hijo del agente. Demuestra captura, pero NO demuestra que los permisos pertenezcan al bundle abierto por Finder/LaunchServices. Se retira cualquier conclusión anterior de persistencia de TCC basada en esa prueba.

- Defecto reproducido por inspección: abrir el panel y recibir didBecomeActive ejecutaba SCShareableContent, que puede solicitar autorización; el botón además solicitaba CoreGraphics incondicionalmente.
- Corrección: consultas pasivas al abrir/activar; petición de ScreenCaptureKit solo por acción explícita, sin CGRequest duplicado; solicitudes serializadas y limitadas a fuentes seleccionadas.
- Regresión: pruebas de política fallaron antes de corregir; suite posterior de 62 pruebas con 0 fallos y build Debug correcto.
- Firma observada: codesign -d -r- --verbose=4 muestra Signature=adhoc, TeamIdentifier no establecido y requisito designado basado en cdhash. security find-identity -v -p codesigning devolvió 0 identidades válidas. El hash cambió al recompilar. No se modificaron certificados, Llavero ni la base TCC.
- Verificación real: dos aperturas del mismo bundle mediante open -n, con cierre entre ambas y sin recompilar, y apertura de Nueva nota por CUA. No hubo solicitud automática; ambos permisos se muestran no confirmados en este artefacto. No se pulsó Solicitar permisos ni se afirmó que persistieran autorizaciones concedidas a otra compilación.
- Pendiente: identidad de firma estable y prueba conceder → cerrar → abrir por LaunchServices. Un interruptor visible en Ajustes no demuestra que el binario recién recompilado satisfaga el requisito de la autorización anterior.
- Fecha: 2026-11-23. Commit: 75d61cd.

## Alternativa Core Audio sin certificado (2026-11-23, 22:58–23:00)

- Se abandonó la enumeración de pantalla: CoreAudioSystemTap usa CATapDescription, agregado privado e IO de audio; Info.plist declara NSAudioCaptureUsageDescription. No se creó ni importó certificado.
- Se autorizó la copia fija anterior mediante Añadir de Ajustes, sin borrar/resetear TCC; ScreenCaptureKit siguió rechazando tras reinicio. No se usó esa vía para afirmar éxito.
- Prueba definitiva: build/audio-only-v2/ActaVoz.app abierto por open -n (LaunchServices), firma ad hoc cdhash d4013dcfb522cd58a7c49c520be3c70ca3c0c89d. Micrófono desactivado. Empezar → tono externo 660 Hz → Detener.
- Primera salida de prueba: 22.773333 s, 2 canales, 1 093 120 frames, RMS 0.0863363916, pico 0.61038965.
- Cierre y reapertura del mismo bundle, sin recompilar ni volver a solicitar permisos. Segunda salida: 17.301333 s, 2 canales, 830 464 frames, RMS 0.1046270545, pico 0.79359496. Ambas llegaron a Procesada.
- Capturas 05-coreaudio-sistema.webp y 06-coreaudio-reapertura.webp. Solo las sesiones creadas por estas pruebas fueron medidas; las anteriores no se modificaron.
- ZIP exacto de la copia validada: build/audio-only-v2/ActaVoz-audio-only-verificada.zip; SHA256 a1bda37696541f8d0fbc1d8e9d72449cbacf6cd7300b414068bddb3a13d22b38. No publicado en GitHub.
- Revisión posterior: crear/destruir un tap solo prueba disponibilidad, no permiso; se eliminó ese falso positivo en fuentes y se añadieron defensas de inicio. Build y suite de 64 pruebas pasan. Esa revisión no modifica el ZIP fijo probado.
- Fecha: 2026-11-23. Commit: 75d61cd.
- Límites: no demuestra continuidad tras recompilar, Gatekeeper de descarga, otro Mac, sincronización dual ni reconexión de dispositivos. La spec sigue en build.

## Aviso falso corregido en la compilación Debug (2026-11-23, 23:13–23:15)

El usuario reportó que build/DerivedData/Build/Products/Debug/ActaVoz.app seguía mostrando «Sin permiso para Audio del sistema» y no capturaba. La reproducción mostró que sí capturaba: el aviso era falso.

- Causa: RecordingController calculaba missingSources antes de que el arranque confirmara el tap y mostraba «Sin permiso» para un estado aún sin verificar.
- Corrección: recalcular disponibilidad después de driver.start y antes de warningIfMissing. Prueba testUnverifiedSystemSourceDoesNotWarnAfterSuccessfulStart con micrófono desactivado.
- Verificación en la ruta Debug: compilación dc573b8b… mostró aviso falso pero audio.m4a de 21.0027 s, 2 canales, RMS 0.0489243. Tras corregir y recompilar (cdhash db3ac3dcc38b0c0ebf59f2c1b209076ebc9289a1): sin aviso, 12.0107 s, 2 canales, RMS 0.1238746, pico 0.9042447, estado Procesada.
- Esto demuestra captura tras cambiar la compilación (otro cdhash). No demuestra que cualquier compilación futura conserve TCC para siempre ni sustituye la prueba en otro Mac.
- Suite: 65 pruebas, 0 fallos. Fecha: 2026-11-23. Commit: 75d61cd.

## Recuperación tras caída real (2026-11-23, 23:22–23:26)

- Preparación: raíz aislada build/recovery-test y build/debug-root.txt leído solo en DEBUG; no se usó la biblioteca personal.
- Método: grabación con solo audio del sistema; tras existir grabacion.json se ejecutó kill -9 sobre el proceso.
- Resultado al reabrir: panel «Recuperar grabación» automático con Reanudar, Dar por terminada y Ahora no; sin formulario de nota nueva.
- Reanudar: restauró fuente, idioma y tiempo del marcador, escribió AudioFuentes/sistema-8E727BE4-….caf y exportó audio.m4a de 8,650666 s, 2 canales, RMS 0,0762370, pico 0,1848260; contador 00:30 al detener.
- Dar por terminada: eliminó grabacion.json, abrió la sesión y no borró el audio existente.
- Regresión: testRecoveredRecordingKeepsElapsedTime; suite de 66 pruebas con 0 fallos.
- Límite: la caída fue kill -9, no un corte de energía; no se probó caída durante la exportación ni disco lleno. La transcripción no existe aún, así que «conservar lo transcrito» no aplica todavía.
- Fecha: 2026-11-23. Commit: 3e976e6 (base) + este incremento.

## Finalización y audio pendiente (2026-11-24, 19:08–19:11)

- AC13 Guardar: sesión temporal con audio-pendiente.json y sistema-prueba.caf. Al abrir apareció «Audio pendiente de decisión». Guardar produjo audio.m4a de 3,0 s (2 canales, RMS 0,12945) y eliminó marcador y CAF.
- AC13 Borrar: segundo CAF pendiente. Borrar eliminó marcador y CAF, no creó m4a y conservó sesion.json.
- AC8: grabación real con solo audio del sistema, detenida a 01:46; estado «Procesada», botón «Generar resumen» y audio.m4a de 105,696 s (2 canales, RMS 0,14106, pico 0,63126).
- AC12 (histórico): el intento por AppleScript devolvió -10004, pero eso no demuestra que falte permiso. El 2026-11-24 se comprobó que DeepSeek Harness → System Events ya estaba activado. Queda validar Cmd+Q y las dos respuestas de cierre sobre la integración actual.
- Suite: 66 pruebas, 0 fallos; build correcto.
- Fecha: 2026-11-24. Commit: d051cac.

## Recuperación con tramos y cierre (2026-11-24, 19:42–19:52)

- AC12: Cmd+Q real mostró «Se está grabando»; «Seguir grabando» mantuvo el contador. «Detener y cerrar» exportó audio de 19,3725 s (2 canales, RMS 0,050947) y terminó el proceso. Repetido en pausa: exportó 11,4288 s (RMS 0,066328) y también terminó.
- AC7 con motor temporal: grabación de sistema, tono 440 Hz, kill -9; al reabrir apareció «Recuperar grabación»; «Reanudar» capturó un segundo tramo; tras corregir la planificación, «Dar por terminada» exportó audio.m4a de 21,8888 s con el primer tramo (2,9055–10,0095 s) y el segundo (12,7901–21,8888 s) en orden, separados por el hueco real de la caída.
- Fallo encontrado y corregido: el sidecar podía quedar una muestra por detrás del CAF tras la caída y los fragmentos se ordenaban por UUID, no por tiempo. Se incorpora la cola realmente presente y se ordena por sessionStart, validando solapes por fuente.
- AC11: prueba reproducible scripts/test-audio-composition.sh; 5,0 s con 440 y 880 Hz simultáneos y 1320 Hz posterior; amplitudes 0,2 cada uno y fuga tardía de 440 Hz 3e-9.
- Suite: 84 pruebas, 0 fallos. Build Debug correcto.
- Límites: la sincronización de dos dispositivos físicos no se ha medido; AC6 nativo (reconexión automática) sigue sin implementar; AC10 sin verificar; AC14 solo con dobles.
- Fecha: 2026-11-24. Commit: d051cac.

## Captura sin internet (2026-11-24, 19:53)

- Método: app abierta con sandbox-exec y perfil que deniega toda salida de red; se comprobó en el mismo perfil que una conexión TCP a 1.1.1.1:443 devuelve PermissionError.
- Resultado: grabación solo de sistema con tono 440 Hz; estado «Procesada»; audio.m4a de 11,6920 s, 2 canales, RMS 0,104774 y pico 0,832068.
- Límite: se bloquea la salida de red del proceso, no se apaga la interfaz del Mac; demuestra que captura y exportación no dependen de internet.
- Fecha: 2026-11-24. Commit: pendiente.

## Monitor nativo de fuentes (2026-11-24)

- Implementado en SystemCaptureDriver: si una fuente activa no entrega búferes durante 4 s, se emite sourceLost, se cierra el tramo, se crea uno nuevo con sessionStart posterior al último sample persistido y se reinician las fuentes. sourceRecovered solo se emite tras un búfer escrito con la época vigente.
- La pausa por pérdida ya no pausa el escritor, para permitir confirmar el primer búfer y reanudar.
- Pruebas: 84 con 0 fallos, incluida la semántica de pausa por pérdida; BUILD SUCCEEDED.
- Límite: no se pudo verificar con desconexión física. Al recompilar cambia el cdhash de la firma ad hoc y TCC volvió a «Sin solicitar»; la ventana quedó bloqueada esperando permisos.
- Fecha: 2026-11-24. Commit: pendiente.

## TCC sin diálogo y bloqueo de interfaz (2026-11-24)

- Tras recompilar (nuevo cdhash ad hoc), micrófono y audio del sistema vuelven a «Sin solicitar». Al pulsar «Solicitar permisos», macOS no mostró diálogo y la app quedó indefinidamente en «Comprobando permisos…», con todos los botones deshabilitados.
- Corrección: la solicitud de micrófono y la comprobación de audio del sistema tienen un límite de 8 s. Al vencer, se refresca la disponibilidad y la interfaz vuelve a permitir Cancelar, Empezar o Solicitar de nuevo.
- Verificación real: se pulsó «Solicitar permisos»; a los 10 s los botones «Solicitar permisos», «Cancelar» y «Empezar» estaban habilitados y el estado seguía «Sin solicitar». No se concedió ningún permiso.
- Límite: no se confirmó el diálogo TCC ni se pudo validar la reconexión física de AC6.
- Fecha: 2026-11-24. Commit: pendiente.
