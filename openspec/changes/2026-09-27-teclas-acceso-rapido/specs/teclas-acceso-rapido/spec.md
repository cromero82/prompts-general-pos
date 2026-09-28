## ADDED Requirements

### Requirement: Id del botón de método de pago

Cada botón visible de método de pago en Tickets SHALL tener `id` igual a `descripcion` (el tooltip) sin espacios y en minúsculas. Un método `inactivo` MUST NOT renderizarse.

#### Scenario: Tooltip con espacios y mayúsculas
- **WHEN** el método visible tiene descripción `Bancolombia - QR`
- **THEN** el botón tiene `id` `bancolombia-qr`

### Requirement: Mapa en configuracion_app

La clave `teclas-acceso-rapido` SHALL existir en `configuracion_app`. `value` SHALL ser JSON texto con arreglo de `{ funcionalidad, map: [{ elemento, combinacion }] }`. La fila SHALL cargarse con `73_teclas_acceso_rapido.sql` (`INSERT … WHERE NOT EXISTS`) y MUST NOT modificarse si la clave ya existe. `70_configuracion_app_leyendas.sql` MUST NOT usarse para esta clave.

El `id` buscado SHALL ser el tramo de `elemento` después del último `>`, sin espacios y en minúsculas. MUST NOT cambiar `descripcion` del método para forzar la coincidencia.

Valor inicial: `Shift+1` → `Metodo de pago > efectivo`; `Shift+2` → `Metodo de pago > bancolombia-qr`, funcionalidad `Tickets`.

#### Scenario: Semilla
- **WHEN** se aplica `73_teclas_acceso_rapido.sql` y la clave no existe
- **THEN** queda `teclas-acceso-rapido` con ese mapa y una leyenda corta

### Requirement: Atajo en Tickets con foco en el buscador

Con la vista Tickets viva, `[Shift] + 1` SHALL coincidir con `shiftKey` y `event.code` = `Digit1` (el `2` con `Digit2`). MUST NOT usar el carácter producido por la tecla.

Si hay botón habilitado con ese `id`, el atajo SHALL hacer `preventDefault`, `stopPropagation` y `click()` en el primero sin `metodo-pago-disabled` ni `aria-disabled="true"`. El carácter MUST NOT escribirse en `#productSearchInput`.

El atajo SHALL funcionar con el foco en `#productSearchInput`. SHALL ignorarse en otro `input`, `textarea` o `contenteditable`, con un diálogo abierto, o si la tecla es `repeat`. Si no hay botón habilitado, el evento MUST NOT consumirse. Al salir de Tickets el listener SHALL desregistrarse.

#### Scenario: Shift+1 con el caret en Buscar producto
- **WHEN** el foco está en `#productSearchInput`, no hay diálogo, y el botón `efectivo` está habilitado
- **THEN** se selecciona ese método y el buscador no recibe el carácter de la tecla

#### Scenario: Edición de recibo
- **WHEN** conviven el botón del footer deshabilitado y el de edición habilitado con el mismo `id`
- **THEN** el atajo hace click en el habilitado

### Requirement: Sin librería de atajos

La implementación SHALL ser TypeScript en el front. MUST NOT agregar una librería de hotkeys.
