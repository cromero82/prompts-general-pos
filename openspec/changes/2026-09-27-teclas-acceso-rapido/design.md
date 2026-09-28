## Context

El POS mantiene el foco en `#productSearchInput`. Un `keydown` que ignore todo `input` no llega a usarse. Los atajos `+/-` ya conviven con ese input; este mapa es distinto: sale de `configuracion_app` y dispara el botón de método de pago.

`configuracion_app.key` es VARCHAR(50) y `value` VARCHAR(1000). No hay Flyway: el SQL `NN_` se aplica a mano. `70_` solo actualiza leyendas.

## Decisions

1. **TypeScript puro**, sin librería. El mapa es datos (JSON), no decoradores. El front ya escucha `keydown` en Tickets.

2. **`id` = tooltip normalizado** (sin espacios, minúsculas). El `elemento` del JSON es una ruta; el id buscado es el tramo tras el último `>`.

3. **`[Shift] + 1` se lee con `shiftKey` + `code` `Digit1`**, no con el carácter (`!`). Así vale en teclado ES y US.

4. **Excepción de foco solo para `#productSearchInput`.** Otro input, textarea, contenteditable o un diálogo abierto no dispara el atajo. `preventDefault` evita escribir el carácter en el buscador.

5. **Click en el primer botón habilitado** con ese `id`. En edición de recibo hay dos `<metodos-pago>`; el del footer lleva `metodo-pago-disabled`.

6. **Captura en `window`.** Si la combinación no está en el mapa, o no hay botón habilitado, el evento no se toca (la lectora sigue igual).

7. **Migración `73_`**, `INSERT … WHERE NOT EXISTS`. No se reescribe `70_`.

## Riesgos

- Si la `descripcion` en vivo no normaliza a `efectivo` o `bancolombia-qr`, el atajo no encuentra botón. No se altera el catálogo.
- La clave no existe en BD hasta aplicar `73_`. Sin fila, el listener no tiene mapa.
