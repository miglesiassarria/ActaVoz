# ActaVoz — contexto para continuar

## Estado actual

La unidad 0002 está en `build` con base implementada: app SwiftUI compilable, arranque con carpetas idempotentes y primer inicio omitible. T1 y T2 están verificadas el 2026-11-23; faltan el clic real de T3 y la ejecución en macOS 26 de T4. Las specs 0003–0011 siguen en `design` con diseños y tareas propuestos; las investigaciones 0012 y 0013 siguen en `discovery`.

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

El objetivo inicial es macOS 26 o posterior en Apple Silicon; su compatibilidad completa sigue pendiente de validación.
