# Contexto IA — Orígenes de fondos (OF) y cambios 2026-08

Documento para **cualquier IA** que retome el POS Infinito. Complementa `GLOSARIO-NUCLEO-FINANCIERO.md` y `interceptar-pagos-tunel.md`. No sustituye el código.

**Última actualización:** 2026-10-01 (modo flexible solo en medios no físicos).  
**Docs triple:** `DUAL-DOCS-CURSOR-OPENSPEC.md` · tester §4.10 / §4.11 / §4.15.  
**Migrate v02:** `MIGRATE-TIENDA-INFINITO-V02.md` lección #11 + `63_align_caja_menor_general.sql`.

## Qué es un OF

- **Origen de fondos** = dónde está la plata (caja, banco, bolsillo hijo).
- **Clasificación operativa** = *qué es* el movimiento para el negocio (personal, vale, gasto…), distinta del OF.
- Tabla ledger: `movimiento_origen_fondos`. Árbol: `origen_fondos` (`parent_origen_fondos_id`, `naturaleza` `FISICA|ELECTRONICA|MIXTA`, `metodo_pago_id`).

## Repos y rutas

| Pieza | Ruta | Pantalla / API |
|-------|------|----------------|
| FE lista OF | `infinito-ai-front/.../financiero/origenes-fondos/origenes-list/` | `/apps/financiero/origenes-fondos` |
| FE diálogo movimiento | `.../origen-movimiento-dialog/` | Trasladar / entrada / préstamo |
| FE reglas traslado | `.../util/traslado-of.util.ts` | `puedeTrasladarEntreOf` |
| FE árbol | `.../util/origen-fondos-arbol.util.ts` | Incluye `naturaleza` |
| BE relational | `pos-relational-data-service` `:8088` | `/origenes-fondos/arbol`, `/movimientos-origen-fondos` |
| Túnel email | `puente-tienda` `:8095` | `/api/email-inbound`, plantillas, legalizar |
| Worker CF | `puente-tienda/workers/email-inbound/` | Email Routing → POST inbound |
| Ayuda humana (futuro UI) | `prompts-general-pos/ayuda-documental/origenes-fondos/` | Ver README de esa carpeta |

BD local `controlneg_rmx_db`.

## Árbol de ejemplo (piloto)

Naturaleza manda (Caja Efectivo tiene `metodo_pago_id` pero es **FISICA**).

```text
Caja: Efectivo          FISICA padre
Bancolombia - QR        ELECTRONICA padre
  ├── Arriendo local    ELECTRONICA hijo
  └── Sin Clasificar    ELECTRONICA hijo   ← destino típico de plantillas de egreso/retiro
Nequi                   ELECTRONICA padre
Caja Menor              FISICA padre   ← id=4 (laptop). NO «Efectivo: base para proveedores»
  └── Ahorro Servicios  FISICA hijo    (piloto laptop; puede no existir en v02)
Caja General            FISICA padre   ← id=5 (laptop). NO «Reserva pago proveedores»
Dueños                  ELECTRONICA padre (no operativo del turno)
  └── Cuenta del dueño  ELECTRONICA hijo   ← personal, no gasto P&L
```

### Migrate prod → v02 (labels)

`14_cuenta_bolsillo` crea un OF por cada `metodo_pago`. En prod, `metodo_pago` id=4 sigue llamándose **Efectivo: base para proveedores** (inactivo) y el seed añade **Reserva pago proveedores**. En la laptop esos OF ya son **Caja Menor** (id 4) y **Caja General** (id 5), `FISICA`, sin `metodo_pago_id`. `26_` no los renombra: solo desvincula si el nombre ya es Caja Menor/General. Por eso el ensayo v02 mostraba los labels viejos. Corrección: `63_align_caja_menor_general.sql` (wrapper, tras `26_`). `metodo_pago` id=4 puede seguir con el nombre legacy e inactivo; no es una tarjeta OF.

Prod no tenía Distribución ni ledger. El primer cierre v02 heredaba el Contado de efectivo del último corte (ej. 1.563.000) como Base. `64_migrate_distribucion_contado_legacy.sql` siembra ese Contado en Caja: Efectivo, deja `corte-venta.base-efectivo` (150.000) y pasa el resto a Caja Menor. El cierre no suma `MIGRACION_CONTADO_LEGACY` ni `DISTRIBUCION` en Movimientos.

QR/Nequi tenían el mismo hueco: el cierre usaba el Contado prod (ej. QR 566.400 → Base 1.217.300) que no está en OF. `consultar-rango` ahora toma esa Base del saldo OF al watermark del último corte (QR 650.900, Nequi 100.000 en el ensayo).

## Cadena email banco → ledger

```text
Bancolombia → Gmail (filtro por frase) → pagos@mayaksoluciones.com
  → Worker CF → POST https://cotiza.mayaksoluciones.com/api/email-inbound
  → cloudflared → puente-tienda :8095
  → parse plantilla (fragmento, no el correo entero)
  → notificacion_email_pago
  → si plantilla de movimiento: TRASLADO ledger origen_tipo = MOVIMIENTO BANCO POR IDENTIFICAR
     id_referencia = notificacion.id
```

### Plantillas (`plantilla_notificacion_pago`)

- Placeholders: `{{nombrePagador}}`, `{{monto}}`, `{{referenciaCuenta}}`, `{{lugarRetiro}}` (se guarda como pagador/tercero).
- Match = **contiene** el fragmento en el cuerpo plano (sin HTML). Se ignoran mayúsculas, tildes y espacios repetidos (`EmailPagoParser.foldForMatch`).
- Orden: `activo` + `orden`. QR/BREVE/OTRO suelen ir primero (confirmación de tickets). EGRESO LULO, PAGOS QR, RETIRASTE, COMPRASTE, TRANSFERENCIA EGRESO, etc. tienen `naturaleza` INGRESO/EGRESO y OF origen/destino.
- Ejemplo RETIRASTE: cuerpo plantilla `Retiraste {{monto}} en {{lugarRetiro}} de tu` matchea  
  `Bancolombia: Retiraste $1.000.000,00 en MF_PUERNOR3 de tu T.Deb **6512 …`
- Gmail: un filtro **no** hace OR. El de `recibiste una transferencia de` **no** reenvía `Retiraste`. Hace falta filtro extra (mismo asunto *Alertas y Notificaciones*).

### Parser / logs (puente-tienda)

- Prefiere HTML si el text/plain no parece pago (`elegirCuerpoInbound`).
- Logs: `email-inbound cuerpo extraído id=N: …` (texto plano, no HTML).
- Hibernate nativo: no usar `id::text` (lo toma como parámetro). Nulls en INSERT: `StandardBasicTypes` o peta `bytea` vs integer.

### Tras plantilla de movimiento

- **No** cruzar con tickets QR (`intentarMatchAutomatico`) si la plantilla es de ledger.
- Traslado: OF origen → destino (ej. Bancolombia QR → Sin Clasificar). Usuario sistema: *Invitado del Sistema*.
- Idempotencia: `origen_tipo` + `id_referencia` = id notificación.
- Al **guardar** plantilla con OF, backfill de notifs de esa plantilla sin movimiento.

## Legalizar vs Formalizar vs Trasladar

| Acción | Dónde | Efecto |
|--------|--------|--------|
| **Legalizar** | Gestión notificaciones email | Traslado `LEGALIZACION_NOTIFICACION` bolsa → OF responsabilidad + `clasificacion_operativa`. Archivar **no** revierte ledger. |
| **Formalizar egreso** | Lista OF, fila `MOVIMIENTO BANCO POR IDENTIFICAR` | Crea **egreso** + `SALIDA_EGRESO` **desde la bolsa**. No restar otra vez el banco. En cierre: Egresos del medio (QR/Nequi/…); Movimientos ya no incluye ese PAGASTE. |
| **A Cuenta del dueño** | Misma fila | Traslado a OF personal (no es gasto). Acumula; para **bajar** el saldo → Egresos PERSONAL/DIVIDENDOS con Persona **dueño/propietario** (ver `egresos.md`). |
| **Trasladar** | Fila impacto + o arrastrar, o botón header | Mueve saldo a otro OF según reglas. Caso típico: retiro cajero/sucursal en Sin Clasificar → Caja Efectivo/Menor/General (plata que se usará en el local). |

## Modo estricto / flexible

Flag: `establecimiento.manejo_estricto_cuentas` (Datos del negocio). Default **false** (flexible).

| Modo | Origen `FISICA` | `ELECTRONICA`, `MIXTA` o sin naturaleza |
|------|-----------------|------------------------------------------|
| Estricto (`true`) | Bloquea si saldo &lt; valor | Bloquea si saldo &lt; valor |
| Flexible (`false`) | **Igual bloquea** | Permite; el egreso solo advierte |

BE: `MovimientoOrigenFondosServiceImpl.exigeSaldoSuficiente` dentro de `validarSalidaSuficiente`. Cubre egreso, traslado y ajuste con impacto negativo. `SALIDA_DEVOLUCION_VENTA` no pasa por esa validación (reembolso de venta que aún no está en el ledger).

FE: insignia «Modo flexible (solo electrónicos)»; en egreso nuevo, origen físico sin saldo deshabilita guardar. Spec: `openspec/specs/modo-cuentas-of/spec.md`.

## Reglas de traslado UI (`traslado-of.util.ts`)

1. **Electrónico** (hijo o raíz): hacia **cualquier padre FISICA** (cajas). También padre/hermanos del mismo árbol electrónico, y destino *Cuenta del dueño* (clasif. personal).
2. **No electrónico:** entre padres físicos (Menor ↔ General ↔ Efectivo).
3. **No electrónico:** entre padres e **hijos** físicos (Caja Menor ↔ Ahorro Servicios).
4. No: caja física → Bancolombia/Nequi (salvo reglas anteriores).

Detección electrónico: `naturaleza`; fallback nombre caja/efectivo → no electrónico (Caja Efectivo tiene `metodo_pago_id`).

BE debe devolver `naturaleza` en `GET /origenes-fondos/arbol` (`OrigenFondosArbolItemDto`). Reiniciar `:8088` tras ese cambio.

Diálogo Trasladar: destinos filtrados; origen se puede bloquear si viene de una fila.

## Gestos en la lista OF

- Clic tarjeta: ver movimientos.
- Doble clic: copia JSON ficha+movs.
- Arrastrar tarjeta → otra: traslado de saldo (si la regla lo permite).
- Arrastrar fila con **impacto +** → tarjeta destino: mismo diálogo.
- Footer: sugerencia permanente; en hover de controles **no** hay `matTooltip`; el texto va al footer (label del botón + descripción, o detalle completo de la columna Detalle).
- **Atrás / Adelante** en filas `TRASLADO` / `DISTRIBUCION` con `grupoTrasladoId`:
  - **Adelante** (impacto &lt; 0, salida): salta al OF de la entrada hermana.
  - **Atrás** (impacto &gt; 0, entrada): salta al OF de la salida hermana.
  - Resalta tarjeta OF + fila ~1.8 s y hace `scrollIntoView`.
  - Cadena multi-hop (Bancolombia → Sin clasificar → Caja menor) = pulsar Adelante en cada salida sucesiva.
  - API: `GET /movimientos-origen-fondos/grupo/{grupoTrasladoId}`.
  - Spec: `openspec/specs/navegacion-traslados-of/spec.md`.

### Tabla de movimientos (historial)

- Clase: `mov-table mov-table-compact` en `origenes-list`.
- **Cebra estándar POS** (igual clientes / productos / egresos):
  - pares: `rgba(0, 0, 0, 0.005)` en `tr` **y** `td` (MDC a veces tapa el fondo del `tr`);
  - impares: transparentes;
  - hover: `var(--pos-mat-table-row-hover)`;
  - selección: azul Material `rgba(63, 81, 181, 0.12)` (persiste sin depender de focus);
  - flash navegación: `.mov-row--nav-flash` ~1.8 s.
- Orden del historial: **id DESC** (más reciente arriba). No usar `fecha` (es `LocalDate`, sin hora) ni `fechaCreacion` (se desordena si el reloj del host se mueve).
- Spec UI lista: `openspec/specs/origenes-fondos-lista/spec.md`.
- Spec saldo estricto/flexible: `openspec/specs/modo-cuentas-of/spec.md`.

## Tipos de movimiento (ledger)

`ENTRADA_MANUAL`, `ENTRADA_PRESTAMO`, `ENTRADA_VENTA`, `TRASLADO`, `SALIDA_EGRESO`, ajustes/reversos de cierre. `origen_tipo` ejemplos: `MOVIMIENTO BANCO POR IDENTIFICAR`, `LEGALIZACION_NOTIFICACION`, `EGRESO`, `CORTE_VENTA`, `DISTRIBUCION`, `TRASLADO`.

## Archivos FE tocados en esta línea de trabajo (ago 2026)

- `origenes-list.component.{ts,html,scss}` — Trasladar, DnD, footer-ayuda, Formalizar, Dueño, **navegación Atrás/Adelante**, **cebra tabla movimientos**, **icono alerta PAGASTE** en Sin Clasificar (`notificacion-egreso-vinculo.md`).
- `origen-movimiento-dialog` — destinos filtrados, título Trasladar.
- `service/movimiento-origen-fondos.service.ts` — `findByGrupoTrasladoId`.
- `util/traslado-of.util.ts`, `clasificacion-operativa.util.ts`.
- `gestion-notificaciones-medios-electronicos` — plantillas naturaleza/OF, `{{lugarRetiro}}` con `ngNonBindable`.
- Confirmación pagos panel / tickets (cliente en QR, etc.) — relacionado pero no es la lista OF.

## Archivos BE relevantes

- `OrigenFondosServiceImpl.toArbolItem` + `naturaleza`.
- `MovimientoOrigenFondosServiceImpl.registrarTraslado`, `findByGrupoTrasladoId`.
- `MovimientoOrigenFondosController` — `GET …/grupo/{grupoTrasladoId}`.
- `EgresoServiceImpl` formalizar desde movimiento.
- puente-tienda: `EmailPagoParser`, `ConfirmacionPagoService`, `MovimientoDesdeNotificacionService`, `GestionNotificacionService`.

## Errores ya vistos (no repetir)

- Plantilla PUT 500: `id::text` Hibernate; `origen_destino_id` null como bytea.
- Angular: `{{lugarRetiro}}` en HTML de ayuda se interpola → `ngNonBindable`.
- Import perdido `ClasificacionOperativaReporteDialogComponent`.
- Correo no llega a `:8095`: filtro Gmail; no es fallo de plantilla.
- Plantilla no matchea: fragmento + `{{lugarRetiro}}` no era tag; match no era “contiene” normalizado.

## Cómo seguir en un chat nuevo

1. Leer este archivo + glosario.
2. Ayuda de usuario: `ayuda-documental/origenes-fondos/`.
3. Código: `traslado-of.util.ts` y `EmailPagoParser`.
4. No reintroducir pantallas demo Vex. OF es producto POS (menú Financiero).
