## ADDED Requirements

### Requirement: Tabla de movimientos con estilo cebra estándar

La tabla de movimientos del historial OF SHALL usar el patrón cebra del POS con fondo en `tr` y `td`, hover con `--pos-mat-table-row-hover`, y selección azul persistente.

#### Scenario: Historial con varias filas
- **WHEN** hay varios movimientos en el OF seleccionado
- **THEN** se distingue cebra pares/impares y la selección/hover prevalecen
