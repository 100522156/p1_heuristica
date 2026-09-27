/*parte-2.mod 
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
param y{k in CAJA}; #es la capacidad de cada caja en gramos.


/*VARIABLES*/
#variable_posicion la uso para comprobar si una caja k esta en alguna fila i y columna j y nivel z, si esta la variable_posicion=1 , si no esta variable_posicion=0  
var variable_posicion{k in CAJA, i in FILA, j in COL, z in NIVEL} binary;

var Prioridad{i in FILA, j in COL,z in NIVEL} >= 0; #prioridad de la caja que queda en la casilla (i,j,z); su valor lo fija DefPrioridad y sirve para comparar casillas en OrdenPrioridad

var Peso{i in FILA, j in COL,z in NIVEL} >= 0; #peso de la caja que queda en la casilla (i,j,z); su valor lo fija DefPeso 

var Capacidad{i in FILA, j in COL,z in NIVEL} >= 0; #capacidad de la caja que queda en la casilla (i,j,z); su valor lo fija DefCapacidad

/*FUNCION OBJETIVO*/
#el coste de una caja es la suma de las prioridades de las cajas que tiene encima hasta llegar a la fila 1 donde i-1=0, por eso se multiplica la prioridad de la caja por (i-1) y se divide entre el numero de cajas para obtener el coste medio
minimize coste__medio_fn_obj:
    (1.0/card(CAJA)) * sum{k in CAJA, i in FILA, j in COL, z in NIVEL} p[k]*(i-1)*variable_posicion[k,i,j,z];

/*RESTRICCIONES*/
# cada caja debe de estar en una unica posicion
s.t. restriccion_posicion_por_caja{k in CAJA}:
    sum{i in FILA, j in COL, z in NIVEL} variable_posicion[k,i,j,z] = 1;

# cada posicion solo dee tener una caja para ello lo comprobamos con variables_posicion, si hay se suma 1 y si no hay se suma 0, por lo que la suma de todas las cajas en una posicion debe ser 1.
s.t. restriccion_caja_por_posicion{i in FILA, j in COL, z in NIVEL}:
    sum{k in CAJA} variable_posicion[k,i,j,z] = 1;

# define que prioridad hay en cada posicion , por eso se le suma la prioridad de la caja por 1 si esta en esa posicion y por 0 si no esta, asi se obtiene la prioridad de la caja que esta en esa posicion.
s.t. restriccion_definir_prioridad{i in FILA, j in COL, z in NIVEL}:
    Prioridad[i,j,z] = sum{k in CAJA} p[k]*variable_posicion[k,i,j,z];

#para establecer un orden cada posicion tiene que tener encima una caja con mayor o igual prioridad , entendiendo con mayor prioridad la que tiene un numero mas bajo 
s.t. restriccion_establecer_orden_prioridad{i in FILA, j in COL, z in NIVEL: i < l}:
    Prioridad[i,j,z] >= Prioridad[i+1,j,z];

s.t. restriccion_definir_peso{i in FILA, j in COL, z in NIVEL}:
    Peso[i,j,z] = sum{k in CAJA} w[k]*variable_posicion[k,i,j,z];

s.t. restriccion_definir_capacidad{i in FILA, j in COL, z in NIVEL}:
    Capacidad[i,j,z] = sum{k in CAJA} y[k]*variable_posicion[k,i,j,z];

s.t. restriccion_capacidad_peso{i in FILA, j in COL, z in NIVEL}:
    Capacidad[i,j,z] >= sum{z2 in NIVEL: z2 > z} Peso[i,j,z2];


solve;

/* salida con formato fijo para que el script no dependa del formato del informe de glpsol */
printf {i in FILA, j in COL, z in NIVEL, k in CAJA: variable_posicion[k,i,j,z] > 0.5} "ASIG %d %d %d %d\n", i, j, z, k;

end;