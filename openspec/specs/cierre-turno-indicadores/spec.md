## Purpose

Modo simple del **Cierre de turno**: cuatro indicadores de dinero del turno, el KPI **Cartera**,
la tabla en dos vistas (Compacta / Extendida) y la vista de solo lectura **Corte de venta #n**
(Ingresos → Detalles por Fecha → Ver). Los cuatro de dinero se publican también en la **barra
de estado (footer)** de Financiero > Ingresos y Financiero > Orígenes de fondos.

## Requirements

### Requirement: Cuatro indicadores del turno

El encabezado del Cierre de turno SHALL mostrar cuatro indicadores, en este orden y con estos
nombres exactos:

| # | Etiqueta | Qué es |
|---|----------|--------|
| 1 | **Ventas turno** | Σ (`totalVentasSistema` + `totalCobranzasSistema`) de todos los medios: tickets cobrados + cobranzas CxC del periodo |
| 2 | **Efectivo disponible** | Efectivo de la caja registradora + saldo de las demás cajas físicas (Caja Menor, Caja General y cualquier otra que exista) |
| 3 | **Dinero medios electrónicos** | Bancolombia QR, Nequi y demás medios no físicos |
| 4 | **Total dinero disponible** | (2) + (3) |

«Ventas turno» SHALL ser el nombre visible; antes se llamaba «Vendido». MUST NOT reintroducirse
esa etiqueta.

Las cajas de **dueños** (`tipoOrigenFondosCodigo = DUENOS`) MUST NOT entrar en ningún
indicador: no son dinero operativo de la tienda.

Un origen de fondos con naturaleza **FISICA** cuenta como efectivo; cualquier otra naturaleza
(`ELECTRONICA`, `MIXTA` o sin declarar) cuenta como medio electrónico, de modo que ningún
origen quede fuera del Total.

#### Scenario: Cierre con caja menor y caja general
- **WHEN** el cajero abre Cierre de turno y hay saldo en Caja Menor y Caja General
- **THEN** «Efectivo disponible» incluye esos saldos además de lo contado en la registradora

#### Scenario: Ventas turno con cobranzas
- **WHEN** en el turno hubo tickets cobrados y abonos CxC
- **THEN** «Ventas turno» suma ambos; el KPI Ventas del dashboard de Ingresos sigue **sin** cobranzas

«Ventas turno» SHALL mostrar un indicador interno vs el **último corte vigente** (fecha `dd/MM`,
flecha y delta en pesos) cuando exista esa referencia. Un botón **Ver detalles** SHALL abrir el
desglose por método de pago. Registrar el cierre MUST NOT permitirse si «Ventas turno» es 0.

#### Scenario: Cierre sin ventas del turno
- **WHEN** el cajero consulta un rango con Ventas turno = 0
- **THEN** no puede registrar el cierre

### Requirement: KPI Cartera

El encabezado del Cierre de turno y el panel izquierdo de Ingresos SHALL mostrar **Cartera**
además de los cuatro indicadores de dinero. Cartera MUST NOT ir en el footer (ese sigue con
cuatro cifras).

**Cartera** SHALL ser Σ `saldo_pendiente` de CxC vigentes (`ABIERTA` / `PARCIAL`). La torta
SHALL ser cobrada (verde) vs pendiente (rojo): cobrada = Σ (`totalTicket` − saldo) de esas
cuentas. El delta SHALL ser contra el saldo al **inicio del día calendario** (no contra el
último corte si su snapshot es nulo). SUBE (más deuda) SHALL verse como alerta; BAJA, como
mejora. Si el día anterior era 0 y hoy hay saldo, el delta SHALL ser +100 % SUBE.

El parámetro `configuracion_app` `cartera-maxima` MUST NOT alterar esta torta ni el ancho de
columnas (queda para otras funciones).

#### Scenario: Cartera baja respecto al día anterior
- **WHEN** ayer el saldo era 120.000 y hoy es 60.000
- **THEN** Cartera muestra 60.000, flecha hacia abajo y −50 %

### Requirement: Un solo mecanismo de cálculo

El cálculo SHALL vivir en un service global de Angular (`TotalDisponibleService`,
`origenes-fondos/service/total-disponible.service.ts`), no en el componente del cierre. Toda
pantalla que muestre estos indicadores SHALL consumir ese service.

Las etiquetas SHALL exportarse como constantes desde ese mismo archivo
(`LABEL_VENTAS_TURNO`, `LABEL_EFECTIVO_DISPONIBLE`, `LABEL_MEDIOS_ELECTRONICOS`,
`LABEL_TOTAL_DISPONIBLE`). Las plantillas MUST NOT repetir el texto a mano: cierre y footer
no pueden desincronizarse.

#### Scenario: Renombrar un indicador
- **WHEN** se cambia el nombre de un indicador
- **THEN** basta cambiar la constante y el nuevo nombre aparece en el cierre y en los dos footers

### Requirement: Dentro del cierre se cuenta; fuera se lee el saldo

Dentro del diálogo de Cierre de turno, «Efectivo disponible» y «Dinero medios electrónicos»
SHALL tomar la columna **Real** de cada fila (lo que el cajero contó), porque esa es la cifra
que el cierre va a guardar.

Fuera del cierre no existe conteo, así que el service SHALL calcular los mismos indicadores
solo desde saldos: por cada origen de fondos, **saldo del ledger + ventas del turno abierto
todavía sin corte** (`saldoOrigenConVentasSinCorte`). Las cobranzas del turno ya están
posteadas en el ledger; MUST NOT volver a sumarse.

Ambas cifras coinciden cuando el cajero cuadra la caja; mientras el turno está abierto la de
saldos es la única que existe. Esta diferencia de origen SHALL quedar documentada donde se
muestre el indicador.

#### Scenario: Footer con turno abierto
- **WHEN** hay ventas del turno sin corte
- **THEN** el footer las incluye en «Ventas turno» y en el disponible del medio que las recibió

### Requirement: Barra de estado en Ingresos y Orígenes de fondos

**Financiero > Ingresos** y **Financiero > Orígenes de fondos** SHALL publicar los cuatro
indicadores en el footer, en el mismo orden del encabezado del cierre. El cuarto
(«Total dinero disponible») SHALL ir resaltado (`footer-item-total-highlight`).

Ingresos SHALL refrescarlos tras cada operación que mueva dinero (cierre de turno, eliminar o
dividir un corte). Orígenes de fondos SHALL calcularlos con el árbol y el rango sin corte que
esa pantalla ya carga, sin pedirlos otra vez al backend.

El footer de Orígenes de fondos MUST NOT seguir mostrando el resumen de pantalla
(«Medios de pago y orígenes hijos — mueva saldo entre cuentas y revise movimientos.»); ese
texto SHALL quedar únicamente en el panel de **Ayuda en línea**.

Los mensajes temporales de esa pantalla (pista de arrastre, ayuda al pasar el puntero por un
control, aviso «No permitido») SHALL seguir reemplazando el footer mientras duran, y al
terminar SHALL volver a los cuatro indicadores.

#### Scenario: Arrastrar y soltar en Orígenes de fondos
- **WHEN** el admin arrastra un origen y luego suelta
- **THEN** durante el arrastre se ve la pista, y al terminar vuelven los cuatro indicadores

### Requirement: Tabla del cierre en dos vistas

La tabla del cierre SHALL ofrecer un `mat-button-toggle` **Compacta | Extendida** en la sección
de título del modal, junto al botón de ayuda. **Compacta** SHALL ser la vista por defecto.

En **Compacta**: columnas `Método de pago`, `Sistema`, `Real`, `Diferencia`. «Sistema»
reemplaza a «Esperado» y, en la fila de Efectivo, **no** suma la base; la columna «Real»
tampoco la suma. Al restarse por igual en ambas, la Diferencia es la misma en las dos vistas.
El total de la tabla SHALL ser la suma de lo que se está mostrando.

En **Extendida**: se muestran todas las columnas (incluida Base y el desglose), como antes.

La columna de conteo SHALL llamarse **Real** (antes «Contado»).

#### Scenario: Alternar vistas
- **WHEN** el cajero pasa de Compacta a Extendida
- **THEN** cambian Sistema/Real por el desglose completo, y la Diferencia de cada fila no cambia

La misma tabla y el mismo toggle SHALL usarse en el modal de solo lectura **Corte de venta #n**.

### Requirement: Vista Ver de un corte cerrado

Desde Ingresos → **Detalles por Fecha** → **Ver**, el modal **Corte de venta #n** SHALL ser de
solo lectura y SHALL mostrar los mismos KPIs del cierre (Ventas turno con delta, Efectivo,
Electrónicos, **Cartera** con torta y delta, Total disponible) y la tabla Compacta|Extendida
con las mismas reglas de Sistema / Real / base.

Si el corte no trae snapshot de KPIs, el modal SHALL reconstruir Cartera a esa fecha
(CxC + abonos + líneas de recibo) y el delta de Ventas turno vs el **día calendario anterior**.

Junto a la fecha del título SHALL haber botones **‹ ›** para pasar al corte anterior/siguiente
de las filas ya consultadas, sin cerrar el modal ni volver a Consultar. El primero y el último
del rango SHALL dejar el botón inactivo. Un día con varios cortes sigue agrupado (pestañas);
‹ › cambia de día.

#### Scenario: Ver cortes de varios días
- **WHEN** Detalles por Fecha tiene más de un día con corte y se abre Ver
- **THEN** ‹ › cambia de corte/día y el título, KPIs y tabla corresponden a ese corte

### Requirement: Leyenda en botón de ayuda

La explicación de las columnas («La columna Ventas…») MUST NOT ocupar espacio fijo en el
modal: SHALL vivir detrás de un botón con icono **(?)** en el encabezado.

### Requirement: Snapshot opcional; Ver reconstruye

Los cuatro indicadores de dinero del footer siguen calculándose sobre datos ya existentes
(`origenes-fondos/arbol` y `corte-venta/consultar-rango`).

Al registrar un cierre el BE MAY persistir snapshot de KPIs en `corte_venta` (migración `74_`).
Cortes viejos o sin esas columnas SHALL seguir viéndose: la vista Ver reconstruye Cartera y el
delta de Ventas turno. La clave `cartera-maxima` (migración `75_`) MUST NOT usarse en estas
tortas.

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/cierre-turno-indicadores.md`,
este spec, `openspec/specs/ingresos-dashboard/spec.md` (botón Ver) y `CONTEXTO-TESTER-POS.md`
§4.9 / §4.11.
