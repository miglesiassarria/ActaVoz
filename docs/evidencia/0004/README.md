# Evidencia de interfaz — 0004

Captura del panel previo de «Nueva nota» tomada el 2026-11-23 por el agente con el control de accesibilidad (CUA) sobre la app compilada, con la biblioteca real vacía del equipo.

| Archivo | Qué muestra | Criterio |
| --- | --- | --- |
| `01-panel-preparacion.webp` | Idioma «Español», perfiles de voz activados, micrófono y audio del sistema activados, selector de micrófono, aviso de permisos y «Empezar» deshabilitado | AC1, AC4 |

Lo que se comprobó en vivo:

- El panel abre desde el botón «Nueva nota» y muestra los valores iniciales acordados.
- Con el audio del sistema denegado y el micrófono sin solicitar, «Empezar» está deshabilitado y aparece el aviso de que concede permiso.
- Al pulsar «Solicitar permisos» se lanza la petición de micrófono y la de grabación de pantalla. El diálogo del sistema no pertenece a la ventana de la app, así que el agente no puede verlo ni pulsarlo: quedó a la espera de la persona.

Limitación: no se ha completado una grabación real. La captura de micrófono y de audio del sistema y la combinación a m4a están implementadas, pero requieren que la persona conceda los permisos de macOS y reinicie la app para el audio del sistema.
