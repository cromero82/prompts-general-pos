# Contexto y Plan de Implementación — Notificaciones de Pago por Email para POS

> **Estado 2026-09-11:** Worker + hostname `tienda-infinito.mayaksoluciones.com` + launcher por ambiente están en OpenSpec `ambientes-launcher-tienda-infinito`. Instalación en la PC de tienda: **`MIGRATE-TIENDA-INFINITO-V02.md`**. Este archivo sigue siendo el plan A original (multi-tienda genérico). No sustituye el spec.
>

## 1. Negocio

- **Rol del usuario**: Desarrollador de software independiente en Colombia.
- **Producto**: Software POS (punto de venta) para tiendas.
- **Modalidades de venta**:
    - **Standalone (Local)**: instalación en el punto/tienda, base de datos local, con opción de webhook para funcionalidades administrativas.
    - **SaaS**: (futuro, NO es el foco ahora).
- **Volumen esperado**: ~30 licencias/año. Se busca resolver para los primeros 2 años (~60 tiendas máx).

## 2. El problema a resolver

Los clientes pagan en cada tienda escaneando un **QR de Bancolombia** que deposita en la cuenta de ahorros del administrador de cada punto/tienda (podría ser otro banco en el futuro, incluso 2-3 bancos).

El software POS debe **detectar automáticamente el pago** (consignación/abono) y marcarlo en el sistema, sin intervención manual del cajero.

## 3. Decisiones ya tomadas (NO re-evaluar)

### 3.1. Vía elegida: intercepción de correo electrónico (PLAN A)

- Se descartó intercepción de SMS (Twilio no soporta números locales colombianos ni SMS inbound en Colombia).
- Se descartó como plan primario la API oficial de Bancolombia QR (Callback/JWT). Es viable y oficial, pero el cliente quiere resolver primero por correo, multi-banco. **Queda como plan B / mejora futura.**
- Cloudflare NO maneja SMS. Solo email, webhooks y túneles.

### 3.2. Arquitectura aprobada

```
Banco (alerta) ──email──> tiendaN@pagos.midominio.com
                              │ Cloudflare Email Routing (MX)
                              ▼
                        Cloudflare Worker
                              │ POST /api/email-inbound (email crudo)
                              ▼
                        tiendaN.midominio.com (Cloudflare Tunnel)
                              ▼
                        POS local (localhost:3000)
```

- Acceso admin: `tiendaN.midominio.com/admin` (misma URL del tunnel).
- Cada tienda = una subdirección de correo (`tienda1@pagos.midominio.com`) y un hostname de tunnel (`tienda1.midominio.com`).

## 4. Plan de implementación (Paso a paso)

### Paso 0 — Dominio en Cloudflare (plan Free)
- Mover `midominio.com` a Cloudflare (~$10/año). Requisito para Email Routing y Tunnel.
- Los registros DNS los gestiona Cloudflare.

### Paso 1 — Cloudflare Email Routing
- Activar Email Routing.
- Crear regla **catch-all**: `*@pagos.midominio.com` → el Worker.
- Así cada tienda obtiene su dirección sin configuraciones adicionales.

### Paso 2 — Worker de email (email-worker.js)
```js
export default {
  async email(message, env, ctx) {
    const store = message.to.split('@')[0];           // "tienda1"
    const raw = new TextDecoder().decode(await message.raw());

    // Entrega al POS vía túnel
    await fetch(`https://${store}.midominio.com/api/email-inbound`, {
      method: 'POST',
      headers: { 'content-type': 'text/plain', 'x-store-key': env.STORE_KEY },
      body: raw,
    });

    // Copia al correo real del admin (opcional)
    await message.forward(env.ADMIN_EMAIL);
  }
}
```
- El POS recibe el **email crudo** y hace el parsing ahí (más fácil de actualizar que el Worker).
- Variables de entorno del Worker: `STORE_KEY`, `ADMIN_EMAIL`.

### Paso 3 — Tunnel en el POS (config.yml)
```yaml
tunnel: <TUNNEL_ID>
credentials-file: /etc/cloudflared/<TUNNEL_ID>.json
ingress:
  - hostname: tienda1.midominio.com
    service: http://localhost:3000
  - service: http_status:404
```
- Instalar `cloudflared` como servicio del sistema: se auto-inicia con el POS.
- URL fija y única por tienda. NO cambia en el plan Free (solo cambia si se usa `trycloudflare.com`).

### Paso 4 — Endpoint en el POS
`POST /api/email-inbound` que debe:
- Validar `x-store-key`.
- Verificar autenticidad del remitente: `Received-SPF: pass` y DKIM (que venga del banco).
- Parsear el email: tipo de notificación ("Consignación recibida"/"abono"), monto, referencia, fecha.
- Marcar la venta como pagada en la BD local.

### Paso 5 — Configuración del banco
- En **Alertas y Notificaciones Bancolombia**, el dueño de la tienda registra `tienda1@pagos.midominio.com` como correo de notificación.
- Nota: el banco envía al correo que el titular configure. Verificar que Bancolombia permita correos externos (sí debería).

## 5. Confiabilidad (POS offline)

El tunnel solo entrega si el POS tiene internet. Solución en capas:
1. **Worker reintenta**: `ctx.waitUntil` + reintentos con backoff.
2. **POS sincroniza al volver**: al arrancar, `GET /api/email-inbound?since=<fecha>` contra Cloudflare (Worker guarda últimos emails en **KV**, gratis) y procesa los pendientes.
3. Esto asegura que si se cae el internet, al volver se ponen al día sin perder consignaciones.

## 6. Seguridad del acceso admin

- `tiendaN.midominio.com/admin` queda expuesto en internet. Proteger con:
    - **Cloudflare Access** (plan Free: hasta 50 usuarios) → auth por email/código antes de llegar al tunnel.
    - O auth propia de la app POS.

## 7. Costos (plan Free de Cloudflare)

| Componente | Servicio | Costo |
|---|---|---|
| Email routing | Cloudflare | $0 |
| Worker + KV | Cloudflare | $0 (100K req/día) |
| Tunnel x tienda | Cloudflare | $0 |
| Access (auth admin) | Cloudflare | $0 (hasta 50 usuarios) |
| Dominio | | ~$10/año |

**Total: $0/mes + dominio (~$10/año).**

## 8. Pendientes / Próximos pasos

- [ ] Escribir Worker completo (reintentos + KV para sincronización).
- [ ] Escribir parseador de email en el POS.
- [ ] Probar con una tienda piloto con un correo real de Bancolombia.
- [ ] Validar formato exacto del email de notificación de Bancolombia.
- [ ] (Futuro) Evaluar API oficial Bancolombia QR (Callback JWT) como mejora.

## 9. Referencias / Datos de contexto relevante

- **Bancolombia APIs**: existe API oficial QR Code con notificación por Callback/URL (POST cifrado con JWT, estados pending/approved/rejected, hasta 3 contactos adicionales, sin costo de integración, solo comisión por transacción). Documentación en `soportedevs.bancolombia.com`. Requiere ser cliente Bancolombia y firmar reglamento de APIs.
- **Twilio**: NO viable para SMS inbound en Colombia (sin números locales, sin SMS inbound, solo número internacional $1.15/mes y SMS outbound $0.0592/msg).
- **Cloudflare**: NO maneja SMS.
- **Servicios de email API alternativos**: Mailgun (Flex $0.80/1K inbound), SendGrid (Essentials $20/50K con inbound parse), Resend (~$10/50K, sin inbound).
- **Webhook tunnels alternativos**: ngrok ($8/mes para URL fija), Hookdeck (gratis hasta 100K eventos, maneja cola/reintentos).