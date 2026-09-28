## Purpose

El dashboard y la tabla de Ingresos reportan **ventas POS sin desfase** (`totalVentasSistema`: tickets cobrados). El arqueo (Base / Esperado / Contado / Diferencia) no es venta del día.

## Requirements

### Requirement: Fuente de verdad — ventas sin desfase

La columna **Ventas** del cierre de turno SHALL ser Σ `totalVentasSistema` (tickets cobrados del periodo). Ese valor SHALL persistirse en `corte_venta.total_ventas_sistema` y SHALL alimentar el KPI **Ventas**, la gráfica y la tabla de Ingresos.

Ingresos MUST NOT sumar ni restar `desfase`, Contado, Esperado ni Base a esa cifra.

#### Scenario: Cierre con base y conteo
- **WHEN** el turno tiene ventas 300.000, base 1.050.000 y Esperado 1.350.000
- **THEN** Ingresos muestra 300.000 en Ventas; no 1.350.000 ni el Contado

#### Scenario: Desfase no cambia Ingresos
- **WHEN** el cajero declara un Contado distinto del Esperado (faltante o sobrante)
- **THEN** el desfase se persiste en el detalle y las Ventas de Ingresos siguen siendo los tickets (sin el desfase)

### Requirement: Contado y desfase no son venta

`corte_venta.total` (Contado) y `corte_venta.total_sistema` (Esperado) MUST NOT usarse como venta del día. El desfase (Contado − Esperado) SHALL seguir guardándose; MUST NOT publicarse aún como ajuste visible de OF/caja ni como corrección de Ingresos.

### Requirement: Orden de tabla vs gráfico

La tabla de Ingresos SHALL listar días en orden descendente. El gráfico del dashboard SHALL ir en orden ascendente (día más reciente a la derecha).

#### Scenario: Semana con varios días
- **WHEN** hay ventas de lun–sáb
- **THEN** la tabla empieza por sábado y el gráfico termina en sábado a la derecha

### Requirement: Cobranzas aparte

Las cobranzas (`ENTRADA_COBRANZA`) SHALL ir en columna propia. MUST NOT sumar al KPI Ventas ni a la gráfica de Ingresos.

### Requirement: consultar-rango expone ventas y esperado

`GET /corte-venta/consultar-rango` SHALL devolver `totalVentasSistema` (tickets, sin desfase) y `total` (Esperado = Σ `totalSistema`).

Con `ultimoCorte=false`, si otros cortes vigentes intersectan el rango, ventas, egresos
y movimientos SHALL ser solo los de id estrictamente mayor al piso de esos cortes
(máximo `ultimoHistorialReciboId` y máximo `ultimoMovimientoOrigenFondosId`) y dentro
de `[fechaIni, fechaFin]`. `excluirCorteId` SHALL omitirse de ese piso. Sin solape, el
piso es cero y la consulta sigue siendo por fechas.

Un cierre que no es watermark (`ultimoCorte=false`) SHALL persistir los totales de
sistema recalculados con esa consulta, no los que envíe el cliente. El Contado
declarado SHALL conservarse. Si el desfase resultante no trae motivo, el cierre SHALL
rechazarse.

#### Scenario: Rango que contiene un corte ya cerrado
- **WHEN** se consulta o se registra un cierre 28/09 10:09–20:23 y ya existe un corte vigente 17:46–17:52 con ventas 2.400.000 (watermark de recibo 12)
- **THEN** las ventas del rango son 2.410.000 (tickets con id mayor a 12), no 4.810.000
- **AND** Ingresos del 28, sumado a ese corte previo, muestra 4.810.000 y no 7.210.000

### Requirement: Detalles por Fecha — Ver corte

Cada fila con cortes SHALL ofrecer **Ver**. El modal **Corte de venta #n** SHALL ser solo
lectura, con los KPIs y la tabla Compacta|Extendida de `cierre-turno-indicadores` (incluidas
Cartera y las columnas Sistema / Real). **‹ ›** SHALL recorrer los cortes de las filas ya
consultadas sin cerrar el modal.

Contrato: `openspec/specs/cierre-turno-indicadores/spec.md`.

#### Scenario: Avanzar sin volver a Consultar
- **WHEN** hay al menos dos días con corte en la tabla y se abre Ver
- **THEN** ‹ › muestra el corte del día siguiente/anterior con su fecha y KPIs
