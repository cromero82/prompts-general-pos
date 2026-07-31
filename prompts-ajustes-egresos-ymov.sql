confirmo:
1. ¿AJUSTE_CIERRE al Registrar o al Finalizar revisión? 
te refieres a: Funcionalidad MPOF debera permitir setear el valor base para el siguiente turno ?
si es asi, entonces el ajuste de cierre debe ser: al momento de REGISTRAR.

2. respuesta corta: ambos, campos. 
	- admin tambien pudo iniciar sesion y actuar como cajero, es decir entre otras funcionalidades "Vender" a traves de la funcionalidad TICKETS (cuando ADMIN INicia sesion, no esta obligado a seleccionar CAJA, pero SI Puede hacerlo)
	- admin puede  Crear CORte de ventas y cuando hace clic en "Registrar cierre" el estado pasara a ser "Revisada", no tiene necesidad de revision, se asume todo "OK".
	
	A continuacion escenario inicial: CAJERO sesion con turno > Registrar Cierre de turno > Cierre de sesion del Cajero. Inicia sesion Admin > Revision CIerre turno.
	- recordar que Cajero solo edita, MP/OF que tiene permisos, y ve los que "trabaja" en las ventas. en los primeros edita motos de desfase, en los segundos solo los ve. no puede editar nada.
	cuando inicia sesion el ADMIN > Abre "CIerre de turno" en estado: Creado.
	- admin solo edita los demas MP/OF (probablemente alguno que el CAJERO vio pero no podia editar), PERO en los que CAJERO edito, admin solo edita revision, pero NO montos.
	
3. si incluye la opcion de visualizar Cierres eliminados
4. si requerimos corte_venta_detalle.


=========================
–	Cuando cajero realiza el cierre esta queda en estado: creada.
–	En el Cierre la columna: Revision. Solo aparece cuando un admin abre dicho registro (estado creada), en esa columna aparecen 2 opciones de boton: (de acuerdo) o (sugerencia) y si elige sugerencia: puede editar esa ultima columna como texto abierto. Si elige de acuerdo. Visualmente aparecera un check OK pero por debajo tendra valor un text: “OK”
Campo observacion aqui hay un problema importante, y es que al consultar: 
'http://localhost:8088/corte-venta/consultar-rango?fechaIni=2026-07-16T08:00:00&fechaFin=2026-07-16T18:00:00&ultimoCorte=true&actual=true' \...
Este carga en el back: com.infinitesoft.pos_relational_data_service.controllers.CorteVentaController#consultarRango
Lo que hace es cargar los movimientos por metodo de pago, y esto termina cargando los datos de la tabla , yo crei que al guardar, se estaba guardando los detalles de estos movimientos, pero realmente se esta guardando un solo registro (que es la suma de  los movimientos por metodo de pago) necesito que se cambie este aspecto, se siga cargando de esa manera, pero al hacer clic en “Registrar cierre” se cree el registro principal (tabla: corte_venta) y adicionalmente ahora generar corte_venta_detalle. Y este es el que se cargara por el admin cuando abra este registro en estado “creada”. Finalmente con respecto al campo observacion, este debera estar en tabla maestra: corte_venta.
–	Cuando el admin ha chequeado los detalles del corte de ventas (de acuerdo / sugerencia) se habilita el boton “Finalizar revision” (el cual es visible solo en estado: creada), y al hacer click se guardan los cambios y corte_ventas.estado pasara a “revisada”
–	Un corte de ventas puede ser eliminado, solo si se realiza: desde el ultimo corte de ventas registrado (esto se debe hacer en el UI y validar en el backend). En este caso el estado pasara a “eliminado” y al crear el nuevo corte no tendra en cuenta el ultimo_historial_recibo_id de ese registro

EN Resumen a tus preguntas.
19.5.ok entonces no fusionesmos, 
19.7. 1. el campo observacion estara en tabla: corte_venta.
2.  los signos que te coloque en el ejemplo y  la formula
Los campos que suman son: inicial, ventas
Los campos que restan son: egresos
Campo movimiento: restan de donde se saca, suman a donde se envian.

Prioridades. Primero resolvamos (aspectos de diseño, impacto, y standares) estos items anteriores recientemente generados o detectados y luego retomamos  B6 KPI (Ya no recuerdo que es ) y B7 Export (supongo que es el export para contador) aplacemos esas tareas.
================================================================

- continuando incluso cuando cargo la app (sin desfase) tampoco esta habilitado el boton, cuando hago un desfase y selecciono un motivo de la lista, tampoco esta habilitado. 
  – asi que trata de arreglarlo, pero vuelve al focus general y los sprint,adicionalmente he analizado mas acerca del funcionamiento del sistema, pienso en complementar la funcionalidad "Corte de venta" la cual requerira  siguientes requisitos para la aplicacion 
  Metodo de pago, Base, Ventas, Egresos, Movimientos, Neto Sistema, Total fisico/Real, Desfase, Revision
—————————————————————————————————————————————
Caja (Efectivo), 150, 200, -30, -20 [boton ver detalles], 50, 50, 0, [null],    
QR Bancolombia, 100, 80, -20, 0, 160, 155, 5, [“Error...”], [“Movimiento pendiente”] 
NEQUI, 50, 10, 0, 0, 60, 60, 0, [null]
Origen Fondos, 
- Base para proveedores, 2000, no aplica, -400, +20 [boton ver detalles]
Boton: ver detalles: muestar los movimientos donde participo ese MPOF, con usuario, fecha/hora, tipo mov, lista motivo.
–	La funcionalidad Origenes de fondos, debe ser complementada (o convertida) en otra, 
o	basicamente debe ser posible gestionar metodos de pago y Origenes de fondos (a partir de ahora para referire a ellos, lo hare a traves de la notacion MPOF),
o	Debe permitir mover dinero entre ellos, ejemplo: Caja (Efectivo) a Base de proveedores (indenpendiente de ser Metodo de pago u origen de fondo ) no se si cuestionar el diseño actual: “metodo_pago”, “tipo_origen_fondos”, “origenes_fondos”, si se prevee algun cambio que sea basado en estandares POS y lo discutimos (dame sugerencias)
–	Con respecto a Roles: admin (administrador) y cajero
1.	Admin puede dar permiso a MPOF (por registro) a cajeros.
2.	En la vista de cierre de ventas, un cajero no podra ver MPOF que no haya tocado, sin embargo si se realizó algun movimiento desde o hacia uno de los metodos de pago con los que interactuo en el turno, entonces este aparecera en la tabla, en el ejemplo: en la columna: MOvimientos, de la caja se saco 20 y se movio a OF “Base para proveedores”, supongamos que  el cajero no tiene permiso a “Base de proveedores”, (pero supongamos que ese movimiento lo realizo un usuario administrador) por ende el cajero lo ve en su sesion, ya que afecto su MP.

–	Funcionalidad MPOF debera permitir setear el valor base para el siguiente turno sustentada en movimientos, ejemplo: si al finalizar el turno. Se recomienda ejecutar esta funcionalidad. (debera aparecer el modal) si el usuario hace clic en cancelar (el sistema inmediatamente cerrara sesion). Entonces al iniciar sesion en el siguiente turno, tambien aparecera esta ventana modal, 
o	Quien deberia diligenciar esta funcionalidades es un administrador, pero si el administrador no lo hace durante la pausa entre turnos del cajero, entonces este tendra que hacerlo pero unicamente para el MP: Caja (Efectivo). “un mensaje algo como: favor cuente billetes y monedas de la caja registradora”
o	En modo estricto activado de movimientos, Si el usuario admin va a registrar la base de la caja, no podra hacerlo si el usuario cajero inicio sesión, debe pedirle al cajero que finalice sesion, con lo que el usuario admin para este caso deberia tener un boton (reintentar) para ver si la caja fue liberada y setear el valor.
o	Si del paso anterior fue el admin quien seteo el valor de la base (ejemplo el dia anterior durante la pausa), entonces al aparecer el modal debera aparecer el valor registrado por el admin, pero el cajerod tiene que contar igualmente el dinero de la base y registrarlo, deberian ser igual al registrado por el admin, de lo contrario, se generara un movimiento que podria ser “Ajuste encontrado base” como probablemente el admin no esta presente para corroborar en fisico, se le dara voto de confianza al cajero, pero obviamente este movimiento aparecera en el cierre: con origen vacio y destino Caja (estamos hablando unicamente de la caja). La idea de esto es no detener la operacion del establecimiento en caso de ausencia del admin.
o	Si el cajero tiene permiso para OF entonces tambien debera registrar lo que recibe. Ejemplo: “Base para proveedores”
–	Campo observacion: texto 200, al final del formulario “Cierre de ventas” para escribir alguna observacion general