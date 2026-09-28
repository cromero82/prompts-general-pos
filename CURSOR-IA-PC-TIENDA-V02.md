# Prompt Cursor — PC de tienda (Tienda Infinito)

Carga este archivo en el chat de Cursor **en la PC de la caja**. No en la laptop de desarrollo (ahí no arrancar el túnel `tienda-infinito`).

**Spec:** `openspec/specs/ambientes-launcher-tienda-infinito/spec.md`  
**Launcher:** repo `intinito-launcher` (typo histórico)

## Qué hay que lograr

Dos pilas en la misma máquina, **sin mezclar BD ni puertos**:

| Ambiente (dropdown) | BD | Front / POS / Auth | Correo / Caddy |
|---------------------|----|--------------------|----------------|
| **Caja actual** | `controlneg_rmx_db` | `:4200` / `:8088` / `:8081` | **No.** Copia de la productiva vieja. |
| **Tienda Infinito** | `controlneg_rmx_db_v02` | `:4220` / `:8288` / `:8281` | **Sí.** Caddy `:8280`, puente `:8295`, túnel + `tienda-infinito@mayaksoluciones.com` |

El launcher **no** aplica scripts: los cambios de BD se entregan como migraciones (SQL `NN_…` en el BE). Nunca `pg_restore --create`. Nunca SQL sobre `controlneg_rmx_db`.

## Pasos (humano + IA)

1. Repos juntos: `infinito-ai-front`, `pos-relational-data-service`, `infinito-security`, `infinito-smtp-service`, `puente-tienda`, `intinito-launcher`, `prompts-general-pos`.
2. Compilar JARs **en este SO** (`mvn -DskipTests package` en POS, security, smtp, puente, launcher). Front: `npm install`.
3. Restaurar el dump de `controlneg_rmx_db_v02` (vacía + `pg_restore --no-owner --no-acl -d controlneg_rmx_db_v02`).
4. Copiar `~/.cloudflared/tienda-infinito.token` (chmod 600). Ingress Cloudflare → `http://127.0.0.1:8280`.
5. Abrir Infinito Launcher → **Ruta proyectos** = carpeta de repos.
6. Dropdown **Tienda Infinito** → **Preparar esta máquina**.
7. **Iniciar todo**. Público: `https://tienda-infinito.mayaksoluciones.com`.
8. Para la copia vieja: dropdown **Caja actual** → Iniciar (solo auth/POS/front). Sin SMTP, puente, Caddy ni túnel.

## Comprobar

```bash
psql -d controlneg_rmx_db_v02 -c "SELECT email_alerta_pagos FROM establecimiento WHERE id=1;"
# esperado: tienda-infinito@mayaksoluciones.com

psql -d controlneg_rmx_db_v02 -c "SELECT key, value, leyenda FROM configuracion_app WHERE key = 'corte-venta.base-efectivo';"
# esperado: 150000 + leyenda
```

Un PAGASTE a `tienda-infinito@mayaksoluciones.com` debe llegar al puente `:8295`, **no** a cotiza/sandbox.
