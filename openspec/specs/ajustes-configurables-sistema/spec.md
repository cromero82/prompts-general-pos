## Purpose

Permitir a un administrador consultar y editar los valores de `configuracion_app` desde el menú de usuario, con la leyenda como etiqueta, y refrescar el `localStorage` que la sesión ya usa.

## Requirements

### Requirement: Entrada en el menú de usuario

El menú de `ToolbarUserComponent` SHALL ofrecer **Configuración y mantenimiento** solo si el usuario es administrador. Dentro SHALL estar **Ajustes configurables del sistema**, que abre el modal de consulta y edición. MUST NOT ser una ruta nueva.

#### Scenario: Administrador
- **WHEN** un administrador abre el menú de usuario y entra a **Configuración y mantenimiento**
- **THEN** ve **Ajustes configurables del sistema** y, al elegirlo, se abre el modal

#### Scenario: No administrador
- **WHEN** un usuario que no es administrador abre el menú de usuario
- **THEN** esa entrada no aparece

### Requirement: Campos del modal

El modal SHALL listar las filas de `GET /configuracion-app/obtenerTodos`. Cada fila SHALL mostrar `leyenda` como label y el `value` editable. La columna `key` MUST NOT mostrarse. Si `leyenda` es nula o vacía, el label SHALL ser la `key` para poder identificar el campo. El modal MUST NOT permitir editar `key` ni `leyenda`.

El API SHALL incluir `leyenda` en cada ítem. La columna ya existe en `configuracion_app` (`leyenda` VARCHAR(255)). Los textos de leyenda SHALL cargarse con `70_configuracion_app_leyendas.sql`, que MUST NOT modificar `value` ni `key`. Las filas sin leyenda en esa migración permanecen sin texto.

#### Scenario: Leyenda presente
- **WHEN** la fila tiene leyenda
- **THEN** el label es esa leyenda y la key no aparece como columna

#### Scenario: Leyenda vacía
- **WHEN** la fila no tiene leyenda
- **THEN** el label es la key y el valor sigue siendo editable

### Requirement: Guardar solo si hay cambios

**Guardar cambios** SHALL permanecer deshabilitado mientras ningún `value` difiera del cargado. SHALL habilitarse cuando al menos un valor cambió y cada valor modificado es no vacío (tras recortar) y de a lo sumo 1000 caracteres. Tras un guardado correcto, el botón MUST volver a deshabilitarse.

#### Scenario: Formulario limpio
- **WHEN** el modal acaba de cargar y nadie editó
- **THEN** **Guardar cambios** está deshabilitado

#### Scenario: Valor modificado
- **WHEN** el administrador cambia un valor por otro no vacío
- **THEN** **Guardar cambios** se habilita

#### Scenario: Valor en blanco
- **WHEN** el administrador deja un valor modificado vacío o solo con espacios
- **THEN** **Guardar cambios** permanece deshabilitado

### Requirement: Persistencia y localStorage

Guardar SHALL enviar `PUT /configuracion-app/key/{key}` con `{ "value" }` solo por cada fila modificada. Ese endpoint SHALL actualizar únicamente `value`.

Solo si esas peticiones responden bien, el FE SHALL volver a aplicar en `localStorage` el mismo mapeo que usa al iniciar sesión. MUST NOT copiar el `value` crudo de claves que ese mapeo no traduce.

Claves que el mapeo escribe:

- `longitud-vertical-panel-productos` (valor tal cual)
- `monitor-bug` (`true` / `false` parseado)
- `monitor-bug.secciones` (JSON crudo; lo consume el Monitor al copiar y al abrir **Editar #**)
- `notificaciones.activa` (`true` / `false` parseado)
- `notificaciones.asociaciones-egresos.obligatorio` (`true` / `false` parseado)
- `alerta-precios` → `alerta-precios-porcentaje-minimo` y `alerta-precios-porcentaje-maximo`

#### Scenario: Guardar notificaciones.activa
- **WHEN** el administrador cambia `notificaciones.activa` y guarda con éxito
- **THEN** la base queda con el nuevo `value` y `localStorage['notificaciones.activa']` queda en `true` o `false`

#### Scenario: Fallo al guardar
- **WHEN** alguna petición de guardado falla
- **THEN** el formulario sigue sucio y no se refresca `localStorage` con esa operación

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar este spec, `contextos-ia/ajustes-configurables-sistema.md` y `CONTEXTO-TESTER-POS.md` §4.16 / §10.12.
