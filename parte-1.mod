/*parte-1.mod 
Miguel Merino 100522156
Pablo Garcia 100522190*/

/*DATOS*/
param l >= 1, integer;  # es el lado del pallet, se comprueba que es mayor o igual  que 1 entero

/*CONJUNTOS*/
set FILA;       # son las filas del pallet que se rellena en el dat
set COL;        #son las columnas del pallet que se rellnan en el dat
set CAJA;       #son las cajas a colocar que son l^2, tambien se rellena en el dat

param p{k in CAJA}; #son la prioridad de las cajas se van rellenando en el dat por parejas cada caja con su prioridad


/*VARIABLES*/
#variable_posicion la uso para comprobar si una caja k esta en alguna fila i y columna j , si esta la variable_posicion=1 , si no esta variable_posicion=0  
var variable_posicion{k in CAJA, i in FILA, j in COL} binary;

var Prioridad{i in FILA, j in COL} >= 0; #prioridad de la caja que queda en la casilla (i,j); su valor lo fija DefPrioridad y sirve para comparar casillas en OrdenPrioridad

/*FUNCION OBJETIVO*/
#el coste de una caja es la suma de las prioridades de las cajas que tiene encima hasta llegar a la fila 1 donde i-1=0, por eso se multiplica la prioridad de la caja por (i-1) y se divide entre el numero de cajas para obtener el coste medio
minimize coste__medio_fn_obj:
    (1.0/card(CAJA)) * sum{k in CAJA, i in FILA, j in COL} p[k]*(i-1)*variable_posicion[k,i,j];

/*RESTRICCIONES*/
# cada caja debe de estar en una unica posicion
s.t. restriccion_posicion_por_caja{k in CAJA}:
    sum{i in FILA, j in COL} variable_posicion[k,i,j] = 1;

# cada posicion solo dee tener una caja para ello lo comprobamos con variables_posicion, si hay se suma 1 y si no hay se suma 0, por lo que la suma de todas las cajas en una posicion debe ser 1.
s.t. restriccion_caja_por_posicion{i in FILA, j in COL}:
    sum{k in CAJA} variable_posicion[k,i,j] = 1;

# define que prioridad hay en cada posicion , por eso se le suma la prioridad de la caja por 1 si esta en esa posicion y por 0 si no esta, asi se obtiene la prioridad de la caja que esta en esa posicion.
s.t. restriccion_definir_prioridad{i in FILA, j in COL}:
    Prioridad[i,j] = sum{k in CAJA} p[k]*variable_posicion[k,i,j];

#para establecer un orden cada posicion tiene que tener encima una caja con mayor o igual prioridad , entendiendo con mayor prioridad la que tiene un numero mas bajo 
s.t. restriccion_establecer_orden_prioridad{i in FILA, j in COL: i < l}:
    Prioridad[i,j] >= Prioridad[i+1,j];

solve;

/* salida con formato fijo para que el script no dependa del formato del informe de glpsol */
printf {i in FILA, j in COL, k in CAJA: variable_posicion[k,i,j] > 0.5} "ASIG %d %d %d\n", i, j, k;

end;