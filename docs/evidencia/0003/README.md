# Evidencia de interfaz — 0003

Capturas tomadas el 2026-11-23 por el agente con el control de accesibilidad y captura de ventana (CUA) sobre la app compilada, usando la biblioteca de ejemplo generada con `ActaVozFixtures` (datos ficticios, sin información personal).

Método: se abrió la app con `-ActaVozRoot build/fixtures`, se navegó con clics reales y se capturó la ventana tras cada acción. Las fixtures se regeneraron al terminar.

| Archivo | Qué muestra | Criterio |
| --- | --- | --- |
| `01-biblioteca.webp` | Barra lateral con «Sin organizar» y «Clientes»; lista agrupada por fecha | AC1, AC11 |
| `02-directorio-clientes.webp` | Directorio seleccionado y lista filtrada a su sesión | AC11 |
| `03-sesion-notas.webp` | Sesión abierta con título, fecha, participantes y pestaña «Mis notas» | AC1, AC10 |
| `04-sesion-transcripcion.webp` | Transcripción con tiempos y nombres de interlocutor | AC4 |
| `05-busqueda.webp` | Búsqueda «presupuesto» con un único resultado | AC12 |
| `06-confirmar-borrado.webp` | Aviso de borrado con alcance y acciones Cancelar/Eliminar | AC7 |
| `07-nueva-nota.webp` | Aviso del botón «Nueva nota» que remite a 0004 | AC9 |
| `08-tras-reiniciar.webp` | Tras cerrar y reabrir: título editado y sesión borrada desaparecida | AC7, AC8, AC10 |

Limitaciones registradas:

- La edición de texto se hizo con eventos simulados. `Cmd+A` no seleccionó el contenido del campo y el título de prueba quedó como «Reunión de producto producto»; el valor se guardó y sobrevivió al reinicio, que es lo que se quería comprobar. Las fixtures se regeneraron después para dejar datos limpios.
- El aviso de borrado se presenta en una ventana aparte; la captura `06` recorta esa ventana, no la principal.
- No se probó el movimiento de una sesión con el menú «Mover a»; AC6 está cubierto por pruebas del repositorio.
