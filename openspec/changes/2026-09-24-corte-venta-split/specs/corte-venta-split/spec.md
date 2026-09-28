## ADDED Requirements

### Requirement: Capacidad viva y pruebas humanas pendientes

El equipo SHALL mantener `openspec/specs/corte-venta-split/spec.md` como source of
truth del comportamiento de corrección de cortes (Eliminar bloqueado + Dividir).

El código está aplicado y compila; las pruebas humanas de punta a punta SHALL quedar
listadas en `tasks.md` de este change hasta `/opsx-archive`. Las corridas hechas
durante el desarrollo MUST NOT darse por válidas: los fixes posteriores (reverso
completo de medios sin distribución, exclusión del estado `dividido`, desempate por id,
watermark del puente) cambiaron el resultado esperado.

#### Scenario: Retomar en otra sesión
- **WHEN** se reabre el trabajo de corrección de cortes de venta
- **THEN** se lee el spec vigente, el narrativo `contextos-ia/corte-venta-split.md` y las tareas pendientes de este change

#### Scenario: Antes de archivar
- **WHEN** se intenta archivar este change
- **THEN** CV-E01, CV-E02-no-permitido, CV-E02-split-por-día, CV-E04-split-en-mismo-día y el split de 3+ particiones ya pasaron sobre binario recompilado y BD reseteada
