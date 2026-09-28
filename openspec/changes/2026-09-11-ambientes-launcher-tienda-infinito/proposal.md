## Why

Hace falta una caja standalone (Tienda Infinito) con hostname y correo propios, y un launcher que distinga dev-local / sandbox / esa caja en Windows, Linux y macOS. El Worker no debe mandar las pruebas de `pagos@` a la tienda.

## What Changes

- Capacidad OpenSpec `ambientes-launcher-tienda-infinito` (contratos vigentes en `openspec/specs/`).
- Worker + DNS + Email Routing para `tienda-infinito.mayaksoluciones.com` (hecho; inbound de caja **no** probado).
- Infinito Launcher: ComboBox ambiente, puente, Caddy, túnel solo-lectura, Preparar esta máquina.
- Health del front independiente del reloj de pared.

## Capabilities

### New Capabilities
- `ambientes-launcher-tienda-infinito`: tres ambientes, launcher portable, Worker por destinatario, túnel propio de caja, piloto pendiente.

### Modified Capabilities

## Impact

- `intinito-launcher`
- `puente-tienda/workers/email-inbound`
- `infinito-ai-front/server.js`
- Cloudflare (zona `mayaksoluciones.com`)
- Docs: `contextos-ia/ambientes-launcher-tienda-infinito.md`, `ARRANQUE-LOCAL-Y-SANDBOX.md`

## Non-goals

- Probar inbound de Bancolombia en esta laptop.
- Enrutar `pagos@` a la caja.
- SaaS multi-tienda genérico (`tiendaN`); solo el hostname piloto `tienda-infinito`.
