# Contexto IA — Métodos de pago + notificaciones / plantillas

**Última actualización:** 2026-09-10 (plantilla EGRESO: hold si hay egreso candidato).  
**OpenSpec:** `openspec/specs/metodos-pago-notificacion/spec.md`  
**Relacionado:** `contextos-ia/confirmacion-pagos-electronicos.md`, `contextos-ia/notificacion-egreso-vinculo.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.12 / §4.14 / §10.5  
**SQL:** `53_metodo_pago_permite_notificacion.sql`, `54_plantilla_naturaleza_ingreso.sql`  
**Rules FE:** `infinito-ai-front/.cursor/rules/metodos-pago-notificacion.mdc`

## Qué es

Cualquier **medio de pago** puede habilitar confirmación por email (`permite_notificacion`). Las **plantillas de extracción** (puente-tienda) se ligan al medio: **Ingreso** → método; **Egreso** → orígenes de fondos. El icono del panel/tickets viene de `metodo_pago.file` (no de un picker suelto en la plantilla).

## Dominios ↔ Gestión notificaciones (UI)

| Desde | Acción | Abre |
|-------|--------|------|
| Gestión notificaciones → Plantillas | Botón **Métodos de pago** (derecha del select Método) | Mismo modal Dominios CRUD |
| Dominios → Métodos de pago | **Plantillas asociadas** (cabecera) o icono por fila | Lista plantillas + Agregar/Modificar/Eliminar |
| Lista plantillas | Agregar / Modificar | Modal formulario (mismos campos que la pestaña Plantillas) |

## Reglas de negocio

1. **HRE pendiente** al cobrar/abonar solo si el medio tiene `permiteNotificacion=true` (ya no basta sigla QR / texto Bancolombia).
2. **Auto-confirmación** de venta/abono: plantilla activa `naturaleza=INGRESO` + `metodoPagoId` = medio del HRE + ese medio con notificaciones.
3. **Egreso** en plantilla: si **no** hay egreso POS candidato, movimiento ledger (OF origen/destino). Si hay candidato, **hold** — bandeja campanita; ver `notificacion-egreso-vinculo.md`. No confirma ticket.
4. **Asociar** con medios distintos: iconos en Esperado y en cada email; emails de otro medio visibles pero no seleccionables; **Corregir / cambiar medio** (chevron) → `PUT /historial-recibos-electronicos/{id}/corregir-metodo-pago` (cascada venta: HRE + `historial_recibo_pago` + header + documento; abono: HRE + `abono_cxc` + traslado OF).

## Plantilla — campos UI

Orden: **Nombre** → **Naturaleza** → condicionales:

- Ingreso → solo **Método de pago** habilitado  
- Egreso → solo **OF origen** / **OF destino**

## Parser email (`EmailPagoParser`)

- Fragmento; ignora mayúsculas/tildes/espacios de más.
- `{{monto}}` acepta `$16.000`, `$ 16.000` (espacio/NBSP tras `$`), punto final de frase.
- Canal real: Gmail filtro → `pagos@…` → Worker → túnel → `:8095`. Sin reenvío **no hay log** `email-inbound`.

## Repos / piezas

| Pieza | Ubicación |
|-------|-----------|
| CRUD Dominios | `…/dominios/metodo-pago/metodo-pago-gestion-dialog.*` |
| Lista + form plantillas | `…/gestion-notificaciones-medios-electronicos/plantillas-asociadas-dialog`, `plantilla-notificacion-form-dialog` |
| Corrección medio HRE | `pos-relational` `HistorialReciboElectronicoService` |
| Match inbound | `puente-tienda` `ConfirmacionPagoService` |
