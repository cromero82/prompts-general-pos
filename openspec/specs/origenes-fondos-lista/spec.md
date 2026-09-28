## Purpose

Definir el comportamiento y la presentación de la lista de Orígenes de fondos (tarjetas + historial de movimientos), alineada al estándar visual de tablas del POS.

## Requirements

### Requirement: Tabla de movimientos con estilo cebra estándar

La tabla de movimientos del historial OF (`mov-table` / `mov-table-compact`) SHALL usar el patrón cebra del POS: filas pares con fondo `rgba(0, 0, 0, 0.005)` aplicado al `tr` y a las celdas `td`, filas impares transparentes, hover con `var(--pos-mat-table-row-hover)`, y fila seleccionada con fondo azul Material persistente (sin depender de focus).

#### Scenario: Historial con varias filas
- **WHEN** el cajero selecciona un OF con más de un movimiento
- **THEN** las filas pares e impares se distinguen visualmente (cebra) y el hover / selección tienen prioridad sobre la cebra

#### Scenario: Compatibilidad Material MDC
- **WHEN** Angular Material MDC pinta fondo en celdas
- **THEN** el estilo cebra y hover/selección se aplican también a `td.mat-mdc-cell` para que el efecto sea visible

### Requirement: Densidad compacta del historial

La tabla de movimientos SHALL mantener densidad compacta (~28 px de alto de fila) coherente con otras listas financieras del POS (p. ej. egresos / resumen económico).

#### Scenario: Layout del historial
- **WHEN** se muestra el panel de movimientos de un OF
- **THEN** filas y celdas usan tipografía/padding compactos (`mov-table-compact`) sin romper botones de Detalle (Ver, Atrás, Adelante, Trasladar, etc.)

### Requirement: Historial ordenado por id descendente

Al seleccionar un OF, `GET /movimientos-origen-fondos?origenFondosId=` y la tabla SHALL listar movimientos por `id` DESC (más reciente primero). MUST NOT ordenar por `fecha` de negocio ni por `fechaCreacion`: `fecha` es solo día y `fechaCreacion` depende del reloj del host.

#### Scenario: Entrada reciente con fecha de negocio distinta
- **WHEN** el cajero abre un OF y hay una entrada manual con `id` mayor que el resto
- **THEN** esa fila es la primera, aunque su `fecha` sea anterior a otras filas

### Requirement: Bolsillos internos Caja Menor y Caja General

El arbol OF SHALL incluir, ademas de los medios de tickets (Caja: Efectivo, Bancolombia - QR, Nequi) y Dueños:

- `origen_fondos.id = 4` nombre **Caja Menor**, `naturaleza = FISICA`, `metodo_pago_id` NULL
- `origen_fondos.id = 5` nombre **Caja General**, `naturaleza = FISICA`, `metodo_pago_id` NULL

MUST NOT mostrar como OF activos los labels legacy de `metodo_pago` id 4 (**Efectivo: base para proveedores**) ni **Reserva pago proveedores**. Esos nombres salen del seed `14_` sobre un dump prod; la migrate SHALL aplicar `63_align_caja_menor_general.sql` (tras `26_`) para dejar el mismo catalogo que `controlneg_rmx_db`.

Caja Menor / Caja General SHALL NOT aparecer como medio de tickets ni como fila de cierre (no tienen `metodo_pago_id`).

Tras migrate desde un dump sin Distribución, el Contado de efectivo del último corte legacy SHALL sembrarse en Caja: Efectivo y partirse: `corte-venta.base-efectivo` permanece en caja y el resto va a Caja Menor (`64_migrate_distribucion_contado_legacy.sql`). El siguiente cierre SHALL usar esa base (no el Contado prod). `MIGRACION_CONTADO_LEGACY` y `DISTRIBUCION` MUST NOT sumar en la columna Movimientos del cierre.

La Base de QR/Nequi (y cualquier medio con OF raíz) SHALL ser el saldo del ledger de ese OF al watermark del último corte, no el Contado persistido en `corte_venta_detalle.total`. Ese Contado de prod no existe en OF y MUST NOT inflar Esperado.

#### Scenario: Lista OF tras migrate v02
- **WHEN** el operador abre Financiero → Origenes de fondos sobre una BD migrada desde prod
- **THEN** ve Caja Menor y Caja General (ids 4 y 5) y MUST NOT ver "Efectivo: base para proveedores" ni "Reserva pago proveedores"

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/origenes-fondos.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.11. La correccion de migrate (Caja Menor/General) SHALL quedar tambien en `MIGRATE-TIENDA-INFINITO-V02.md` y `MIGRATE-PROD-TO-DIAN-V2.md`.
