## Purpose

Habilitar confirmación electrónica por cualquier medio de pago (`permite_notificacion`), ligar plantillas de extracción a ese medio (Ingreso) u OF (Egreso), y mantener la UI de Dominios y Gestión de notificaciones sincronizada.

## Requirements

### Requirement: Flag permite notificación en método de pago

El sistema SHALL persistir `metodo_pago.permite_notificacion` y exponerlo en API/FE. Solo los medios con el flag en true SHALL generar HRE `CREADA` al liquidar venta (tramo) o abono CxC, y SHALL aparecer en el select de plantillas Ingreso.

#### Scenario: Medio sin flag
- **WHEN** se cobra un ticket solo con un medio que tiene `permiteNotificacion=false`
- **THEN** no se crea HRE pendiente de confirmación por email

#### Scenario: Medio con flag
- **WHEN** se cobra (o abona CxC) con un medio `permiteNotificacion=true`
- **THEN** existe HRE `CREADA` con ese `metodo_pago_id`

### Requirement: CRUD Dominios métodos de pago

El sistema SHALL permitir a roles admin gestionar métodos de pago desde Dominios (descripción, sigla, color, `file`/icono, visibilidad tickets/egresos, `permiteNotificacion`, estado). La desactivación SHALL ser soft (estado inactivo / ocultar flags).

#### Scenario: Activar notificaciones Nequi
- **WHEN** el operador marca «Permite notificación electrónica» en Nequi y guarda
- **THEN** ese medio aparece en plantillas Ingreso y puede crear pendientes HRE

### Requirement: Plantilla Ingreso ligada a método

Una plantilla de extracción con `naturaleza=INGRESO` SHALL requerir `metodo_pago_id` de un medio con notificaciones. El icono visible SHALL tomarse de `metodo_pago.file`.

#### Scenario: Guardar Ingreso sin método
- **WHEN** el operador intenta guardar plantilla Ingreso sin método
- **THEN** el sistema rechaza o bloquea el guardado con mensaje claro

### Requirement: Plantilla Egreso ligada a OF

Una plantilla con `naturaleza=EGRESO` SHALL requerir origen y destino de fondos y MUST NOT exigir método de pago de notificación. Tras match, si **no** hay egreso candidato sin vincular, el sistema SHALL contabilizar el movimiento ledger (QR → Sin Clasificar). Si hay candidato, MUST NOT crear ese traslado hasta que el operador asocie o envíe a bolsa (`notificacion-egreso-vinculo`). MUST NOT confirmar HRE de venta.

#### Scenario: PAGASTE sin egreso del mismo monto
- **WHEN** el email matchea plantilla EGRESO y no hay egreso candidato
- **THEN** se registra el movimiento ledger hacia el OF destino y no se confirma un ticket

#### Scenario: PAGASTE con egreso candidato
- **WHEN** el email matchea plantilla EGRESO y existe al menos un egreso candidato
- **THEN** no se crea el traslado hasta Asociar o Enviar a Sin clasificar


### Requirement: Auto-confirmación solo con plantilla Ingreso válida

Tras inbound, el sistema SHALL auto-emparejar HRE solo si la plantilla matcheada es Ingreso, su `metodoPagoId` coincide con el del pendiente y el medio tiene `permite_notificacion`.

#### Scenario: Email matchea Ingreso Nequi y hay HRE Nequi mismo monto
- **WHEN** llega el email y existe un único HRE `CREADA` con ese método y monto
- **THEN** el HRE pasa a confirmado (o queda listo según reglas de ambigüedad)

### Requirement: Modal Asociar — claridad multi-método

Si entre las notificaciones sin asignar hay al menos un `metodoPagoId` distinto al del pendiente (o entre sí), el modal Asociar SHALL mostrar iconos del medio en «Esperado» y en cada fila. Las notificaciones de otro medio MUST permanecer visibles pero no seleccionables.

#### Scenario: Corregir medio del pendiente
- **WHEN** el cajero usa «Corregir / cambiar medio» y elige otro medio con notificaciones
- **THEN** el sistema actualiza HRE y datos de pago relacionados (líneas de historial o abono+traslado OF) y las notificaciones del nuevo medio pasan a seleccionables

### Requirement: UI bidireccional Dominios ↔ Plantillas

Desde Plantillas de extracción, el FE SHALL ofrecer abrir el modal Dominios de métodos de pago. Desde ese modal, el FE SHALL ofrecer «Plantillas asociadas» (lista + alta/edición en modal de formulario con los mismos campos de la pestaña Plantillas).

#### Scenario: Alta plantilla desde Dominios
- **WHEN** el operador abre Plantillas asociadas → Agregar y guarda Ingreso con método
- **THEN** la plantilla queda activa y usable en inbound

### Requirement: Parser de monto con espacio tras símbolo

El parser SHALL reconocer montos con espacio o NBSP entre `$` y el número (p.ej. `$ 16.000`) y MUST NOT fallar solo por un punto final de frase tras miles CO.

#### Scenario: Fragmento Nequi
- **WHEN** el cuerpo contiene `Venta exitosa por $ 16.000` y la plantilla es `Venta exitosa por {{monto}}`
- **THEN** se extrae monto 16000 y se asocia la plantilla Ingreso correspondiente

### Requirement: Documentacion triple

Al cambiar esta capacidad, el equipo SHALL actualizar `contextos-ia/metodos-pago-notificacion.md`, este spec y `CONTEXTO-TESTER-POS.md` §4.12 / §4.14 / §10.5, más la oleada QA del ciclo.

#### Scenario: Cambio de plantilla Egreso
- **WHEN** cambia el hold inbound o los campos OF de una plantilla EGRESO
- **THEN** se actualizan spec, narrativo y tester en el mismo ciclo
