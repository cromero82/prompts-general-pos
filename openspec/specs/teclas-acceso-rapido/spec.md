## Purpose

En Tickets, el cajero elige el método de pago con el teclado sin salir del buscador de producto. Los atajos salen de `configuracion_app` y el `id` del botón sale del tooltip.

## Requirements

### Requirement: Id del botón de método de pago

Cada botón visible de método de pago en Tickets SHALL tener `id` igual a `descripcion` (el tooltip) sin espacios y en minúsculas. Un método `inactivo` MUST NOT renderizarse.

Ejemplos: `Efectivo` → `efectivo`; `Bancolombia - QR` → `bancolombia-qr`.

#### Scenario: Tooltip con espacios y mayúsculas
- **WHEN** el método visible tiene descripción `Bancolombia - QR`
- **THEN** el botón tiene `id` `bancolombia-qr`

### Requirement: Mapa en configuracion_app

La clave `teclas-acceso-rapido` SHALL existir en `configuracion_app`. `value` SHALL ser un JSON (texto, VARCHAR 1000) con esta forma: arreglo de `{ funcionalidad, map: [{ elemento, combinacion }] }`. La fila SHALL cargarse con `73_teclas_acceso_rapido.sql` (`INSERT … WHERE NOT EXISTS`). Ese script MUST NOT modificar la fila si la clave ya existe. `70_configuracion_app_leyendas.sql` MUST NOT usarse para esta clave.

Valor inicial:

```json
[{"funcionalidad":"Tickets","map":[{"elemento":"Metodo de pago > efectivo","combinacion":"[Shift] + 1"},{"elemento":"Metodo de pago > bancolombia-qr","combinacion":"[Shift] + 2"}]}]
```

El `id` buscado SHALL ser el tramo de `elemento` después del último `>`, sin espacios y en minúsculas. MUST NOT cambiar `descripcion` del método de pago para forzar la coincidencia.

#### Scenario: Semilla
- **WHEN** se aplica `73_teclas_acceso_rapido.sql` y la clave no existe
- **THEN** queda `teclas-acceso-rapido` con el JSON inicial y una leyenda corta

#### Scenario: Reejecución
- **WHEN** la clave ya existe y se vuelve a aplicar el script
- **THEN** `value` y `leyenda` no cambian

### Requirement: Atajo en Tickets con foco en el buscador

Mientras la vista Tickets está viva, el listener SHALL leer solo el bloque `funcionalidad` = `Tickets`. SHALL escuchar `keydown` en captura sobre `window`.

`[Shift] + 1` SHALL coincidir con `shiftKey` y `event.code` = `Digit1` (igual para el dígito `2` → `Digit2`). MUST NOT usar el carácter que produce la tecla (`!` u otro).

Si hay un botón habilitado con ese `id`, el atajo SHALL hacer `preventDefault`, `stopPropagation` y `click()` en el primero que no tenga la clase `metodo-pago-disabled` ni `aria-disabled="true"`. Ese click SHALL disparar la misma selección que un click manual. El carácter MUST NOT escribirse en `#productSearchInput`.

El atajo SHALL funcionar con el foco en `#productSearchInput`. SHALL ignorarse si el foco está en otro `input`, `textarea` o `contenteditable`, si hay un diálogo abierto, o si la tecla es repetición (`repeat`). Si no hay botón habilitado, el evento MUST NOT consumirse.

Al salir de Tickets el listener SHALL desregistrarse.

#### Scenario: Shift+1 con el caret en Buscar producto
- **WHEN** el foco está en `#productSearchInput`, no hay diálogo, y el botón `efectivo` está habilitado
- **THEN** se selecciona ese método y el buscador no recibe el carácter de la tecla

#### Scenario: Otro campo de texto
- **WHEN** el foco está en un input que no es `#productSearchInput`
- **THEN** `Shift+1` no selecciona método de pago

#### Scenario: Edición de recibo
- **WHEN** conviven el botón del footer (deshabilitado) y el de edición (habilitado) con el mismo `id`
- **THEN** el atajo hace click en el habilitado

### Requirement: Sin librería de atajos

La implementación SHALL ser TypeScript en el front. MUST NOT agregar una librería de hotkeys.
