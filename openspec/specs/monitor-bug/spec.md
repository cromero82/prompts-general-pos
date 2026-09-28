## Purpose

El Monitor captura peticiones HTTP y permite revisarlas y copiar un JSON de traza. La clave `monitor-bug.secciones` decide qué partes de ese JSON se incluyen, según `trazable`.

## Requirements

### Requirement: Clave monitor-bug.secciones

`configuracion_app` SHALL tener la key `monitor-bug.secciones`. El `value` SHALL ser un JSON objeto cuyas claves son rutas del reporte y cuyo valor es `{ "trazable": true|false }`. La leyenda SHALL describir que las secciones marcadas se almacenan en la traza.

La fila SHALL crearse con `71_monitor_bug_secciones.sql` y el `value` de rutas del reporte completo SHALL fijarse con `72_monitor_bug_secciones_export.sql`. Esas migraciones MUST NOT editarse; un cambio posterior de valor exige un SQL `NN_` nuevo.

Al cargar `GET /configuracion-app/obtenerTodos` (login o tras guardar Ajustes), el FE SHALL copiar el `value` crudo a `localStorage['monitor-bug.secciones']`. Si la key no viene, SHALL borrar esa entrada de `localStorage`.

#### Scenario: Config presente
- **WHEN** la sesión carga configuraciones y la key existe
- **THEN** `localStorage['monitor-bug.secciones']` queda con el JSON de la base

#### Scenario: Config ausente
- **WHEN** la respuesta no trae `monitor-bug.secciones`
- **THEN** se quita de `localStorage` y el Monitor no recorta secciones

### Requirement: Rutas del reporte

Las rutas SHALL nombrar el JSON completo que se copia al portapapeles, no la petición suelta.

- Raíz: `exportedAt`, `user`, `route`, `userAgent`
- Cada ítem de `requests`: prefijo `requests.` (`requests.method`, `requests.requestBody`, `requests.requestHeaders.Accept`, `requests.responseHeaders.content-type`, `requests.requestParams.query`)

`requests.*` MUST aplicarse a cada elemento del arreglo. La comparación de la ruta MUST NOT distinguir mayúsculas (un header `authorization` coincide con `requests.requestHeaders.Authorization`).

#### Scenario: Header anidado
- **WHEN** la config tiene `requests.requestHeaders.Authorization` con `trazable: false` y el padre `requests.requestHeaders` no está en `false`
- **THEN** el objeto de headers se conserva y esa clave no aparece

#### Scenario: Padre apagado
- **WHEN** `requests.requestHeaders` tiene `trazable` distinto de `true`
- **THEN** no se incluye `requestHeaders` ni ninguno de sus hijos, aunque un hijo diga `trazable: true`

### Requirement: Regla trazable

Una ruta presente en la config SHALL incluirse solo si `trazable` es el booleano `true`. Cualquier otro valor MUST omitir ese nodo y no recorrer sus hijos. Una ruta que no está en la config SHALL conservarse (`url`, `responseStatus`, `durationMs`, `source` y cualquier header o param no listado).

Si el JSON de config falta o no parsea, el FE MUST NOT recortar por esta regla.

#### Scenario: Ejemplo de traza
- **WHEN** el value es el de `72_` (`exportedAt` y `route` en true; `user` y `userAgent` en false; en cada petición `id`, `method`, `requestBody` y `responseBody` en true; headers, params, `timestamp` y `responseStatusText` en false)
- **THEN** el JSON copiado trae `exportedAt`, `route` y, por petición, `id`, `method`, `requestBody`, `responseBody`, más `url` y `responseStatus` porque no están en la config

### Requirement: Dónde se aplica el recorte

La captura en memoria SHALL guardar la petición completa. El recorte SHALL aplicarse al armar el JSON:

- **Guardar al portapapeles y cerrar**, y cualquier copiado del reporte completo (`exportJson`), recorta el documento entero.
- En **Monitor — detalle de peticiones**, la tabla izquierda MUST seguir mostrando la petición capturada (método, status, URL, fecha).
- El panel **Editar #** (JSON y lista de secciones) SHALL mostrar solo la petición ya recortada con las rutas `requests.*`.

Siguen vigentes, antes del recorte por `trazable`: omitir headers `cache-control`, `expires` y `pragma`; truncar headers sensibles; e incluir `durationMs` solo si la petición superó 120 s.

#### Scenario: Ver una petición
- **WHEN** el usuario abre el detalle y selecciona una petición con `Authorization` en `trazable: false`
- **THEN** el JSON de **Editar #** no muestra ese header, y la tabla izquierda sigue listando la petición

#### Scenario: Copiar el todo
- **WHEN** el usuario pulsa **Guardar al portapapeles y cerrar**
- **THEN** el portapapeles recibe un solo JSON (`exportedAt`, `route`, `requests`, …) ya recortado, no el borrador crudo de la tabla

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar este spec, `contextos-ia/monitor-bug.md` y `CONTEXTO-TESTER-POS.md` §6.2.
