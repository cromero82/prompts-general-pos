## Context

Traslados ya son 2 filas con `grupo_traslado_id`. El repo tenía `findByGrupoTrasladoIdOrderByIdAsc` sin endpoint. La UI solo mostraba `→ destino` en la salida.

## Goals / Non-Goals

**Goals**
- Navegar al OF hermano del par.
- Resaltar tarjeta OF + fila movimiento.
- Cadena multi-hop = sucesivos pares (no grafo persistido).

**Non-Goals**
- Breadcrumb automático de 3+ hops.
- Cambiar modal «Ver» egreso/corte.

## Decisions

| Decisión | Motivo |
|----------|--------|
| Adelante solo en impacto &lt; 0 | Seguir el dinero (salida → entrada) |
| Atrás solo en impacto &gt; 0 | Volver al origen (entrada → salida) |
| GET por grupo | Evita N+1 al listar; fetch al clic |
| Expandir padre al ir a hijo | «Sin clasificar» puede estar colapsado |

## Risks / Trade-offs

- Doble request (grupo + lista OF destino): aceptable en volumen de tienda.
