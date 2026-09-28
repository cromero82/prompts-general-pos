## Hecho (2026-09-11)

- [x] Worker: `INBOUND_URL_TIENDA` + fan-out solo si el To no contiene `tienda-infinito`
- [x] DNS CNAME `tienda-infinito` → túnel propio (no `pos-local`)
- [x] Email Routing: `tienda-infinito@mayaksoluciones.com` → Worker
- [x] Launcher: ComboBox ambiente, puente, Caddy, túnel solo estado, Preparar esta máquina
- [x] Scripts host Windows / Unix; `run-linux.sh` / `run-windows.ps1`
- [x] Front health por uptime + launcher mira el puerto Angular del ambiente
- [x] Pila v02 en puertos distintos a la caja vieja (`4220` / `8280` / `8281` / `8288` / `8295`) y BD `controlneg_rmx_db_v02`
- [x] Runbook: `prompts-general-pos/MIGRATE-TIENDA-INFINITO-V02.md` (enlazado desde `README.md`)

## Pendiente (retomar en otra sesión)

Ejecutar en la PC de tienda: **`MIGRATE-TIENDA-INFINITO-V02.md`**.

- [ ] Crear `controlneg_rmx_db_v02` (vacía o `WITH TEMPLATE`)
- [ ] Copiar token + JAR/front; compilar launcher **allí**
- [ ] Subir pila v02 sin tocar `:4200` / `:8088`
- [ ] `cloudflared` → `:8280`
- [ ] Correo piloto a `tienda-infinito@mayaksoluciones.com`
- [ ] Archivar este change (`/opsx-archive`)
