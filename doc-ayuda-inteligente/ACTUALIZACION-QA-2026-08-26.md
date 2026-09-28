# Actualización QA — oleada 2026-08-26

**Para:** tester + IA en pair testing (sandbox / pos-sandbox).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre).  
**Si la IA verifica datos en BD:** también `../contextos-ia/sandbox-reset-transaccional.md`.

**Chat / trabajo de referencia:** cambios recientes en egresos/personas, sandbox consulta BD, fix cierre tras sobrepago QR, Historial Tickets + modal OF “Tickets sin corte”.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **Catálogos egreso** | Dominios: Naturalezas de tipo egreso, Tipos de egreso, **Personas** (toggle dueño/propietario). SQL 46→49 en BD. |
| **Egresos** | Badge Financiero: **Gastos y pagos**. Beneficiario = Proveedor **o** Persona. Filtros: Naturaleza → Proveedor → Persona. |
| **Cuenta del dueño** | Clasificar en OF ≠ pagar. Para bajar saldo: egreso PERSONAL/DIVIDENDOS + persona **dueño** + origen Cuenta del dueño. |
| **Sandbox consulta BD** | Admin puede (vía API / IA) hacer `SELECT` de verificación; no es pantalla del cajero. |
| **Sobrepago QR** | Devolución desde caja: en **Cierre/Ingresos**, movimientos de **efectivo ≈ −diff** y del **QR ≈ +diff**. Ya no debe quedar la caja en 0 movimientos por “egreso” mal tipado. |
| **Historial Tickets** | Filtro medio (+ Mixto) + **Tickets sin corte**; chip Con notificación / Pendiente; modal **Productos** con **Atendió: …**. |
| **OF → Tickets sin corte** | Icono en tarjeta del medio abre modal arrastrable: total parcial alineado, filas info\|monto\|productos, medio en color, usuario que atendió. |

---

## 2. Checklist pair testing (prioridad)

### A. Personas + egreso dueño
1. Dominios → Personas: crear/editar; marcar **Es dueño / propietario** en una y no en otra.
2. OF: llevar plata a **Cuenta del dueño** (legalizar / traslado).
3. Egresos → nuevo PERSONAL + persona dueño → origen **Cuenta del dueño** visible → guardar → baja saldo OF.
4. Misma naturaleza + persona **sin** flag → no debe permitir ese origen.
5. Naturaleza compra + persona dueño → no Cuenta del dueño.

### B. Historial + modal sin corte
1. Varias ventas Pagadas en un medio (p.ej. Nequi) **sin** hacer corte.
2. Historial: filtro ese medio + check **Tickets sin corte** → mismas ventas.
3. Chip notificación coherente con panel QR (si aplica).
4. OF → tarjeta del medio → icono tickets sin corte → lista = mismas ventas; total parcial alineado a la derecha con montos; **Atendió** en fila/modal productos; ventana se puede arrastrar.
5. Productos: sin texto “Total líneas”; total alineado a columna Subtotal; título con **Atendió: nombre**.

### C. Sobrepago QR → cierre
1. Venta QR esperada (ej. 75k); banco confirma de más (ej. 95k); confirmar sobrepago + devolución desde **Caja efectivo**.
2. OF: QR +20k (ajuste); Caja −20k (ajuste), no “salida egreso” confusa.
3. Ingresos / corte del turno: movimientos caja ≈ −20k; QR ≈ +20k; totales coherentes (ej. efectivo 150k base −20k = 130k; QR 75k +20k = 95k).

### D. Sandbox (IA / admin)
1. Tras reset o ciclo limpio: logout + login si lo pide.
2. Verificación SQL solo lectura vía `POST /sandbox/consulta-bd` (flag `habilitarEndpointConsultaBd`).
3. Ejemplos útiles abajo.

---

## 3. SQL de verificación (consulta-bd)

Solo en **sandbox**, rol admin, body `{ "sql": "…", "maxRows": 50 }`.

```sql
-- Personas dueño
SELECT id, documento, nombre, es_dueno_propietario, activo
FROM persona ORDER BY id DESC LIMIT 20;

-- Egresos recientes con persona
SELECT e.id, e.naturaleza, e.valor, e.persona_id, p.nombre, e.origen_fondos_id
FROM egreso e
LEFT JOIN persona p ON p.id = e.persona_id
ORDER BY e.id DESC LIMIT 20;

-- Movimientos sobrepago QR
SELECT id, origen_fondos_id, tipo, origen_tipo, valor, observacion, fecha
FROM movimiento_origen_fondos
WHERE origen_tipo = 'QR_MONTO_DISTINTO'
ORDER BY id DESC LIMIT 20;

-- Tickets / HRE
SELECT id, estado, monto_esperado, historial_recibo_id, fecha_creacion
FROM historial_recibos_electronicos
ORDER BY id DESC LIMIT 20;
```

---

## 4. Migración BD (si el ambiente aún no la tiene)

Orden en `pos-relational-data-service/.../database/`:

1. `46_egreso_naturaleza_tipo.sql`
2. `47_naturaleza_tipo_egreso.sql`
3. `48_persona_egreso.sql`
4. `49_persona_es_dueno_propietario.sql`

Sandbox BD: `controlneg_rmx_db_sandbox`.

---

## 5. Rutas de pantalla

| Qué | Dónde |
|-----|--------|
| Historial | `/apps/tickets/historial` |
| OF | `/apps/financiero/origenes-fondos` |
| Egresos | `/apps/financiero/egresos` |
| Ingresos / cortes | `/apps/financiero/ingresos` |
| Personas | Dominios → Personas |
| Tipos / naturalezas egreso | Dominios → catálogos egreso |

---

## 6. Docs triple (detalle técnico / contratos)

| Capa | Path |
|------|------|
| QA principal | `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` |
| Esta oleada | `doc-ayuda-inteligente/ACTUALIZACION-QA-2026-08-26.md` |
| Historial narrativo | `contextos-ia/historial-tickets.md` |
| Egresos / personas | `contextos-ia/egresos.md` |
| QR / sobrepago | `contextos-ia/confirmacion-pagos-electronicos.md` |
| Sandbox + consulta BD | `contextos-ia/sandbox-reset-transaccional.md` |
| OF | `contextos-ia/origenes-fondos.md` |
| Specs | `openspec/specs/egresos-personas/`, `egresos-naturaleza-tipo/`, `confirmacion-pagos-electronicos/`, `sandbox-entorno-pruebas/`, `historial-tickets/` |
| Índice | `DUAL-DOCS-CURSOR-OPENSPEC.md` |

---

*Actualizar este archivo cuando cierre la siguiente oleada de aceptación; el perfil estable del día a día sigue siendo `CONTEXTO-TESTER-POS.md`.*
