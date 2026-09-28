## Purpose

Permitir registrar en cada abono CxC la persona (cliente) que entrega el dinero, distinta o igual al deudor de la cuenta, con traza en listado del rail y en OF (tercero).

## Requirements

### Requirement: Pagador en abono CxC

Al registrar un abono, el sistema SHALL aceptar `clientePagadorId` (y opcionalmente snapshot de nombre) y persistirlo en `abono_cxc`.

Si el request no trae pagador, el sistema SHALL usar el `cliente_id` deudor de la CxC.

#### Scenario: Abona el deudor
- **WHEN** el cajero deja el selector en el cliente de la CxC y confirma
- **THEN** el abono guarda ese `cliente_pagador_id` / nombre

#### Scenario: Abona otra persona
- **WHEN** el cajero elige u otro cliente (o crea uno con +) y confirma
- **THEN** el abono guarda el pagador elegido y el deudor de la CxC no cambia

### Requirement: UI Registrar abono

El dialog de abono SHALL mostrar el selector de clientes etiquetado como «Quién abona», con posibilidad de buscar existentes y crear nuevos (mismo patrón + / Enter), y MUST exigir un cliente seleccionado para habilitar el submit.

Al recibir foco, el input «Monto del abono» SHALL seleccionar todo su texto.

#### Scenario: Sin pagador seleccionado
- **WHEN** el cajero limpia el selector
- **THEN** no puede confirmar el abono

#### Scenario: Foco en monto del abono
- **WHEN** el cajero entra al campo Monto del abono
- **THEN** el valor actual queda seleccionado

### Requirement: Visibilidad en rail

El panel Crédito SHALL listar en cada abono el nombre del pagador cuando exista.

Al pasar el cursor sobre la fecha corta de un abono, el panel SHALL mostrar la traza de fecha de `FechaUtilService.formatDate` (p. ej. «Hoy, 8:30 p. m.»).

El panel Crédito SHALL mostrar **Total ticket**, **Abonado** y **Saldo**. MUST NOT mostrar ni calcular un renglón «Original crédito».

#### Scenario: Abrir crédito
- **WHEN** se genera crédito sobre un ticket
- **THEN** el rail muestra Total ticket, Abonado y Saldo (sin Original crédito)

#### Scenario: Hover fecha de abono
- **WHEN** el cajero pasa el mouse sobre la fecha de un abono
- **THEN** aparece el tooltip con día relativo y hora

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/cxc-abono-pagador.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.5 / §10.3.
