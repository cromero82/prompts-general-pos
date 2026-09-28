# Corrección de cortes de venta: Dividir (Split) — Explicación detallada

> Documento técnico del fix. Para una versión sin tecnicismos ver
> [`explicacion-simple.md`](explicacion-simple.md).
>
> **Actualizado 2026-09-24:** refleja lo **implementado**, no el diseño inicial. Varias
> decisiones cambiaron al probar (bloqueo más amplio, huecos permitidos entre
> particiones, puente por OF) y dos pasos del diseño original quedaron obsoletos. El
> contrato vigente es `openspec/specs/corte-venta-split/spec.md`.

---

## 1. El problema

Un **corte de ventas** (cierre de turno) se generó con parámetros incorrectos:
tomó **2 días en un solo corte** (ventas del 23/09 y 24/09/2026 agregadas juntas)
en vez de 2 cortes, uno por día. Después del corte se registraron **egresos** desde
el origen de fondos destino (Caja Menor), es decir, **el dinero distribuido ya se
gastó**.

Datos del ejemplo real (dev):

| Dato | Valor |
|---|---|
| Corte malo (agregado 2 días) | 1.500.000 = 1.000.000 (23/09) + 500.000 (24/09) |
| Distribución a Caja Menor | 1.500.000 |
| Caja:Efectivo (saldo base) | 150.000 |
| Egreso posterior desde Caja Menor | 1.500.000 (COMPRA_MERCANCIA, origenFondosId=4) |
| Situación del corte | Es el **último corte**; no hay cortes posteriores |

### Por qué no basta con Eliminar

- Eliminar un corte imprime la distribución (reversos). Si Caja Menor/Caja General
  ya gastó el dinero (egresos posteriores), no existe fuente real para devolverlo →
  **saldos negativos** o ledger inconsistente.
- Por eso, **Eliminar queda bloqueado** cuando hay movimientos posteriores en **cualquier**
  OF que el corte tocó (no solo los destinos de la distribución; ver 4.1). Mensaje exacto:
  > «Existen movimientos generados luego del corte, reintente Dividir o Editar el corte»

### Lección de un intento fallido anterior (no repetir)

Un intento previo hizo **un solo** `REVERSO_ENTRADA_VENTA` (−500.000) y el saldo
quedó en **−350.000**: se revirtió la entrada sin su traslado.

**Regla de oro del ledger:** ningún cambio puede dejar `saldoDespues` negativo ni
romper la contraparte 1:1 de los movimientos.

---

## 2. Cómo funciona el ledger de un corte (base del fix)

Cada corte genera, en **cada OF asociado a método de pago**
(Caja:Efectivo, Bancolombia – QR, Nequi):

1. `ENTRADA_VENTA` (+ ventas del rango) — entra el dinero de las ventas.

Y además, **solo en Caja:Efectivo** (es el único medio que se distribuye):

2. `TRASLADO` (− distribución) — se manda efectivo a Caja Menor / Caja General,
   con su **contraparte (+)** en el OF destino.

> ⚠️ Esta asimetría es la trampa principal del fix. QR y Nequi reciben `ENTRADA_VENTA`
> **sin** traslado, así que cualquier lógica que recorra "los traslados de distribución"
> se salta esos medios. Pasó de verdad: la primera versión del split solo reversaba las
> ventas de los OF con traslado, el re-corte las volvía a postear y QR quedaba contado
> **dos veces** en el ledger.

Secuencia esperada si el corte hubiera salido bien (2 cortes):

```
Caja:Efectivo        ENTRADA_VENTA +1.000.000 → TRASLADO −1.000.000   (23/09)
                     ENTRADA_VENTA  +500.000  → TRASLADO   −500.000   (24/09)
Caja Menor           +1.000.000 (23/09), +500.000 (24/09)             (contrapartes)
Saldo Caja:Efectivo  150.000 (base) ... saldo final 150.000
```

El corte malo, en cambio, dejó **un solo par** por OF: `ENTRADA_VENTA +1.500.000`
y `TRASLADO −1.500.000` (y su contraparte en Caja Menor).

---

## 3. Alternativas evaluadas y descartadas

| Alternativa | Por qué se descartó |
|---|---|
| **Bloqueo duro** (no permitir corregir) | La corrección es urgente; no soluciona nada |
| **Reverso total + re-corte** (con asiento puente) | Válida, deja el historial con reversos; es la base, pero el split la hace más limpia |
| **Corrección por diferencias** | Innecesaria: `total del corte malo == suma de los 2 cortes correctos` (misma base imponible) |
| **Soft-supersede** (marcar filas "reemplazadas" y filtrarlas en todas las queries de saldo) | Obliga a cambiar el sistema de consulta de saldos para un evento aislado — descartado a propósito |
| **SPLIT / Dividir** ✅ | Reestructura el registro sin cambiar montos, sin tocar queries, con traza completa |

Clave de la decisión: **el split no cambia la plata** (mismos totales, mismos
saldos finales), solo reorganiza el registro del corte → no amerita reversos que
parezcan movimientos reales ni un cambio global de consultas.

---

## 4. Solución final: funcionalidad "Dividir"

### 4.1 Reglas globales

- **Eliminar:** habilitado solo si el corte es el último vigente **y ninguna OF que el
  corte tocó** tuvo movimientos posteriores. El conjunto incluye los OF de los medios
  de pago con ventas (`CORTE_VENTA`), las cajas destino de la distribución
  (`DISTRIBUCION`) y los de ajustes de cierre (`CIERRE`); para cada uno se compara
  contra el último id de movimiento que el corte generó ahí.

  > Mirar solo las cajas destino **no alcanza**: un egreso desde Bancolombia – QR deja
  > el reverso de esas ventas sin fondos y el saldo queda negativo. Esa era la versión
  > inicial y se corrigió.

  Mensaje exacto del BE (HTTP 409), que el FE muestra tal cual:
  > «Existen movimientos generados luego del corte, reintente Dividir o Editar el corte»

- **Orden de los reversos al eliminar:** ajustes de cierre → **distribución** (crédito
  que devuelve el traslado al medio de pago) → **ventas** (débito). Al revés, la fila
  intermedia queda con `saldoDespues` negativo aunque el saldo final cuadre.

- **Dividir:** botón nuevo junto a Eliminar, para administradores, sobre el registro más
  reciente. **No** exige que el rango abarque más de un día: dividir un corte de un solo
  día en dos turnos es un caso válido y probado (CV-E04).

### 4.2 Interfaz (diálogo `dividir-corte-dialog`)

No son pestañas estilo "Cierre de turno" como se planteó al inicio; es un diálogo
arrastrable con una fila por partición:

1. Cabecera **inmutable** con el rango del corte original, **con segundos**
   (`dd/MM/yyyy HH:mm:ss`). Los segundos importan: son los que deciden si una partición
   cabe en el rango, y ocultarlos deja al admin sin forma de apuntarle al límite.
2. Campo **motivo (obligatorio)**, exigido antes de Confirmar (divida o edite).
3. Una fila por partición con **Desde** y **Hasta**, cada uno como Fecha (datepicker
   acotado al rango original) + Hora con segundos. **Todas** las fechas son editables,
   incluidos el inicio de la primera y el fin de la última: de ellas depende en qué día
   calendario cae cada corte nuevo.
4. Botón **Agregar partición**: sugiere cortar al final del día (`23:59:59`) y arrancar
   la siguiente a las `00:00:00`, que es el caso típico. El admin puede ajustar.
5. Botón **Consultar** por partición: llama a `consultar-rango` con ese rango exacto y
   muestra las ventas por método de pago, igual que Cierre de turno.
6. **Prorrateo** a Caja Menor / Caja General por partición: se precarga proporcional a
   las ventas en efectivo, es editable, y la **última partición se calcula por resta**.
   Un destino sin distribución original se oculta. Un resumen en vivo muestra
   «repartido X de Y» y bloquea la confirmación si no cuadra.
7. **Confirmar división** → el BE aplica todo en **una transacción**.

### 4.3 Backend — algoritmo (N ≥ 2 particiones)

`dividirCorte(corteId, particiones[], motivo)` en una sola `@Transactional`:

1. **Validar** (ver 4.7), incluida la cobertura, **antes de tocar el ledger**.
2. Crear el registro `corte_venta_correccion` (`SPLIT`, motivo obligatorio).
3. **Reverso del corte original** (`revertirParaSplit`):
   - Se reversa **todo** lo que el corte posteó: las `ENTRADA_VENTA` de **cada** medio
     de pago (incluidos QR y Nequi, que no tienen traslado) y **ambas patas** de cada
     traslado de distribución.
   - Se calcula el **impacto neto del corte por OF**. Si es positivo, se acredita un
     `AJUSTE_PUENTE_SPLIT` por ese neto **antes** de los reversos. Caja:Efectivo suele
     quedar en neto 0 (entra la venta, sale el traslado) y no necesita puente; Caja
     Menor, QR y Nequi sí.
   - Los reversos se ordenan **crédito antes que débito** (por el signo del movimiento
     original), así el saldo nunca pasa por negativo.
4. Corte original → `estado = 'dividido'`.
5. **Re-corte**: un `CorteVenta` nuevo por partición, reutilizando `consultarRango`,
   `registrarEntradasVentaCorte` y `registrarTrasladoDistribucion` (los mismos métodos
   de un cierre normal), con el prorrateo indicado por el admin.
6. **Cierre del puente** (`cerrarPuenteSplit`): débito `AJUSTE_PUENTE_SPLIT` por el mismo
   monto, después de que el re-corte ya repuso el dinero.
7. **Ampliar el watermark** del último corte creado, porque el cierre del puente ocurre
   después de él (ver 4.9).

> **Qué NO hace (y por qué):** el diseño original incluía un paso de *recalcular
> `saldoAntes/saldoDespues` hacia adelante* y registrar los movimientos con *fecha
> explícita* del corte. Ambos quedaron obsoletos al decidir que los movimientos de
> corrección llevan **fecha del sistema**: se agregan al final del ledger, cada snapshot
> queda consistente con el acumulado en ese instante, y `calcularSaldo` es un
> `SUM(impacto)` sin orden ni filtro temporal, así que el saldo autoritativo nunca
> dependió de eso. No es deuda técnica.

Resumen de la secuencia por OF:

```
Caja: Efectivo   (neto 0 → sin puente)
  REVERSO_TRASLADO       +X     (crédito primero)
  REVERSO_ENTRADA_VENTA  −X
  re-corte: ENTRADA_VENTA / TRASLADO por partición

Caja Menor       (neto +X → con puente)
  AJUSTE_PUENTE_SPLIT    +X     (antes del reverso)
  REVERSO_TRASLADO       −X
  re-corte: + por partición
  AJUSTE_PUENTE_SPLIT    −X     (cierre, al final)

Bancolombia – QR (neto +X, sin traslado → con puente)
  AJUSTE_PUENTE_SPLIT    +X
  REVERSO_ENTRADA_VENTA  −X
  re-corte: ENTRADA_VENTA por partición
  AJUSTE_PUENTE_SPLIT    −X
```

Resultado: saldos finales **idénticos** a los previos al split (cambio económico neto
= 0), egresos intactos, ningún `saldoDespues` negativo.

### 4.4 Particiones: dentro del rango, sin solapes, **con huecos permitidos**

Cambio respecto al diseño inicial, que exigía contigüidad exacta:

- Cada partición debe caber dentro de `[fechaIni, fechaFin]` del corte original.
- Las particiones **no pueden solaparse**.
- Los **huecos sí se permiten**, y son necesarios: Ingresos agrupa por el día calendario
  de `fechaIni`, así que para que cada corte nuevo quede en su día hay que terminar una
  partición a las `23:59:59` y empezar la siguiente a las `00:00:00`. Con contigüidad
  exacta ambos cortes caían en el mismo día.
- Además, las consultas de ventas son **inclusivas en ambos extremos**: dos particiones
  que comparten el mismo instante de borde pueden contar dos veces un ticket ubicado
  justo ahí. El hueco de un segundo también evita eso.
- La cobertura se garantiza comparando **Σ ventas de las particiones == total del
  original**, no exigiendo contigüidad. Esa validación corre antes de tocar el ledger,
  así que si no cuadra se aborta sin haber reversado ni creado nada.

### 4.5 Prorrateo de la distribución

- El diálogo **precarga** el prorrateo proporcional a las ventas de efectivo de cada
  partición como **sugerencia**.
- El administrador puede **editar** el monto por partición y por destino.
- **Única regla dura:** `Σ montos por partición == monto original` por destino; la
  **última partición se calcula por resta** para cerrar a centavo exacto.
- El BE expone `GET /corte-venta/{id}/distribucion-original` para que el FE sepa cuánto
  distribuyó el corte a cada caja y pueda precargar y validar en vivo.

### 4.6 Modo editor (N = 1 partición)

- **No reestructura el ledger** (sin reversos ni puente).
- El ajuste de campos sigue delegado al flujo de revisión existente
  (`finalizarRevision`).
- Igual se crea un registro de corrección con `tipo = 'EDICION'` y **motivo
  obligatorio**, para que toda edición quede rastreada.

### 4.7 Validaciones

**BE (`dividirCorte`):**
- Solo administrador. Corte existente, que no esté ya `eliminado` ni `dividido`.
- Es el **último corte vigente**.
- Sin corrección previa sobre ese corte (idempotencia: un corte se corrige una vez).
- Motivo obligatorio, máximo 500 caracteres.
- Particiones: cada `hasta > desde`, todas dentro del rango original, sin solapes.
- **Cobertura:** `Σ ventas` de las particiones == `totalVentasSistema` del original,
  validado **antes** de tocar el ledger.
- `Σ prorrateo` por destino == monto original distribuido a ese destino.
- Guarda de no-negativo en cada inserción de corrección: si un movimiento fuera a dejar
  el saldo negativo, se aborta con error explícito.
- Todo en una sola `@Transactional`.

**BE (`delete`):** último corte vigente + `validarCorteEliminable` (4.1) antes de
revertir nada.

**FE:** motivo requerido; datepickers acotados al rango original; validación de rango,
solape y orden antes de llamar, con el **límite exacto** en el mensaje; resumen de
prorrateo que bloquea Confirmar si no cuadra.

### 4.8 Trazabilidad (DIAN: nada se borra sin rastro)

- Corte original → `estado = 'dividido'` (sigue existiendo y consultable; el FE tiene
  filtro **Divididos**).
- `corte_venta_correccion`: quién, cuándo, motivo, total y rango del original.
- `corte_venta_correccion_detalle`: qué cortes nuevos nacieron, en qué rango y orden.
- `corte_venta.origen_split_id`: vínculo directo corte nuevo → corrección.
- Observación uniforme en reversos y puente: «Reverso por corrección #X del corte #N».
- **No se borra ni una fila de movimientos.**
- Los cortes nuevos quedan `SOLO_VISIBLE`, **sin Contado ni desfase**: son
  reconstrucción del sistema, no un arqueo físico nuevo.

### 4.9 El estado `dividido` sale de circulación

Constante compartida `ESTADOS_NO_VIGENTES = ['eliminado', 'dividido']`, en BE y FE. Un
corte dividido:

- **No cuenta en Ingresos** (KPI, gráfica, tabla). Sus ventas ya las heredaron los
  cortes nuevos; contarlo otra vez las duplica. Pasó: un día mostró
  `3.000.000 (original) + 1.600.000 (partición) = 4.600.000`.
- **No puede ser "último corte vigente"** (afecta eliminar, dividir, distribución
  pendiente, base inicial y el watermark de tickets).
- No aporta a la suma de ventas de cortes vigentes.

Además, la resolución del último corte **desempata por id**: un SPLIT crea varios cortes
con la misma `fechaCreacion` y sin desempate la BD devuelve cualquiera, dejando
watermarks equivocados (síntoma: «Tickets sin corte» mostrando tickets ya cortados).

Y dos exclusiones para que los asientos de corrección no contaminen el siguiente cierre:

- `SPLIT_PUENTE` y `SPLIT_REVERSO` quedan fuera del filtro de la columna «Movimientos»
  del cierre, igual que `DISTRIBUCION`. Sin eso, el `REVERSO_TRASLADO` del medio de pago
  inflaba el Esperado, porque su contraparte (el nuevo `TRASLADO`) sí estaba excluida.
- El **watermark** del último corte se amplía tras cerrar el puente; si no, el siguiente
  cierre tomaba como Base el saldo con el puente todavía abierto.

### 4.10 Migración de BD (aditiva, sin tocar el ledger)

Migración `68_corte_venta_split.sql`:

- `ck_corte_venta_estado` ampliado con el valor `'dividido'`.
- Columna `corte_venta.origen_split_id`.
- Tablas `corte_venta_correccion` (con `motivo` **NOT NULL**) y
  `corte_venta_correccion_detalle` + índices.

**Qué NO toca:** ninguna query de saldo (`sumImpactoByCuentaId*` intactas), ninguna
columna de supersede. Es traza pura.

El enum `REVERSO_TRASLADO_DISTRIBUCION` se conserva `@Deprecated` como legacy, para no
romper la deserialización de filas ya existentes; los reversos nuevos usan
`REVERSO_TRASLADO`.

---

## 5. Alcance técnico (dónde se tocó)

**BE (`pos-relational-data-service`):**

- `68_corte_venta_split.sql` (migración).
- Entidades: `CorteVenta.origenSplitId`, `CorteVentaCorreccion`,
  `CorteVentaCorreccionDetalle` + repos.
- Enum `TipoMovimientoOrigenFondos`: `REVERSO_TRASLADO`, `AJUSTE_PUENTE_SPLIT`.
- `MovimientoOrigenFondosServiceImpl`: `validarCorteEliminable`, `revertirParaSplit`,
  `cerrarPuenteSplit`, `reversoDirecto` (con guarda de no-negativo).
- `CorteVentaServiceImpl`: `dividirCorte`, `delete` (orden + validación),
  `obtenerDistribucionOriginal`.
- `CorteVentaRepository`: `ESTADOS_NO_VIGENTES` + consultas `…NotIn…` con desempate por id.
- `MovimientoOrigenFondosRepository`: exclusión de `SPLIT_PUENTE` / `SPLIT_REVERSO`.
- `CorteVentaController`: `POST /corte-venta/{id}/dividir`,
  `GET /corte-venta/{id}/distribucion-original`.
- Test `CorteVentaServiceImplTest`.

**FE (`infinito-ai-front`):**

- `ingresos.component.*`: botones Eliminar / Dividir, mensaje del BE en el error,
  exclusión de `dividido`, filtro **Divididos** y badge.
- `dividir-corte-dialog/`: el asistente descrito en 4.2.
- `corte-venta.service.ts`: `dividir()`, `obtenerDistribucionOriginal()`.

---

## 6. Plan de pruebas (dev, BD `controlneg_rmx_db_v02`)

> **Estado: pendientes de corrida humana completa.** Las corridas hechas durante el
> desarrollo quedaron invalidadas por los fixes posteriores (doble conteo de QR, corte
> dividido sumando en Ingresos, watermark del puente). Requieren binario recompilado y
> BD reseteada. Seguimiento en
> `openspec/changes/2026-09-24-corte-venta-split/tasks.md`.

| Escenario | Qué valida |
|---|---|
| **CV-E01-permitido** | Día 1 ventas + corte; día 2 ventas + corte; Eliminar el del día 2 → **permitido**; saldos vuelven al estado del día 1 |
| **CV-E02-no-permitido** | Igual, con un **egreso** antes de Eliminar → **bloqueo** con el mensaje del BE |
| **CV-E02-no-permitido (variante medio de pago)** | El egreso sale de **Bancolombia – QR** o Caja: Efectivo, no de Caja Menor → también debe bloquear |
| **CV-E02-split-por-día** | 1 corte para dos días + egreso posterior. Eliminar bloqueado; **Dividir en 2** (`23:59:59` / `00:00:00`) → 2 cortes, original `dividido`, Σ ventas == original, egreso intacto, ningún `saldoDespues` negativo, reintento → error |
| **CV-E04-split-en-mismo-día** | Corte de un solo día dividido en **2 turnos** |
| **Split 3+ particiones** | Reparto exacto sin residuo de redondeo (última por resta) |

Verificar después de cada split: Ingresos **sin** el corte dividido, «Tickets sin corte»
en 0, y la Base del siguiente cierre igual al saldo real de cada OF.

---

## 7. Lecciones y reglas para el futuro

1. **Nunca** un reverso sin su contraparte (lección del saldo −350.000).
2. **Ningún** cambio con `saldoDespues` negativo; ordenar crédito antes que débito.
3. Los **totales** del corte son invariantes: el split no crea ni destruye dinero.
4. **Traza obligatoria**: motivo NOT NULL; nada se borra físicamente.
5. **No todos los medios se distribuyen.** Recorrer "los traslados" se salta QR y Nequi.
   Cualquier lógica sobre el corte debe partir de lo que el corte **posteó**, no de los
   traslados.
6. **Un estado nuevo hay que propagarlo.** `dividido` se agregó al flujo de corrección
   pero no a los filtros de "vigente", y el día quedó sumando el corte viejo con los
   nuevos. Al agregar un estado, revisar Ingresos, "último corte vigente" y watermarks.
7. **Cuidado con los empates de `fechaCreacion`.** Un SPLIT crea varios cortes en la
   misma transacción; ordenar solo por fecha devuelve cualquiera. Desempatar por id.
8. **Los movimientos creados después del último corte quedan fuera de todo watermark.**
   Si la operación postea algo al final (como el cierre del puente), hay que ampliarlo.
9. Mantener intactas las **queries de saldo** fue una decisión consciente (evento
   aislado). Si los splits por turno se vuelven frecuentes, reevaluar el soft-supersede
   como refactor.
10. El **modo editor (N=1)** es la operación del día a día; el flujo pesado
    (reverso + puente + re-corte) es la excepción.
