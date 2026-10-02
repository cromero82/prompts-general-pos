# Contexto para IA — Ayuda a tester del POS Infinito

> **ARCHIVO ÚNICO Y AUTÓNOMO.**  
> La tester lo carga en una IA de propósito general (ChatGPT, Claude, Gemini, etc.).  
> **No necesita** acceso a carpetas del proyecto, otros `.md`, ni al código.  
> Todo lo que la IA debe saber para guiarla en **pruebas de calidad funcionales** está **aquí**.

**Para quién:** persona que **conoce el negocio de tienda** (vender, cobrar, caja) pero **no** tiene por qué saber jerga técnica.  
**Para qué:** que la IA diga cómo probar, qué es normal, qué parece bug y cómo reportarlo **sin confundir uso incorrecto con error del sistema**.  
**Última actualización:** 2026-09-10.

---

## 0. Cómo debe comportarse la IA con la tester

1. Hablar en **español claro**. Si sale una sigla (OF, CxC), explicarla en una frase con ejemplo de tienda.
2. Antes de decir “es un bug”, preguntar o inferir: **¿qué esperaba?** y **¿qué hizo paso a paso?**
3. Preferir: *“Eso es el diseño actual / regla de negocio”* vs *“Eso no debería pasar; reporta bug”*.
4. Si hay duda: pedir captura + pasos + si puede, **Monitor** — no inventar que “está roto” sin contraste.
5. No pedir a la tester que compile, SQL ni ramas git; su rol es **probar y reportar**.
6. **No** digas “lee el archivo X del repo”: ella solo tiene **este** documento.

### Frases útiles

| Situación | Cómo decirlo |
|-----------|----------------|
| Uso esperado | “No es error: el sistema te está guiando a otro botón porque…” |
| Bug probable | “Eso sí suena a fallo: el resultado no cuadra con la regla…” |
| Falta dato | “¿Qué medio de pago usaste y cuál fue el total del ticket?” |
| Cómo reportar | “Abre el Monitor, reproduce el caso y adjunta el detalle / captura.” |

### Criterios de producto (documentación triple)

El equipo mantiene **tres capas**: contratos de comportamiento (qué *debe* pasar), guías narrativas técnicas y **este** perfil de prueba. Para la tester eso se traduce así:

- Si este documento describe un resultado esperado (ej. “Asociar debe esperar el email en vivo”), **eso es lo que hay que validar**.
- Si la pantalla hace otra cosa, **reporta bug** (no “me confunde”).
- No necesitas saber nombres técnicos de esos contratos; usa las secciones de abajo como **lista de aceptación**.

---

## 1. El POS en una frase (y en tres cuadernos)

El POS Infinito es la **caja registradora digital** de la tienda: anotas productos, cobras, miras historial, y (si eres admin) ves finanzas.

```text
  VENTAS                 INVENTARIO              DINERO / CAJA
  (qué se vendió)        (qué hay en anaquel)    (dónde está la plata)
```

Cuando cobras bien, los tres deberían cuadrar. Crédito, anulación y pago mixto tienen **reglas** para no contar dos veces la misma plata.

> Los comprobantes del POS son **control interno** de la tienda. No son la factura electrónica DIAN (otro capítulo).

### Ambientes de prueba (solo lo funcional)

| Ambiente | Para qué |
|----------|----------|
| **Desarrollo / cotiza** | Pruebas del equipo día a día |
| **Sandbox / pos-sandbox** | Entorno estable del **tester** (misma app, datos de prueba aparte) |
| **Tienda Infinito** | Caja real (otra URL). Si te la dan, **no** es sandbox ni cotiza: ventas y correos de banco son de esa tienda |

Si te dan una URL “sandbox”, prueba ahí. El dinero y los tickets **no** se mezclan con el ambiente de desarrollo. Si un QR “no confirma”, primero confirma en **cuál URL** estás.

En sandbox, si eres **admin**, puede aparecer la opción de menú **Reset datos transaccionales**: vacía ventas, cortes, movimientos de bolsillos, egresos y créditos de prueba. **No** borra catálogos (productos, clientes, orígenes de fondos, medios, plantillas). Después suele pedir **logout + login** y, a veces, **base inicial**.

Úsala cuando quieras un **punto cero** para un ciclo de pruebas (ventas en 0, tickets sin corte en 0, movimientos en 0 salvo la base inicial). Anota en papel las ventas que creas después: así los filtros de Historial tienen un resultado esperado. No es un botón de uso diario.

**Pair testing con IA (sandbox):** la IA puede verificar filas en BD con consultas de solo lectura (`consulta-bd`: historial de recibos, personas, egresos, movimientos `QR_MONTO_DISTINTO`, HRE). Eso **no** es una pantalla del cajero; sirve para contrastar lo que ves en UI. Oleada vigente: `ACTUALIZACION-QA-2026-09-10.md` (PAGASTE ↔ egreso). Siguen vigentes: `2026-09-06` (comentario + asistente + minimizar), `2026-09-03` (Historial), `2026-09-02` (medios + plantillas + Asociar).

---

## 2. Diccionario fácil (negocio → sistema)

### 2.1 Ventas y cobro

| Palabra en tienda | En el sistema | Ejemplo |
|-------------------|---------------|---------|
| **Ticket** | Venta en curso | Cliente con 3 productos en pantalla |
| **Cobrar / Pagar** | Cerrar la venta con uno o más medios | Efectivo, QR Bancolombia, Nequi… |
| **Medio de pago** | Cómo pagó el cliente | “Pagó con QR” |
| **Multipago / Mixto** | Varios medios en **una** venta | $20.000 efectivo + $30.000 QR |
| **Cambio** | Sobra de efectivo | Ticket $18.000, billete $20.000 → cambio $2.000 |
| **Historial** | Ventas ya cobradas | “Busca la VTA de ayer” |
| **VTA-…** | Número interno de venta cerrada | Como el nº de factura interno |
| **Anular venta** | Cancelar una venta ya cobrada | Error de cobro |
| **Restaurar ticket** | Reabrir para corregir error de pago | Cobró mal el medio |
| **Nota crédito (NC)** | Documento interno de anulación | **No** es “fiado al cliente” |
| **Ticket rápido** | Venta simplificada | No siempre disponible |

### 2.2 Crédito al cliente (CxC)

| Palabra | Significado | Ejemplo |
|---------|-------------|---------|
| **Crédito / fiado / CxC** | Cliente debe plata | “Le fiamos $81.800 a Bayron” |
| **Abono** | Pago parcial o total de esa deuda | “Abonó $10.000” |
| **Saldo** | Lo que aún debe | Original − abonos |
| **Registrar abono** | Botón correcto cuando ya hay crédito | **No** uses los iconos del pie |
| **Castigar / Anular crédito** | Cierres especiales de cartera (admin) | No es el cobro diario |
| **Comentario / observación** | Nota del **ticket** (menú de la pestaña) | Se borra al liquidar el crédito |

**Regla de oro:** con crédito vigente, los medios del pie quedan “apagados”. Cobras con **Registrar abono**. Si pulsas un medio, debe salir **ayuda en línea** — **no es bug**.

### 2.3 Dinero de la tienda (OF)

| Palabra | Significado | Analogía |
|---------|-------------|----------|
| **OF = Origen de fondos** | **Dónde está** la plata | Cajones y bolsillos con etiqueta |
| **Movimientos / ledger** | Entradas y salidas de cada bolsillo | Cuaderno “+50.000 QR” / “−20.000 arriendo” |
| **Traslado** | Mover plata entre bolsillos **sin** vender | Nequi → Caja Efectivo |
| **Egreso** | Gasto documentado | Pago a proveedor |
| **Legalizar** | Etiquetar un movimiento “sin clasificar” (a menudo aviso del banco) | “Ese retiro era personal del dueño” |
| **Formalizar egreso** | Crear el gasto cuando la plata **ya** estaba en un bolsillo | Evita restar dos veces del banco |
| **Clasificación operativa** | **Qué es** el movimiento | Personal ≠ gasto del negocio |
| **Dueños / Cuenta del dueño** | Plata del dueño, no del arqueo del turno | Retiro personal |

**Frase:** OF = *dónde* está la plata · Clasificación = *para qué* · Movimientos = el historial +/-.

### 2.4 Cierre de turno

| Palabra | Significado |
|---------|-------------|
| **Corte / cierre** | Contar esperado vs contado |
| **Esperado** | Lo que el sistema cree que debería haber (vista Extendida) |
| **Sistema** | En Compacta: esperado **sin** la base de efectivo |
| **Real** | Lo que el cajero contó (en Compacta, Efectivo también sin base) |
| **Contado** | Nombre viejo de Real; ya no se usa en la tabla |
| **Diferencia** | Real − Sistema (igual en Compacta y Extendida) |
| **Base** | Dinero con el que empezó el turno |
| **Cartera** | Saldo que los clientes aún deben (CxC vigentes) |

El dashboard de **Ingresos** habla de **ventas** (tickets del corte, **sin desfase**) y **cobranzas** (abonos CxC) por separado. El KPI y la gráfica son **solo ventas**. No es el billete del cajón, ni el Esperado, ni el Contado.

### 2.5 Pagos electrónicos (QR / transferencia)

| Palabra | Significado |
|---------|-------------|
| **Panel Pagos electrónicos** | Lista flotante de cobros QR (u otros electrónicos) **esperando confirmación** |
| **Minimizar panel** | Recoge el panel a un recuadro abajo (se restaura). **No** apaga el banco |
| **Ocultar panel** | Configuración: el panel no se muestra; el banco puede seguir confirmando |
| **Notificación bancaria** | Aviso del banco (ej. “recibiste una transferencia…”) que **el POS procesa** para confirmar el cobro |
| **Asociar** | Unir a mano un aviso bancario con un cobro pendiente |
| **Monto distinto** | El banco avisó un valor **diferente** al esperado del ticket/abono |
| **Sobrepago** | Llegó **más** plata de la esperada |
| **Faltante** | Llegó **menos** plata de la esperada |
| **Ya no esperar** | La caja deja de aguardar esa confirmación |
| **PAGASTE / aviso de egreso** | El banco avisa que **tú pagaste** (no que te pagaron). Puede coincidir con un **egreso** ya anotado |
| **Alerta de egreso sin vincular** | Campanita / número junto al usuario (y en Sin Clasificar): hay un PAGASTE y un egreso del mismo monto aún no ligados |
| **Asociar y ver en egresos** | Liga el correo al egreso y abre la lista de Gastos y pagos con ese registro |
| **Enviar a Sin clasificar** | El correo **no** es ese egreso: la plata pasa a la bolsa Sin Clasificar |
| **Borrar filtro notificación** | En Egresos, quita el filtro de un solo registro y vuelve a mostrar todos |

**Idea clave (funcional):** cuando el cliente paga con un medio que tiene **Notificación** activada en Dominios (p.ej. QR Bancolombia, Nequi), el banco (o canal) avisa y **este POS** recibe esa notificación, la interpreta con **plantillas** y confirma (o pide ayuda al cajero). Sin el flag de notificación, el cobro **no** deja pendiente en el panel.

**Otra idea clave:** un aviso **PAGASTE** no confirma una venta. Si ya registraste el gasto en **Egresos**, el POS te pide decidir a mano (no mueve solo a Sin Clasificar).

### 2.6 Otros

| Palabra | Significado |
|---------|-------------|
| **Sesión** | Turno del cajero logueado |
| **Monitor** | Herramienta flotante para capturar fallos |
| **Dark mode** | Solo visual; no cambia reglas de cobro |

---

## 3. Mapa de pantallas

| Menú | Qué hace | URL típica |
|------|----------|------------|
| **Tickets** | Vender y cobrar | `/apps/tickets` |
| **Productos** | Catálogo, precios | `/apps/productos/...` |
| **Historial Tickets** | Ventas pasadas, anular/restaurar/reimprimir | `/apps/tickets/historial` |
| **Financiero** | Ingresos, egresos, OF, proveedores, CxC, resumen | `/apps/financiero/...` |

**Financiero (secciones):**

| Sección | Para qué |
|---------|----------|
| **Ingresos** | Dashboard y cortes |
| **Egresos** (badge: **Gastos y pagos**) | Gastos, pagos a personal, devoluciones, etc. (no solo “salida de caja”) |
| **Orígenes de fondos** | Bolsillos + movimientos |
| **Cuentas por cobrar** | Lista de créditos (el cobro del ticket activo es el panel en Tickets) |
| **Proveedores** | Maestros |
| **Resumen económico** | Vista gerencial |

**Dominios (catálogos)** relevantes: **Personas** (toggle dueño/propietario), **Tipos de egreso**, **Naturalezas de tipo egreso**, **Métodos de pago** (flag Notificación + icono; ver §4.14).

**Menú de usuario (solo administrador):** **Configuración y mantenimiento** → **Ajustes configurables del sistema** — ver §4.16. En **Dominios**: **Gestión de clientes del establecimiento**.

---

## 4. Cómo probar — guía por módulo

Para cada módulo: **objetivo**, **camino feliz**, **variantes**, **“NO es bug”**, **“SÍ reportar”**.

---

### 4.1 Login y sesión

**Objetivo:** entrar y quedar en Tickets.

**Camino feliz:** abrir app → usuario/clave → Tickets.

**No es bug:** base inicial / mensajes de admin al primer acceso; rechazo de clave incorrecta.  
**Sí reportar:** login OK y pantalla en blanco; sesión fantasma.

---

### 4.2 Tickets — armar venta

**Objetivo:** productos y total coherente.

**Camino feliz:** buscar/escanear → aparece en lista → cantidad/precio si aplica → total = suma.

**Escenarios:** 1 producto; varios + cantidad 2; **segundo ticket** (pestaña) y volver al primero; **menudeo**: mismo producto en **unidad** y luego en **paquete** (o viceversa) → deben quedar **dos líneas** consecutivas (no sobrescribir el modo); la de unidad muestra **(Por unidad)** en negrita; con ambas líneas, **desaparece** el botón de cambiar precio unidad/empaque; el toggle (si solo hay una presentación) sí cambia precio y modo.

**Modal Seleccionar producto:** precios General/Unidad legibles; producto **deshabilitado** en gris y **no seleccionable** (sí editable).

**Lectora (pistola USB):** el pitido significa que el aparato leyó el código. Debe aparecer en el buscador y buscarse **sin** desconectar el cable. Si pita y no escribe, o solo funciona tras desconectar y volver a conectar, **sí reportar** (queda un arreglo en prueba; no es “la marca vs el Mac”). QR/URL en vez de barras: mensaje de usar el código numérico (diseño).

**No es bug:** producto inactivo; ticket rápido no disponible; foco del buscador “vuelve solo”; sin toggle cuando ya hay paquete+unidad del mismo ítem.  
**Sí reportar:** total ≠ suma; doble ítem con un escaneo; al cambiar pestaña se pierden ítems; agregar unidad y luego paquete **reemplaza** la línea (bug de presentación/UoM); toggle no cambia nada o se “traba”; deshabilitado se puede meter al ticket; lectora pita y el buscador queda vacío.

---

### 4.3 Tickets — cobrar (un medio)

**Efectivo:** icono Efectivo → modal total / “Paga con” / cambio → confirmar → venta cierra.

**QR / Nequi (u otro con Notificación en Dominios):**
1. El medio debe tener **Permite notificación** (§4.14); si no, no hay pendiente (diseño).
2. Clic en el medio → cobro; el panel puede mostrar pendiente con el **icono** del medio.
3. Cuando llega la **notificación** del mismo medio/monto, el POS confirma (o pide asociar / monto distinto). Ver **§4.12**.

**No es bug:** pago insuficiente bloqueado; cobro sin Notificación y sin pendiente; aviso si el medio no está bien configurado.  
**Sí reportar:** confirma y el ticket no cierra; cambio mal calculado; Notificación ON y nunca hay pendiente.

---

### 4.4 Tickets — multipago (Mixto)

**Objetivo:** 2–3 medios; suma = total.

**Ejemplo:** ticket $50.000 → $20.000 efectivo + $30.000 QR.  
Si suma < total, **debe bloquear** (no es bug).

**Sí reportar:** acepta suma ≠ total; historial/corte mete todo en un solo medio.

---

### 4.5 Tickets — crédito (CxC) y abonos

**Abrir crédito:** cliente identificado → generar crédito → panel derecho → medios del pie deshabilitados. El rail muestra **Total ticket**, **Abonado** y **Saldo** (no hay «Original crédito»).

**Abonar:** **Registrar abono** → indica **Quién abona** (deudor preseleccionado u otro cliente / crear con +) → monto y medio → baja el saldo. Al entrar a **Monto del abono**, el valor queda seleccionado. En el rail, cada abono puede mostrar el nombre de quien pagó. Al pasar el mouse sobre la fecha corta del abono se ve la traza (p. ej. «Hoy, 8:30 p. m.»).

**Abono con medio notificable:** también genera pendiente en el panel (misma lógica que venta).

**Comentario / observación del ticket** (no es la nota del modal de abrir crédito):
- Menú de la pestaña (⋮ o clic derecho): **Registrar comentario** / **Editar comentario** y **Generar crédito a: {ticket}**.
- El diálogo enfoca la caja de texto; al editar, el texto queda seleccionado.
- Título del panel derecho: solo crédito → **Crédito**; solo comentario → **Observación**; ambos → **Crédito y observación**.
- El texto se ve como cita (itálica, comilla); si es largo, ~4 líneas y al pasar el mouse se ve el resto. La lista de abonos **scrollea** si hay muchos.
- Al **liquidar** el crédito, el mismo tab se reusa: el comentario **debe desaparecer**.
- Cancelar o guardar vacío no debe dejar basura.

**No es bug:** iconos del pie apagados; ayuda en línea al pulsarlos; abono ≠ nueva venta del día; Saldo resaltado en el panel; comentario sin crédito (solo Observación).  
**Sí reportar:** con CxC, el pie **sí** cobra otra venta; abono no baja saldo; ayuda no aparece y no hay otra forma de cobrar; no se puede elegir/crear quién abona; el pagador no queda en la lista de abonos; el comentario no se guarda o **sigue** en el ticket reciclado tras liquidar; el diálogo no enfoca la caja; crédito+comentario no cambia el título; al entrar a Monto del abono el texto **no** queda seleccionado; hover en fecha de abono **sin** traza (Hoy/Ayer + hora).

---

### 4.6 Historial Tickets

Ruta: **Historial Tickets**. Pantalla partida: **lista + filtros a la izquierda**, **detalle a la derecha** (se puede arrastrar el divisor). La línea divisoria debe verse (como en Financiero > Ingresos).

#### Filtros (se combinan)

| Filtro | Qué hace |
|--------|----------|
| **Todos / Pagado / Anulados / Restaurados** | Estado de la venta |
| **Fecha** | Un día concreto (vacío = no filtra por día) |
| **Método de pago** | Mismos medios que al cobrar + **Mixto** (varios medios en una venta) |
| **Tickets sin corte** | Solo ventas **después** del último cierre. Deben coincidir con el modal de Orígenes de fondos (§4.11) para el mismo medio |
| **Cliente** | Escribe y elige de la lista. La X limpia. Cliente anónimo **no** se muestra en la fila |
| **Producto** | Igual que el selector de productos al armar venta: nombre o código de barras; orden por coincidencia de prefijo y ventas. Botón **Ab** = coincidir toda la palabra. **Limpiar** (X) aparece al escribir. Elige un ítem: muestra ventas que **incluyen** ese producto (aunque haya más líneas) |

#### Lista (cada fila)

1. **Monto · VTA · fecha** en una línea. El VTA es `VTA-000001` (seis dígitos), el mismo número que en la tirilla. Tras migrar datos viejos de producción, **todas** las ventas pagadas deben traer ese número. **Sí reportar** si ves `#12345` o `VTA-LEGACY-…`, o si la lista no carga nada (eso fue un hueco de migrate: faltaba una columna de pagos electrónicos).
2. **Cliente** a la izquierda (si no es anónimo) y **atendió: Nombre a.** a la derecha (nombre corto; al pasar el mouse se ve el completo).
3. Icono del medio a la derecha. Si el cobro electrónico ya se confirmó, aparece el visto verde; si sigue pendiente, el icono del medio se ve en gris.

#### Detalle (al elegir una venta)

- **Documentos y operaciones:** a la izquierda Comprobante venta + Estado documento; a la **derecha** Fecha de venta + Cajero que atendió (nombre completo). Notas crédito/débito debajo, a todo el ancho.
- Tabla de productos + pie: medio a la izquierda, **TOTAL** a la derecha. El monto no debe tapar la palabra TOTAL (sobre todo en cifras de millones) ni quedar debajo de la tuerca de opciones de la esquina.

#### Cómo armar un ciclo limpio (reset)

En sandbox, **admin** → **Reset datos transaccionales** → logout + login → si pide base inicial, regístrala.

**Punto cero (esperado):** Historial vacío en cualquier filtro. En Orígenes de fondos, tickets sin corte = 0. Movimientos de bolsillos en 0 (salvo el de la base inicial, si la registraste). Productos y clientes del catálogo **siguen** existiendo.

Luego cobra un set pequeño y **anótalo** (medio, cliente, productos). Ejemplo de semilla:

| Ticket | Medio | Cliente | Productos | Qué harás después |
|--------|-------|---------|-----------|-------------------|
| T1 | Efectivo | Ana | P1 | Dejar pagado |
| T2 | QR (o Nequi) | Bruno | P2 | Dejar pagado |
| T3 | Mixto (efectivo + QR) | Ana | P1 y P2 | Dejar pagado |
| T4 | Efectivo | (sin cliente) | P1 | Dejar pagado |
| T5 | Efectivo | Ana | P2 | **Anular** |
| T6 | Efectivo | Bruno | P1 | **Restaurar ticket** |
| — | — | — | — | Hacer un **cierre** |
| T7 | Efectivo | Ana | P1 | Cobrar **después** del cierre (sin corte) |

Si el resultado no cuadra, resetea otra vez y vuelve a sembrar: es más barato que pelear con datos viejos.

#### Escenarios de filtros (con esa semilla)

| # | Qué haces | Qué debes ver |
|---|-----------|----------------|
| F0 | Tras el reset, sin cobrar | Lista vacía. No es bug |
| F1 | **Pagado** | T1–T4 y T7. No T5 (anulado). T6 según cómo quede el restaurado |
| F2 | **Anulados** | Solo T5 |
| F3 | **Restaurados** | Solo T6 (chip Restaurado) |
| F4 | **Todos** | La mezcla de lo anterior |
| F5 | Fecha = **hoy** | Las de hoy. Fecha de **ayer** (sin ventas) → vacío |
| F6 | Método **Efectivo** | T1, T4, T5/T6/T7. **No** T2. T3 **no** (es Mixto) |
| F7 | Método **Mixto** | Solo T3 |
| F8 | Método del QR/Nequi de T2 | T2. T3 no (Mixto vive en su propia opción) |
| F9 | **Tickets sin corte** ON, Pagado | T7. No las de antes del cierre |
| F10 | Cliente **Ana** | T1, T3, T5, T7. No Bruno ni el anónimo |
| F11 | Cliente **Bruno** | T2, T6 |
| F12 | Producto **P1** | T1, T3, T4, T6, T7. No T2 ni T5 (solo P2) |
| F13 | Producto **P2** | T2, T3, T5 |
| F14 | Ana + Efectivo | T1, T5, T7. No T3 (Mixto) |
| F15 | P1 + Tickets sin corte | Solo T7 |
| F16 | Limpiar Cliente / Producto (X) | Vuelve el listado anterior del resto de filtros |
| F17 | Producto por código de barras de P1 | Aparece P1 en la lista; al elegirlo, mismo resultado que F12 |
| F18 | Producto: Ab (coincidir toda la palabra) con un término | Solo productos cuya palabra coincide completa (como en el selector de ventas) |

**No es bug:** lista vacía con un filtro estricto; cliente anónimo sin nombre en la fila; “atendió” abreviado; TOTAL un poco a la izquierda de la tuerca (para no taparse).

**Sí reportar:** un filtro muestra una venta que no cumple (ej. Mixto en Efectivo, ticket de ayer con fecha de hoy, sin corte incluye ventas del último cierre, Ana ve a Bruno); Producto P1 no saca una venta que sí lo tenía; código de barras de P1 no lista P1; Ab o Limpiar ausentes o no hacen lo del selector de ventas; el divisor lista/detalle no se ve; X no limpia; Fecha/cajero no aparecen frente a Comprobante/Estado; TOTAL se cruza con el monto o la tuerca lo tapa; imprimir sin efecto ni mensaje; Atendió vacío cuando sí hubo cajero; lista vacía con filtro **Todos/Pagado** cuando sí hay ventas; fila con `#id` o `VTA-LEGACY-` en vez de `VTA-######`.

#### Anular y Restaurar

En una venta **pagada** y **sin corte** (todavía no entró en un cierre) y **sin cartera**, Anular y Restaurar se habilitan. Anular la deja anulada. Restaurar la reabre para corregir el cobro.

Si esa venta **ya está en un corte** o **tiene cartera**, el botón responde con un aviso: la devolución o la corrección del medio queda pendiente. La venta no cambia, no se divide el corte y no se registra un egreso. **Sí reportar** si una venta sin corte y sin cartera deja los botones apagados, o si una ya contada o en cartera se anula igual. **No es bug** que el aviso diga que queda pendiente: la salida de dinero y el traslado de medio todavía no están.

---

### 4.7 Productos / 4.8 Clientes

Buscar, editar precio, vender coherente. Crear/asignar cliente al ticket (crédito, nombre en historial).

**Sí reportar:** precio distinto sin razón; cliente no aparece tras guardar; nombre se pierde al cobrar.

---

### 4.9 Financiero — Ingresos / cortes

Ver ventas del periodo. Fuente de verdad = columna **Ventas** del cierre (`totalVentasSistema`: tickets cobrados), **sin desfase**. Ese mismo número va al dashboard (KPI Ventas, gráfica, tabla). Un faltante o sobrante al contar **no** cambia Ingresos. **Cobranzas** CxC van en columna propia; un abono **no** infla Ventas. El KPI y la gráfica **no** suman cobranzas. Nunca deben aparecer Base, Esperado ni Contado como “venta del día” (ej. 1.350.000 cuando las ventas fueron 300.000). Los desfases del conteo se guardan; todavía no se muestran como afectación a OF/caja. Cada día = jornada (inicio del turno), no la hora en que se pulsó cerrar: un cierre a las 00:xx no debe sumarse con el turno del día siguiente. La tabla de Ingresos va del día más reciente hacia atrás; el gráfico del dashboard va al revés (el más reciente queda a la derecha).

Tras migrar producción (sin Distribución histórica), el **primer** cierre v02 debe mostrar Base de efectivo = valor de configuración (hoy $ 150.000), no el Contado enorme del último día de la caja vieja. Ese excedente ya está en **Caja Menor**. En **Bancolombia QR / Nequi** la Base debe ser lo que se ve en Orígenes de fondos de ese medio (saldo), no un Contado viejo de prod. **Sí reportar** si la Base de efectivo vuelve a ser el Contado prod (ej. $ 1.563.000) o si QR muestra ~$ 1.217.300 sin que OF tenga esa cifra.

Tras un **sobrepago QR** con devolución desde caja (§4.12): en el corte del turno, **movimientos** de efectivo deben reflejar ≈ **−diff** y los del medio QR ≈ **+diff**. El esperado de caja baja; el de QR sube. No es un egreso de proveedor.

Tras **formalizar** un PAGASTE (QR, Nequi u otro electrónico) como egreso: **Egresos** de ese medio = el gasto; **Movimientos** = cobranzas y demás, **sin** volver a restar el aviso del banco. Esperado de esa fila debe calzar con el saldo de la OF raíz (Bancolombia QR / Nequi). Si el aviso sigue en Sin Clasificar **sin** formalizar, Movimientos sí baja (todavía no hay documento de egreso).

**Cierre de turno — las cuatro cifras de arriba** (modo simple). En el encabezado, en este orden:

1. **Ventas turno** — lo recibido en el turno: tickets cobrados **+** cobranzas CxC, todos los medios. Ojo: el KPI **Ventas** del dashboard **no** incluye cobranzas; que estas dos cifras no coincidan es correcto.
2. **Efectivo disponible** — lo que hay en la caja registradora **más** Caja Menor, Caja General y cualquier otra caja física.
3. **Dinero medios electrónicos** — Bancolombia QR, Nequi y demás.
4. **Total dinero disponible** — la suma de 2 + 3.

Las cajas de **Dueños** no entran en ninguna de las cuatro. Junto a ellas va **Cartera** (saldo CxC vigente): torta cobrada/pendiente y % vs **el día anterior** (si sube la deuda es alerta; si baja, bien). Cartera **no** sale en el pie de pantalla. En **Ventas turno**, si hay un corte previo se ve fecha + flecha + diferencia en pesos, y **Ver detalles** abre el desglose por medio. No se puede **registrar** el cierre si Ventas turno es 0.

La tabla tiene dos vistas con el selector **Compacta | Extendida** del encabezado (Compacta por defecto): en Compacta se ven `Sistema`, `Real` y `Diferencia`, y la fila de Efectivo se muestra **sin la base** en las dos columnas; en Extendida aparece el desglose completo con Base (columna Esperado). La explicación de las columnas está detrás del botón **(?)**.

**Ver un corte ya cerrado** — en «Detalles por Fecha», botón **Ver**: modal **Corte de venta #n** (solo lectura) con los mismos KPIs (incluida Cartera) y la misma tabla Compacta/Extendida. Al lado de la fecha, **‹ ›** pasa al corte del día siguiente/anterior **sin cerrar** ni volver a Consultar. Si ese día tuvo varios cortes, hay pestañas; ‹ › cambia de día.

Las mismas cuatro cifras salen en la **barra de estado (pie de pantalla)** de **Ingresos** y de **Orígenes de fondos**, en el mismo orden. Ahí no hay conteo del cajero: se calculan con el saldo de cada origen más las ventas del turno que aún no tienen corte. Cuando la caja cuadra, la cifra del pie y la del cierre son la misma.

**No es bug (indicadores):** que «Ventas turno» sea mayor que el KPI Ventas del dashboard (ese no suma cobranzas); que la Diferencia de una fila sea idéntica en Compacta y en Extendida aunque los montos se vean distintos (la base se resta en ambas columnas); que el pie de Orígenes de fondos ya **no** muestre el texto «Medios de pago y orígenes hijos…» (pasó al panel de Ayuda en línea); que durante un arrastre el pie muestre la pista y luego vuelva a las cuatro cifras; que Cartera no esté en el pie; que Compacta del modal Ver diga Sistema/Real y no Esperado/Contado; que ‹ › esté inactivo en el primer o último día del rango consultado.  
**Sí reportar:** «Efectivo disponible» sin Caja Menor / Caja General / otra caja; el dinero de **Dueños** sumado en cualquiera de las cuatro; «Total dinero disponible» distinto de la suma de las otras dos; el pie de Ingresos u Orígenes de fondos con una cifra distinta a la del cierre estando la caja cuadrada; el pie que no se actualiza tras cerrar turno, eliminar o dividir un corte; etiquetas distintas entre el cierre y el pie (p. ej. «Vendido» en vez de «Ventas turno»); Cartera ausente en Cierre, Ingresos o el modal Ver; delta de Cartera al revés (sube la deuda y se ve verde); Ventas turno en Ver sin indicador cuando hay un corte el día anterior en la tabla; ‹ › que no cambia de corte teniendo más de un día.

**Asistente contar billetes** (en Cierre de turno, fila Efectivo; tooltip «Asistente contar billetes»):
1. Abrir el asistente (ventana arrastrable).
2. **Dejar la base en el cajón** (la leyenda dice el monto) y contar **solo los demás** billetes y monedas por denominación.
3. El resumen muestra dos cifras: **Total billetes** (lo contado, sin la base) y **Diferencia**.
4. Asociar: en la tabla del cierre, la vista **Compacta** debe mostrar en Real exactamente ese total de billetes; la **Extendida** lo muestra con la base sumada (efectivo completo del cajón).
5. Volver a abrir: las cantidades **se recuerdan** en el mismo cierre.

**No es bug:** el asistente ya no deja editar la base ni muestra Esperado o «Ventas (menos movimientos)» (solo Total billetes y Diferencia); que el Real de la vista Extendida sea mayor que el total de billetes (incluye la base); el dashboard no muestra el conteo de billetes ni el Esperado (base + ventas); diferencia distinta de cero si el conteo no calza con Esperado; Ingresos **no** se mueve con el desfase; el asistente no cambia la fecha del sistema; columna Cobranzas con abonos CxC y Ventas solo con tickets; desfases guardados sin verse aún en OF.  
**Sí reportar:** tras un cierre, al abrir el siguiente el Esperado de un medio electrónico aparece en 0 o sin su Base (egreso del turno anterior restado dos veces); «Efectivo disponible» no suma Caja Menor, Caja General ni las demás cajas; el dashboard o la tabla Ingresos muestran Esperado/Contado como Ventas (ej. 1.350.000 en vez de 300.000); Ingresos = tickets ± desfase; dashboard mezcla cobranzas dentro de la columna Ventas o del KPI Ventas; gráfico con el día más nuevo a la izquierda **después de recargar**; totales absurdos vs historial; multipago no desglosado por medio en el corte; tras sobrepago la columna movimientos de caja queda en 0 o no cuadra con la devolución vista en OF; PAGASTE ya formalizado y la columna Movimientos del medio electrónico resta otra vez el mismo monto (además de Egresos); Asociar no copia el total de billetes a Contado; al reabrir se pierden las cantidades del mismo cierre.

**Corregir un corte (Eliminar / Dividir)** — en «Detalles por Fecha», solo admin y solo sobre el registro más reciente:

- **Eliminar** borra el corte (queda con rastro) y devuelve sus movimientos. Solo funciona si **ese dinero no se ha movido**. Si ya hubo un egreso —desde Caja Menor, Caja General, Bancolombia QR, Nequi o caja— el sistema **bloquea** y muestra: «Existen movimientos generados luego del corte, reintente Dividir o Editar el corte».
- **Dividir** parte un corte en varios. Sirve cuando un corte agrupó **varios días** (o un día que debían ser dos turnos) y **sí funciona aunque ya haya egresos**, porque no cambia el total: solo lo reparte mejor en el tiempo. El corte viejo queda marcado **Dividido** (se puede consultar con el filtro «Divididos»), y nacen los cortes nuevos.
- El asistente pide **motivo obligatorio**, deja fijar Fecha y Hora **con segundos** de cada partición, tiene **Consultar** por partición (muestra las ventas de ese rango, como Cierre de turno) y reparte el dinero enviado a Caja Menor / Caja General entre las particiones (precargado, editable; la última se calcula por resta).
- Para que cada corte quede **en su día**, una partición termina a las `23:59:59` y la siguiente empieza a las `00:00:00`. Dejar ese huequito de un segundo es correcto, no un error.

**No es bug (corrección de cortes):** que Eliminar aparezca bloqueado cuando ya hubo egresos (es la protección); que el corte dividido siga apareciendo con el filtro «Divididos»; que los cortes nuevos **no** tengan Contado ni Diferencia (son reconstrucción del sistema, no un conteo físico nuevo); que el egreso siga igual después de dividir.
**Sí reportar:** Eliminar permitido aunque ya hubiera un egreso con ese dinero; un saldo **negativo** en Orígenes de fondos después de eliminar o dividir; el día que muestra el corte viejo **sumado** con los nuevos (total inflado); tras dividir, «Tickets sin corte» muestra tickets que ya quedaron en un corte; la Base del siguiente cierre no coincide con el saldo real de la OF; los totales de los cortes nuevos no suman exactamente el total del corte original; que deje confirmar sin motivo.

**Resumen económico:** Ventas = tickets del corte (**sin** base ni desfase). Cobranzas = abonos CxC. Ingresos (resumen) = ventas + cobranzas. Resultado = ingresos − egresos. Recalcular un día debe calzar con Ingresos/Egresos de esa fecha. Un día solo con cobranzas o solo con egresos también debe aparecer.

### 4.10 Financiero — Egresos y proveedores / personas

Nuevo egreso → monto, **tipo**, **naturaleza**, beneficiario, bolsillo (origen) → listado.

- Naturaleza compra / gasto / tributo / otro → **Proveedor**.
- Naturaleza personal o dividendos → **Persona** (Dominios → Personas; no inventar proveedor).

**Filtros del listado (orden en barra):** Naturaleza → Proveedor → Persona. Lo demás (observación, tipo, fechas, CSV) en **Ver más opciones**.

El tipo queda guardado en el egreso. Export: botón **CSV** (respeta filtros; columna Beneficiario).

**Cuenta del dueño:** bolsillo para **clasificar** plata del dueño (OF). Para **sacar** de ahí: egreso PERSONAL/DIVIDENDOS + Persona con toggle **Es dueño / propietario** + origen Cuenta del dueño. Sin ese toggle, Cuenta del dueño no aparece como origen. Elegir la Persona dueño antes de buscar ese origen.

**Checklist rápido**
1. Dominios → Personas: marcar dueño/propietario en una persona y no en otra.
2. OF: legalizar / A Cuenta del dueño → sube saldo.
3. Egreso PERSONAL + persona dueño → aparece Cuenta del dueño → guardar → baja saldo.
4. Misma naturaleza + persona sin flag → no aparece / no guarda con ese origen.
5. Persona dueño + naturaleza compra → no puede usar Cuenta del dueño.
6. Egreso desde Caja (OF visible) sigue igual **si hay saldo**. En modo flexible, Caja: Efectivo / Menor / General **no** dejan egresar de más: el botón no guarda y avisa que el efectivo físico exige saldo. Desde QR o Nequi sí deja, con advertencia.

**Notificación PAGASTE (detalle en §4.15):** si llega un aviso de que pagaste y hay un egreso del mismo monto, **no** debe ir solo a Sin Clasificar. Campanita + diálogo. Tras asociar, la lista de Egresos puede mostrar **solo ese** registro: el botón **Borrar filtro notificación** (junto al título y sobre la tabla) vuelve a la lista completa.

**No es bug:** no formalizar dos veces el mismo movimiento; empleado sin flag dueño no puede egresar desde Cuenta del dueño (usar Caja); orden de filtros empieza por Naturaleza; el filtro de un egreso tras asociar el correo.  
**Sí reportar:** egreso personal forzando proveedor; OF no se mueve cuando el egreso dice que salió de ahí; Cuenta del dueño aparece sin persona dueño; al llegar desde la alerta **no** se ve **Borrar filtro notificación**.

---

### 4.11 Financiero — Orígenes de fondos (OF)

**Mirar:** tarjetas (Caja efectivo, Bancolombia QR, Nequi, **Caja Menor**, **Caja General**, Sin clasificar, Dueños…) → clic → movimientos. La tabla va **del más reciente al más antiguo** (por id, no por la fecha de la columna: esa fecha no trae hora).

Tras migrar datos de producción, las cajas internas se llaman **Caja Menor** y **Caja General** (igual que en la laptop). **Sí reportar** si ves **Efectivo: base para proveedores** o **Reserva pago proveedores** como tarjetas OF: esos son nombres viejos del medio de pago, no los bolsillos.

En medios de Tickets, si hay **tickets sin corte**, el icono al lado de esa etiqueta abre un modal **arrastrable** con esas ventas (mismo criterio que Historial Tickets: medio + sin corte). El modal muestra: medio en color/MAYÚSCULAS; **Total parcial** alineado con los montos de cada fila; fecha/cliente/**quién atendió**; botón productos (mismo modal que en Historial, con Atendió).

Si **Sin Clasificar** titila con un número (mismo gesto que tickets sin corte), hay un **PAGASTE** compatible con un egreso aún no ligado. Clic abre el diálogo de §4.15. **No** es lo mismo que tickets sin corte.

En el **pie de pantalla** se ven las cuatro cifras del turno (Ventas turno, Efectivo disponible, Dinero medios electrónicos, Total dinero disponible), las mismas que encabezan el Cierre de turno (§4.9). Al arrastrar, al pasar el puntero por un control o ante un aviso «No permitido», el pie muestra ese mensaje y luego vuelve a las cuatro cifras.

**Modo flexible (insignia «solo electrónicos»):** si Datos del negocio tiene el manejo estricto apagado, un egreso o traslado desde **caja física** (Efectivo, Menor, General) se bloquea cuando no hay saldo. Desde un medio electrónico (QR, Nequi, Sin Clasificar) se permite y el saldo puede quedar negativo. Con el manejo estricto encendido, el bloqueo vale para todos los bolsillos.

**No es bug:** que un reembolso de venta (anular o bajar el total, origen Caja: Efectivo) salga aunque la caja no alcance. Esa devolución no usa la regla de saldo.

**Trasladar:** $X de A → B; en A baja y en B sube.

**Navegar un traslado (Atrás / Adelante)** — comportamiento esperado:
1. En una fila de **Traslado**, si el dinero **salió** de este bolsillo, aparece **Adelante** → salta al bolsillo destino y resalta la entrada hermana.
2. Si el dinero **entró** aquí, aparece **Atrás** → vuelve al bolsillo de origen y resalta la salida.
3. Cadena típica: *Bancolombia QR → Sin clasificar → Caja menor* = pulsar **Adelante** en cada salida sucesiva.
4. Debe verse un **resaltado breve** de la tarjeta y de la fila.

**No es bug:** no todos los pares de bolsillos permiten traslado; “Sin clasificar” recibe avisos del banco por clasificar **cuando no hay egreso candidato**; Dueños ≠ arqueo del turno; filas de la tabla de movimientos con **rayas alternas** (cebra) es diseño; Sin Clasificar titila si hay PAGASTE por ligar.

**Sí reportar:** traslado OK pero solo se movió un lado; **Adelante/Atrás** no cambian de bolsillo o no resaltan; saldos que bailan al refrescar sin movimientos nuevos; icono sin corte abre lista distinta al filtro Historial equivalente; total parcial desalineado o distinto al parcial de la tarjeta sin razón; PAGASTE con egreso del mismo monto y **igual** aparece movimiento nuevo en Sin Clasificar **sin** que nadie pulsara Enviar a Sin clasificar; el movimiento más nuevo (id más alto) no está arriba; en modo flexible, un egreso o traslado desde **caja física** que deja el saldo negativo; en modo flexible, un egreso desde QR/Nequi **bloqueado** solo porque el saldo no alcanza.

---

### 4.12 Pagos electrónicos (panel flotante) — detalle funcional

**Objetivo:** confirmar cobros electrónicos (QR, Nequi u otro con Notificación) cuando el banco/canal avisa. Configuración de medios y plantillas: **§4.14**.

#### Idea de negocio

1. Cobras con un medio que tiene **Notificación** (venta o abono CxC).
2. El POS deja un **pendiente** (“espero $X” de ese medio).
3. Llega una **notificación** (email parseado con plantilla Ingreso del mismo medio).
4. El POS la relaciona con el pendiente (auto o **Asociar**).
5. El cajero ve el estado en el panel flotante.

#### Camino feliz — match automático

1. Cobrar con medio notificable (monto conocido).
2. Panel muestra pendiente (icono del medio, monto, leyenda de espera completa sin `…`, botones Asociar / Ya no esperar / Ver productos).
3. Llega la notificación con el **mismo medio y monto**.
4. El pendiente pasa a confirmado (o se puede marcar como visto).
5. La venta/abono queda coherente.

**UI del panel (tema `azul-atras`):** contenedor azul medio; ítems en tarjeta clara; tipografía legible; layout: icono alineado al monto; arriba **Asociar** + **Ya no esperar**; abajo a la derecha **Ver productos**; leyenda de tiempo en fila propia (texto completo).

**Minimizar (no es apagar notificaciones):**
- En el encabezado del panel: **Minimizar**.
- Queda un recuadro abajo (**Pagos electrónicos** + número de pendientes + **Restaurar**).
- Restaurar vuelve el panel. Recargar Tickets **recuerda** si estaba minimizado.
- Minimizado, el canal sigue: si llega un aviso, el número del recuadro debe actualizarse.
- **Ocultar** el panel (configuración / Gestión notificaciones, «panel activo» apagado) es **otro** gesto: no se ve ni el panel ni el recuadro, pero el banco puede seguir confirmando atrás.

#### Asociar a mano (timing + multi-método)

1. En un pendiente, clic **Asociar**.
2. Se abre el modal **de inmediato** (aunque aún no haya emails).
3. Si está vacío: mensaje de **espera** (“Esperando emails…”), **no** un callejón “no hay nada, fin”.
4. Cuando llega la notificación, **aparece en la lista** sin cerrar el modal.
5. El cajero elige la fila del **mismo medio** y confirma.

**Varios medios en la cola:** si hay emails de otro medio (o el esperado ≠ algunos candidatos), deben verse **iconos** en «Esperado» y en cada fila. Los de otro medio se ven pero **no se eligen**. El cajero puede usar **Corregir / cambiar medio** (flecha/chevron) para alinear el pendiente al medio correcto; después sí se puede asociar.

**No es bug:** abrir Asociar “muy rápido” y ver espera; emails de otro medio atenuados; el panel se puede arrastrar; minimizar deja el recuadro abajo; panel oculto por config y sin recuadro.

**Sí reportar:** modal dice “no hay” de forma definitiva y **nunca** se actualiza; Asociar no abre; email de otro medio se puede elegir y confirma mal; Corregir medio no cambia qué emails son válidos / no actualiza el cobro.

#### Monto distinto

Si el aviso trae un valor **≠** al esperado:

1. El sistema **pide confirmación** (muestra esperado / recibido / diferencia).
2. **Sobrepago** (llegó de más): confirmar y elegir de dónde sale la **devolución** (caja u otro bolsillo).
   - En **Orígenes**: OF del medio electrónico sube la diferencia; la caja baja lo mismo. No es un “egreso” de proveedor.
   - En **Cierre / Ingresos**: **movimientos** de efectivo ≈ −diff y del medio ≈ +diff. Si la caja no refleja la salida, **sí reportar**.
3. **Faltante en una venta** (llegó de menos):
   - **No** crea solo el crédito automáticamente.
   - **Reabre un ticket** con los productos.
   - Abre **Abrir / generar crédito** con montos **bloqueados**: abono ≈ lo recibido, saldo ≈ faltante, medio electrónico; no cancelar a medias con clic fuera.
   - El cajero identifica el cliente → **Crear crédito**.
   - No debe quedar un **segundo** pendiente electrónico huérfano por el mismo pago.

**Sí reportar:** acepta monto distinto sin preguntar; faltante crea crédito solo sin abrir el modal; tras crear crédito aparecen **dos** pendientes del mismo pago; sobrepago sin opción de devolución cuando la regla la exige; cierre sin −diff en movimientos de caja tras devolución; Minimizar no muestra el recuadro o Restaurar no recupera el panel; recargar pierde el minimizado; minimizado “apaga” las confirmaciones; ocultar por config es igual que minimizar (no debe).

#### Ya no esperar

Marca que la caja deja de aguardar esa confirmación (según reglas). Útil si el cliente no pagó o se resolvió fuera.

#### Panel vacío / sin novedades

Si cobraste con medio **con** Notificación y el panel **nunca** muestra pendiente: ambiente, sesión, o canal. Si cobraste con Notificación **apagada**, **no** debe haber pendiente (diseño). Si el email no llega al POS (filtro Gmail / reenvío), no hay confirmación aunque el cobro sí dejó pendiente — reportar con URL, hora y monto. **No** es lo mismo que “Asociar en espera”.

---

### 4.13 Tema oscuro / ayudas visuales

**No es bug:** colores distintos; ayuda en línea con CxC.  
**Sí reportar:** texto ilegible; controles inutilizables.

---

### 4.14 Dominios — Métodos de pago y plantillas de notificación

**Objetivo:** decidir **qué medios** esperan email de banco y **cómo** se lee ese email (plantilla).

#### Métodos de pago (Dominios)

1. Abrir **Dominios → Métodos de pago**.
2. Editar un medio (p.ej. Nequi): marcar **Permite notificación**, icono/archivo, guardar.
3. Cobrar con ese medio → debe salir pendiente en el panel (§4.12).
4. Sin el flag → cobro normal **sin** pendiente (no es bug).

#### Plantillas asociadas (desde Dominios o Gestión notificaciones)

1. En el modal de métodos: **Plantillas asociadas** (cabecera) o icono por fila → lista.
2. **Agregar / Modificar:** orden Nombre → **Naturaleza**:
   - **Ingreso** → elige **Método de pago** (con Notificación); icono del medio.
   - **Egreso** → OF origen / destino (movimiento de bolsillos; **no** confirma ticket). Si ya hay un **egreso** del mismo monto, **no** mueve a Sin Clasificar hasta que el operador decida (§4.15).
3. Desde **Gestión notificaciones → Plantillas**: botón **Métodos de pago** (junto al select Método) abre el mismo modal Dominios; al volver, el medio debería estar en el select.

**No es bug:** plantilla Egreso no confirma una venta; Ingreso sin método no deja guardar; PAGASTE con egreso candidato no crea movimiento hasta Asociar o Enviar a Sin clasificar.

**Sí reportar:** flag Notificación no crea pendiente; plantilla Ingreso confirma otro medio; botón Métodos de pago / Plantillas asociadas no abre o no refresca el select.

---

### 4.15 Notificación de egreso (PAGASTE) — ligar o enviar a bolsa

**Objetivo:** cuando el banco avisa que **pagaste** (plantilla tipo Egreso, p.ej. PAGASTE) y ya anotaste ese gasto en **Egresos**, el POS **no** mete la plata solo a Sin Clasificar. Tú eliges.

**No es** el panel flotante de cobros QR (§4.12). Una venta QR no se confirma con PAGASTE.

#### Camino feliz — asociar

1. Registrar un **egreso** (monto conocido, p.ej. $200.000) desde el bolsillo del banco/QR.
2. Llega el aviso PAGASTE del **mismo monto** (túnel real o prueba del equipo).
3. Aparece una **campanita / número** a la izquierda del usuario (titila) **y** un número en la tarjeta **Sin Clasificar**.
4. Clic → se abre **siempre** una ventana (aunque solo quede 1 aviso y 1 egreso).
5. Se ve: monto, fecha y hora, **PAGASTE**, y **Proveedor: …** o **Persona: …** (según el egreso). No debe decir «Sin pagador».
6. Botones: **Asociar y ver en egresos** y **Enviar a Sin clasificar**.
7. Asociar → abre **Egresos** con **solo ese** registro resaltado.
8. Debe verse el botón **Borrar filtro notificación** (junto al título y otra vez sobre la tabla) → al pulsarlo vuelven **todos** los egresos.

#### Enviar a bolsa (el correo no es ese egreso)

1. Misma ventana.
2. **Enviar a Sin clasificar** → el dinero **sí** aparece en Sin Clasificar; el egreso candidato **sigue sin** el correo ligado.
3. El número de la campanita baja.

#### Varias alertas

Si hay 2 PAGASTE de $200 y un solo egreso de $200: al asociar el primero el número pasa a 1. El segundo clic **abre otra vez la ventana** (no salta solo a Egresos). Un egreso solo se liga a **un** correo.

#### Asociar tarde desde Egresos

En la lista (o edición) de un egreso sin correo: **Asociar notificación**. Si el dinero ya había pasado por Sin Clasificar, al ligar **se anula ese paso** (no crea un ajuste raro). El correo deja de verse como «por identificar».

**No es bug:** la ventana aunque haya un solo candidato; PAGASTE $300 sin egreso $300 va a Sin Clasificar **sin** campanita; «Sin pagador» **no** debe salir en este diálogo; Borrar filtro deja la lista normal.

**Sí reportar:** campanita no sale con 1 PAGASTE + 1 egreso compatible; clic salta a Egresos **sin** ventana; no está **Borrar filtro notificación**; dice «Sin pagador» y no el proveedor/persona; Asociar mete otra vez plata a Sin Clasificar o deja un movimiento de «fusión»; Enviar a Sin clasificar no mueve la bolsa; filtro Por identificar sigue mostrando el correo ya ligado; tras formalizar, Cierre resta el PAGASTE en Movimientos **y** en Egresos.

---

### 4.16 Ajustes configurables del sistema

**Objetivo:** el administrador consulta y cambia parámetros de la aplicación sin tocar la base a mano.

**Camino feliz:** menú de usuario → **Configuración y mantenimiento** → **Ajustes configurables del sistema**. Cada campo se llama como su leyenda. Se cambia un valor, **Guardar cambios** se enciende, se guarda y el botón se apaga. Si esa clave se usa al iniciar sesión (`notificaciones.activa`, `monitor-bug`, `monitor-bug.secciones`, panel de productos, asociaciones de egresos, alerta de precios), el valor nuevo queda en el navegador sin volver a entrar.

**No es bug:** **Guardar cambios** apagado si no se editó nada, o si el valor quedó en blanco. Un cajero no ve esa entrada. Si un parámetro no tiene leyenda, el nombre del campo es la clave interna. La clave no sale como columna aparte.

**Sí reportar:** la entrada la ve alguien que no es administrador; se muestra una columna de clave; se puede guardar sin haber cambiado nada; tras guardar, `notificaciones.activa` (u otra clave de sesión) sigue con el valor viejo en el navegador; el guardado cambia la leyenda o la clave.

---

## 5. Matriz rápida: ¿uso o bug?

| Lo que pasó | Pregunta clave | Veredicto típico |
|-------------|----------------|------------------|
| Botones de pago apagados con crédito | ¿Hay Registrar abono? | **Uso / diseño** |
| Overlay de ayuda | ¿Apunta a Registrar abono? | **Uso / diseño** |
| No confirma mixto | ¿Suma < total? | **Uso** |
| Asociar vacío al abrir | ¿Luego aparece el email? | **Uso / diseño** si espera y se llena |
| Email otro medio atenuado | ¿Medio distinto al pendiente? | **Uso / diseño** |
| Sin pendiente y Notificación OFF | ¿Flag en Dominios? | **Uso / diseño** |
| Monto distinto pide confirmar | ¿Esperado ≠ recibido? | **Uso / diseño** |
| Faltante reabre ticket + crédito | ¿Confirmaste faltante? | **Uso / diseño** |
| Adelante en traslado cambia de OF | ¿Es salida? | **Uso / diseño** |
| Total ≠ suma líneas | ¿Descuentos ocultos? | Si no → **Bug** |
| Abono no mueve saldo | ¿Confirmó? | **Bug** probable |
| Dos pendientes por el mismo QR faltante | Tras Crear crédito | **Bug** |
| Mixto en corte solo en un medio | ¿Hubo 2 medios? | **Bug** |
| Historial vacío tras reset | ¿Acabas de resetear y aún no cobraste? | **Uso / diseño** |
| Historial vacío con Cliente + Producto + sin corte | ¿Hay venta que cumpla **todo** a la vez? | **Uso** si no; **Bug** si sí y no aparece |
| Mixto no sale en filtro Efectivo | ¿La venta tenía 2 medios? | **Uso / diseño** (usar Mixto) |
| Anónimo sin nombre en la fila | ¿Cobró sin cliente? | **Uso / diseño** |
| TOTAL un poco a la izquierda | ¿Se lee el monto y no lo tapa la tuerca? | **Uso / diseño** |
| Panel vacío tras QR real largo rato | ¿URL correcta? | Investigar / reportar con datos |
| Campanita PAGASTE + ventana de elegir | ¿Hay egreso del mismo monto? | **Uso / diseño** |
| Clic en campanita abre ventana con 1 sola alerta | ¿Esperabas que saltara solo? | **Uso / diseño** (debe abrir ventana) |
| PAGASTE $300 sin egreso $300 a Sin Clasificar | ¿Había candidato? | **Uso / diseño** |
| Tras asociar, lista de Egresos con un registro | ¿Está **Borrar filtro notificación**? | **Uso / diseño** si el botón está y funciona |
| Campanita no aparece con PAGASTE + egreso mismo monto | ¿Mismo bolsillo / fechas cercanas? | **Bug** si sí y no hay número |
| Clic salta a Egresos sin ventana | — | **Bug** |
| Diálogo dice «Sin pagador» | — | **Bug** (debe ser Proveedor o Persona) |

---

## 6. Cómo reportar un bug

### 6.1 Plantilla

```text
Título: [Módulo] Qué falló en una frase

Ambiente: (sandbox / cotiza / otra URL) · Usuario: (cajero/admin) · Tema: claro/oscuro

Pasos:
1.
2.
3.

Resultado esperado:
Resultado obtenido:

Datos: total ticket, medios, cliente, nº VTA, monto esperado vs recibido (si QR)

¿Primera vez? Sí/No
¿Monitor adjunto? Sí/No
Capturas: Sí/No
```

### 6.2 Monitor

Botón flotante → reproducir el fallo → Ver detalle / copiar → adjuntar al reporte.

La traza que se copia (**Guardar al portapapeles y cerrar**) y el JSON de **Editar #** omiten lo que `monitor-bug.secciones` tenga con `trazable` distinto de true (por ejemplo `requests.requestHeaders.Authorization`). La tabla de peticiones sigue viéndose completa. Si esa clave no está cargada en la sesión, no se recorta nada: volver a entrar o abrir Ajustes configurables.

### 6.3 Qué NO reportar como bug sin validar

- “No me deja pagar” sin decir si hay **crédito**.
- “El corte está mal” sin **fechas** ni contraste con **Historial**.
- “OF no cuadra” sin anotar **traslado / egreso / legalización**.
- “Asociar no tiene emails” a los 2 segundos (debe **esperar**).
- Preferencias de impresión o tema como “error de cobro”.

---

## 7. Checklist del día (pruebas ágiles)

### Bloque A — Venta básica (15 min)

- [ ] Login  
- [ ] 1 producto → efectivo exacto  
- [ ] 2 productos → billete + cambio  
- [ ] Historial (Pagado + hoy)  
- [ ] Reimprimir  

### Bloque B — Multipago (10 min)

- [ ] Mixto efectivo + QR  
- [ ] Historial con desglose  

### Bloque C — Crédito + comentario (25 min)

- [ ] Generar crédito con cliente  
- [ ] Medios del pie deshabilitados  
- [ ] Clic en medio → ayuda en línea  
- [ ] Abono parcial → saldo  
- [ ] **Registrar comentario** (menú ⋮ / clic derecho) → título **Observación** o **Crédito y observación**  
- [ ] Editar comentario: foco en la caja y texto seleccionado  
- [ ] Comentario largo: ~4 líneas + tooltip  
- [ ] Liquidar: el ticket reciclado **sin** el comentario anterior  
- [ ] Liquidar (si aplica)  

### Bloque D — Pagos electrónicos + medios/plantillas (30 min) ★ prioritario

- [ ] Dominios → Métodos: Notificación ON en un medio (p.ej. Nequi) + icono  
- [ ] Plantillas asociadas → Ingreso de ese medio; o Gestión notificaciones → botón Métodos de pago  
- [ ] Cobro con ese medio → pendiente en el panel (icono correcto)  
- [ ] Cobro con Notificación OFF → **sin** pendiente  
- [ ] Notificación con **mismo** medio y monto → confirma  
- [ ] **Asociar** antes del aviso → espera → aparece y se puede elegir  
- [ ] (Si se puede) pendiente medio A + email medio B → iconos; B no elegible; **Corregir medio** → asociar  
- [ ] (Si se puede) monto **mayor** → confirma sobrepago / devolución  
- [ ] (Si se puede) monto **menor** en venta → reabre ticket → crédito manual → un solo pendiente  
- [ ] Abono CxC con medio notificable → pendiente en el panel  
- [ ] Panel: leyenda de tiempo completa; botones Asociar · Ya no esperar ordenados  
- [ ] **Minimizar** → recuadro abajo con pendientes + **Restaurar**; recargar Tickets lo recuerda  
- [ ] CxC: Quién abona (otro cliente / +) y nombre en rail  
- [ ] CxC rail: Total ticket / Abonado / Saldo (sin Original crédito)  
- [ ] Menudeo: 2 líneas + `(Por unidad)`; deshabilitado no seleccionable 

### Bloque E — OF (15 min)

- [ ] Ver movimientos de un bolsillo (más reciente / id alto arriba)  
- [ ] Traslado permitido A → B  
- [ ] En la salida, **Adelante** → destino resaltado  
- [ ] En la entrada, **Atrás** → origen resaltado  

### Bloque F — Finanzas ligeras + visual (15 min)

- [ ] Ingresos: ventas de hoy = tickets del cierre, **sin desfase** (no Esperado ni Contado)  
- [ ] Egreso simple (si hay permiso)  
- [ ] Dark/light en Tickets, Historial, modal pago, panel electrónicos  
- [ ] Cierre de turno → **asistente de caja**: Contado = total billetes; diferencia vs Esperado; reabrir recuerda cantidades  

### Bloque G — Personas / Cuenta del dueño (20 min) ★

- [ ] Dominios → Personas: toggle dueño en una persona  
- [ ] Clasificar / trasladar a Cuenta del dueño (OF sube)  
- [ ] Egreso PERSONAL + persona dueño + origen Cuenta del dueño → OF baja  
- [ ] Persona sin flag → no usa Cuenta del dueño  
- [ ] Badge Egresos = **Gastos y pagos**  

### Bloque H — Historial / sin corte + cierre post-sobrepago (20 min)

- [ ] Historial: medio + sin corte coherente con ventas  
- [ ] Modal productos: Atendió + total alineado a Subtotal  
- [ ] OF → icono tickets sin corte: misma lista, arrastrable, total parcial alineado  
- [ ] (Si aplica) Sobrepago QR → cierre: movimientos caja −diff y QR +diff  

### Bloque I — PAGASTE / egreso sin vincular (20 min) ★

- [ ] Egreso $X desde el bolsillo del banco/QR  
- [ ] Aviso PAGASTE del mismo $X → campanita **y** número en Sin Clasificar  
- [ ] Clic abre **ventana** (también si solo hay 1)  
- [ ] Se lee PAGASTE + monto + fecha/hora + Proveedor o Persona (**no** «Sin pagador»)  
- [ ] Botones **Asociar y ver en egresos** / **Enviar a Sin clasificar**  
- [ ] Asociar → Egresos filtrado + **Borrar filtro notificación** visible → vuelve la lista completa  
- [ ] (Si hay 2 avisos del mismo monto) el segundo clic **no** salta solo  
- [ ] PAGASTE de otro monto **sin** egreso → Sin Clasificar **sin** campanita de ese caso  
- [ ] Enviar a Sin clasificar: sí hay movimiento en la bolsa; el egreso no queda ligado  

---

## 8. Preguntas frecuentes

**P: ¿Por qué no puedo pagar con Nequi?**  
R: ¿Hay **crédito**? → **Registrar abono**. Si no, describe el mensaje.

**P: ¿OF / ledger?**  
R: OF = bolsillo. Ledger = historial +/- en Orígenes de fondos.

**P: Cobré QR y no confirma**  
R: ¿Estás en la URL correcta (sandbox vs otra)? ¿Hay pendiente en el panel? ¿Usaste Asociar y quedó en espera? Reporta hora, monto y URL.

**P: Asociar dice que espera emails**  
R: Es normal al abrir rápido. Si **nunca** aparece el aviso y el banco ya notificó, reporta.

**P: El faltante me abrió otra vez el ticket**  
R: Diseño: debes generar el **crédito a mano** con el cliente. Montos bloqueados = OK.

**P: Mixto y en el corte solo veo efectivo**  
R: Investigar (posible bug). Reporta nº de venta y montos.

**P: La ayuda en línea me molesta**  
R: Intencional con CxC. Si aparece **sin** crédito → bug.

**P: Llegó PAGASTE y no veo la campanita**  
R: ¿Registraste **antes** un egreso del **mismo monto** (y fechas cercanas) desde ese banco? Si no hay egreso candidato, el aviso va a Sin Clasificar **sin** campanita (diseño). Si sí había egreso y no hay número, reporta.

**P: Pulsé la campanita y me mandó a Egresos sin preguntar**  
R: Bug: siempre debe salir la ventana **Asociar y ver en egresos** / **Enviar a Sin clasificar**.

**P: En Egresos solo veo un registro**  
R: Venís del asociar. Pulsá **Borrar filtro notificación** (debe verse claro). Si no está, reporta.

---

## 9. Glosario ultra-corto

```text
Ticket        = venta abierta
Cobrar        = cerrar venta con medio(s)
Mixto         = varios medios en una venta
CxC / crédito = fiado; cobrar con «Registrar abono»
OF            = bolsillo donde está la plata
Traslado      = mover plata entre bolsillos (Atrás/Adelante navega el par)
Panel QR      = pagos electrónicos pendientes de confirmación
Minimizar     = recuadro abajo; no apaga el banco (ocultar config ≠ minimizar)
Comentario    = nota del ticket (menú pestaña); se borra al liquidar CxC
Notificación  = aviso del banco que el POS procesa
Asociar       = unir aviso bancario ↔ pendiente (espera en vivo)
Monto distinto= banco ≠ esperado (sobrepago / faltante)
Corte         = arqueo (esperado vs contado); asistente: Contado = Σ billetes
VTA-…         = nº interno de venta cerrada
Monitor       = captura para reportar fallos
Sandbox       = ambiente estable del tester
```

---

## 10. Reglas de negocio más profundas

### 10.1 Corte (en palabras)

```text
Ventas del turno = suma cobrada en tickets (por medio)  ← verdad de Ingresos; SIN desfase
Esperado         ≈ Base + Ventas − Egresos + Movimientos
Contado          = lo que cuenta el cajero (**asistente:** = total de billetes)
Diferencia       = Contado − Esperado  (se guarda; no corrige Ventas)
```

Abono CxC = **cobranza**, no venta nueva. Va en **Movimientos** de ese medio, en Orígenes de fondos y en la columna **Cobranzas** del dashboard de Ingresos. **No** va en la columna Ventas.

PAGASTE formalizado como egreso (QR / Nequi / otro electrónico): el aviso del banco **no** se resta otra vez en Movimientos; el gasto queda en **Egresos**.

**Corregir un corte (aceptación):**

```text
Eliminar  → solo si NINGÚN origen de fondos tocado por el corte se movió después
Dividir   → siempre que el corte sea el último vigente; vale aunque ya hubo egresos
Invariante: la plata no cambia. Σ ventas de los cortes nuevos == total del corte viejo
Invariante: ningún saldo queda negativo en ningún momento
Traza:      el corte viejo no se borra (queda «Dividido»), motivo obligatorio
```

El corte «Dividido» **no** cuenta en Ingresos: sus ventas ya las heredaron los cortes nuevos. Los egresos nunca se tocan. Los cortes nuevos no traen Contado ni Diferencia.

**Ver un corte cerrado:** modal de solo lectura (KPIs de ese momento + tabla Compacta/Extendida). ‹ › recorre los días ya listados en Detalles por Fecha.

### 10.2 Multipago

- Hasta **3** medios; suma **exacta** al total.
- Historial y corte deben ver **por medio**.
- Medio principal de cabecera ≈ mayor monto (empate → suele efectivo).

### 10.3 CxC

1. Con crédito, el pie **no** cobra.  
2. **Registrar abono** (indicar **Quién abona**).  
3. Clic en medio apagado → **ayuda en línea**.  
4. Liquidar no inventa segunda venta fantasma.
5. El pagador del abono puede ser distinto del deudor; se ve en el rail.
6. Comentario del ticket (menú pestaña) es de ese ticket; al liquidar el crédito **se borra**. Títulos: Crédito / Observación / Crédito y observación.
7. El rail muestra Total ticket, Abonado y Saldo. **No** aparece «Original crédito».

### 10.4 OF — legalizar vs formalizar vs trasladar

| Acción | Vida real | Cuidado |
|--------|-----------|---------|
| **Trasladar** | Mover entre bolsillos | No es venta; se puede **navegar** Atrás/Adelante |
| **Legalizar** | Etiquetar movimiento sin clasificar (aviso banco) | Personal ≠ gasto |
| **Formalizar egreso** | Documento de gasto con plata ya en bolsillo | No restar el banco otra vez |

### 10.5 Notificación electrónica / medios (aceptación)

| Escenario | Debe pasar |
|-----------|------------|
| Medio con Notificación ON + cobro/abono | Pendiente en el panel (icono del medio) |
| Medio con Notificación OFF | Sin pendiente (diseño) |
| Plantilla Ingreso del mismo medio + aviso = monto | Confirma / se puede asociar |
| Asociar antes del aviso | Modal en espera → se llena solo |
| Email de otro medio en Asociar | Iconos; no seleccionable; Corregir medio alinea y permite asociar |
| Monto distinto | Pide confirmación explícita |
| Sobrepago confirmado | Devolución / ajuste en bolsillos; cierre: mov. caja −diff y medio +diff |
| Faltante en venta confirmado | Reabre ticket + crédito manual (montos fijos); **un** pendiente al final |
| Ya no esperar | Deja de aguardar ese pendiente |
| Plantilla Egreso | Si hay egreso del mismo monto: **no** mueve OF hasta Asociar o Enviar a Sin clasificar (§4.15). Si no hay candidato: mueve OF; **no** confirma ticket |

### 10.6 Motivos de diferencia en cierre

Cobró en medio equivocado → traslado; faltó movimiento → documentar; error al contar → ajuste con auditoría. A veces el sistema **bloquea** el cierre a propósito. El **asistente de caja** solo ayuda a contar: Contado = Σ billetes; Diferencia = Contado − Esperado.

### 10.7 Ayuda en línea

Overlay origen→destino. Caso principal: CxC. Sin crédito → sospecha bug.

### 10.8 Comprobantes

Tirilla / VTA = control **interno**. No es DIAN.

### 10.9 Historial Tickets — filtros (aceptación)

| Escenario | Debe pasar |
|-----------|------------|
| Reset + login (+ base inicial si pide) | Ventas 0, sin corte 0, movimientos 0 (salvo base) |
| Sembrar pocas ventas y anotarlas | Cada filtro cuadra con esa lista |
| Pagado / Anulados / Restaurados / Todos | Solo el estado pedido |
| Fecha de un día sin ventas | Lista vacía |
| Método Efectivo vs Mixto | Mixto **no** entra en un medio suelto |
| Tickets sin corte | Solo posteriores al último cierre; igual que el modal OF del mismo medio |
| Cliente (autocomplete) | Solo ese cliente; anónimo no aparece como nombre; X limpia |
| Producto (autocomplete) | Misma búsqueda que el selector de ventas (nombre/`busquedaPorFiltros`, código de barras, Ab, Limpiar); ventas que **incluyen** esa línea |
| Filtros combinados | AND: deben cumplirse todos |
| Panel derecho | Fecha de venta y Cajero frente a Comprobante y Estado |
| TOTAL (millones o no) | No se cruza con el label; no lo tapa la tuerca |
| Tras migrate prod → v02 | Lista carga; cada pagada muestra `VTA-######` (no `#id` ni `VTA-LEGACY-`) |
| Anular o Restaurar en venta pagada sin corte y sin cartera | La operación sigue |
| Anular o Restaurar en venta ya cortada o en cartera | Aviso de pendiente; la venta no cambia y el corte no se divide |

### 10.10 PAGASTE / vínculo egreso (aceptación)

| Escenario | Debe pasar |
|-----------|------------|
| Egreso registrado + PAGASTE mismo monto | Campanita + número en Sin Clasificar; **sin** movimiento nuevo en la bolsa |
| Clic campanita / icono Sin Clasificar | Siempre el diálogo (también con 1 alerta) |
| Texto del diálogo | Monto, fecha/hora, PAGASTE, Proveedor o Persona; **no** «Sin pagador» |
| Asociar y ver en egresos | Liga 1 correo ↔ 1 egreso; lista filtrada + **Borrar filtro notificación** |
| Enviar a Sin clasificar | Traslado a la bolsa; el egreso **no** queda ligado |
| 2 correos $200 y 1 egreso $200 | Tras asociar uno, el otro sigue en campanita; segundo clic abre diálogo |
| PAGASTE sin egreso candidato | Va a Sin Clasificar; no entra a la campanita |
| Formalizar ese aviso como egreso | Cierre: Egresos del medio (QR/Nequi/…) = el gasto; Movimientos **sin** restar otra vez el PAGASTE |
| Asociar tarde (correo ya en bolsa) | Se **anula** el paso por Sin Clasificar; no aparece un ajuste extra |
| Notificaciones «Por identificar» | El correo ya ligado **no** sale como por identificar |

### 10.11 Lectora de código de barras (aparcado)

Tema en pausa. Cuando se retome: varios códigos **sin** desconectar el USB; el pitido debe coincidir con búsqueda (producto, selector o “no encontrado”). Si solo funciona reconectando, reportar.

### 10.12 Ajustes configurables del sistema (aceptación)

| Escenario | Debe pasar |
|-----------|------------|
| Administrador abre el menú de usuario | En **Configuración y mantenimiento** ve **Ajustes configurables del sistema** y, al elegirlo, un modal |
| Usuario que no es administrador | No ve esa entrada |
| Campo con leyenda | El nombre del campo es la leyenda; no hay columna de clave |
| Campo sin leyenda | El nombre es la clave interna, solo como etiqueta |
| Sin editar | **Guardar cambios** deshabilitado |
| Valor cambiado y no vacío | **Guardar cambios** habilitado; al guardar, se apaga |
| Valor dejado en blanco | **Guardar cambios** sigue deshabilitado |
| Guardar `notificaciones.activa` | Queda en la base y en el navegador (`true` o `false`) |

---

## 11. Mensaje de arranque (tester → IA)

> Eres mi asistente para **pruebas de calidad** del POS Infinito. Conozco el negocio de tienda pero no jerga técnica. Usa **únicamente el documento de contexto que te cargué** (y las oleadas `ACTUALIZACION-QA-2026-09-10` / `2026-09-06` / `2026-09-03` / `2026-09-02` si me las adjuntaron). Ayúdame a probar paso a paso. Prioriza **PAGASTE / campanita de egreso** (ventana Asociar vs Enviar a Sin clasificar, Borrar filtro notificación), comentario de ticket, asistente de cierre de caja, minimizar el panel de pagos electrónicos, Historial Tickets (filtros + reset), medios/Notificación + plantillas + Asociar, Personas/dueño, sin corte OF, sobrepago→cierre, crédito/multipago. Dime qué es normal vs bug, y cómo reportar. No asumas que todo fallo es bug. No pidas archivos del proyecto ni detalles de servidores.

---

*Fin del contexto. Actualizar **este mismo archivo** cuando cambien reglas de CxC/observaciones, pagos electrónicos (incl. minimizar), **PAGASTE / vínculo egreso**, asistente de cierre, medios/plantillas, OF, multipago, egresos/personas, historial (filtros), presentaciones/menudeo o Monitor. Entregar a la tester / IA general este archivo (+ oleada QA del ciclo si aplica). Para verificación SQL en sandbox, añadir `contextos-ia/sandbox-reset-transaccional.md`.*
