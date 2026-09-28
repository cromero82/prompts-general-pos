## Purpose

La lectora USB (teclado HID) debe agregar el producto al ticket en un solo escaneo. **Estado 2026-09-13: aparcado** — hay un arreglo local en Mac; falta validar en caja con la lectora física y retomar UX/atajos.

## Requirements

### Requirement: Un escaneo agrega el producto

En Tickets, un código de barras válido (EAN/UPC o SKU) SHALL escribirse en `#productSearchInput` y SHALL disparar la misma búsqueda que Enter. El pitido de la lectora MUST coincidir con una búsqueda (producto al ticket, selector, o mensaje de no encontrado / QR rechazado). MUST NOT exigir desconectar y reconectar el USB.

#### Scenario: Escaneo con foco en el buscador
- **WHEN** el caret está en `#productSearchInput` y el cajero escanea un EAN existente
- **THEN** el código aparece y se busca; no se pierde a mitad por un `select()` del restore de foco

#### Scenario: Escaneo sin foco en el buscador
- **WHEN** el foco está en un tab o botón del panel (sin modal ni input de edición)
- **THEN** el buffer de documento acumula la ráfaga y confirma con Enter, Tab, o idle si el código está completo

### Requirement: Ventana HID compatible con macOS

El buffer MUST esperar al menos **400 ms** de idle entre teclas (no 80 ms). En macOS el HID USB a menudo llega más lento; vaciar antes del Enter hace que la lectora pite y la app no escriba. Reconectar el USB “arregla” un burst lento: eso MUST tratarse como bug de captura, no como fallo de marca.

Si `key` llega `Unidentified` / `Dead` / `Process`, el carácter SHALL tomarse de `code` (Digit/Numpad/Key). Un modificador fantasma (Alt/Ctrl/Meta) a mitad de ráfaga MUST NOT tirar el buffer.

Al timeout, un EAN/UPC de 8–14 dígitos (o SKU alfanumérico ≥ 8 con al menos un dígito) SHALL confirmarse aunque no llegue Enter.

#### Scenario: Ráfaga lenta en Mac
- **WHEN** las teclas del HID llegan con más de 80 ms de separación y el foco no está en el buscador
- **THEN** el código no se descarta; se confirma al Enter/Tab o al idle si está completo

### Requirement: No capturar en overlays ni edición

Mientras hay hold (modal, menú, edición inline) o el target es otro `input`/`textarea`, el buffer MUST NOT consumir teclas. QR/URL siguen el rechazo ya documentado (`resolveProductSearchTerm`).

### Requirement: Documentacion triple y retomar

Esta capacidad está **aparcada**. Al retomarla, el equipo SHALL actualizar este spec, `contextos-ia/lectora-codigo-barras.md` y `CONTEXTO-TESTER-POS.md` §4.2 / §10.11, y SHALL probar con la lectora física (varios códigos, sin desconectar USB) en Mac y en la PC de tienda.

#### Scenario: Retomar
- **WHEN** se abre un chat nuevo sobre “la lectora no lee”
- **THEN** se lee este spec + el narrativo antes de tocar atajos `+/-` o más `setTimeout` de foco
