# Actualización QA — oleada 2026-09-02

**Para:** tester + IA en pair testing (sandbox / pos-local con túnel email).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre).  
**Narrativos:** `contextos-ia/metodos-pago-notificacion.md`, `contextos-ia/confirmacion-pagos-electronicos.md`.  
**Specs:** `metodos-pago-notificacion`, `confirmacion-pagos-electronicos`.  
**SQL sandbox:** `53_metodo_pago_permite_notificacion.sql` → `54_plantilla_naturaleza_ingreso.sql`.  
**Reiniciar:** relational + `puente-tienda` (:8095) tras SQL.

**Chat / trabajo de referencia:** notificaciones por cualquier medio (`permiteNotificacion`), plantillas Ingreso/Egreso, UI Dominios↔Plantillas, Asociar multi-método + corregir medio, parser `$ 16.000`.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Medio con Notificación** | Dominios → Métodos de pago: flag «Permite notificación»; ya no solo “QR Bancolombia” por nombre. |
| **Plantillas** | Nombre → Naturaleza; Ingreso = método; Egreso = OF origen/destino. Icono del medio. |
| **Link UI** | En Plantillas: botón **Métodos de pago**. En Dominios: **Plantillas asociadas** (+ form Agregar/Modificar). |
| **Auto-confirm** | Email confirma venta solo si plantilla **Ingreso** del **mismo** medio del cobro. |
| **Asociar** | Si hay emails de otro medio: iconos; esos emails no se eligen; **Corregir / cambiar medio** (flecha). |
| **Canal email** | Sin filtro Gmail → `pagos@…` el MS **no loguea** inbound (no es fallo del parser). |

---

## 2. Checklist pair testing (prioridad)

### A. Dominios + plantillas (~15 min)
1. Dominios → Métodos de pago → activar Notificación en un medio (p.ej. Nequi) + icono.
2. Plantillas asociadas → Agregar Ingreso ligada a ese medio; cuerpo tipo `Venta exitosa por {{monto}}`.
3. Desde Gestión notificaciones → Plantillas: botón Métodos de pago abre el mismo modal; al volver, el medio aparece en el select.

### B. Cobro + confirmación (~15 min)
1. Ticket pagado con ese medio → pendiente en panel (icono del medio).
2. Inbound (túnel real **o** `curl` a `:8095/api/email-inbound` con `X-Store-Key` y texto `Venta exitosa por $ 16.000`) → match plantilla / monto 16000.
3. Confirma automático o Asociar.

### C. Asociar multi-método (~10 min)
1. Pendiente medio A + email sin asignar medio B → Asociar: iconos; B no seleccionable; Corregir medio a B → luego se puede asociar.
2. Verificar que tras corregir, historial/medio del ticket o abono quedó coherente.

---

## 3. Sí reportar / No es bug

| Observación | Tip |
|-------------|-----|
| Cobro Nequi sin pendiente y flag Notificación apagado | **Diseño OK** |
| Email a Gmail personal sin llegar al POS / sin log `email-inbound` | Revisar **filtro reenvío** (Has the words); no es bug del parser |
| `$ 16.000` no extrae tras SQL+restart puente | **Bug** parser / plantilla |
| Email otro medio seleccionable y confirma mal | **Bug** Asociar |
| Corregir medio no cambia select de emails aplicables | **Bug** corrección HRE |

---

## 4. Entregar a la IA / tester

1. Este archivo + `CONTEXTO-TESTER-POS.md`.  
2. Specs: `metodos-pago-notificacion`, `confirmacion-pagos-electronicos`.  
3. Confirmar scripts 53→54 y servicios arriba.
