# Monitor (traza HAR)

OpenSpec: `openspec/specs/monitor-bug/spec.md`  
QA: `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` §6.2

## Qué es

Botón **Monitor**. Captura HTTP en memoria (hasta 200). **Ver detalle** lista las peticiones completas. **Editar #** y **Guardar al portapapeles y cerrar** recortan el JSON según `configuracion_app` key `monitor-bug.secciones`.

## Regla

Cada ruta del reporte (`exportedAt`, `requests.method`, `requests.requestHeaders.Accept`) vale si `trazable` es `true`. Otro valor omite ese nodo y sus hijos. Una ruta que no está en el JSON se conserva (`url`, `responseStatus`). El nombre del header no distingue mayúsculas.

El valor se copia a `localStorage['monitor-bug.secciones']` al cargar configuraciones (login o guardar Ajustes). Sin esa entrada no hay recorte.

SQL: `71_monitor_bug_secciones.sql` (alta) y `72_monitor_bug_secciones_export.sql` (rutas del reporte completo). No editarlos.

## Dónde

| Pieza | Archivo |
|---|---|
| Captura | `infinito-ai-front` `src/app/core/bug-reporter/bug-reporter.interceptor.ts` |
| Recorte al copiar y al editar | `bug-reporter.service.ts` (`exportJson`, `applyRequestTrazabilidad`) |
| Panel detalle | `bug-reporter-detail-dialog.component.ts` |
| Sync config | `ConfigurationService.obtenerTodasConfiguraciones()` |
