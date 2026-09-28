## Purpose

Entorno sandbox de pruebas del POS: BD y puertos aparte de desarrollo, con utilidades admin para resetear transacciones y consultar datos en solo lectura.

## Requirements

### Requirement: Aislamiento sandbox

El entorno sandbox SHALL usar BD `controlneg_rmx_db_sandbox` y el perfil Spring `sandbox` (API tipica `:8188`), separado de desarrollo (`controlneg_rmx_db`, `:8088`). El código estable del tester SHALL vivir bajo `repos/sandbox/{proyecto}`.

#### Scenario: Datos no se mezclan
- **WHEN** el tester opera en la URL sandbox
- **THEN** ventas, pagos QR y saldos no afectan la BD de desarrollo

### Requirement: Flags de habilitacion en configuracion_app

Los endpoints `/sandbox/*` SHALL comprobar flags booleanos en `configuracion_app` key `sistema`, ruta JSON `sandbox.*`. Si el flag falta o es false, el endpoint SHALL responder HTTP 403.

#### Scenario: Reset habilitado
- **WHEN** `sistema.sandbox.habilitarEndpointResetTransacciones` es `true`
- **THEN** `POST /sandbox/reset-datos-transaccionales` puede ejecutarse (rol admin)

#### Scenario: Consulta BD habilitada
- **WHEN** `sistema.sandbox.habilitarEndpointConsultaBd` es `true`
- **THEN** `POST /sandbox/consulta-bd` puede ejecutarse (rol admin)

#### Scenario: Flag apagado
- **WHEN** el flag correspondiente no es `true`
- **THEN** el endpoint responde 403 con cuerpo `{ ok: false, error: "…" }`

### Requirement: Reset de datos transaccionales

`POST /sandbox/reset-datos-transaccionales` (rol `admin`) SHALL vaciar tablas transaccionales (ventas, cortes, ledger, egresos, CxC, notificaciones de pago, etc.) y SHALL conservar parametricas (OF, medios, productos, plantillas, usuarios). Tras el reset, el siguiente login admin SHALL poder exigir base inicial.

#### Scenario: Reset exitoso
- **WHEN** un admin invoca el reset con el flag activo
- **THEN** la respuesta indica exito y las tablas transaccionales quedan vacias sin borrar catalogos

### Requirement: Consulta BD solo SELECT

`POST /sandbox/consulta-bd` (rol `admin`) SHALL ejecutar SQL de solo lectura contra la BD del servicio. Body: `{ "sql": string, "maxRows"?: number }` (`maxRows` default 100, maximo 500).

El sistema SHALL aceptar solo sentencias que empiecen por `SELECT` o `WITH`, sin `;` intermedios, sin DML/DDL ni `SELECT INTO`. Allowlist de tablas: **todas**. Timeout de consulta: 15s. Respuesta: `{ ok, columns, rows, rowCount, truncated, maxRows }`.

#### Scenario: SELECT valido
- **WHEN** admin envia `{"sql":"select * from egreso ORDER BY id DESC LIMIT 10","maxRows":10}` con el flag activo
- **THEN** responde 200 con columnas y hasta 10 filas

#### Scenario: DML rechazado
- **WHEN** el SQL contiene `INSERT`, `UPDATE`, `DELETE`, `DROP` u otra operacion de escritura
- **THEN** responde 400 sin ejecutar la sentencia

#### Scenario: Multi-sentencia rechazada
- **WHEN** el SQL incluye `;` entre sentencias
- **THEN** responde 400

### Requirement: UI reset solo en FE sandbox

El menu admin **Reset datos transaccionales** SHALL mostrarse solo cuando `environment.sandbox === true` (build sandbox). En FE de desarrollo no MUST aparecer ese item de menu.

#### Scenario: Menu en sandbox
- **WHEN** el admin usa el FE sandbox
- **THEN** ve la opcion de reset tras Copias de seguridad
