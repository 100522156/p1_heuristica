/*parte-3.mod 
Miguel Merino 100522156
Pablo Garcia 100522190*/

/*DATOS*/
param l >= 1, integer;  # es el lado del pallet
param h >= 1, integer;  # son los niveles del pallet

/*CONJUNTOS*/
set FILA;   # son las filas del pallet 
set COL;    #son las columnas del pallet 
set NIVEL; #son los niveles del pallet 
set CAJA;   #son las cajas a colocar que son l^2 *h

param p{k in CAJA}; #son la prioridad de las cajas se van rellenando en el dat por parejas cada caja con su prioridad
param w{k in CAJA}; #son los pesos de las cajas en gramos
param y{k in CAJA}; #es la capacidad de cada caja en gramos
param M := max{k in CAJA} p[k] + 1; #para poder hacer luego la restriccion de prioridad hago que M sea el mayor
param M_coste := sum{k in CAJA} p[k];

/*VARIABLES*/
#variable_posicion la uso para comprobar si una caja k esta en alguna fila i y columna j y nivel z, si esta la variable_posicion=1 , si no esta variable_posicion=0  
var variable_posicion{k in CAJA, i in FILA, j in COL, z in NIVEL} binary;

var Prioridad{i in FILA, j in COL,z in NIVEL} >= 0; #prioridad de la caja que queda en la casilla (i,j,z); su valor lo fija DefPrioridad y sirve para comparar casillas en OrdenPrioridad

var Peso{i in FILA, j in COL,z in NIVEL} >= 0; #peso de la caja que queda en la casilla (i,j,z); su valor lo fija DefPeso 

var Capacidad{i in FILA, j in COL,z in NIVEL} >= 0; #capacidad de la caja que queda en la casilla (i,j,z); su valor lo fija DefCapacidad

var Coste{i in FILA, j in COL, z in NIVEL} >= 0;

/*FUNCION OBJETIVO*/
#el sumatorio de los costes  dividio de las cajas , es la suma de las prioridades de las cajas de delante (i2>i)
minimize coste__medio_fn_obj:
    (1.0/card(CAJA)) * sum{i in FILA, j in COL, z in NIVEL} Coste[i,j,z];

/*RESTRICCIONES*/
# cada caja debe de estar en una unica posicion
s.t. restriccion_posicion_por_caja{k in CAJA}:
    sum{i in FILA, j in COL, z in NIVEL} variable_posicion[k,i,j,z] = 1;

# cada posicion solo dee tener una caja o ninguna para ello lo comprobamos con variables_posicion
s.t. restriccion_caja_por_posicion{i in FILA, j in COL, z in NIVEL}:
    sum{k in CAJA} variable_posicion[k,i,j,z] <= 1;

# define que prioridad hay en cada posicion , ademas si esta vacia le pondra el maximo de prioridad de la caja para luego provocar que las vacias esten lo mas atras posible
s.t. restriccion_definir_prioridad{i in FILA, j in COL, z in NIVEL}:
    Prioridad[i,j,z] = sum{k in CAJA} p[k]*variable_posicion[k,i,j,z]+ M * (1 - sum{k in CAJA} variable_posicion[k,i,j,z]);

#para establecer un orden cada posicion tiene que tener encima una caja con mayor o igual prioridad , entendiendo con mayor prioridad la que tiene un numero mas bajo 
s.t. restriccion_establecer_orden_prioridad{i in FILA, j in COL, z in NIVEL: i < l}:
    Prioridad[i,j,z] >= Prioridad[i+1,j,z];

#solo establezco el peso usando el parametro para el peso
s.t. restriccion_definir_peso{i in FILA, j in COL, z in NIVEL}:
    Peso[i,j,z] = sum{k in CAJA} w[k]*variable_posicion[k,i,j,z];

#defino igual la capacidad
s.t. restriccion_definir_capacidad{i in FILA, j in COL, z in NIVEL}:
    Capacidad[i,j,z] = sum{k in CAJA} y[k]*variable_posicion[k,i,j,z];

#defino la capacidad de peso que puede aguantar una caja y tiene que ser mayor la capacidad que la suma de pesos encima suya
s.t. restriccion_capacidad_peso{i in FILA, j in COL, z in NIVEL}:
    Capacidad[i,j,z] >= sum{z2 in NIVEL: z2 > z} Peso[i,j,z2];

#no se puede colocar una caja si abajo de la q quieres colocar no hay otra , (z<h para que no se compare con el nivel que no existe que seria el z+1)
s.t. restriccion_colocacion_caja_vacio{i in FILA, j in COL, z in NIVEL: z < h}:
    sum{k in CAJA} variable_posicion[k,i,j,z] >= sum{k in CAJA} variable_posicion[k,i,j,z+1];

#restriccion para la funcion objetivo donde si no hay nada en esa posicion le resto el sumatorio de las prioridades para asegurar que no tiene ningun coste que sumar en la funcion objetivo
s.t. restriccion_coste_objetivo{i in FILA, j in COL , z in NIVEL}:
    Coste[i,j,z]>= sum{i2 in FILA, k in CAJA: i2 > i} p[k]*variable_posicion[k,i2,j,z]- M_coste * (1 - sum{k in CAJA} variable_posicion[k,i,j,z]); 

solve;

/* salida con formato fijo para que el script no dependa del formato del informe de glpsol */
printf {i in FILA, j in COL, z in NIVEL, k in CAJA: variable_posicion[k,i,j,z] > 0.5} "ASIG %d %d %d %d\n", i, j, z, k;

end;