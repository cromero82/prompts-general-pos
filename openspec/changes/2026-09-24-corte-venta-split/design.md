## Context

Un corte genera, en cada OF de método de pago, `ENTRADA_VENTA` (+ventas) y, si hay
distribución de efectivo, `TRASLADO` (−) con contraparte (+) en Caja Menor / Caja
General. `calcularSaldo(of)` es un `SUM(impacto)` sin orden ni filtro temporal, así que
el saldo autoritativo no depende del orden de inserción; `saldoAntes/saldoDespues` son
snapshots por fila calculados al insertar.

Eso fija la regla de oro: **ningún movimiento puede dejar `saldoDespues` negativo**, y
ningún reverso puede ir sin su contraparte.

## Decisions

1. **Reverso + puente + re-corte**, no soft-supersede. El soft-supersede obligaba a
   filtrar filas en todas las queries de saldo por un evento aislado. El split
   reorganiza con movimientos reales y deja las queries intactas.

2. **Orden crédito-antes-que-débito**, tanto en Eliminar como en Dividir. El reverso de
   una salida suma; el de una entrada resta. Ordenando por el signo del original el
   saldo nunca pasa por negativo. Esto obligó a invertir el orden en `delete()`
   (distribución antes que ventas).

3. **Puente por OF con neto positivo**, no solo cajas destino. El impacto neto del corte
   en Caja: Efectivo suele ser 0 (entra la venta, sale el traslado) y no necesita
   puente; QR y Nequi quedan en neto positivo y sí lo necesitan, porque un egreso
   posterior pudo consumir ese dinero. El puente se cierra después del re-corte.

4. **Huecos permitidos entre particiones.** Ingresos agrupa por el día calendario de
   `fechaIni`; con contigüidad exacta los dos cortes nuevos caían en el mismo día. Se
   permite terminar en `23:59:59` y empezar en `00:00:00`. Además, las consultas de
   ventas son inclusivas en ambos extremos, así que un borde compartido puede duplicar
   un ticket: el hueco de un segundo también evita eso.

5. **Cobertura por igualdad de totales, validada antes de tocar el ledger.** Sustituye a
   la contigüidad como garantía de que no se pierde ni se duplica ninguna venta, y
   permite abortar sin haber reversado ni creado nada.

6. **`ESTADOS_NO_VIGENTES = ['eliminado', 'dividido']`** como constante compartida, con
   desempate por **id** en la resolución del último corte: un SPLIT crea varios cortes
   con la misma `fechaCreacion` y sin desempate la BD devuelve cualquiera.

7. **Reutilizar el cierre de turno** (`consultarRango`, `registrarEntradasVentaCorte`,
   `registrarTrasladoDistribucion`) para el re-corte, en vez de un cálculo nuevo.

8. **Fecha de sistema** en los movimientos de corrección (no fecha del corte original):
   son hechos de hoy. No se recalculan los snapshots de saldo ya persistidos.

## Riesgos y trampas encontradas

| Trampa | Síntoma | Mitigación |
|---|---|---|
| Reversar solo los medios con traslado | QR contado dos veces en el ledger | Reversar todas las `ENTRADA_VENTA` del corte |
| Bloquear Eliminar mirando solo cajas destino | Egreso desde QR → reverso deja saldo negativo | Validar todas las OF tocadas |
| `dividido` sin excluir | El día suma original + cortes nuevos (4.600.000) | `ESTADOS_NO_VIGENTES` en Ingresos, watermarks y «último vigente» |
| Empate de `fechaCreacion` | Watermark del corte equivocado; tickets ya cortados salen «sin corte» | Desempate por id |
| Cierre del puente fuera de todo watermark | Base inflada en el siguiente cierre | Ampliar el watermark del último corte tras cerrar |
| Reversos del split contados como «Movimientos» | Esperado inflado en el siguiente cierre | Excluir `SPLIT_PUENTE` y `SPLIT_REVERSO` del filtro |
| Cabecera del diálogo sin segundos | El admin no ve el límite real y se sale del rango | Mostrar `HH:mm:ss` y acotar datepickers |

## Secuencia por OF (ejemplo)

```
Caja: Efectivo  (neto 0 → sin puente)
  REVERSO_TRASLADO       +X    (crédito primero)
  REVERSO_ENTRADA_VENTA  −X
  re-corte: ENTRADA_VENTA / TRASLADO por partición

Caja Menor      (neto +X → con puente)
  AJUSTE_PUENTE_SPLIT    +X    (antes del reverso)
  REVERSO_TRASLADO       −X
  re-corte: + por partición
  AJUSTE_PUENTE_SPLIT    −X    (cierre, al final)

Bancolombia – QR (neto +X, sin traslado → con puente)
  AJUSTE_PUENTE_SPLIT    +X
  REVERSO_ENTRADA_VENTA  −X
  re-corte: ENTRADA_VENTA por partición
  AJUSTE_PUENTE_SPLIT    −X
```

Cambio económico neto = 0; egresos intactos.

## Modelo de datos

- `corte_venta.estado` admite `'dividido'`; `corte_venta.origen_split_id` → corrección.
- `corte_venta_correccion`: `tipo` (`SPLIT` | `EDICION`), `motivo` NOT NULL, usuario,
  fecha, total y rango del original.
- `corte_venta_correccion_detalle`: corte nuevo, rango y orden.
- Enum: `REVERSO_TRASLADO` y `AJUSTE_PUENTE_SPLIT` nuevos;
  `REVERSO_TRASLADO_DISTRIBUCION` queda `@Deprecated` como legacy.
- `origenTipo`: `SPLIT_REVERSO`, `SPLIT_PUENTE`.
