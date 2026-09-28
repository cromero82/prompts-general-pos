## Purpose

Permitir egresos de naturaleza PERSONAL o DIVIDENDOS hacia un catálogo de Personas (sin liquidar nómina), sin inventar proveedores. Cuenta del dueño sigue siendo clasificación OF; el egreso descarga el saldo.

## Requirements

### Requirement: Catalogo Personas

El sistema SHALL exponer CRUD de `persona` (documento, nombre, telefono, correo, activo) para rol admin. El documento SHALL ser unico.

#### Scenario: Crear persona
- **WHEN** admin crea una persona con documento y nombre validos
- **THEN** queda disponible para seleccionar en egresos PERSONAL/DIVIDENDOS

### Requirement: Beneficiario del egreso

Un egreso SHALL tener proveedor O persona (exactamente uno segun naturaleza):
- Naturalezas `PERSONAL` o `DIVIDENDOS`: `persona_id` obligatorio, `proveedor_id` null
- Resto de naturalezas: `proveedor_id` obligatorio, `persona_id` null

El tipo de egreso sigue siendo obligatorio (snapshot). Si hay proveedor, el tipo puede defaultar al usual del proveedor; si hay persona, el tipo se elige explicitamente.

#### Scenario: Egreso a personal
- **WHEN** admin registra egreso naturaleza PERSONAL con persona y OF (p.ej. Cuenta del dueño)
- **THEN** se guarda sin proveedor y se registra SALIDA_EGRESO

#### Scenario: Egreso compra sigue con proveedor
- **WHEN** naturaleza es COMPRA_MERCANCIA u otra no personal/dividendos
- **THEN** el proveedor sigue siendo obligatorio

### Requirement: Listado y export con persona

El listado SHALL mostrar el beneficiario (proveedor o persona), filtrar por persona y exportar CSV incluyendo documento/nombre de persona cuando aplique.

#### Scenario: CSV con persona
- **WHEN** se exporta un egreso PERSONAL
- **THEN** el CSV incluye datos de la persona
