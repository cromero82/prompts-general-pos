## Context

Listas financieras del POS ya usan cebra sutil `rgba(0,0,0,0.005)`. OF tenía un intento parcial; MDC ocultaba el efecto si solo se pintaba el `tr`.

## Goals / Non-Goals

**Goals**
- Cebra visible y alineada al estándar.
- No romper selección, hover ni flash de navegación Atrás/Adelante.

**Non-Goals**
- Cambiar densidad global de otras pantallas.
- Variables CSS nuevas (reutilizar `--pos-mat-table-row-hover`).

## Decisions

| Decisión | Motivo |
|----------|--------|
| Pintar `tr` + `td` | MDC a menudo ignora fondo del `tr` |
| Mismo alpha 0.005 | Consistencia con cliente-list / productos |
| Odd explícito transparent | Evita residuos de estilos Material |

## Risks / Trade-offs

Ninguno relevante; solo CSS.
