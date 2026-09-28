# Desarrollo Lite — POS Infinito

Contexto de desarrollo **funcional** de la app: **backend + frontend + base de datos actual**. Todo lo demás existe, pero **no se gestiona**.

## 1. Alcance (único foco)

| Pieza | Path | Puerto |
|---|---|---|
| Backend | `pos-relational-data-service` (Java/Spring; lógica de tienda + SQL del schema) | `:8088` |
| Frontend | `infinito-ai-front` (Angular/Vex) | `:4200` |
| Base de datos | `controlneg_rmx_db_v02` (por defecto) | — |

El schema vive en el BE (`src/main/resources/doc/contextos/database/`). No hay que preocuparse por entornos ni por versiones de BD.

## 2. Existe, pero NO se gestiona

Launcher, seguridad, SMTP, puente, Caddy/túnel, sandbox, arranques dev/sandbox, resets de tablas financieras, instalación/operación en tienda. **No** se leen ni se citan sus runbooks ni mds de infra (p. ej. `interceptar-pagos-tunel.md`, `CURSOR-IA-PC-TIENDA-V02.md`, `ARRANQUE-LOCAL-Y-SANDBOX.md`, `contextos-ia/sandbox-*`, `contextos-ia/ambientes-launcher-*`). Que el tema aparezca ⇒ "fuera de alcance", no se profundiza.

## 3. Funcionalidades de la app

| Funcionalidad | Contexto | Spec OpenSpec |
|---|---|---|
| Orígenes de fondos / ledger / traslados | `contextos-ia/origenes-fondos.md` | `origenes-fondos-lista` · `navegacion-traslados-of` |
| Egresos (naturaleza, personas, tipo) | `contextos-ia/egresos.md` | `egresos-naturaleza-tipo` · `egresos-personas` |
| Pagos electrónicos / confirmación | `contextos-ia/confirmacion-pagos-electronicos.md` | `confirmacion-pagos-electronicos` |
| Métodos de pago / notificación | `contextos-ia/metodos-pago-notificacion.md` | `metodos-pago-notificacion` |
| Notificación egreso ↔ CxC | `contextos-ia/notificacion-egreso-vinculo.md` | `notificacion-egreso-vinculo` |
| Cierres / corte de caja | `contextos-ia/cierre-asistente-caja.md` | `cierre-asistente-caja` |
| Historial de tickets / VTA | `contextos-ia/historial-tickets.md` | `historial-tickets` |
| CxC / abonos / pagador | `contextos-ia/cxc-abono-pagador.md` | `cxc-abono-pagador` |
| Ventas / lectora de código | `contextos-ia/lectora-codigo-barras.md` | `lectora-codigo-barras` |
| Observaciones de ticket | `contextos-ia/ticket-observaciones.md` | `ticket-observaciones` |
| Multi-pago / medios por ticket | `MULTIPAGO-MEDIOS-POR-TICKET.md` | — |
| Ingresos / dashboard | `contextos-ia/ingresos-dashboard.md` | `ingresos-dashboard` |
| Guía en línea (overlay) | `contextos-ia/guia-en-linea.md` | — |
| Producto / presentaciones | `contextos-ia/producto-presentaciones.md` | `producto-presentaciones-uom` |
| Glosario financiero | `GLOSARIO-NUCLEO-FINANCIERO.md` | — |
| Ajustes configurables del sistema | `contextos-ia/ajustes-configurables-sistema.md` | `ajustes-configurables-sistema` |
| Atajos de teclado en Tickets | — | `teclas-acceso-rapido` |
| Monitor (traza HAR) | `contextos-ia/monitor-bug.md` | `monitor-bug` |

## 4. Base de datos

- Default y única: **`controlneg_rmx_db_v02`**.
- Schema = SQL manual en el BE (`database/`, archivos `NN_…`); `ddl-auto=none` (JPA no crea nada).
- Cambio de BD → **migración nueva**: crear un SQL `NN_…` nuevo; nunca editar ni eliminar los existentes.
- **Sin contexto** de resets financieros, sandbox ni versiones de BD.

## 5. OpenSpec

- Root: `openspec/` (specs vigentes = fuente de verdad del comportamiento).
- Consultar specs: sí (para entender comportamiento). **Documentar cambios o crear specs nuevos solo cuando el usuario lo pida**; no proponer por iniciativa propia.

## 6. Puntos de entrada (leer bajo demanda, no copiar aquí)

- Dominio general: `README.md` + `GLOSARIO-NUCLEO-FINANCIERO.md`.
- BE: `repos/pos-relational-data-service/CLAUDE.md` → `AI-ONBOARDING-basic.md`.
- FE: `repos/infinito-ai-front/CLAUDE.md` → `.cursor/rules/pos-app-map.mdc` + `pos-component-inventory.mdc`.

## 7. Reglas

- Español; sin saludos; solo lo pedido; directo y corto.
- Nada de compilar, levantar servicios, aplicar SQL real ni commitear sin pedido explícito.
- Cambio de comportamiento → revisar spec/contexto correspondiente antes de tocar código.
- Todo lo ajeno al alcance (sección 2): se reconoce que existe, pero **no se gestiona**.