# Actualización QA — oleada 2026-09-06

**Para:** tester + IA en pair testing (sandbox / pos-local).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre; §4.5 / §4.9 / §4.12).  
**Narrativos:** `contextos-ia/ticket-observaciones.md`, `contextos-ia/cierre-asistente-caja.md`, `contextos-ia/confirmacion-pagos-electronicos.md`.  
**Specs:** `ticket-observaciones`, `cierre-asistente-caja`, `confirmacion-pagos-electronicos`.  
**SQL sandbox:** `55_notificaciones_activa.sql` → `56_ticket_observaciones.sql` (tras `53`→`54`).  
**Reiniciar:** relational si acabas de aplicar SQL. El asistente y minimizar **no** piden SQL.

**Chat / trabajo de referencia:** comentario de ticket en el rail; asistente de billetes en Cierre de turno; minimizar el panel Pagos electrónicos (distinto de ocultar por config); **notificaciones Nequi** (mismo flujo que QR, plantilla Ingreso del medio 3).

Las oleadas `ACTUALIZACION-QA-2026-09-03.md` (Historial) y `2026-09-02.md` (medios/plantillas) **siguen vigentes**.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Comentario de ticket** | Menú ⋮ / clic derecho: Registrar o Editar comentario. El panel se titula Observación o Crédito y observación. Cita itálica. Al liquidar el crédito, el comentario **se borra**. |
| **Asistente de caja** | En Cierre de turno, fila Efectivo: contar billetes. Contado = total de billetes. Diferencia vs Esperado. Reabrir recuerda cantidades. |
| **Minimizar panel** | Encabezado del panel → recuadro abajo (Pagos electrónicos + número + Restaurar). No apaga el banco. Recargar Tickets lo recuerda. |
| **Ocultar panel** | Config / Gestión notificaciones: panel activo OFF. No se ve panel ni recuadro. **No** es minimizar. |
| **Nequi + Notificación** | Dominios: Nequi **activo** y **Permite notificación**. Plantilla Ingreso **INGRESO NOTIF NEQUI** ligada a Nequi (`Venta exitosa por {{monto}}`). Cobro Nequi deja pendiente con icono Nequi; el aviso confirma o se Asocia. No es solo “QR Bancolombia”. |

---

## 2. Checklist pair testing (prioridad)

### A. Comentario (~15 min)

1. Ticket sin crédito → Registrar comentario → título **Observación**; se ve la cita.
2. Editar: la caja toma foco y el texto queda seleccionado.
3. Generar crédito (mismo ticket) → título **Crédito y observación**.
4. Texto largo: se corta a ~4 líneas; al pasar el mouse se ve el resto.
5. Varios abonos: la lista **scrollea**.
6. Liquidar crédito → el tab reusado **sin** el comentario.
7. Cancelar o guardar vacío: no deja basura.

### B. Asistente de cierre (~10 min)

1. Cobrar algo en efectivo (si el turno está vacío).
2. Cierre de turno → asistente para cierre de caja.
3. Contar billetes → Asociar → Contado de Efectivo = total de billetes.
4. Si no calza con Esperado, se ve faltante o sobrante.
5. Reabrir el asistente: mismas cantidades.

### C. Minimizar panel (~10 min)

1. Cobro con medio que tiene Notificación → hay pendiente.
2. Minimizar → recuadro abajo con el número.
3. Restaurar → vuelve el panel.
4. Minimizar otra vez → recargar Tickets → sigue el recuadro.
5. (Si se puede) con el recuadro visible, que llegue un aviso: el número cambia; no “se apaga” el canal.
6. (Opcional) apagar panel activo en Gestión notificaciones → no hay panel ni recuadro.

### D. Notificaciones Nequi (~15 min)

Precondición (sandbox ya copiado desde dev): Nequi activo + Permite notificación; plantilla **INGRESO NOTIF NEQUI** (Ingreso, medio Nequi, cuerpo `Venta exitosa por {{monto}}`).

1. Dominios → Métodos de pago: Nequi **ACTIVO**, **Permite notificación** ON, icono `nequi-logo.png`.
2. Plantillas asociadas (o Gestión notificaciones → Plantillas): existe **INGRESO NOTIF NEQUI** ligada a Nequi, naturaleza **Ingreso**.
3. Ticket → cobrar **Nequi** (monto conocido, p.ej. $16.000) → el panel muestra **pendiente** con icono Nequi (no el de QR).
4. Llega el aviso del mismo medio y monto (túnel real **o** `curl` a `:8195/api/email-inbound` en sandbox con texto `Venta exitosa por $ 16.000`) → confirma automático **o** Asociar elige solo emails Nequi.
5. Abono CxC con Nequi → también deja pendiente (no es una venta nueva).
6. (Variante) Nequi con Notificación **OFF** → cobro OK y **sin** pendiente (diseño).
7. Encaja con C: minimizar con pendiente Nequi → el recuadro cuenta ese pendiente; Restaurar lo muestra.

---

## 3. Sí reportar / No es bug

| Observación | Tip |
|-------------|-----|
| Comentario sin crédito (solo Observación) | **Diseño OK** |
| Diferencia ≠ 0 si el conteo no calza Esperado | **Diseño OK** |
| Minimizado y el recuadro sigue abajo | **Diseño OK** |
| Panel OFF por config: no hay recuadro | **Diseño OK** (no es minimizar) |
| Comentario sigue tras liquidar el crédito | **Bug** |
| Asociar no copia el total de billetes a Contado | **Bug** |
| Minimizar no muestra recuadro o Restaurar no abre | **Bug** |
| Minimizado deja de confirmar avisos | **Bug** |
| Cobro Nequi sin pendiente y flag Notificación apagado | **Diseño OK** |
| Pendiente Nequi con icono de QR / no aparece plantilla INGRESO NOTIF NEQUI | **Bug** |
| Email Nequi se asocia a un pendiente QR (o al revés) sin corregir medio | **Bug** |

---

## 4. Entregar a la IA / tester

1. Este archivo + `CONTEXTO-TESTER-POS.md`.  
2. Confirmar scripts **55 → 56** en la BD del ambiente (dev y/o sandbox).  
3. Oleadas 09-03 y 09-02 si el ciclo también toca Historial o medios/plantillas.
