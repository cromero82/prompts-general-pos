# Contexto IA — Lectora de código de barras (aparcado)

**Última actualización:** 2026-09-13.  
**Estado:** aparcado. Retomar cuando se vuelva a la caja / lectora física.  
**OpenSpec:** `openspec/specs/lectora-codigo-barras/spec.md`  
**QA:** `CONTEXTO-TESTER-POS.md` §4.2 / §10.11  
**Foco POS:** `.cursor/rules/tickets-pos-focus-coordinator.md`

## Qué pasó (2026-09-12 / 13, laptop Mac)

En la versión local, **algunos** códigos: la lectora pita (leyó el hardware) y la app no escribe. La única forma de recuperarla era **desconectar y volver a conectar** el USB. En la versión anterior no pasaba.

No es un conflicto de marca con macOS. La lectora es un teclado HID. La versión local intercepta `document:keydown` cuando el foco no está en `#productSearchInput` (`TicketsPosFocusService.handlePossibleBarcodeKeydown`). El idle era **80 ms**: si las teclas llegan más despacio (típico USB en Mac), el buffer se vaciaba **antes del Enter**. El pitido queda; la app no busca. Al reconectar, el burst vuelve a ser rápido y “funciona”.

## Arreglo ya en código (sin cerrar el tema)

- Idle **400 ms**.
- Confirmar EAN/SKU completo al timeout aunque no llegue Enter/Tab.
- `key` Unidentified/Dead/Process → carácter desde `code`.
- No restaurar/select el buscador a mitad de ráfaga.
- No tirar el buffer por un modificador fantasma a mitad de escaneo.

Archivos:

- `infinito-ai-front/src/app/pages/apps/ventas/tickets/tickets-pos-focus.service.ts`
- `infinito-ai-front/src/app/pages/apps/ventas/util/barcode-scan.util.ts`
- Host: `tickets.component.ts` (`document:keydown` → `preventDefault` si el servicio consumió)

Pendiente de validar con la lectora real: códigos que fallaban, QR vs EAN, letras, y si algún USB se cuelga de verdad (entonces reconectar sí es hardware).

## Cómo retomar

1. Leer este archivo + el spec.
2. No añadir otro `setTimeout` de foco: usar `hold` / `release` / `requestDefaultFocus`.
3. Si “pita y no escribe”: ¿aparecen dígitos en el buscador? Si no, es captura/HID. Si sí y no hay producto, es búsqueda / QR (`resolveProductSearchTerm`).
4. Probar **sin** desconectar el USB. Si solo funciona tras reconectar, medir si llegan `keydown` (buffer vs driver).
5. Cerrar el tema: actualizar spec + este narrativo + § tester cuando la lectora de caja quede estable.

## No es

- Cámara / diálogo `barcode-scanner-dialog` (otro flujo, productos).
- Atajos `+` / `-` de cantidad (no deben dispararse a mitad de un escaneo con texto).
- Marca de lectora vs macOS como primera hipótesis.
