# Contexto IA — Egresos (Plan 1 + Plan 2 Personas)

**Última actualización:** 2026-09-10 (vínculo PAGASTE ↔ egreso: ver `notificacion-egreso-vinculo.md`).  
**OpenSpec:** `openspec/specs/egresos-naturaleza-tipo/spec.md`, `openspec/specs/egresos-personas/spec.md`, `openspec/specs/notificacion-egreso-vinculo/spec.md`  
**QA / tester:** `doc-ayuda-inteligente/CONTEXTO-TESTER-POS.md` §4.10 / §4.15; oleada `ACTUALIZACION-QA-2026-09-10.md`  
**Docs triple:** `DUAL-DOCS-CURSOR-OPENSPEC.md`

## Objetivo

Documento de gasto operativo ligado a OF (caja/banco/bolsillos). El corte y el ledger deben cuadrar. No es ERP ni nómina.

## Modelo actual

Al crear/editar egreso:

| Campo | Rol |
|-------|-----|
| Fecha, valor, observación | Núcleo |
| **Beneficiario** | Proveedor **o** Persona (según naturaleza) |
| **Tipo** (`tipo_egreso_id` en `egreso`) | Snapshot; default = tipo usual del proveedor (si aplica) |
| **Naturaleza** | Código del catálogo `naturaleza_tipo_egreso` (vía tipo) |
| Origen de fondos | De dónde sale el dinero (`SALIDA_EGRESO`) |

### Regla beneficiario (Plan 2)

| Naturaleza | Beneficiario |
|------------|--------------|
| `PERSONAL`, `DIVIDENDOS` | `persona_id` obligatorio; `proveedor_id` null |
| Resto | `proveedor_id` obligatorio; `persona_id` null |

### Relación catálogo (Dominios)

```text
naturaleza_tipo_egreso  1 ──< N  tipo_egreso
        │                         │
        │                         └── proveedor.tipo_egreso_id (usual)
        └── egreso.naturaleza = codigo  (sugerido al elegir tipo)

persona  ──<  egreso.persona_id   (PERSONAL / DIVIDENDOS)
proveedor ──< egreso.proveedor_id (resto)
```

Menú Dominios: Tipos de egreso · Naturalezas de tipo egreso · Personas (incluye toggle **Es dueño / propietario**).

## Cuenta del dueño (OF)

- **Dueños > Cuenta del dueño** = mecanismo de **clasificación / acumulación** (legalizar, traslados con clasificación). Sigue con `visible_en_egreso = FALSE` en el catálogo general.
- **Disminuir** ese acumulado = **egreso** PERSONAL/DIVIDENDOS con:
  1. Persona con flag **`esDuenoPropietario`** (Dominios → Personas), y
  2. Origen = Cuenta del dueño (excepción acotada: visible **o** esa bolsa + persona dueño + naturaleza PERSONAL/DIVIDENDOS).
- En el formulario de egreso: elegir Persona dueño **antes** de ver Cuenta del dueño en el select de origen (no hay leyenda bajo Observación).
- Clasificar hacia la bolsa ≠ pagar.
- Límite v1: anticipo a empleado (persona **sin** flag dueño) **desde** Cuenta del dueño no está habilitado; usar Caja/banco visible.

## Formalizar vs egreso normal

- Egreso normal: resta del OF elegido.
- Formalizar: dinero ya en bolsa «por identificar»; crea egreso + salida desde esa bolsa sin restar otra vez el banco.

## Listado / export (UI)

Barra principal de filtros (orden):

1. **Naturaleza**
2. **Proveedor**
3. **Persona**
4. «Ver más opciones» → observación, tipo, fechas, limpiar, CSV

Columna **Beneficiario** (proveedor o persona).  
Botón **CSV** exporta el resultado filtrado (incluye tipo_beneficiario).

### Filtro desde notificación PAGASTE

Tras **Asociar y ver en egresos**, la lista abre con `?egresoId=` (un registro + flash). Botón visible **Borrar filtro notificación** (toolbar y barra sobre la tabla). Detalle: `notificacion-egreso-vinculo.md`.

## Migración BD

1. `46_egreso_naturaleza_tipo.sql` — columnas en `egreso`
2. `47_naturaleza_tipo_egreso.sql` — catálogo naturaleza + FK en `tipo_egreso` + backfill
3. `48_persona_egreso.sql` — tabla `persona`, `egreso.persona_id`, `proveedor_id` nullable
4. `49_persona_es_dueno_propietario.sql` — `persona.es_dueno_propietario`
5. `59_notificacion_vinculo_operacion.sql` — `vinculo_operacion` + FK correo ↔ egreso (flujo PAGASTE; ver `notificacion-egreso-vinculo.md`)
