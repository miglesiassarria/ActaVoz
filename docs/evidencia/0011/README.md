# Evidencia de 0011 · Calidad y entrega

Fecha: 2026-11-26. Hardware: Apple M5 Pro, 48 GB, macOS 27.2.1.

## Ejecutado

- 145 pruebas del núcleo, 0 fallos.
- Build Release firmado con «ActaVoz Development»: correcto.
- DMG generado: build/ActaVoz-0.1.0-dev.dmg (13 MB).
- codesign --verify --deep --strict: correcto.
- spctl -a -vv: **rejected** (sin notarización).
- Única identidad de firma: «ActaVoz Development» autofirmada de desarrollo; no hay Developer ID.
- Ollama local disponible con qwen3.6-abliterated-local:35b-64k.

## Evidencia reutilizada

- AMI-SDM de 0012: DER 10,25 % / 5,8 %, 4/4 interlocutores, RTFx 120,2 / 116,2.
- ASR ES/EN y diarización de 0005.
- Suite con red saliente denegada de 0005/0006.

## Bloqueos

- AC5: no hay umbrales aprobados por la persona usuaria; no se declara estabilidad.
- AC6: la notarización requiere Developer ID y credenciales de Apple, descartadas para el proyecto; el artefacto no es instalable como estable.
- AC7: no se verificó el recorrido completo sin internet con un modelo local en la app; solo funciones locales y pruebas aisladas.
- No se comparó una reunión nueva bilingüe con referencia etiquetada; se reutiliza 0012.

## Prueba offline con Ollama (2026-11-26)

- `sandbox-exec` con `deny network-outbound` y permiso solo para localhost.
- `curl` a example.com falló; `/api/tags` de Ollama respondió.
- La app cargó la biblioteca, abrió una sesión y respondió a una pregunta usando qwen3.6 local; no hubo red externa.
- La respuesta tardó unos 15 s; no se usa como umbral.
- Se corrigió el prompt de chat para una sola instrucción de sistema, compatible con la plantilla de Ollama.

## Beta ad-hoc B1 (2026-11-27)

- Build Release ad-hoc: Signature=adhoc, TeamIdentifier=not set.
- codesign --verify --deep --strict: correcto.
- DMG: build/ActaVoz-0.1.0-beta.1.dmg; hdiutil verify correcto.
- SHA256: 7bb3a1baf2063681d573dec0a216125b994559bc95fca26cca91e2f36a36c849.
- spctl: rejected (esperado; no notarizado).
- Contenido: ActaVoz.app + INSTALAR.txt.
- Release GitHub: prerelease v0.1.0-beta.1.
