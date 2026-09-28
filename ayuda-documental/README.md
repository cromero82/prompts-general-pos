# Ayuda documental (futura «Ayuda en línea»)

Contenido de ayuda para la UI del POS. Parte es documentación estática; parte ya tiene
implementación FE genérica.

## Implementación FE (2026-08)

Componente genérico **`GuiaEnLineaService`** en:

`infinito-ai-front/src/app/core/components/guia-en-linea/`

- Overlay con resaltado origen/destino + popover + «Cerrar ayuda en línea».
- Primer uso proactivo: **Tickets + CxC** (clic en medio de pago deshabilitado → apunta a Registrar abono).
- Contexto IA: [`../contextos-ia/guia-en-linea.md`](../contextos-ia/guia-en-linea.md).

Esto **no** es aún el modo global «cursor de ayuda» del contrato de abajo; es la base reutilizable para llegar ahí.

## Contrato para la interfaz (modo global — pendiente)

1. Botón global **Ayuda en línea** (p. ej. toolbar).
2. Al activarlo: cursor tipo ayuda (`help` / icono `?`).
3. Clic en un elemento con `data-ayuda-id="of.btn.trasladar"`.
4. Overlay o panel: título, HTML de `htmlFile`/`html`, lista `relacionados` (puede reutilizar `GuiaEnLineaService`).
5. Esc o segundo clic en el botón: sale del modo ayuda.

### Catálogo

Cada módulo tiene `catalogo.json`:

| Campo | Uso |
|-------|-----|
| `ayudaId` | Clave estable. En el FE: `data-ayuda-id` |
| `titulo` | Encabezado del panel |
| `rutaApp` | Ruta Angular donde aplica |
| `htmlFile` | Fragmento HTML relativo a esta carpeta |
| `selectores` | Pistas CSS/texto por si aún no hay `data-ayuda-id` |
| `relacionados` | Otros `ayudaId` |

Al cablear la UI: copiar `ayudaId` a los botones/secciones del componente. No cambiar ids existentes (rompe bookmarks).

## Módulos

| Carpeta | Pantalla |
|---------|----------|
| [`origenes-fondos/`](origenes-fondos/) | Financiero → Orígenes de fondos |
| [`tickets-cxc/`](tickets-cxc/) | Tickets → crédito / Registrar abono |

Contexto técnico para IAs:

- OF: [`../contextos-ia/origenes-fondos.md`](../contextos-ia/origenes-fondos.md)
- Guía en línea: [`../contextos-ia/guia-en-linea.md`](../contextos-ia/guia-en-linea.md)
