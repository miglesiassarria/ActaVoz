# 0004 · Diseño: Captura y recuperación

## Estado y dependencias

Diseño propuesto sobre spec aprobada; dependencias: 0002, 0003 y 0012. Las rutas siguientes son propuestas, no archivos existentes. Resolver las investigaciones y contratos compartidos antes de construir; si cambia comportamiento aprobado, volver a spec.

## Enfoque

CaptureCoordinator coordina estado idle, preparación, grabación, pausa, procesamiento y finalización; dos adaptadores de fuente entregan búferes con marcas temporales y se procesan por separado. La salida final se mezcla solo al conservar audio.

## Superficies propuestas

`Captura/CaptureCoordinator.swift; Captura/AudioSource.swift; Captura/RecordingView.swift; Captura/AudioRetention.swift` y pruebas correspondientes bajo `ActaVozTests/`. Ajustar rutas al proyecto real de 0002 sin alterar contratos aprobados.

## Contratos, datos y errores

Se adopta Core Audio Process Taps para audio del sistema, sin enumerar pantallas (ADR 0003). La prueba audio-only del bundle ad hoc abierto por LaunchServices produjo señal no nula y se repitió tras reabrir. Crear el tap no demuestra autorización: se mantiene el estado sin verificar hasta la acción explícita. La sincronización dual, reconexión y robustez de sesiones largas no se dan por validadas. Persistir progreso por fragmentos en sesión y recuperar lo efectivamente escrito; avisar en fallos. El cierre y la política de audio se resuelven como estados persistidos, sin borrar texto.

## Seguridad, compatibilidad y reversión

Audio y procesamiento de voz locales; credenciales únicamente en Llavero; pruebas en directorios temporales con datos ficticios. Preservar archivos ante errores y cancelar sin efectos destructivos. Versionar contratos persistidos y documentar migración y restauración antes de introducir cambios incompatibles. La compatibilidad macOS 26 y hardware requiere evidencia real.

## Riesgos y validación

La integración con las dependencias y el comportamiento en equipos reales requieren pruebas; dobles no sustituyen pruebas de extremo a extremo. Cada criterio de la spec conserva resultado pendiente hasta ejecutar y registrar método, resultado, fecha y commit. Evitar datos personales y claves en logs.

## ADR

Crear o actualizar ADR cuando el diseño cierre límites entre componentes, persistencia, seguridad o compatibilidad. No marcar decisiones de discovery como verificadas sin evidencia.
