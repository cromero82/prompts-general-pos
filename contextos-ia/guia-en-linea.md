# Contexto IA — Guía en línea (componente genérico)

Documento para retomar el trabajo de **ayuda contextual en overlay** del POS Infinito. Complementa `ayuda-documental/README.md` (catálogo humano) y este archivo (implementación FE).

**Última actualización:** 2026-08-20.

## Qué es

Componente **genérico** que, ante una acción incorrecta o confusa del cajero:

1. Oscurece el fondo.
2. **Resalta** uno o más elementos *origen* y un elemento *destino*.
3. Muestra un **popover** con mensaje + flecha hacia el destino.
4. Botón **Cerrar ayuda en línea**.

No sustituye tooltips ni `matTooltip`. Sirve para flujos donde el control “obvio” está deshabilitado y hay que dirigir al usuario a otro CTA.

## Repos y rutas

| Pieza | Ruta |
|-------|------|
| Servicio + overlay | `infinito-ai-front/src/app/core/components/guia-en-linea/` |
| Types | `guia-en-linea.types.ts` (`GuiaEnLineaConfig`, `GuiaEnLineaTarget`) |
| Servicio | `GuiaEnLineaService` (`abrir` / `cerrar` / `isOpen`) — `providedIn: 'root'` |
| Overlay UI | `guia-en-linea-overlay.component.*` (CDK Overlay, pane `guia-en-linea-overlay-pane`) |
| Estilos pane global | `infinito-ai-front/src/styles.scss` (clase `.guia-en-linea-overlay-pane`) |
| Ayuda humana (texto) | `prompts-general-pos/ayuda-documental/tickets-cxc/` |

## API de uso (desde cualquier pantalla)

```typescript
import { GuiaEnLineaService } from '…/core/components/guia-en-linea';

this.guiaEnLinea.abrir({
  titulo: 'Cobranza con crédito',
  mensaje: '…texto…',
  origenes: [{ el: '.metodos-pago-container', etiqueta: 'Métodos de pago' }],
  destino: { el: '.cxc-rail-cta--abonar', etiqueta: 'Registrar abono' },
  cerrarLabel: 'Cerrar ayuda en línea',
  onCerrar: () => { /* opcional */ }
});
```

- `el`: `HTMLElement` **o** selector CSS (`document.querySelector`).
- Si el destino aún no está en el DOM (panel colapsado), expandir/renderizar primero y luego `abrir` (p. ej. `setTimeout` corto + `detectChanges`).
- Recalcula posición en `resize` y `scroll` (capture).

## Primer caso cableado: Tickets + CxC

**Problema:** con CxC vigente, los medios de pago del footer están deshabilitados; el cobro va por **Registrar abono** en el rail.

**Flujo:**

1. Cajero hace clic en un medio de pago (aunque visualmente “disabled”).
2. `metodos-pago` emite `intentoMientrasDeshabilitado` (ya no usa `[disabled]` nativo; usa clase `metodo-pago-disabled` + `aria-disabled` para seguir recibiendo clicks).
3. `detalle-ticket` emite `guiaCreditoSolicitada` si `modoCredito`.
4. `tickets.mostrarGuiaAbonoCxc()`:
   - Expande el rail CxC si estaba cerrado.
   - Abre la guía: origen `.metodos-pago-container` → destino `.cxc-rail-cta--abonar`.

| Archivo | Rol |
|---------|-----|
| `…/metodos-pago/metodos-pago.component.*` | Click aunque “disabled”; output `intentoMientrasDeshabilitado` |
| `…/detalle-ticket/…` | Input `modoCredito`; output `guiaCreditoSolicitada` |
| `…/cxc-ticket-rail/…` | Botón abono con clase `cxc-rail-cta--abonar` |
| `…/tickets/tickets.component.*` | `mostrarGuiaAbonoCxc()` + `GuiaEnLineaService` |

Mensaje actual (puede alinearse al HTML de `ayuda-documental/tickets-cxc/`):

> Una vez generado un crédito al cliente o pagos parciales al cliente, para continuar registrando pago total o aportes debe utilizar «Registrar abono».

## Relación con `ayuda-documental/`

- **Hoy:** la guía CxC es **proactiva** (se dispara al intentar pagar mal), no el modo “cursor de ayuda” global del README de `ayuda-documental/`.
- **Después:** el mismo `GuiaEnLineaService` (o una capa encima) puede alimentar overlays desde `catalogo.json` + `data-ayuda-id`.
- Artículo humano de este caso: `ayuda-documental/tickets-cxc/` (`ayudaId`: `tickets.cxc.registrar-abono`).

## Pendiente / ideas al retomar

- [ ] Más casos (otros CTAs deshabilitados con destino alternativo).
- [ ] Modo ayuda global (botón toolbar + `data-ayuda-id`) leyendo `ayuda-documental/*/catalogo.json`.
- [ ] Unificar copy del popover con el HTML del catálogo (una sola fuente de verdad).
- [ ] Accesibilidad: foco atrapado en el popover, Escape para cerrar (parcial: clic en backdrop cierra).
- [ ] Evitar solapamiento con panel flotante «Pagos electrónicos» / FABs.

## No confundir con

- `matTooltip` en medios de pago (sigue existiendo como pista corta).
- Confirmación de pagos electrónicos (`confirmacion-pagos-panel`) — ver `confirmacion-pagos-electronicos.md` + OpenSpec.
- Menú Financiero → Cuentas por cobrar (atajo de nav; la cobranza del ticket activo es el rail + Registrar abono).
