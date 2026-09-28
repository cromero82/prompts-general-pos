# Arranque local (dev) y puente sandbox

**Última actualización:** 2026-09-11.

Guía para levantar, parar y reiniciar los servicios en tu Mac. Úsala después de un reinicio, si un Java se quedó colgado, o cuando quieras simular otro día de operación.

Hay **tres ambientes**. Dev y sandbox conviven en la laptop; Tienda Infinito es otra PC. Contratos: `openspec/specs/ambientes-launcher-tienda-infinito/spec.md`.

| | Local (tú, día a día) | Sandbox (el tester) | Tienda Infinito |
|---|---|---|---|
| Para qué | Desarrollar y probar con tus datos | Entorno estable, datos aparte | Caja standalone de producción |
| Lo abres en | http://localhost:4200 | http://localhost:4210 o https://pos-sandbox.mayaksoluciones.com | http://localhost:4220 o https://tienda-infinito.mayaksoluciones.com |
| Base de datos | `controlneg_rmx_db_v02` | `controlneg_rmx_db_sandbox` | BD de esa máquina |

Un POS local (`:8088`) no debe hablar con el puente del sandbox (`:8195`). Cada entorno tiene su propio auth, POS, puente y front.

Más detalle de sandbox (clone de BD, flags de `./up.sh`): `contextos-ia/sandbox-reset-transaccional.md` y `sandbox/infinito-ai-front/scripts/sandbox/README.md`.

PostgreSQL tiene que estar escuchando en `:5432` **antes** de arrancar cualquier Java.

---

## Quién controla los procesos

Tú. El launcher, IntelliJ o un agente de Cursor marcan un servicio como “up” solo porque **el puerto ya está ocupado**. Eso no quiere decir que el proceso sea tuyo: a veces lo dejó un agente en una terminal que tú no ves, y por eso no puedes hacer Ctrl+C.

Para pruebas (sobre todo **cambiar la fecha del Mac**) para y relanza **tú** el backend y el front, en **tus** terminales.

Si un agente dejó un `java -jar` o un `ng serve` colgado, no busques esa terminal: libera el puerto (sección más abajo) y arranca el comando en la tuya.

---

## Puertos

Cada pieza es un proceso. El número es el puerto en el que escucha.

| Pieza | Qué es | Local (tú) | Sandbox (tester) |
|---|---|---|---|
| Angular | La pantalla del POS | 4200 | 4210 |
| Caddy | Portero local: recibe lo que llega de internet y lo pasa al Java/Angular correcto | **8080** | 8180 |
| Auth (`infinito-security`) | Login y tokens | 8081 | 8181 |
| Relacional (`pos-relational-data-service`) | Backend de tienda (ventas, cortes, OF, etc.) | 8088 | 8188 |
| Puente-tienda | Correos de banco / notificaciones de pago | **8095** | **8195** |
| Health node | Chequeo de salud del front sandbox | 3001 | 3011 |
| Mail (`infinito-smtp-service`) | Envío de correo (Gmail de desarrollo). Uno solo, lo usan los dos entornos | 8082 | 8082 |
| PostgreSQL | Base de datos | `controlneg_rmx_db` | `controlneg_rmx_db_sandbox` |

Para el día a día dentro de `localhost:4200` te bastan Auth, POS y Angular. Caddy y el puente solo hacen falta cuando algo **entra desde internet** (correo PAGASTE, cotización de invitado).

---

## Local (dev) — cómo arrancar

Rutas bajo `/Users/carlosromero/Documents/dev/repos/`. Cada bloque es **una terminal**. Orden sugerido: auth → mail → POS → puente → front. Caddy al final, solo si vas a probar correo o invitado.

```bash
# Auth :8081
cd /Users/carlosromero/Documents/dev/repos/infinito-security
mvn -DskipTests spring-boot:run
```

```bash
# Mail :8082 (si no está ya)
cd /Users/carlosromero/Documents/dev/repos/infinito-smtp-service
mvn -DskipTests spring-boot:run
```

```bash
# POS relacional :8088 → controlneg_rmx_db_v02
cd /Users/carlosromero/Documents/dev/repos/pos-relational-data-service
./mvnw -DskipTests package
java -jar target/pos-relational-data-service-0.0.1-SNAPSHOT.jar
# Auth se queda en controlneg_rmx_db (mismos UUID; login de esta laptop).
# Si el launcher «Dev local» arranca el POS, pásale:
#   --spring.datasource.url=jdbc:postgresql://localhost:5432/controlneg_rmx_db_v02
```

```bash
# Puente local :8095 (correos de banco hacia TU POS)
cd /Users/carlosromero/Documents/dev/repos/puente-tienda
mvn -DskipTests package
java -jar target/puente-tienda-0.0.1-SNAPSHOT.jar
```

```bash
# Front :4200
cd /Users/carlosromero/Documents/dev/repos/infinito-ai-front
npm run dev
```

```bash
# Caddy de desarrollo :8080 — ver la sección siguiente
cd /Users/carlosromero/Documents/dev/repos/infinito-ai-front
caddy run --config Caddyfile
```

Si cambias código Java, vuelve a hacer `package` y relanza el `java -jar`. Angular (`npm run dev`) se recarga solo.

El puente también se puede correr sin jar (hot-reload Maven):

```bash
cd /Users/carlosromero/Documents/dev/repos/puente-tienda
mvn -DskipTests spring-boot:run
```

---

## Túnel Cloudflare y Caddy: no son lo mismo

Aquí suele haber confusión. Son **dos procesos distintos**, uno detrás del otro.

### 1. El túnel (`cloudflared`)

Es el cable hacia internet. Cloudflare recibe el HTTPS (correo del banco, cotización de invitado) y lo deja en un puerto de tu Mac.

Hay **un solo** túnel de la laptop, que se llama `pos-local`. Infinito Launcher lo instala como **inicio de sesión** (LaunchAgent en macOS). Tras reiniciar el Mac, vuelve solo. También puedes:

```bash
cloudflared tunnel --metrics 127.0.0.1:46494 --config ~/.cloudflared/config.yml run
```

cubre **los dos** nombres públicos:

| Nombre en internet | Lo deja en tu Mac en |
|---|---|
| `cotiza.mayaksoluciones.com` (tu entorno de desarrollo) | puerto **8080** |
| `pos-sandbox.mayaksoluciones.com` (el tester) | puerto **8180** |

El túnel no sabe de Java ni de Angular. Solo dice: “esto que llegó de internet, ponlo en el puerto 8080 o en el 8180”.

### 2. Caddy (el portero **dentro** del Mac)

Alguien tiene que estar **escuchando** ese puerto y pasar el request al proceso correcto. Eso es Caddy: un reverse proxy local.

Hay **dos** Caddy, uno por entorno:

| Caddy | Lo arrancas con | Escucha | Entrega el correo a |
|---|---|---|---|
| Desarrollo | `caddy run --config Caddyfile` en `repos/infinito-ai-front` | **8080** | puente local **8095** (también reparte auth 8081, POS 8088 y Angular 4200) |
| Sandbox | lo levanta `./up.sh` | **8180** | puente sandbox **8195** |

Sin Caddy en 8080, el túnel sí deja el paquete en la puerta, pero **nadie abre**. El Worker de Cloudflare puede haber entregado el mail, y aun así en `localhost:4200` la bandeja queda vacía. El mismo mail sí puede aparecer en sandbox, porque ahí `./up.sh` sí dejó Caddy en 8180.

### Qué hace `./up.sh --tunnel`

Ese flag es del **sandbox**, no de tu desarrollo:

1. Enciende `cloudflared` (el cable) si no estaba.
2. Enciende el stack del tester, incluido **Caddy :8180**.

No enciende el Caddy de desarrollo (`:8080`). Por eso **no sustituye** `caddy run --config Caddyfile`. Si estás en `localhost:4200` y quieres ver correos PAGASTE / cotiza, necesitas **los tres**: túnel + Caddy `:8080` + puente `:8095`.

Para vender y hacer cortes en local **sin** correo de banco, Caddy no hace falta: Auth + POS + Angular alcanzan.

---

## Parar o tomar el control (por puerto)

“Ya está up” = alguien escucha ese puerto. No hace falta encontrar la terminal del agente: se mata **quien tiene el LISTEN**.

```bash
# Ver qué hay en local (dev)
lsof -nP -iTCP:4200,8080,8081,8082,8088,8095 -sTCP:LISTEN

# Liberar un puerto (ejemplo: el POS :8088)
kill $(lsof -tiTCP:8088 -sTCP:LISTEN)
# si a los ~2 segundos sigue ocupado:
kill -9 $(lsof -tiTCP:8088 -sTCP:LISTEN)
```

| Puerto | Pieza | Cuándo pararlo / relanzarlo |
|---|---|---|
| 4200 | Front Angular | Cambiaste la fecha del Mac, `ng serve` se trabó, o quieres el FE en tu terminal |
| 8081 | Auth | Cambiaste la fecha del Mac (los tokens JWT se rompen) o el login se pone raro |
| 8088 | POS relacional | **Siempre** si cambiaste código Java o vas a simular otro día |
| 8082 | Mail | Casi nunca por la fecha |
| 8095 | Puente | Casi nunca por la fecha |
| 8080 | Caddy de desarrollo | Cuando pruebes correo inbound en local |

No uses `pkill -f pos-relational-data-service` si el sandbox (`:8188`) también está arriba: matarías los dos POS.

Después de liberar el puerto, arranca el comando en **una terminal tuya** (bloques de [Local (dev)](#local-dev--cómo-arrancar)). El Ctrl+C de esa terminal es tu parada normal.

### Reinicio rápido del POS y del front (dev)

```bash
kill $(lsof -tiTCP:8088 -sTCP:LISTEN)
cd /Users/carlosromero/Documents/dev/repos/pos-relational-data-service
./mvnw -DskipTests package
java -jar target/pos-relational-data-service-0.0.1-SNAPSHOT.jar
```

```bash
kill $(lsof -tiTCP:4200 -sTCP:LISTEN)
cd /Users/carlosromero/Documents/dev/repos/infinito-ai-front
npm run dev
```

Auth solo si también cambiaste la fecha o el login falla:

```bash
kill $(lsof -tiTCP:8081 -sTCP:LISTEN)
cd /Users/carlosromero/Documents/dev/repos/infinito-security
mvn -DskipTests spring-boot:run
```

---

## Simular 1, 2 o 3 días de operación

El POS no tiene un “día de prueba” interno. `DateUtils.obtenerFechaSistema()` es la hora del Mac (`LocalDateTime.now()`). Postgres `now()` también. El Angular usa la fecha del navegador, que es la misma del Mac.

Para que un corte, una cobranza o un “hoy” caigan en otro día:

1. Cierra sesión en http://localhost:4200. Si saltas días con la sesión abierta, los tokens JWT suelen quedar vencidos o “del futuro”.
2. En el Mac: **Ajustes del Sistema → General → Fecha y hora**. Desactiva “definir automáticamente” y pon el día que quieras. No hace falta `sudo date`.
3. Reinicia **Auth (`:8081`)** y **POS (`:8088`)** con los bloques de arriba. En el front, recarga fuerte el navegador; si la UI se ve rara, relanza `npm run dev`.
4. Entra otra vez y opera ese “día” (ventas, corte, distribución, etc.).
5. Cuando termines: **vuelve a activar la fecha automática** y reinicia otra vez Auth + POS. Si no, “hoy” y los tokens siguen en el día inventado.

El sandbox (`:4210` / `:8188`) es otro proceso. No lo toques si la prueba es solo en local.

### Hostname de producción (Tienda Infinito)

Pila **v02** al lado de la caja actual. PC de tienda: **`CURSOR-IA-PC-TIENDA-V02.md`** (el launcher no aplica scripts: los cambios de BD se entregan como SQL `NN_…`).

- Front `:4220`, Caddy `:8280`, auth `:8281`, POS `:8288`, puente `:8295`, SMTP `:8282`, health `:3021`
- BD `controlneg_rmx_db_v02` (si se crea desde cero, restaurar de un dump; los cambios de schema se aplican como SQL `NN_…`)
- Worker: `INBOUND_URL_TIENDA` = `https://tienda-infinito.mayaksoluciones.com/api/email-inbound`
- Túnel → `http://127.0.0.1:8280` (no `:8080` de la caja vieja)
- Token: `~/.cloudflared/tienda-infinito.token`

En el launcher: ambiente **Tienda Infinito**. No arranques ese túnel en esta laptop salvo que ella sea la caja.

---

## Sandbox (el tester)

Misma idea que local, pero en otros puertos y otra BD. El perfil Spring es `sandbox`.

### Solo el puente sandbox

Útil si el resto del sandbox ya está arriba y quieres probar inbound en paralelo a local.

```bash
cd /Users/carlosromero/Documents/dev/repos/puente-tienda
mvn -DskipTests package
java -jar target/puente-tienda-0.0.1-SNAPSHOT.jar --spring.profiles.active=sandbox
```

Eso escucha en **8195** y usa `application-sandbox.properties`.

### Stack sandbox completo

Los scripts canónicos están en la copia estable:

```bash
cd /Users/carlosromero/Documents/dev/repos/sandbox
./up.sh
# además enciende el túnel Cloudflare (pos-sandbox.mayaksoluciones.com)
# y el Caddy del sandbox en :8180 — no el Caddy de desarrollo :8080
./up.sh --tunnel
```

Eso es: front 4210 + Caddy 8180 + auth 8181 + POS 8188 + puente 8195.

Para bajar el sandbox **sin** apagar tu local (`:4200` / `:8088` / `:8095`):

```bash
cd /Users/carlosromero/Documents/dev/repos/sandbox
./down.sh
```

Después de un `git pull` en sandbox: `./restart.sh --tunnel` (baja, compila microservicios, sube).

Desde el front de desarrollo, `npm run sandbox:up` / `sandbox:down` **llaman** a ese árbol. No arranques el Angular del tester desde `repos/infinito-ai-front`.

### Dos copias del puente

| Qué | Ruta | Cuándo usarla |
|---|---|---|
| Código con el que trabajas tú | `repos/puente-tienda` | `java -jar … --spring.profiles.active=sandbox` (arriba) |
| Copia estable del tester | `repos/sandbox/puente-tienda` | la que levanta `./up.sh` |

Si el cambio está solo en `repos/puente-tienda`, `./up.sh` **no** lo ve. O arrancas el jar de `repos/` con perfil `sandbox`, o copias/compilas en `sandbox/puente-tienda`.

---

## Comprobar que escuchan

```bash
# Local (tú)
lsof -iTCP:8081,8082,8088,8095,4200,8080 -sTCP:LISTEN -n -P
# Sandbox (tester)
lsof -iTCP:8181,8188,8195,4210,8180 -sTCP:LISTEN -n -P
```

Salud del puente:

```bash
curl -sS http://127.0.0.1:8095/actuator/health   # local
curl -sS http://127.0.0.1:8195/actuator/health   # sandbox
```
