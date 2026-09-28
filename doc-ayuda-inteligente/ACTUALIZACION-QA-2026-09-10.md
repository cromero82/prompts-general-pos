# Actualización QA — oleada 2026-09-10

**Para:** tester + IA en pair testing (sandbox / pos-local).  
**Cargar junto a:** `CONTEXTO-TESTER-POS.md` (siempre; §4.15 / §4.10 / §4.11 / §4.14 / §10.10).  
**Narrativo:** `contextos-ia/notificacion-egreso-vinculo.md`.  
**Spec:** `notificacion-egreso-vinculo`.  
**SQL sandbox:** `59_notificacion_vinculo_operacion.sql` (tras `53`→`56` si el ambiente es viejo).  
**Reiniciar:** `puente-tienda` si el jar no tiene alertas / hold inbound.

**Chat / trabajo de referencia:** campanita de PAGASTE vs egreso ya registrado; diálogo **Asociar y ver en egresos** / **Enviar a Sin clasificar**; botón **Borrar filtro notificación**; no auto-saltar con 1 alerta.

Las oleadas `2026-09-06` (comentario + asistente + minimizar), `2026-09-03` (Historial) y `2026-09-02` (medios/plantillas) **siguen vigentes**.

---

## 1. Qué cambió (negocio)

| Tema | Qué debe notar el tester |
|------|---------------------------|
| **PAGASTE con egreso del mismo monto** | **No** aparece solo en Sin Clasificar. Sale **campanita** (número) junto al usuario **y** en la tarjeta Sin Clasificar. |
| **Ventana siempre** | Aunque quede 1 aviso y 1 egreso, el clic **abre la ventana**. No salta solo a Egresos. |
| **Botones** | **Asociar y ver en egresos** liga y abre la lista. **Enviar a Sin clasificar** mueve a la bolsa **sin** ligar el egreso. |
| **Proveedor / Persona** | En la ventana: monto, fecha/hora, PAGASTE y el nombre del proveedor o de la persona. **No** «Sin pagador». |
| **Filtro en Egresos** | Tras asociar se ve **un** registro y el botón **Borrar filtro notificación** (visible, dos veces). Lo quita y vuelve la lista normal. |
| **PAGASTE sin egreso candidato** | Va a Sin Clasificar **sin** campanita (como antes). |
| **Cierre tras formalizar** | En QR/Nequi/otro electrónico: **Egresos** = el gasto; **Movimientos** = cobranzas, **sin** restar otra vez el PAGASTE. Esperado = saldo de esa OF. |

---

## 2. Checklist pair testing (prioridad)

### A. Campanita y ventana (~15 min)

1. Crear egreso $X (proveedor o persona) desde el bolsillo del QR/banco.
2. Hacer llegar PAGASTE del mismo $X.
3. Ver número en header **y** en Sin Clasificar. En Sin Clasificar **no** debe haber movimiento nuevo de ese aviso.
4. Clic campanita → ventana. Textos de botones correctos. Nombre Proveedor o Persona.
5. Cerrar sin elegir → el número sigue.

### B. Asociar (~10 min)

1. **Asociar y ver en egresos** → lista con ese egreso resaltado.
2. **Borrar filtro notificación** visible junto al título y sobre la tabla → lista completa.
3. Gestión notificaciones: el correo **no** aparece como Por identificar; clasificación tipo **Egreso #**.

### C. Segundo aviso (~10 min)

1. Otro PAGASTE del **mismo** $X (sin segundo egreso) → campanita = 1.
2. Clic → **otra vez la ventana** (no navega solo).
3. **Enviar a Sin clasificar** → sí hay movimiento en la bolsa; el egreso ya ligado no cambia.

### D. Sin candidato (~5 min)

1. PAGASTE de un monto **sin** egreso parecido → Sin Clasificar, **sin** campanita de ese caso.

### E. Cierre de turno tras formalizar (~5 min)

1. Cobranza electrónica $100.000 (QR o Nequi) + PAGASTE $50.000 enviado a Sin Clasificar y **formalizado** como egreso.
2. Cierre de turno de ese medio: Ventas 0 (si no hubo venta de ese medio), Movimientos **100.000**, Egresos **50.000**. No 50.000 en Movimientos.

### F. (Opcional) Asociar tarde

1. Un PAGASTE que **sí** pasó por bolsa + egreso después → desde Egresos **Asociar notificación** → el paso por bolsa se **anula** (no un ajuste extra).

---

## 3. Sí reportar / No es bug

| Observación | Tip |
|-------------|-----|
| Ventana con un solo candidato | **Diseño OK** |
| PAGASTE sin egreso a Sin Clasificar | **Diseño OK** |
| Lista de Egresos con un solo registro tras asociar | **Diseño OK** si está Borrar filtro |
| Campanita ausente con egreso + PAGASTE mismo monto | **Bug** |
| Clic salta a Egresos sin ventana | **Bug** |
| «Sin pagador» en el diálogo | **Bug** |
| No se ve **Borrar filtro notificación** | **Bug** |
| Asociar deja movimiento de fusión o doble plata en bolsa | **Bug** |
| Tras formalizar PAGASTE, Cierre resta el monto en Movimientos **y** en Egresos | **Bug** |

---

## 4. Entregar a la IA / tester

1. Este archivo + `CONTEXTO-TESTER-POS.md`.  
2. Confirmar script **59** en la BD del ambiente.  
3. Oleadas 09-06 / 09-03 / 09-02 si el ciclo también toca comentario, Historial o medios.
