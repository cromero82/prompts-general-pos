## Context

Dev y sandbox ya comparten el túnel `pos-local` (cotiza `:8080`, pos-sandbox `:8180`). Una tienda de producción no puede colgarse de esa laptop.

## Decisions

1. **Túnel remoto Cloudflare** `tienda-infinito` (config en dashboard + token local). CNAME dedicado. La laptop no añade ese hostname al `config.yml` de `pos-local`.
2. **Worker por substring** `tienda-infinito` en `message.to`. Más simple que parsear cada subdominio; suficiente para el piloto.
3. **Launcher observa `cloudflared`**, no lo arranca/para (el proceso suele vivir fuera del panel: brew, servicio Windows, `up.sh --tunnel`).
4. **Caddy y puente sí** los controla el launcher: sin ellos el Worker pega a un puerto muerto.
5. **Health Angular = puerto del `ng serve`**. El sidecar `:3001` no usa `Date.now()` para “listo” (rompe al simular fecha).

## Repos / artefactos

| Pieza | Dónde |
|---|---|
| Ambientes / puertos | `intinito-launcher/.../LaunchEnvironment.java` |
| Arranque OS | `OsSupport.java`, `scripts/prepare-host.sh`, `prepare-host.ps1` |
| Token | `~/.cloudflared/tienda-infinito.token` (no git) |
| Worker | `puente-tienda/workers/email-inbound/src/index.js` |

## Risks

- Elegir Tienda Infinito en la laptop y arrancar `cloudflared` con el token de prod = esa Mac **es** la caja.
- Compilar el launcher en Mac y copiar el JAR a Windows: JavaFX natives incorrectos.
- Catch-all de Email Routing sigue en **drop**; solo la regla literal `tienda-infinito@mayaksoluciones.com` entra al Worker.
