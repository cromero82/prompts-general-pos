## Purpose

Complementar el egreso operativo del POS: categoría estable en el documento (tipo snapshot + naturaleza), sin convertir el módulo en ERP ni nómina. Cuenta del dueño sigue siendo clasificación/acumulación en OF; bajar ese saldo se hace con egreso de pago (nómina, anticipo, dividendos, etc.).

## Requirements

### Requirement: Tipo de egreso en el documento (snapshot)

Al crear o actualizar un egreso, el sistema SHALL persistir `tipo_egreso_id` en la fila `egreso`. Si el cliente no envía tipo, el sistema SHALL tomar el `tipo_egreso` del proveedor seleccionado. El filtro por tipo en listado/búsqueda SHALL usar el tipo del egreso (no solo el del proveedor).

#### Scenario: Nuevo egreso hereda tipo del proveedor
- **WHEN** el admin registra un egreso eligiendo proveedor con tipo «Compra proveedor de producto» y no cambia el tipo
- **THEN** el egreso queda con ese `tipo_egreso_id`

#### Scenario: Tipo editable independiente del proveedor
- **WHEN** el admin cambia el tipo en el formulario respecto al default del proveedor
- **THEN** se guarda el tipo elegido en el egreso; el proveedor no cambia de tipo

#### Scenario: Backfill histórico
- **WHEN** se aplica la migración Plan 1
- **THEN** egresos existentes reciben `tipo_egreso_id` desde su proveedor cuando exista

### Requirement: Naturaleza del egreso

El egreso SHALL tener `naturaleza` con uno de: `COMPRA_MERCANCIA`, `GASTO_OPERATIVO`, `PERSONAL`, `DIVIDENDOS`, `TRIBUTO`, `OTRO`. No MUST existir valor `RETIRO_DUENO` (el retiro/acumulación del dueño es OF «Cuenta del dueño»).

Si el cliente no envía naturaleza, el sistema SHALL inferirla a partir del tipo de egreso (p. ej. compra+proveedor → `COMPRA_MERCANCIA`, personal → `PERSONAL`).

#### Scenario: Inferencia desde tipo
- **WHEN** se crea un egreso con tipo cuyo nombre indica compra a proveedor y sin naturaleza explícita
- **THEN** `naturaleza` = `COMPRA_MERCANCIA`

#### Scenario: Dividendos / personal como pago
- **WHEN** el usuario elige naturaleza `DIVIDENDOS` o `PERSONAL` y un OF visible en egreso (p. ej. Cuenta del dueño)
- **THEN** el egreso se registra y genera `SALIDA_EGRESO` desde ese OF (misma mecánica de caja)

### Requirement: Listado, filtros y export

El listado de egresos SHALL mostrar naturaleza y tipo del egreso. SHALL permitir filtrar por naturaleza y por tipo. SHALL ofrecer export CSV del resultado filtrado con al menos: fecha, valor, proveedor, documento proveedor, naturaleza, tipo, origen fondos id/nombre si disponible, observación.

#### Scenario: Export CSV
- **WHEN** el admin pulsa exportar con filtros activos
- **THEN** descarga un CSV con las filas que cumplen esos filtros

### Requirement: Entrada inventario usa tipo del egreso

La regla de permitir entrada a inventario SHALL basarse en el nombre del tipo del egreso (fallback al tipo del proveedor si el snapshot aún no viene en la respuesta).

#### Scenario: Compra permite entrada
- **WHEN** el tipo del egreso incluye «compra» y «proveedor»
- **THEN** se muestra la acción de entrada inventario

### Requirement: Documentacion de negocio (dueno)

La documentacion de producto/IA SHALL aclarar: clasificar/legalizar hacia «Cuenta del dueño» acumula; disminuir ese acumulado se hace con egreso (u otra salida) como pago (nomina, anticipo, dividendos), no con una naturaleza «retiro del dueño».

#### Scenario: Distincion clasificar vs pagar
- **WHEN** un usuario o IA consulta la guia de egresos / OF
- **THEN** queda documentado que Cuenta del dueño es acumulacion y que bajar el saldo es egreso de pago (PERSONAL / DIVIDENDOS / etc.)
