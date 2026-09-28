## Purpose

Permitir egresos de naturaleza PERSONAL o DIVIDENDOS hacia un catálogo de Personas (sin liquidar nómina), sin inventar proveedores. Cuenta del dueño sigue siendo clasificación OF; el egreso descarga el saldo solo con persona dueño/propietario.

## Requirements

### Requirement: Catalogo Personas

El sistema SHALL exponer CRUD de `persona` (documento, nombre, telefono, correo, activo, esDuenoPropietario) para rol admin. El documento SHALL ser unico.

#### Scenario: Crear persona
- **WHEN** admin crea una persona con documento y nombre validos
- **THEN** queda disponible para seleccionar en egresos PERSONAL/DIVIDENDOS

#### Scenario: Persona dueño
- **WHEN** admin marca `esDuenoPropietario = true`
- **THEN** esa persona habilita origen Cuenta del dueño en egresos PERSONAL/DIVIDENDOS

### Requirement: Beneficiario del egreso

Un egreso SHALL tener proveedor O persona (exactamente uno segun naturaleza):
- Naturalezas `PERSONAL` o `DIVIDENDOS`: `persona_id` obligatorio, `proveedor_id` null
- Resto de naturalezas: `proveedor_id` obligatorio, `persona_id` null

El tipo de egreso sigue siendo obligatorio (snapshot). Si hay proveedor, el tipo puede defaultar al usual del proveedor; si hay persona, el tipo se elige explicitamente.

### Requirement: Origen Cuenta del dueño

El OF Cuenta del dueño SHALL permanecer con `visible_en_egreso = false` en el catalogo general.
El sistema SHALL permitir ese OF como origen de egreso solo si:
`visibleEnEgreso == true` OR (`esCuentaDelDueno` AND `persona.esDuenoPropietario` AND naturaleza PERSONAL|DIVIDENDOS).

En UI, el select de origen SHALL mezclar el arbol-egreso (visibles) con Cuenta del dueño solo cuando naturaleza PERSONAL/DIVIDENDOS y la persona seleccionada tiene `esDuenoPropietario`. Al cambiar persona/naturaleza, el origen invalidado SHALL limpiarse.

#### Scenario: Egreso a dueño desde Cuenta del dueño
- **WHEN** admin registra egreso naturaleza PERSONAL/DIVIDENDOS con persona dueño/propietario y origen Cuenta del dueño
- **THEN** se guarda y se registra SALIDA_EGRESO desde esa bolsa

#### Scenario: Persona no dueño no desbloquea Cuenta del dueño
- **WHEN** la persona no tiene `esDuenoPropietario`
- **THEN** Cuenta del dueño no es origen valido (ni en select ni en BE)

#### Scenario: Naturaleza compra no usa Cuenta del dueño
- **WHEN** naturaleza es COMPRA_MERCANCIA (u otra no PERSONAL/DIVIDENDOS) aunque la persona sea dueño
- **THEN** Cuenta del dueño no es origen valido

#### Scenario: Egreso a personal (caja visible)
- **WHEN** admin registra egreso naturaleza PERSONAL con persona (no dueño) y OF visible (p.ej. Caja)
- **THEN** se guarda sin proveedor y se registra SALIDA_EGRESO

#### Scenario: Egreso compra sigue con proveedor
- **WHEN** naturaleza es COMPRA_MERCANCIA u otra no personal/dividendos
- **THEN** el proveedor sigue siendo obligatorio

### Requirement: Listado y export con persona

El listado SHALL mostrar el beneficiario (proveedor o persona), filtrar por persona (barra principal: Naturaleza → Proveedor → Persona) y exportar CSV incluyendo documento/nombre de persona cuando aplique.

#### Scenario: CSV con persona
- **WHEN** se exporta un egreso PERSONAL
- **THEN** el CSV incluye datos de la persona

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar narrativo (`contextos-ia/egresos.md`), este spec y `CONTEXTO-TESTER-POS.md` §4.10.

#### Scenario: Perfil QA refleja flag dueño
- **WHEN** la tester sigue §4.10
- **THEN** valida clasificar vs pagar y el toggle Es dueño / propietario
