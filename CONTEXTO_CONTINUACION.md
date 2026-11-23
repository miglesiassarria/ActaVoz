# ActaVoz — contexto para continuar

## Estado actual

0002 y 0003 están en `done` desde el 2026-11-23: base de aplicación y biblioteca con persistencia, verificadas con pruebas (43 en el núcleo) y con capturas de interfaz en `docs/evidencia/0003`. macOS 26 queda fuera de alcance por falta de equipo. La siguiente unidad es 0004 (grabación), que depende de la investigación 0012 sobre captura dual; 0005–0011 siguen en `design` y 0012–0013 en `discovery`.

## Referencias

- [Definición](DEFINICION_PROYECTO.md): acuerdos de producto vigentes.
- [Seguimiento](PENDIENTES_DOCUMENTACION.md): casillas históricas y pendientes reales.
- [Índice de specs](specs/README.md): capacidades, dependencias y aprobación.
- [Entrega a agentes](docs/entrega-agentes.md): orden de trabajo, contratos y condiciones para verificar cada unidad.
- [Ejemplos](EJEMPLOS_PLANTILLAS.md): formatos ficticios aceptados.
- [Informe de revisión](docs/revision-auditoria.md): correcciones de la última auditoría y límites de la evidencia.

## Próximo trabajo

Plataforma decidida el 2026-11-23: macOS 26 o posterior en Apple Silicon. Completar la investigación [0012](specs/0012-viabilidad-captura-transcripcion-y-voz-local/discovery.md) con el acceso a carpetas en otra cuenta e instalación distribuida, la captura dual, la transcripción con audio real, la diarización y los perfiles; después refinar 0002 y 0003. En [0013](specs/0013-viabilidad-proveedores-contexto-y-oauth/discovery.md), continuar OAuth autorizado, inferencia, streaming, Llavero y estrategia de contexto largo. No afirmar viabilidad completa por una consulta de idiomas o del catálogo público.

## Evidencia disponible

Xcode 27.2 compila los experimentos de idiomas y carpetas. SpeechAnalyzer transcribió frases sintéticas cortas en español e inglés; se instaló el recurso inglés. La restricción de red al proceso cliente no demuestra desconexión de los servicios de macOS. Las pruebas de carpetas conservaron el centinela tanto en un home simulado como en el home real de la cuenta actual usando un ejecutable local sin sandbox; falta comprobar otra cuenta y la instalación distribuida. El catálogo público de OpenCode Go respondió sin credenciales; no se probó inferencia autenticada. Una prueba simulada de fragmentación conservó íntegro el texto, sin demostrar equivalencia semántica ni integración real. Los detalles y límites constan en cada discovery.

## Restricciones y preferencias

La API REST, adjuntos en chat, calendario y control de costes están fuera del alcance actual. Mantener audio y procesamiento de voz locales. El usuario solicita autonomía para corregir documentación y escoger detalles técnicos razonables; distinguir siempre acuerdos, propuestas y observaciones. No reabrir preguntas de producto ya resueltas salvo incompatibilidad demostrada.

Preparar casillas pendientes antes de tratar los temas; marcar la misma casilla al acordar y documentar una decisión. No añadir casillas ya cerradas para aparentar avance. Si se necesita una decisión del usuario, presentar opciones y recomendación; tras resolverla, presentar directamente el siguiente punto. Conservar cambios ajenos y no tocar datos personales ni credenciales para las pruebas.

El objetivo es macOS 26 o posterior en Apple Silicon. No hay equipo con macOS 26 para probarlo (confirmado el 2026-11-23): el despliegue apunta a 26.0, se valida en la versión disponible y el riesgo queda aceptado y declarado.
