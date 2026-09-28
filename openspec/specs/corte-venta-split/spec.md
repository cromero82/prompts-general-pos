## Purpose

Corregir un **corte de ventas** mal generado (por ejemplo, uno que agrupó varios días
en un solo corte) sin borrar nada y sin descuadrar el ledger de Orígenes de fondos:

- **Eliminar** cuando el dinero del corte todavía no se movió.
- **Dividir (SPLIT)** cuando ya hubo egresos u otros movimientos con ese dinero: no
  cambia el total, solo lo reparte mejor en el tiempo.

Invariantes de todo el flujo: ningún `saldoDespues` negativo, ningún reverso sin su
contraparte, totales del corte inalterados y traza completa con motivo obligatorio
(DIAN: nada se borra sin rastro).

## Requirements

### Requirement: Eliminar bloqueado por movimientos posteriores

`delete(corteId)` SHALL validar, **antes** de generar cualquier reverso, que ninguna
OF tocada por el corte tenga movimientos posteriores a los del propio corte. El
conjunto de OF tocadas SHALL incluir las de los medios de pago con ventas
(`CORTE_VENTA`), las cajas destino de la distribución (`DISTRIBUCION`) y las de los
ajustes de cierre (`CIERRE`); para cada una se compara contra el **último id** de
movimiento que el corte generó en esa OF.

Si alguna tiene movimientos posteriores, el BE SHALL responder con el mensaje
«Existen movimientos generados luego del corte, reintente Dividir o Editar el corte»
y MUST NOT revertir nada. Validar solo las cajas destino MUST NOT considerarse
suficiente: un egreso desde Bancolombia – QR o Nequi (medios sin traslado de
distribución) también deja el reverso de ventas sin fondos.

El FE SHALL mostrar el mensaje devuelto por el BE, no un texto genérico.

#### Scenario: Egreso desde una caja destino
- **WHEN** el corte distribuyó a Caja Menor y luego se registró un egreso desde Caja Menor
- **THEN** Eliminar queda bloqueado con el mensaje del BE y el ledger no cambia

#### Scenario: Egreso desde un medio de pago sin distribución
- **WHEN** el corte registró ventas por QR y luego se registró un egreso desde QR
- **THEN** Eliminar queda bloqueado igual, porque revertir esas ventas dejaría saldo negativo

### Requirement: Orden de reversos sin saldo negativo

Al eliminar un corte, los reversos SHALL emitirse en orden crédito-antes-que-débito:
ajustes de cierre, luego la **distribución** (crédito que devuelve el traslado al
medio de pago) y por último las **entradas de venta** (débito). Revertir primero las
ventas MUST NOT ocurrir: deja una fila intermedia con `saldoDespues` negativo aunque
el saldo final cuadre.

#### Scenario: Caja Efectivo con base
- **WHEN** se elimina un corte con ventas en efectivo ya distribuidas
- **THEN** ninguna fila de reverso queda con `saldoDespues` negativo y el saldo final vuelve al previo

### Requirement: Dividir en modo editor (una partición)

Con **una sola partición**, `dividirCorte` SHALL registrar la corrección con
`tipo = 'EDICION'` y motivo obligatorio, y MUST NOT reestructurar el ledger (sin
reversos, sin puente, sin re-corte). El ajuste de campos sigue delegado al flujo de
revisión existente (`finalizarRevision`).

#### Scenario: Dejar traza de una edición
- **WHEN** el admin confirma con una sola partición y un motivo
- **THEN** queda un registro en `corte_venta_correccion` y el ledger no cambia

### Requirement: Dividir en modo SPLIT (dos o más particiones)

Con dos o más particiones, `dividirCorte` SHALL ejecutar en **una sola transacción**:
validar → crear la corrección `tipo = 'SPLIT'` → reversar el corte original → marcar
el original `estado = 'dividido'` → generar un corte nuevo por partición → cerrar el
puente. Cualquier fallo SHALL abortar toda la operación.

El re-corte SHALL reutilizar la lógica del cierre de turno
(`consultarRango`, `registrarEntradasVentaCorte`, `registrarTrasladoDistribucion`);
MUST NOT inventar un cálculo propio de ventas.

#### Scenario: Corte de dos días dividido por día
- **WHEN** un corte agrupó dos días y se divide en dos particiones
- **THEN** quedan dos cortes nuevos con las ventas de cada día y el original en `dividido`

### Requirement: Reverso completo del corte original

El reverso del SPLIT SHALL cubrir **todo** lo que el corte posteó: las
`ENTRADA_VENTA` de **cada** medio de pago —incluidos los que no se distribuyen, como
QR o Nequi— y **ambas patas** de cada traslado de distribución. Reversar solo los
medios con traslado MUST NOT ocurrir: el re-corte vuelve a postear esas ventas y
quedarían contadas dos veces en el ledger.

#### Scenario: Medio sin distribución
- **WHEN** el corte tenía ventas por QR sin traslado de distribución
- **THEN** esa `ENTRADA_VENTA` también se reversa antes de que el re-corte la vuelva a postear

### Requirement: Asiento puente para no dejar saldo negativo

Para cada OF cuyo **impacto neto** del corte sea positivo, el SPLIT SHALL acreditar un
`AJUSTE_PUENTE_SPLIT` por ese neto **antes** de los reversos, y SHALL debitarlo
(cerrar el puente) **después** de que el re-corte repuso el monto. Los reversos SHALL
ordenarse crédito-antes-que-débito.

El puente SHALL abrirse para cualquier OF con neto positivo, no solo para las cajas
destino: un medio de pago sin traslado (QR, Nequi) también queda en neto positivo y
su reverso podría chocar con un egreso posterior. Caja: Efectivo suele quedar en neto
cero (entra la venta, sale el traslado) y no necesita puente.

Si aun así un movimiento fuera a dejar el saldo negativo, la operación SHALL abortar
con error explícito.

#### Scenario: Dinero ya gastado
- **WHEN** Caja Menor recibió la distribución y un egreso posterior la gastó
- **THEN** el puente pre-financia el reverso y ningún movimiento queda con saldo negativo

### Requirement: Rango, solapes y cobertura de las particiones

Cada partición SHALL tener `fechaHasta` posterior a `fechaDesde` y SHALL caber dentro
de `[fechaIni, fechaFin]` del corte original. Las particiones MUST NOT solaparse.

Los **huecos entre particiones SHALL permitirse**: es lo que deja a cada corte nuevo
en su propio día de calendario (terminar una a las `23:59:59` y empezar la siguiente a
las `00:00:00`). Exigir contigüidad exacta MUST NOT hacerse.

La cobertura SHALL garantizarse comparando la **suma de ventas de las particiones**
contra el total del corte original, y esa validación SHALL ejecutarse **antes** de
tocar el ledger, para abortar sin haber reversado ni creado nada.

Las consultas de ventas son inclusivas en ambos extremos, así que dos particiones que
comparten exactamente el mismo instante de borde pueden contar dos veces un ticket
ubicado ahí; dejar un hueco de al menos un segundo lo evita.

Una partición cuyo rango solapa **otro** corte vigente (distinto del original) MUST NOT
volver a contar ventas, egresos ni movimientos ya cubiertos por ese corte. El piso SHALL
ser el máximo `ultimoHistorialReciboId` y el máximo `ultimoMovimientoOrigenFondosId` de
los cortes vigentes cuyo turno intersecta `[fechaDesde, fechaHasta]`. Las consultas de
la partición SHALL limitarse a ids estrictamente mayores a ese piso y dentro de ese
intervalo. El corte que se divide SHALL excluirse del piso (`excluirCorteId`): si entra,
su propio watermark deja las particiones en cero.

La comparación de cobertura contra el total del original SHALL hacerse **después** de
aplicar ese piso. Si la suma no iguala, la operación SHALL rechazarse sin tocar el ledger.

#### Scenario: Corte por día
- **WHEN** la partición 1 termina `23:59:59` y la partición 2 empieza `00:00:00` del día siguiente
- **THEN** la división se acepta y cada corte nuevo cae en su propio día de Ingresos

#### Scenario: Particiones que no cubren todo
- **WHEN** las fechas dejan ventas fuera o las cuentan dos veces
- **THEN** la operación se rechaza con el monto repartido y el esperado, sin tocar el ledger

#### Scenario: Otro corte vigente el mismo día
- **WHEN** un corte vigente del 28/09 ya cerró 2.400.000 (recibos hasta el id 12) y se divide un corte posterior cuyo rango del 28 empieza antes de ese cierre
- **THEN** la partición del 28 cuenta solo los tickets con id mayor a 12 (2.410.000, no 4.810.000) y la del 29 solo los suyos (2.640.000)
- **AND** Ingresos del 28 suma el corte previo más esa partición (4.810.000), no 7.210.000

### Requirement: Prorrateo editable de la distribución

Por cada destino (Caja Menor / Caja General), la suma de los montos de todas las
particiones SHALL igualar exactamente lo que el corte original distribuyó a ese
destino. El FE SHALL precargar una sugerencia proporcional a las ventas en efectivo de
cada partición, SHALL permitir editarla, y SHALL calcular la **última partición por
resta** para cerrar al centavo exacto. Un destino sin distribución original SHALL
ocultarse.

El FE SHALL mostrar en vivo el avance («repartido X de Y») y bloquear la confirmación
si no cuadra, sin depender de que el BE rechace la llamada.

#### Scenario: Partición sin ventas en efectivo
- **WHEN** una partición solo tuvo ventas por QR
- **THEN** su monto a Caja Menor queda en 0 y el resto se concentra en las demás particiones

### Requirement: Motivo obligatorio y trazabilidad

Toda corrección SHALL exigir `motivo` (columna NOT NULL), tanto en SPLIT como en
EDICION. La traza SHALL incluir: el corte original conservado con
`estado = 'dividido'`, el registro `corte_venta_correccion` (quién, cuándo, motivo,
total y rango del original), el detalle `corte_venta_correccion_detalle` (qué cortes
nuevos, en qué rango y orden) y `corte_venta.origen_split_id` en cada corte nuevo.

Los reversos y el puente SHALL llevar observación uniforme apuntando a la corrección
(«Reverso por corrección #X del corte #N»). MUST NOT borrarse ninguna fila de
movimientos.

Un corte ya corregido MUST NOT volver a dividirse ni eliminarse.

#### Scenario: Reintento
- **WHEN** se intenta dividir o eliminar un corte ya dividido
- **THEN** el BE responde con error explícito y no crea una segunda corrección

### Requirement: El estado dividido sale de circulación

`dividido` SHALL tratarse igual que `eliminado` en **todo** el sistema: un corte
dividido MUST NOT contar en Ingresos (KPI, gráfica, tabla), MUST NOT ser candidato a
«último corte vigente» y MUST NOT aportar a la suma de ventas de cortes vigentes. Sus
ventas ya las heredaron los cortes nuevos, así que contarlo otra vez las duplicaría.

La resolución del «último corte vigente» SHALL desempatar por **id**: un SPLIT crea
varios cortes con la misma `fechaCreacion` y sin desempate la base de datos devuelve
cualquiera, dejando watermarks equivocados (tickets del último corte apareciendo como
«sin corte»).

El FE SHALL mantener consultables los cortes divididos mediante un filtro de estado
propio, para trazabilidad.

#### Scenario: Ingresos tras dividir
- **WHEN** un corte de 3.000.000 se divide en dos de 1.600.000 y 1.400.000
- **THEN** el día muestra solo los cortes nuevos, no 4.600.000

#### Scenario: Tickets sin corte
- **WHEN** se consulta el turno abierto después de un SPLIT
- **THEN** el watermark es el del último corte nuevo y no reaparecen tickets ya cortados

### Requirement: Los asientos de corrección no son ingreso ni movimiento del cierre

`AJUSTE_PUENTE_SPLIT` y los reversos del SPLIT SHALL quedar fuera del filtro de la
columna «Movimientos» del cierre (por `origenTipo` `SPLIT_PUENTE` y `SPLIT_REVERSO`),
igual que hoy se excluye `DISTRIBUCION`. Sin esa exclusión el `REVERSO_TRASLADO` del
medio de pago inflaría el Esperado del siguiente cierre, porque su contraparte (el
nuevo `TRASLADO`) sí está excluida.

Como el cierre del puente ocurre **después** del último corte creado, su watermark
(`ultimoMovimientoOrigenFondosId`) SHALL ampliarse al terminar; de lo contrario el
siguiente cierre tomaría como Base el saldo con el puente todavía abierto.

#### Scenario: Cierre de turno posterior al split
- **WHEN** se abre el cierre de turno después de dividir
- **THEN** la Base de cada medio coincide con el saldo real de su OF y Movimientos no incluye los asientos de corrección

### Requirement: Endpoints y permisos

El BE SHALL exponer `POST /corte-venta/{id}/dividir` restringido a administrador, y
`GET /corte-venta/{id}/distribucion-original` con el monto que el corte distribuyó a
cada caja destino, para que el FE precargue y valide el prorrateo.

#### Scenario: Usuario sin rol admin
- **WHEN** un usuario no administrador llama a `POST /corte-venta/{id}/dividir`
- **THEN** la petición se rechaza y ningún corte cambia de estado

### Requirement: Asistente Dividir

El diálogo SHALL ser arrastrable y SHALL mostrar el rango original **con segundos**
(`dd/MM/yyyy HH:mm:ss`): los segundos son los que deciden si una partición cabe en el
rango, y ocultarlos deja al admin sin forma de apuntarle al límite.

Cada extremo de partición SHALL capturarse como Fecha (datepicker) + Hora con
segundos, con los datepickers acotados al rango del corte original. Todas las fechas
SHALL ser editables, incluidos el inicio de la primera partición y el fin de la
última, porque de ellas depende en qué día calendario queda cada corte nuevo.

Cada partición SHALL ofrecer **Consultar**, que reutiliza `consultar-rango` con el
rango exacto de esa partición, `ultimoCorte=false` y `excluirCorteId` del corte
original, y muestra las ventas por método de pago antes de confirmar. La consulta
inicial del diálogo (prorrateo) SHALL usar el mismo `excluirCorteId`. Los mensajes de
validación SHALL incluir el límite exacto que se violó.

#### Scenario: Revisar antes de confirmar
- **WHEN** el admin fija las fechas de una partición y pulsa Consultar
- **THEN** ve las ventas por medio de ese rango, sin los tickets ya cerrados por otro corte vigente que lo solapa

### Requirement: Cortes generados por el split

Los cortes nuevos SHALL quedar con `modoCaptura = 'SOLO_VISIBLE'`, sin Contado ni
desfase: son reconstrucción del sistema, no un arqueo físico nuevo. No existe
«diferencia» para ninguna partición, ni la primera ni la última.

El SPLIT MUST NOT tocar los egresos: quedan como están, y un egreso posterior al
`fechaFin` del corte original queda fuera de todas las particiones por construcción.

#### Scenario: Egreso posterior al corte
- **WHEN** se divide un corte que tenía un egreso registrado después de su `fechaFin`
- **THEN** el egreso queda intacto y no aparece en ninguna partición

### Requirement: Migración aditiva

El schema SHALL cambiarse con migración nueva `68_corte_venta_split.sql`: `estado`
ampliado con `'dividido'`, columna `corte_venta.origen_split_id` y tablas
`corte_venta_correccion` (motivo NOT NULL) + `corte_venta_correccion_detalle`.

MUST NOT tocarse ninguna query de saldo (`sumImpactoByCuentaId*`) ni añadirse columnas
de supersede: el soft-supersede se descartó a propósito por ser un evento aislado. El
valor de enum `REVERSO_TRASLADO_DISTRIBUCION` SHALL conservarse como legacy para no
romper la deserialización de filas existentes; los reversos nuevos usan
`REVERSO_TRASLADO`.

El script de reset transaccional SHALL incluir `corte_venta_correccion` y
`corte_venta_correccion_detalle`.

#### Scenario: Filas antiguas con el enum legacy
- **WHEN** existen movimientos guardados con `REVERSO_TRASLADO_DISTRIBUCION`
- **THEN** siguen deserializando sin error y los reversos nuevos usan `REVERSO_TRASLADO`

### Requirement: Pruebas humanas pendientes

Esta capacidad está **implementada y compilando, pendiente de pruebas humanas de punta
a punta**. Los escenarios SHALL listarse en `tasks.md` del change
`2026-09-24-corte-venta-split` hasta que se ejecuten y se archive el change:

- **CV-E01-permitido** — Eliminar sin movimientos posteriores.
- **CV-E02-no-permitido** — Eliminar bloqueado por egreso posterior (incluida la
  variante con egreso desde un medio de pago sin distribución).
- **CV-E02-split-por-día** — corte de dos días dividido en dos, con egreso previo.
- **CV-E04-split-en-mismo-día** — corte de un día dividido en dos turnos.
- **Split 3+ particiones** — reparto sin residuo de redondeo (última por resta).
- **CV-E05-solape-mismo-día** — partición que solapa un corte vigente anterior del mismo día: no recontabiliza sus tickets (piso por id) y Ingresos no suma 7.210.000.

Las pruebas SHALL correrse sobre un binario que incluya **todos** los fixes, y sobre
BD reseteada: los hallazgos previos (doble conteo de QR, corte dividido sumando en
Ingresos, watermark del puente) invalidan las corridas anteriores.

#### Scenario: Retomar el trabajo
- **WHEN** se reabre el tema de corrección de cortes
- **THEN** se leen este spec, `contextos-ia/corte-venta-split.md` y las tareas pendientes del change

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/corte-venta-split.md`,
este spec y `CONTEXTO-TESTER-POS.md` §4.9 / §10.1. El detalle técnico y las lecciones
del incidente viven en `ayuda-documental/corte-venta-split/`.
