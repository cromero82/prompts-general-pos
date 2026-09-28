## Context

Tras Plan 1, personal/dividendos seguían exigiendo proveedor. Plan 2 introduce Persona sin nómina.

## Decisions

1. XOR estricto por naturaleza (PERSONAL/DIVIDENDOS → persona).
2. Tipo sigue obligatorio; con persona no hay default de proveedor.
3. CRUD Personas en Dominios (admin).
4. Observación ledger usa nombre de persona o proveedor.

## Risks

| Riesgo | Mitigación |
|--------|------------|
| Egresos históricos solo con proveedor | Sin backfill a persona; UI sigue mostrando proveedor |
| Migración sin DROP NOT NULL en proveedor_id | SQL `48` lo hace |
