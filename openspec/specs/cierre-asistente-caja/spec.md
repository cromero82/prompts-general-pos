## Purpose

Ayudar al cajero a contar billetes COP en Cierre de turno y asociar ese total como Contado de efectivo, con diferencia frente a Esperado.

## Requirements

### Requirement: Nombre y acceso desde Cierre de turno

El diálogo SHALL titularse **«Asistente contar billetes»**, y ese SHALL ser el nombre con el
que se le referencie en conversación, incidencias y documentación. El componente sigue
llamándose `asistente-cierre-caja-dialog` en el código.

La fila de efectivo en Cierre de turno SHALL ofrecer un botón con tooltip «Asistente contar
billetes» que abre el diálogo. El diálogo SHALL ser arrastrable.

#### Scenario: Abrir asistente
- **WHEN** el cajero abre Cierre de turno y pulsa el asistente de caja
- **THEN** ve denominaciones COP y puede capturar cantidades

### Requirement: Se cuenta sin la base

El asistente SHALL indicar «Deja la base $X en la caja y cuenta los demás billetes por
denominación», con X tomado de `configuracion_app` / `corte-venta.base-efectivo`.

En consecuencia **Total billetes** es el efectivo SIN la base, y el valor que se asocia a la
fila Efectivo del cierre SHALL ser `total billetes + base`: el corte guarda el efectivo
completo del cajón, que es contra lo que se compara el Esperado. MUST NOT asociarse el total
de billetes en crudo: dejaría el Contado corto por el monto de la base.

MUST NOT usar la fecha del Mac ni un reloj distinto al del backend.

#### Scenario: Asociar conteo
- **WHEN** el cajero deja la base, cuenta el resto y confirma Asociar
- **THEN** la fila Efectivo del cierre queda con el contado completo (billetes + base)

#### Scenario: Vista compacta del cierre
- **WHEN** el cierre está en vista Compacta, que muestra Efectivo sin base (ver `cierre-turno-indicadores`)
- **THEN** la columna Real muestra exactamente el total de billetes contado en el asistente

### Requirement: Diferencia vs Esperado

El asistente SHALL mostrar Diferencia = Contado − Esperado de la fila efectivo, con el mismo
criterio visual de desfase que la tabla de medios (faltante / sobrante / cero). Contado es el
efectivo completo (total billetes + base) y el Esperado es el que calcula el cierre, que
también incluye la base: así la diferencia coincide con la de la tabla en ambas vistas,
Compacta y Extendida.

#### Scenario: Faltante o sobrante
- **WHEN** el total de billetes no coincide con Esperado
- **THEN** se ve la diferencia firmada; Asociar igual deja ese Contado en la tabla

### Requirement: Solo dos cifras en el resumen

El resumen del asistente SHALL mostrar únicamente **Total billetes** y **Diferencia**.
MUST NOT mostrar el editor de base, «Ventas (menos movimientos)», el Esperado ni la fórmula:
el conteo de billetes es la única tarea del diálogo.

La base SHALL leerse de `configuracion_app` solo para la leyenda; el asistente MUST NOT
persistirla. Ajustarla es responsabilidad de otra pantalla.

Las cifras del asistente son una ayuda de conteo. MUST NOT sustituir `totalVentasSistema`
(tickets) como fuente de verdad de Ingresos. Un desfase al contar MUST NOT cambiar las Ventas
del dashboard.

#### Scenario: Rehidratar conteo
- **WHEN** el cajero cierra el asistente con un conteo y lo vuelve a abrir en el mismo cierre
- **THEN** las cantidades anteriores reaparecen

### Requirement: Entrada manual precarga la base

El diálogo **Entrada manual** (`base-inicial-dialog`), que registra el efectivo inicial de la caja, SHALL precargar **Valor** con los pesos enteros de `configuracion_app` / `corte-venta.base-efectivo` (`ConfigurationService.obtenerBaseEfectivoSugerida`). Si la clave no existe, está vacía o el monto es menor a 0.01, **Valor** SHALL quedar vacío. Si el usuario ya editó **Valor**, MUST NOT sobrescribirlo.

Al recibir el foco, el texto de **Valor** SHALL quedar seleccionado.

**Registrar** SHALL permanecer deshabilitado mientras **Valor** no sea un número mayor o igual a 0.01, o mientras el registro está en curso. Enter en cualquier parte del diálogo SHALL invocar la misma acción que **Registrar**. Si **Valor** no es válido, esa acción MUST NOT enviar el registro. Mientras guarda, Enter MUST NOT reenviar.

#### Scenario: Valor por defecto
- **WHEN** se abre Entrada manual y `corte-venta.base-efectivo` tiene un monto mayor o igual a 0.01
- **THEN** Valor muestra ese monto y, al recibir el foco, el texto queda seleccionado

#### Scenario: Sin base configurada
- **WHEN** se abre Entrada manual y la clave no tiene un monto mayor o igual a 0.01
- **THEN** Valor queda vacío y Registrar permanece deshabilitado

#### Scenario: Enter registra
- **WHEN** Valor es válido y el usuario pulsa Enter en cualquier control del diálogo
- **THEN** se ejecuta la misma acción que el botón Registrar

### Requirement: Sin SQL de schema

Esta capacidad MUST NOT exigir migración de tablas. No sustituye el handoff de simular días / fecha-sistema sandbox.

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/cierre-asistente-caja.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.9 / §10.1 / §10.6.
