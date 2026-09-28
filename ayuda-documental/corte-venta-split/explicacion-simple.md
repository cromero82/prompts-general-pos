# Cómo se corrige un corte de ventas mal hecho (explicación simple)

> Versión sin tecnicismos. Para los detalles técnicos ver
> [`explicacion-detallada.md`](explicacion-detallada.md).
>
> Actualizado 2026-09-24: describe la pantalla tal como quedó.

---

## ¿Qué pasó?

Un corte de ventas (el "cierre de turno") se generó mal: en vez de hacer **un corte
por día**, juntó **dos días en uno solo**.

Después, con ese dinero se hicieron **gastos** (egresos). O sea, la plata ya se usó.

## ¿Por qué no se puede simplemente borrar?

Borrar el corte significa "devolver" el dinero que entró y se repartió. Pero ese dinero
ya se gastó: no hay forma real de devolverlo sin que las cuentas queden en negativo.

Por eso, cuando **cualquiera** de las cuentas que el corte tocó ya tuvo movimientos
después, el botón **Eliminar queda bloqueado** con este mensaje:

> «Existen movimientos generados luego del corte, reintente Dividir o Editar el corte»

Ojo: no es solo Caja Menor o Caja General. Si el gasto salió de **Bancolombia QR** o de
**Nequi**, también bloquea, porque esas cuentas recibieron las ventas del corte y
tampoco podrían devolverlas.

## ¿Qué hace "Dividir"?

Es como **corregir el registro sin borrar nada**:

1. El corte malo queda **marcado como "Dividido"** (se conserva, no se borra).
2. Se crean **los cortes nuevos**, uno por cada parte que definas. En total es la misma
   plata, solo que separada correctamente.
3. Los movimientos internos se acomodan con una **ayuda temporal** (el "puente"): un
   registro de ajuste que evita que las cuentas queden en negativo mientras se hace el
   cambio, y que se cierra al terminar la misma operación.
4. Los **gastos (egresos) no se tocan**: siguen exactamente igual.
5. Todo queda con un **motivo obligatorio**, para que una revisión de auditoría entienda
   qué pasó.

## ¿Cómo se usa en la pantalla?

En Ingresos → "Detalles por Fecha", sobre el registro más reciente:

1. Pulsar **Dividir**. Se abre una ventana (se puede mover arrastrándola).
2. Arriba aparece el rango del corte original **con segundos**. Ese es el límite: ninguna
   parte puede salirse de ahí.
3. Escribir el **motivo** (obligatorio).
4. Cada parte tiene **Desde** y **Hasta**, con fecha y hora (incluidos los segundos).
   Todas se pueden editar.
5. Pulsar **Agregar partición** para separar en dos. La ventana propone cortar al final
   del día (`23:59:59`) y arrancar la siguiente a las `00:00:00` del día siguiente, que
   es lo más común. Se puede repetir para tres o más partes.
6. En cada parte, **Consultar** muestra las ventas de ese rango por medio de pago, igual
   que en Cierre de turno. Sirve para revisar antes de confirmar.
7. Si el corte había mandado dinero a **Caja Menor / Caja General**, cada parte muestra
   cuánto le corresponde. Viene precargado y se puede cambiar; abajo se ve «repartido X
   de Y» y la última parte se ajusta sola para que cuadre exacto.
8. Pulsar **Confirmar división**.

> Si solo se quiere **dejar una nota** sobre el corte sin dividirlo (una sola parte con
> el mismo rango), también se puede: es el modo "editor", y queda registrado con motivo.

## Preguntas frecuentes

**¿Cuándo puedo Eliminar un corte?**
Cuando es el último corte y **ninguna** de las cuentas que tocó (Caja: Efectivo, QR,
Nequi, Caja Menor, Caja General) tuvo movimientos después. Si hubo aunque sea uno, hay
que usar Dividir.

**¿Por qué una parte termina en `23:59:59` y la otra empieza en `00:00:00`?**
Porque Ingresos agrupa por el **día en que empieza** cada corte. Si las dos partes
empiezan el mismo día, los dos cortes nuevos caen en la misma fila. Ese huequito de un
segundo es correcto, no un error; además evita que un ticket justo en el borde se cuente
dos veces.

**¿El "puente" cuenta como un ingreso?**
No. Es un ajuste técnico temporal, se marca aparte y no aparece en ventas ni ingresos ni
en la columna Movimientos del siguiente cierre.

**¿Se pierde el registro del corte malo?**
No. Queda con estado "Dividido", con el motivo y el vínculo a los cortes nuevos. Se
consulta con el filtro **Divididos**. Eso sí, ya **no suma** en Ingresos: sus ventas
ahora están en los cortes nuevos, y contarlo otra vez las duplicaría.

**¿Por qué los cortes nuevos no tienen Contado ni Diferencia?**
Porque son una reconstrucción que hace el sistema a partir de los tickets, no un conteo
físico nuevo. No hay arqueo por partición.

**¿Se puede dividir un corte dentro del mismo día (turnos mañana/tarde)?**
Sí. Los campos son de fecha **y hora**, así que se puede separar por turnos. Igual
conviene dejar un segundo entre el fin de uno y el inicio del otro.

**¿Y si un corte ya dividido quedó mal?**
Un corte se corrige una sola vez: si se intenta dividir o eliminar uno ya dividido, el
sistema lo rechaza. Lo que se corrige son los cortes nuevos.

**¿En qué casos NO se necesita Dividir?**
Si el corte se puede eliminar (sin movimientos posteriores), se elimina y listo. Dividir
es para cuando el dinero ya se usó y no se puede "devolver".

## Resumen

| Concepto | En una frase |
|---|---|
| **Corte de ventas** | Cierre del turno: junta ventas de un rango y reparte el efectivo |
| **Eliminar** | Borra el corte; solo si **ninguna** cuenta que tocó se movió después |
| **Dividir** | Corrige un corte mal hecho **sin borrar nada** y sin tocar los gastos |
| **Puente** | Ayuda temporal que evita saldos negativos; se crea y se cierra en la misma operación |
| **Motivo** | Obligatorio en toda división o edición, para auditoría |
| **"Dividido"** | El corte viejo: se conserva y se consulta, pero ya no suma en Ingresos |
| **Regla de oro** | El total de dinero nunca cambia: solo se reacomoda cómo está registrado |
