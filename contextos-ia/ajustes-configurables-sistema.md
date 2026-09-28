# Ajustes configurables del sistema

OpenSpec: `openspec/specs/ajustes-configurables-sistema/spec.md`  
QA: `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` §4.16 / §10.12

## Qué es

Modal del menú de usuario (solo administrador) para ver y editar `configuracion_app.value`. El label es `leyenda`. Si la leyenda está vacía, el label es la `key`. La `key` no se muestra como columna y no se edita, tampoco la leyenda.

## Dónde

| Pieza | Archivo |
|---|---|
| Menú | `toolbar-user-dropdown` → **Configuración y mantenimiento** → **Ajustes configurables del sistema** |
| Modal | `toolbar-user/ajustes-configurables/ajustes-configurables-dialog.component.*` |
| Sync `localStorage` | `ConfigurationService.obtenerTodasConfiguraciones()` (el mismo del login) |
| API | `GET /configuracion-app/obtenerTodos` · `PUT /configuracion-app/key/{key}` `{ value }` |
| Entidad | `ConfiguracionApp.leyenda` (columna en SQL `67_`; textos en `70_configuracion_app_leyendas.sql`) |

## Guardar

**Guardar cambios** solo si hay dirty y cada valor modificado es no vacío y ≤ 1000 caracteres. Tras el PUT, se reaplican en `localStorage` las claves que el login ya traduce: `longitud-vertical-panel-productos`, `monitor-bug`, `monitor-bug.secciones` (JSON crudo), `notificaciones.activa`, `notificaciones.asociaciones-egresos.obligatorio`, `alerta-precios` (parte en mínimo/máximo). El resto no se copia crudo a `localStorage`.

## No romper

- `notificaciones.activa=false` sigue ocultando el panel de pagos y, en el FE, el poll de `alertas-egreso-sin-vincular`.
- `cartera-maxima` (SQL `75_`) aparece en el listado; **no** pinta la torta de KPI Cartera (otras funciones).
- No editar SQL `67_` ni los `NN_` existentes. La columna `leyenda` ya está.
