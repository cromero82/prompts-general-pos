# Contexto IA — Ambientes, launcher y Tienda Infinito

**Última actualización:** 2026-09-13.  
**OpenSpec:** `openspec/specs/ambientes-launcher-tienda-infinito/spec.md`  
**Ops (instalación en la PC de tienda):** `MIGRATE-TIENDA-INFINITO-V02.md`  
**Ops (comandos laptop):** `ARRANQUE-LOCAL-Y-SANDBOX.md`  
**Plan histórico túnel/email:** `interceptar-pagos-tunel.md`  
**QA:** `CONTEXTO-TESTER-POS.md` (ambientes). Sin detalle de firewall/túnel para la tester.

## Qué es

Tres stacks que no se mezclan:

| Ambiente | URL típica | BD | Para qué |
|---|---|---|---|
| Dev local | `http://localhost:4200` / `https://cotiza.mayaksoluciones.com` | `controlneg_rmx_db` | Desarrollo |
| Sandbox | `http://localhost:4210` / `https://pos-sandbox.mayaksoluciones.com` | `controlneg_rmx_db_sandbox` | Tester |
| Tienda Infinito | `https://tienda-infinito.mayaksoluciones.com` (Caddy `:8280`) o `http://localhost:4220` | `controlneg_rmx_db_v02` | Caja v02, **junto** a la productiva vieja (`:4200` / `:8088` / `controlneg_rmx_db`) |

El correo `pagos@mayaksoluciones.com` alimenta **cotiza + sandbox**. La caja usa **`tienda-infinito@mayaksoluciones.com`**. El Worker mira si el `To` contiene `tienda-infinito`.

## Launcher (`intinito-launcher`)

Repo con typo histórico. Panel JavaFX: ComboBox Ambiente (**Dev local / Sandbox / Caja actual / Tienda Infinito**), filas de servicios, Iniciar todo.

**Tienda Infinito** no aplica scripts: la BD `controlneg_rmx_db_v02` se exporta ya migrada (mismo nombre en la PC de tienda). El launcher solo arranca la pila. Los SQL del manifiesto (`67_`, etc.) son históricos / laptop.

**Caja actual** = productiva vieja (`:4200` / `:8088` / `controlneg_rmx_db`) **sin** Caddy ni notificaciones. **Tienda Infinito** = pila nueva (`:4220` / `:8288` / puente `:8295` / Caddy `:8280`) y **sí** recibe `tienda-infinito@mayaksoluciones.com`.

Prompt Cursor en la PC de caja: `CURSOR-IA-PC-TIENDA-V02.md`.

- **Controla:** Seguridad, SMTP, POS, Puente, Frontend, Caddy.
- **Túnel Cloudflare:** se instala como **inicio de sesión** y funciona en Windows, macOS y Linux (LaunchAgent / systemd user + XDG / tarea ONLOGON). Iniciar y Reiniciar reaniman ese servicio en cualquier SO. Detener todo **no** lo mata. Dev/sandbox = `pos-local`; Tienda Infinito = token propio.
- **Solo muestra estado de arranque Docker:** Base de datos (se inicia a mano).
- **Preparar esta máquina:** `prepare-host.sh` / `prepare-host.ps1` (PATH + firewall LAN) **y** deja el autostart del túnel.
- Compilar el JAR **en el SO donde corre** (`mvn -DskipTests package` → `target/infinito-launcher.jar`).

Al cerrar el panel los procesos **siguen**. El dueño de `:8088` / `:4200` es el humano (pruebas de fecha del sistema).

Frontend “Iniciando” eterno: el health `:3001` usaba el reloj de pared; si atrasas la fecha del Mac, 503 para siempre. Ya se corrige con uptime + “`:4200` abierto = Ejecutándose”.

## Cloudflare (listo, inbound de caja no probado)

- Worker vars: `INBOUND_URL`, `INBOUND_URL_SANDBOX`, `INBOUND_URL_TIENDA`.
- DNS: `tienda-infinito` → túnel UUID `cf623430-1915-4236-82cf-7256421a9102` (**no** `pos-local`).
- Token (secreto, no git): `~/.cloudflared/tienda-infinito.token`
- Plantilla YAML: `intinito-launcher/src/main/resources/cloudflared/config-tienda-infinito.yml.example`

Caddy es el portero local; el túnel entrega a **`:8280`** (no al `:8080` de la caja vieja). `./up.sh --tunnel` del sandbox **no** levanta el Caddy de desarrollo `:8080`.

SQL para crear la BD v02: `create-db-controlneg-rmx-db-v02.sql`. Perfil Spring `tienda-infinito` en POS, puente y security.

## Retomar en otra sesión (piloto)

Runbook en la PC de tienda: **`MIGRATE-TIENDA-INFINITO-V02.md`**.

## Código

- Launcher: `intinito-launcher` (`LaunchEnvironment`, `ServiceManager`, `OsSupport`, `PrepareHost`, `CloudflaredAutostart`, `hello-view.fxml`)
- Worker: `puente-tienda/workers/email-inbound/`
- Health front: `infinito-ai-front/server.js`
