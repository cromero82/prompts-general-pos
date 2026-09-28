## Why

Egresos PERSONAL/DIVIDENDOS no deben inventar proveedores. Plan 2 añade catálogo Personas y XOR beneficiario según naturaleza.

## What Changes

- Tabla `persona` + `egreso.persona_id`; `proveedor_id` nullable
- API `/personas` (CRUD admin; GET multi-rol)
- Validación: PERSONAL/DIVIDENDOS → persona; resto → proveedor
- FE: Dominios Personas; form egreso condicional; listado Beneficiario + filtro persona; CSV

## Capabilities

### New Capabilities
- `egresos-personas`: catálogo persona + regla XOR en egreso

### Modified Capabilities
- (ninguna delta aparte; narrativo egresos unificado)

## Impact

- BE: `Persona*`, `Egreso`, `EgresoServiceImpl`, `EgresoRepository`, ledger observación, SQL `48_…`
- FE: Dominios persona, egreso-edit/list, egresos.service
- Docs: `contextos-ia/egresos.md`, dual docs, tester §4.10
