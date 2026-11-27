# ADR 0008: Distribución beta ad-hoc por GitHub

- **Estado:** accepted
- **Fecha:** 2026-11-27
- **Spec relacionada:** 0011

## Contexto

El proyecto decidió no usar una cuenta de Apple Developer. Sin Developer ID no es posible notarizar el DMG y Gatekeeper rechaza la app. La persona usuaria aprobó la Vía B1: una beta ad-hoc honesta.

## Decisión

- Firmar la app en modo ad-hoc, sin certificado de distribución.
- Publicar un DMG como prerelease de GitHub, con SHA256 e instrucciones de apertura.
- No declarar notarización ni estabilidad; documentar el rechazo de Gatekeeper y el riesgo de TCC al cambiar de build.
- Mantener la posibilidad de migrar a Developer ID/notarización en el futuro sin cambiar la app.

## Consecuencias

- El usuario debe autorizar la app en Ajustes del Sistema o retirar la cuarentena.
- La firma ad-hoc cambia entre compilaciones y puede reiniciar permisos de micrófono/audio.
- No hay verificación de identidad del desarrollador.
- La release se marca como beta, no como entrega estable.

## Verificación

codesign --verify --deep --strict correcto; spctl rechaza (esperado); SHA256 publicado; instrucciones en el DMG. Evidencia en docs/evidencia/0011/README.md.
