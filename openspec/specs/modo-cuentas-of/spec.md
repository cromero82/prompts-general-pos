## Purpose

Definir cuándo una salida de un origen de fondos exige saldo suficiente. El flag del establecimiento (`manejo_estricto_cuentas`) no cubre el efectivo físico: el modo flexible solo aplica a medios electrónicos.

## Requirements

### Requirement: Efectivo físico siempre exige saldo

Una salida con impacto negativo desde un origen de fondos con naturaleza **FISICA** (Caja: Efectivo, Caja Menor, Caja General y sus hijos) SHALL rechazarse si el saldo del ledger es menor que el valor, aunque `establecimiento.manejo_estricto_cuentas` sea false.

El mensaje SHALL indicar saldo disponible y valor requerido. El formulario de egreso nuevo SHALL mostrar el aviso y MUST NOT habilitar guardar en ese caso.

#### Scenario: Egreso desde caja sin saldo, modo flexible
- **WHEN** el establecimiento está en modo flexible y el usuario registra un egreso desde Caja: Efectivo por un monto mayor al saldo
- **THEN** el sistema no guarda el egreso y el formulario indica que el efectivo físico exige saldo suficiente

#### Scenario: Traslado desde caja física sin saldo
- **WHEN** el usuario traslada desde un origen FISICA un valor mayor al saldo, en modo flexible o estricto
- **THEN** el traslado se rechaza y ningún lado del par queda registrado

### Requirement: Modo flexible solo en medios no físicos

Si `manejo_estricto_cuentas` es false, una salida desde un origen **ELECTRONICA**, **MIXTA** o sin naturaleza SHALL permitirse aunque el saldo no alcance. El formulario de egreso SHALL advertir que se permitirá en modo flexible y MUST NOT bloquear el guardado por ese motivo.

Si `manejo_estricto_cuentas` es true, toda salida (de cualquier naturaleza) SHALL exigir saldo suficiente, con la excepción de devolución de venta.

#### Scenario: Egreso electrónico descubierto
- **WHEN** el establecimiento está en modo flexible y el usuario egresa desde Bancolombia QR (o un hijo electrónico) más de lo que marca el saldo
- **THEN** el egreso se guarda y el ledger de ese origen puede quedar negativo

#### Scenario: Modo estricto
- **WHEN** el establecimiento tiene manejo estricto activo y cualquier origen no alcanza
- **THEN** la salida se rechaza, sea efectivo o medio electrónico

### Requirement: Devolución de venta no usa esta validación

`SALIDA_DEVOLUCION_VENTA` MUST NOT pasar por la validación de saldo suficiente. El reembolso puede salir de un origen distinto al medio de la venta cuando esa venta aún no está en el ledger.

#### Scenario: Reembolso en efectivo de una venta sin corte
- **WHEN** se anula o se baja el total de una venta sin corte y el origen del reembolso es Caja: Efectivo
- **THEN** la salida de devolución se registra aunque el saldo de esa caja no alcance

### Requirement: Textos visibles del modo

Con el flag desactivado, Orígenes de fondos SHALL mostrar la insignia **Modo flexible (solo electrónicos)**. El interruptor en Datos del negocio SHALL explicar que, desactivado, el efectivo físico sigue exigiendo saldo y los medios electrónicos se permiten con advertencia.

#### Scenario: Insignia en lista OF
- **WHEN** el operador abre Orígenes de fondos y el establecimiento no está en modo estricto
- **THEN** ve «Modo flexible (solo electrónicos)»
