## Purpose

Tres ambientes del POS en la misma máquina de desarrollo o en una PC de tienda: **dev-local**, **sandbox** y **tienda-infinito** (standalone de producción). El launcher (`intinito-launcher`, typo histórico del repo) arranca y para procesos; Cloudflare Email Routing + Worker + túnel entregan el correo de banco al puente correcto **sin mezclar** pruebas (`pagos@`) con la caja real.

**Piloto en la PC de tienda:** `MIGRATE-TIENDA-INFINITO-V02.md` (índice: `README.md`). El inbound real a la caja **no** se ha probado.

## Requirements

### Requirement: Tres ambientes mutuamente aislados

El launcher SHALL ofrecer un ComboBox de ambiente con: `dev-local`, `sandbox`, `caja-actual`, `tienda-infinito`. Cambiar de ambiente MUST detener lo que ese launcher haya arrancado y MUST usar puertos, carpeta de repos y hostname público de ese ambiente. Sandbox SHALL resolver repos bajo `{projects.base.path}/sandbox`. Dev-local, Caja actual y Tienda Infinito SHALL usar `{projects.base.path}` sin subcarpeta.

| Ambiente | Front | Caddy | Auth | POS | Puente | Health node | BD | Hostname público | Túnel |
|---|---|---|---|---|---|---|---|---|---|
| Dev local | 4200 | 8080 | 8081 | 8088 | 8095 | 3001 | `controlneg_rmx_db_v02` (login `controlneg_rmx_db`) | `cotiza.mayaksoluciones.com` | `pos-local` |
| Sandbox | 4210 | 8180 | 8181 | 8188 | 8195 | 3011 | `controlneg_rmx_db_sandbox` | `pos-sandbox.mayaksoluciones.com` | `pos-local` |
| Caja actual | 4200 | — | 8081 | 8088 | — | 3001 | `controlneg_rmx_db` | — | — |
| Tienda Infinito (v02) | 4220 | 8280 | 8281 | 8288 | 8295 | 3021 | `controlneg_rmx_db_v02` | `tienda-infinito.mayaksoluciones.com` | `tienda-infinito` (propio) |

Caja actual MUST NOT arrancar SMTP, puente, Caddy ni túnel (copia productiva local, sin notificaciones). Tienda Infinito SHALL recibir el correo Cloudflare (`tienda-infinito@mayaksoluciones.com` → Worker → puente `:8295`).

SMTP de desarrollo MAY compartir `:8082` entre dev y sandbox. Tienda Infinito SHALL usar SMTP `:8282`. En la PC de tienda, la **caja productiva actual** se queda en 4200 / 8081 / 8088 (y el puente viejo si lo hay); la pila v02 MUST NOT reutilizar esos puertos.

#### Scenario: Convivencia con la caja vieja
- **WHEN** en la misma PC corre la versión productiva actual y el launcher ambiente Tienda Infinito
- **THEN** Angular v02 escucha en `:4220`, el POS v02 en `:8288` y Caddy v02 en `:8280`, sin ocupar `:4200` ni `:8088`

#### Scenario: Base v02
- **WHEN** arrancan auth / POS / puente en ambiente Tienda Infinito
- **THEN** usan `jdbc:postgresql://localhost:5432/controlneg_rmx_db_v02` (no `controlneg_rmx_db`)

#### Scenario: Selector en el panel
- **WHEN** el operador abre Infinito Launcher
- **THEN** ve Ambiente y puede elegir Dev local, Sandbox, Caja actual o Tienda Infinito

### Requirement: Tienda Infinito no migra

El launcher MUST NOT mostrar **Ejecutar scripts** ni aplicar SQL. `controlneg_rmx_db_v02` SHALL llegar a la PC de tienda ya migrada (mismo nombre). MUST NOT dump/restore ni correr `migrate-tienda-infinito-v02.files` desde el panel.

#### Scenario: Panel Tienda Infinito
- **WHEN** el operador elige Tienda Infinito
- **THEN** solo ve Iniciar / Detener / Preparar esta máquina; no hay botón de scripts

#### Scenario: Caja actual
- **WHEN** el ambiente es Caja actual
- **THEN** no hay SMTP, puente, Caddy ni túnel

#### Scenario: No mezclar laptop y caja
- **WHEN** el operador elige Tienda Infinito en la laptop de desarrollo
- **THEN** el panel advierte que ese túnel es el de producción; MUST NOT usarse en esa laptop salvo que ella sea la caja

### Requirement: Arranque uno a uno o todos

El launcher SHALL permitir Iniciar / Detener / Reiniciar (y Actualizar git+build cuando aplique) para: Seguridad, SMTP, Lógica tienda, Puente, Frontend, Caddy. SHALL existir **Iniciar todo** / **Detener todo** / **Reiniciar todo** para esos mismos servicios (sin DB Docker). Iniciar todo SHALL asegurar el túnel Cloudflare de este ambiente si no está sano. Detener todo MUST NOT matar `cloudflared`.

#### Scenario: Iniciar puente solo
- **WHEN** el operador pulsa Iniciar en Puente en Dev local
- **THEN** arranca `puente-tienda` en `:8095` si el puerto no está sano

#### Scenario: Iniciar todo no toca DB y no mata el túnel
- **WHEN** el operador pulsa Iniciar todo
- **THEN** no arranca Postgres Docker; si el túnel no responde, instala/reanima el autostart de `cloudflared`

### Requirement: Túnel Cloudflare con autostart de sesión

El launcher SHALL instalar `cloudflared` como servicio de **inicio de sesión** en Windows, macOS y Linux (LaunchAgent, systemd --user + XDG autostart, tarea ONLOGON `/IT`) con `--metrics` en el puerto del ambiente, KeepAlive/Restart y ruta absoluta al binario. Al abrir el panel o pulsar Iniciar/Reiniciar en la fila Túnel, MUST reanimar ese servicio si no está sano, en cualquiera de esos sistemas. MUST NOT depender de un proceso hijo del launcher que muera al cerrar Java o al reiniciar el PC.

Dev/sandbox SHALL usar el conector `pos-local` (`~/.cloudflared/config.yml`). Tienda Infinito SHALL usar `tienda-infinito.token` (o `config-tienda-infinito.yml`). Detener todo MUST NOT desinstalar el autostart. La fila Base de datos MAY conservar abrir gestor; Iniciar todo MUST NOT parar/arrancar Postgres.

#### Scenario: Reinicio del computador
- **WHEN** el operador reinicia el PC e inicia sesión
- **THEN** `cloudflared` del ambiente vuelve solo y el launcher muestra Ejecutándose sin tener que pulsar Iniciar

#### Scenario: Fila túnel
- **WHEN** el autostart está sano
- **THEN** el estado del túnel es Ejecutándose; hay Iniciar (reanima) y Reiniciar, no Detener

### Requirement: Caddy y puente son servicios de primera clase

El correo de banco no llega al POS si faltan Caddy (portero local del hostname) o puente (`POST /api/email-inbound`). El launcher SHALL tratarlos como filas propias, no embebidos en `npm run start` del front.

Dev: túnel `pos-local` → Caddy `:8080` → puente `:8095`.  
Sandbox: mismo túnel, hostname `pos-sandbox` → Caddy `:8180` → puente `:8195`.  
Tienda Infinito: túnel propio → Caddy `:8280` → puente `:8295` (la caja vieja puede seguir en otros puertos).

#### Scenario: Caddy en dev
- **WHEN** el operador inicia Caddy en Dev local
- **THEN** escucha en `:8080` con el `Caddyfile` del front

#### Scenario: Caddy v02
- **WHEN** el operador inicia Caddy en ambiente Tienda Infinito
- **THEN** escucha en `:8280` con `Caddyfile.tienda-infinito` y proxea Angular `:4220`, auth `:8281`, POS `:8288` y puente `:8295`

### Requirement: Perfil Spring y BD v02

Auth, POS y puente en ambiente Tienda Infinito SHALL activar `--spring.profiles.active=tienda-infinito` y SHALL conectar a `controlneg_rmx_db_v02`. JWT de auth v02 MUST ser distinto al de la caja vieja (`:8081`). Crear la BD: `create-db-controlneg-rmx-db-v02.sql` (vacía o `WITH TEMPLATE`); migraciones son un ejercicio posterior.

#### Scenario: POS v02 no usa la BD productiva
- **WHEN** arranca Lógica tienda en Tienda Infinito
- **THEN** el datasource apunta a `controlneg_rmx_db_v02` y el puerto es `:8288`

### Requirement: Launcher portable (Windows, macOS, Linux)

El launcher MUST arrancar procesos con el shell del SO (`cmd.exe` / `sh`), matar por puerto o patrón de forma portable, y MUST NO depender de un solo sistema operativo. Compilar el JAR SHALL hacerse **en el SO de destino** (JavaFX natives). Atajos: `run-macos.sh`, `run-linux.sh`, `run-windows.ps1`.

El botón **Preparar esta máquina** SHALL copiar y ejecutar `prepare-host.sh` (macOS/Linux) o `prepare-host.ps1` (Windows): revisar `java`, `mvn`, `docker`, `npm`, `caddy`, `cloudflared` en PATH y abrir puertos **LAN** (tablets/cajas). El túnel Cloudflare MUST NOT exigir puertos de entrada a internet.

#### Scenario: Windows Administrador
- **WHEN** Preparar esta máquina corre en PowerShell como Administrador en ambiente tienda-infinito
- **THEN** crea reglas de firewall inbound TCP para los puertos de ese ambiente

#### Scenario: macOS
- **WHEN** el mismo botón corre en macOS
- **THEN** no intenta ufw; indica que el firewall es por aplicación y que la IP LAN se configura en el launcher

### Requirement: Worker no mezcla pruebas con la caja

El Worker `email-inbound-pos` SHALL POST a:

- `INBOUND_URL` (`https://cotiza.mayaksoluciones.com/api/email-inbound`) y `INBOUND_URL_SANDBOX` (`https://pos-sandbox.mayaksoluciones.com/api/email-inbound`) cuando el destinatario **no** contiene `tienda-infinito` (p. ej. `pagos@mayaksoluciones.com`)
- solo `INBOUND_URL_TIENDA` (`https://tienda-infinito.mayaksoluciones.com/api/email-inbound`) cuando el destinatario contiene `tienda-infinito`

Si al menos un POST responde OK, el correo se acepta.

#### Scenario: Correo de prueba
- **WHEN** llega mail a `pagos@mayaksoluciones.com`
- **THEN** el Worker MUST NOT llamar a la URL de Tienda Infinito

#### Scenario: Correo de la caja
- **WHEN** llega mail a `tienda-infinito@mayaksoluciones.com`
- **THEN** el Worker llama solo a `https://tienda-infinito.mayaksoluciones.com/api/email-inbound`

### Requirement: Hostname y túnel propios de la tienda

Cloudflare DNS SHALL tener CNAME proxied `tienda-infinito.mayaksoluciones.com` al túnel **tienda-infinito** (UUID `cf623430-1915-4236-82cf-7256421a9102`), MUST NOT al túnel `pos-local` de la laptop. Email Routing SHALL tener regla literal `tienda-infinito@mayaksoluciones.com` → el mismo Worker. El token del conector SHALL vivir en `~/.cloudflared/tienda-infinito.token` (Windows: `%USERPROFILE%\.cloudflared\`) y MUST NOT subirse a git.

En la PC de tienda el launcher, ambiente Tienda Infinito, SHALL preferir `cloudflared tunnel run --token` si existe ese archivo; si no, `config-tienda-infinito.yml`.

#### Scenario: Tráfico de producción
- **WHEN** alguien visita `https://tienda-infinito.mayaksoluciones.com` y el conector de esa PC está activo
- **THEN** Cloudflare entrega a Caddy `:8280` de **esa** máquina, no a cotiza ni a pos-sandbox

### Requirement: Salud del frontend independiente del reloj de pared

`infinito-ai-front/server.js` MUST marcar `/health` y `/actuator/health` listos con uptime del proceso, no con `Date.now()` menos instante de arranque. El launcher SHALL considerar el Frontend **Ejecutándose** si el puerto del Angular del ambiente (p. ej. `:4200` en dev) está abierto, aunque el health `:3001` aún devuelva 503. MUST NOT lanzar un segundo `npm start` si Angular ya escucha.

#### Scenario: Simular otro día en el Mac
- **WHEN** el operador atrasa o adelanta la fecha del sistema con `ng serve` ya arriba
- **THEN** el launcher no se queda en Iniciando ni arranca otro front

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/ambientes-launcher-tienda-infinito.md`, este spec y `ARRANQUE-LOCAL-Y-SANDBOX.md` (ops). El perfil tester no cubre firewall/túnel.

### Requirement: Piloto de caja aún no verificado

Hasta que un humano confirme inbound en la PC de tienda, el sistema MUST tratar Tienda Infinito como **listo en Cloudflare y en el launcher**, no como flujo QA cerrado. Queda pendiente: copiar token y JARs a esa PC, `cloudflared` conectado, Caddy + puente arriba, un correo real o reenviado a `tienda-infinito@mayaksoluciones.com`.

#### Scenario: No probar inbound desde la laptop
- **WHEN** el equipo trabaja en Dev local
- **THEN** MUST NOT arrancar el conector `tienda-infinito` en esa laptop
