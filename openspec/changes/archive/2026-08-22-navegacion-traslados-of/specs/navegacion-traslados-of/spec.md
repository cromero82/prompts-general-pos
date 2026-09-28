## ADDED Requirements

### Requirement: Consultar patas de un grupo de traslado

El sistema SHALL exponer `GET /movimientos-origen-fondos/grupo/{grupoTrasladoId}` devolviendo ambas patas ordenadas por id ASC. Si no hay movimientos, SHALL responder 404.

#### Scenario: Par existente
- **WHEN** se consulta un `grupoTrasladoId` válido de un TRASLADO o DISTRIBUCION
- **THEN** la respuesta incluye la salida y la entrada con `origenFondosId` y nombres resueltos

### Requirement: Navegación Atrás y Adelante en la lista OF

La lista de movimientos de Orígenes de fondos SHALL mostrar **Adelante** en filas con `grupoTrasladoId` e impacto negativo, y **Atrás** en filas con `grupoTrasladoId` e impacto positivo.

#### Scenario: Adelante desde salida
- **WHEN** el usuario pulsa Adelante en una salida de traslado
- **THEN** se selecciona el OF de la entrada hermana, se cargan sus movimientos y se resalta la fila de la entrada

#### Scenario: Atrás desde entrada
- **WHEN** el usuario pulsa Atrás en una entrada de traslado
- **THEN** se selecciona el OF de la salida hermana y se resalta esa fila

#### Scenario: Resaltado temporal
- **WHEN** se completa una navegación Atrás/Adelante
- **THEN** la tarjeta del OF y la fila del movimiento muestran un efecto de resaltado breve y se hace scrollIntoView hacia ellos
