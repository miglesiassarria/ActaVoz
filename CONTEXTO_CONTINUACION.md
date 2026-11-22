# ActaVoz — contexto para continuar

## Estado actual

Fase de documentación y discovery de la primera versión de escritorio. No hay aplicación implementada. Las specs 0002–0011 siguen en `spec` y fueron aprobadas explícitamente por la persona usuaria el 2026-11-22; 0012 y 0013 siguen en `discovery`. Su aprobación permite avanzar al diseño conforme a las dependencias y al flujo SDD.

## Referencias

- [Definición](DEFINICION_PROYECTO.md): acuerdos de producto vigentes.
- [Seguimiento](PENDIENTES_DOCUMENTACION.md): casillas históricas y pendientes reales.
- [Índice de specs](specs/README.md): capacidades, dependencias y aprobación.
- [Ejemplos](EJEMPLOS_PLANTILLAS.md): formatos ficticios aceptados.
- [Informe de revisión](docs/revision-auditoria.md): correcciones de la última auditoría y límites de la evidencia.

## Próximo trabajo

Completar la investigación [0012](specs/0012-viabilidad-captura-transcripcion-y-voz-local/discovery.md), empezando por plataforma y acceso al directorio para refinar 0002 y 0003; continuar captura dual, transcripción con audio real, diarización y perfiles. En [0013](specs/0013-viabilidad-proveedores-contexto-y-oauth/discovery.md), continuar OAuth autorizado, inferencia, streaming, Llavero y estrategia de contexto largo. No afirmar viabilidad completa por una consulta de idiomas o del catálogo público.

## Evidencia disponible

Xcode 27.2 compila los experimentos de idiomas y carpetas. La consulta de idiomas declara español e inglés compatibles en este equipo, con recursos de español instalados. Las pruebas de carpetas conservaron el centinela tanto en un home simulado como en el home real de la cuenta actual usando un ejecutable local sin sandbox. Falta comprobar otra cuenta y la instalación distribuida. El catálogo público de OpenCode Go respondió sin credenciales; no se probó inferencia autenticada. Los detalles, comandos y límites constan en cada discovery.

## Restricciones y preferencias

La API REST, adjuntos en chat, calendario y control de costes están fuera del alcance actual. Mantener audio y procesamiento de voz locales. El usuario solicita autonomía para corregir documentación y escoger detalles técnicos razonables; distinguir siempre acuerdos, propuestas y observaciones. No reabrir preguntas de producto ya resueltas salvo incompatibilidad demostrada.

Preparar casillas pendientes antes de tratar los temas; marcar la misma casilla al acordar y documentar una decisión. No añadir casillas ya cerradas para aparentar avance. Si se necesita una decisión del usuario, presentar opciones y recomendación; tras resolverla, presentar directamente el siguiente punto. Conservar cambios ajenos y no tocar datos personales ni credenciales para las pruebas.
