# Contexto IA — Corrección de cortes: Eliminar bloqueado y Dividir (SPLIT)

**Última actualización:** 2026-09-24.
**OpenSpec:** `openspec/specs/corte-venta-split/spec.md`
**Change abierto (pruebas humanas):** `openspec/changes/2026-09-24-corte-venta-split/`
**QA:** `CONTEXTO-TESTER-POS.md` §4.9 / §10.1
**Detalle técnico + incidente:** `ayuda-documental/corte-venta-split/`
**Glosario:** `GLOSARIO-NUCLEO-FINANCIERO.md`

## Qué es

Dos formas de corregir un corte de ventas mal generado, desde Ingresos → «Detalles por Fecha»:

- **Eliminar** — solo si el dinero del corte todavía no se movió.
- **Dividir (SPLIT)** — parte un corte en N cortes correctos. Funciona **aunque ya haya
  egresos**, porque no cambia el total: solo lo reparte mejor en el tiempo.

Regla de oro del ledger: ningún `saldoDespues` negativo, ningún reverso sin su
contraparte, totales invariantes, motivo obligatorio (DIAN).

## Eliminar: cuándo bloquea

Se bloquea si **cualquier** OF que tocó el corte tuvo movimientos posteriores: los
medios de pago con ventas (Caja: Efectivo, Bancolombia – QR, Nequi) **y** las cajas
destino de la distribución (Caja Menor / Caja General).

> «Existen movimientos generados luego del corte, reintente Dividir o Editar el corte»

Mirar solo las cajas destino no alcanza: QR y Nequi reciben `ENTRADA_VENTA` sin
traslado, así que un egreso desde ahí deja el reverso de ventas sin fondos.

Orden de los reversos: ajustes de cierre → distribución (crédito) → ventas (débito).
Al revés deja una fila intermedia con saldo negativo aunque el final cuadre.

## Dividir: cómo funciona

Todo en una `@Transactional`:

1. Validar (rango, solapes, cobertura por totales, prorrateo) **antes** de tocar el ledger.
2. Crear `corte_venta_correccion` (`SPLIT`, motivo obligatorio).
3. Reversar **todo** lo que el corte posteó, con asiento puente `AJUSTE_PUENTE_SPLIT` en
   cada OF cuyo impacto neto sea positivo.
4. Corte original → `estado = 'dividido'` (no se borra).
5. Un corte nuevo por partición, reutilizando la lógica del cierre de turno.
6. Cerrar el puente y ampliar el watermark del último corte.

**Modo editor (1 partición):** no toca el ledger, solo deja traza `tipo = 'EDICION'`.

### El asiento puente, en corto

Si el dinero ya se gastó, revertir la entrada dejaría saldo negativo. El puente lo
pre-financia antes del reverso y se cierra después de que el re-corte repuso el monto.
Cambio económico neto = 0. No cuenta como ingreso ni como «Movimientos» del cierre.

## Particiones: huecos sí, solapes no

Cada partición debe caber dentro del rango del corte original y no solaparse, pero **sí
se permiten huecos**. Es intencional: Ingresos agrupa por el día calendario de
`fechaIni`, así que para que cada corte quede en su día hay que terminar una partición
a las `23:59:59` y empezar la siguiente a las `00:00:00`.

Las consultas de ventas son inclusivas en ambos extremos: un borde compartido puede
contar dos veces un ticket que caiga justo ahí. El hueco de un segundo también lo evita.

La cobertura se garantiza comparando Σ ventas de las particiones contra el total del
original, no exigiendo contigüidad.

## Estado `dividido`

Se trata igual que `eliminado` (`ESTADOS_NO_VIGENTES`): no cuenta en Ingresos, no puede
ser «último corte vigente» y no aporta a la suma de ventas vigentes. Sus ventas ya las
heredaron los cortes nuevos; contarlo otra vez las duplica.

La resolución del último corte **desempata por id**: un SPLIT crea varios cortes con la
misma `fechaCreacion` y sin desempate la BD devuelve cualquiera, dejando watermarks
equivocados (tickets ya cortados apareciendo como «sin corte»).

En el FE hay filtro de estado **Divididos** para consultarlos.

## FE / BE

- Ingresos: `ingresos.component.*` — botones Eliminar / Dividir en la fila más reciente.
- Asistente: `dividir-corte-dialog/` — arrastrable, motivo obligatorio, Fecha + Hora
  **con segundos**, datepickers acotados al rango, **Consultar** por partición
  (reusa `consultar-rango`), prorrateo precargado proporcional a ventas en efectivo y
  editable, última partición por resta, resumen «repartido X de Y».
- BE: `CorteVentaServiceImpl.dividirCorte` / `delete`,
  `MovimientoOrigenFondosServiceImpl.validarCorteEliminable` / `revertirParaSplit` /
  `cerrarPuenteSplit`.
- Endpoints: `POST /corte-venta/{id}/dividir`, `GET /corte-venta/{id}/distribucion-original`.
- SQL: `68_corte_venta_split.sql` (aditiva; no toca queries de saldo).
- Enum: `REVERSO_TRASLADO`, `AJUSTE_PUENTE_SPLIT`; `REVERSO_TRASLADO_DISTRIBUCION` queda
  legacy. `origenTipo`: `SPLIT_REVERSO`, `SPLIT_PUENTE`.

## No es

- **Soft-supersede**: se descartó marcar filas «reemplazadas» y filtrarlas en las queries
  de saldo. No se cambia el sistema de consulta por un evento aislado.
- Tocar egresos: quedan intactos. Un egreso posterior al `fechaFin` del original queda
  fuera de todas las particiones por construcción.
- Arqueo por partición: los cortes nuevos son `SOLO_VISIBLE`, sin Contado ni desfase. No
  existe «diferencia» en ninguna partición.
- Recalcular hacia atrás los `saldoAntes/saldoDespues` ya persistidos.

## Estado

Implementado y compilando; **pendiente de pruebas humanas** (CV-E01,
CV-E02-no-permitido, CV-E02-split-por-día, CV-E04-split-en-mismo-día, split 3+).
Ver `tasks.md` del change. Requiere binario recompilado y BD reseteada.
