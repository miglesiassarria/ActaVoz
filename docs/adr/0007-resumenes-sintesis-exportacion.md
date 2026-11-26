# ADR 0007: Resúmenes atómicos, síntesis separada y exportación local

- **Estado:** accepted
- **Fecha:** 2026-11-26

## Decisión

- El resumen se genera solo con transcripción y plantilla; nunca con notas.
- Se escribe en resumen.md solo tras éxito; un fallo conserva el archivo anterior.
- resumen.editado distingue edición manual y activa la confirmación de sobrescritura.
- La síntesis usa notas y resumen, se guarda en sintesis.md y registra un hash de fuentes para avisar de cambios.
- Exportación y copia son locales; la reproducción usa audio.m4a y se oculta si no existe.

## Consecuencias

- Sin historial de versiones por plantilla.
- La calidad semántica requiere evaluación en 0011.
