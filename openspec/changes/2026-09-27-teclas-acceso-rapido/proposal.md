## Why

En Tickets el caret queda en **Buscar producto**. Elegir efectivo o QR exigía soltar el teclado y pulsar el ícono. Hacía falta un atajo que funcione ahí, definido en configuración y no hardcodeado en el botón.

## What Changes

- Capacidad OpenSpec nueva `teclas-acceso-rapido`.
- `id` del botón de método de pago = tooltip (`descripcion`) sin espacios y en minúsculas.
- Clave `configuracion_app.teclas-acceso-rapido` (JSON). Semilla en `73_teclas_acceso_rapido.sql`. No se toca `70_`.
- En Tickets, `[Shift] + 1` y `[Shift] + 2` hacen click en el botón habilitado. El foco en `#productSearchInput` no los bloquea y el carácter no entra en el buscador.

## Capabilities

### New Capabilities

- `teclas-acceso-rapido`: atajos de teclado de Tickets leídos de `configuracion_app`, resueltos por `id` del tooltip.

### Modified Capabilities

- Ninguna. El modal de ajustes ya lista cualquier clave de `configuracion_app`; no cambia su contrato.

## Impact

- `infinito-ai-front`: `metodos-pago.component.html`, `acceso-teclado.ts`, `acceso-teclado.service.ts`, `tickets.component.ts`, `tickets.component.html` (`id="productSearchInput"`).
- `pos-relational-data-service`: migración `73_teclas_acceso_rapido.sql` (no aplicada en esta sesión).

## Non-goals

- Librería de hotkeys.
- Cambiar `descripcion` de los métodos de pago para que coincida con el mapa.
- Atajos fuera de la vista Tickets.
- Editar `70_configuracion_app_leyendas.sql`.
- Narrativo `contextos-ia/` y sección de tester: no van en este change.
