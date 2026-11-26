# 0006 · Tareas: Proveedores, modelos y credenciales

Estado: build. Reabierta el 2026-11-26 porque la verificación de UI y consumo no estaba completa.

- [x] **T1. Configuración, conexiones y Llavero**
  - Objetivo: AC1–AC3 y AC6.
  - Evidencia:
    - Método: pruebas de configuración, Llavero, OpenAI/Claude/Ollama; UI con servidor local.
    - Resultado: 11 pruebas de proveedores; JSON sin secretos; conexión simulada OK.
    - Fecha: 2026-11-24.
    - Commit: c7c0e88.

- [x] **T2. Modelos, contexto y errores**
  - Objetivo: AC4, AC5, AC7 y AC11–AC12 en núcleo.
  - Evidencia:
    - Método: transporte simulado, selección y división tras rechazo.
    - Resultado: cobertura exacta; errores sin secretos.
    - Fecha: 2026-11-24.
    - Commit: c7c0e88.

- [ ] **T3. Consumo en chat, resúmenes y nombres**
  - Objetivo: cerrar AC8–AC10 y la UI de AC11–AC12 con 0007/0008/0009.
  - Pendiente: integrar el proveedor en las funciones que consumen la transcripción.

- [ ] **T4. Verificación de extremo a extremo**
  - Objetivo: probar dos conexiones y reapertura, modelo enviado desde UI, errores de credencial y reintento/cambio de modelo.
  - Pendiente: repetir con la UI terminada.

## Cierre

- [ ] Completar T3 y T4.
- [ ] Actualizar AC y estado solo con evidencia.
