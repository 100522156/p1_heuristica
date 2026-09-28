/*parte-4.mod 
Miguel Merino 100522156
Pablo Garcia 100522190*/

/*DATOS*/
param l >= 1, integer;  # es el lado del pallet
param h >= 1, integer;  # es el numero maximo de niveles de cada pallet
param P >= 0;           # (NUEVO) coste de montar cada pallet, igual para todos

/*CONJUNTOS*/
set FILA;   # son las filas del pallet 
set COL;    #son las columnas del pallet 
set NIVEL; #son los niveles del pallet 
set CAJA;   #son las cajas a colocar, n cajas en total
set PALLET; #pallets disponibles    

param p{k in CAJA}; #son la prioridad de las cajas se van rellenando en el dat por parejas cada caja con su prioridad
param w{k in CAJA}; #son los pesos de las cajas en gramos
param y{k in CAJA}; #es la capacidad de cada caja en gramos
param M := max{k in CAJA} p[k] + 1; #prioridad de una posicion vacia (+infinito): mayor que la de cualquier caja, para que las vacias queden al fondo
param M_coste := sum{k in CAJA} p[k]; #mayor que cualquier suma de prioridades de delante, para anular el coste de una posicion vacia

/*VARIABLES*/
# variable_posicion vale 1 si la caja k esta en la fila i, columna j, nivel z del pallet t, y 0 si no
var variable_posicion{k in CAJA, i in FILA, j in COL, z in NIVEL, t in PALLET} binary;

# las variables auxiliares llevan tambien el pallet t: cada casilla de cada pallet tiene las suyas
var Prioridad{i in FILA, j in COL, z in NIVEL, t in PALLET} >= 0; #prioridad de la casilla, M si esta vacia; la fija restriccion_definir_prioridad

var Peso{i in FILA, j in COL, z in NIVEL, t in PALLET} >= 0; #peso de la caja de la casilla, 0 si esta vacia; lo fija restriccion_definir_peso

var Capacidad{i in FILA, j in COL, z in NIVEL, t in PALLET} >= 0; #capacidad de la caja de la casilla, 0 si esta vacia; la fija restriccion_definir_capacidad

var Coste{i in FILA, j in COL, z in NIVEL, t in PALLET} >= 0; #suma de prioridades de las cajas de delante, 0 si esta vacia; lo fija restriccion_coste_objetivo

# vale 1 si se monta el pallet t y 0 si no; sirve para cobrar P solo por los pallets que se usan
var pallet_usado{t in PALLET} binary;

/*FUNCION OBJETIVO*/
# (CAMBIA) ahora se minimiza el coste TOTAL, no el medio (asi lo pide el enunciado): la suma del coste de todas las
# posiciones de todos los pallets, mas P por cada pallet montado. Por eso ya no se divide entre el numero de cajas
minimize coste_total_fn_obj:
    sum{i in FILA, j in COL, z in NIVEL, t in PALLET} Coste[i,j,z,t] + P * sum{t in PALLET} pallet_usado[t];

/*RESTRICCIONES*/
# cada caja debe de estar en una unica posicion, contando todas las posiciones de todos los pallets
s.t. restriccion_posicion_por_caja{k in CAJA}:
    sum{i in FILA, j in COL, z in NIVEL, t in PALLET} variable_posicion[k,i,j,z,t] = 1;

# cada posicion de cada pallet puede tener una caja o ninguna
s.t. restriccion_caja_por_posicion{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    sum{k in CAJA} variable_posicion[k,i,j,z,t] <= 1;

#restriccion para que si no ese pallet no se usa que se quede vacio y si se usa , poner tantas cajas como l*l*h
s.t. restriccion_pallet_usado{t in PALLET}:
    sum{k in CAJA, i in FILA, j in COL, z in NIVEL} variable_posicion[k,i,j,z,t]<= card(FILA) * card(COL) * card(NIVEL) * pallet_usado[t];

# define que prioridad hay en cada posicion de cada pallet; si esta vacia le suma M para que cuente como la menor prioridad posible
s.t. restriccion_definir_prioridad{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    Prioridad[i,j,z,t] = sum{k in CAJA} p[k]*variable_posicion[k,i,j,z,t]+ M * (1 - sum{k in CAJA} variable_posicion[k,i,j,z,t]);

# cada posicion debe tener delante (fila i+1) una caja con mayor o igual prioridad, entendiendo con mayor prioridad la que tiene un numero mas bajo; se aplica dentro de cada nivel de cada pallet
s.t. restriccion_establecer_orden_prioridad{i in FILA, j in COL, z in NIVEL, t in PALLET: i < l}:
    Prioridad[i,j,z,t] >= Prioridad[i+1,j,z,t];
#esto no lo pide el enunciado pero para optimizar mas en ejemplos grandes mejor crear esto para que solo se puedan usar los pallets por orden
s.t. restriccion_orden_pallets{t in PALLET: t+1 in PALLET}:
    pallet_usado[t] >= pallet_usado[t+1];

#establezco el peso de cada posicion usando el parametro para el peso
s.t. restriccion_definir_peso{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    Peso[i,j,z,t] = sum{k in CAJA} w[k]*variable_posicion[k,i,j,z,t];

#defino igual la capacidad
s.t. restriccion_definir_capacidad{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    Capacidad[i,j,z,t] = sum{k in CAJA} y[k]*variable_posicion[k,i,j,z,t];

#la capacidad de cada caja tiene que ser mayor o igual que la suma de pesos de las cajas encima suya en el mismo pallet
s.t. restriccion_capacidad_peso{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    Capacidad[i,j,z,t] >= sum{z2 in NIVEL: z2 > z} Peso[i,j,z2,t];

#no se puede colocar una caja si abajo de la q quieres colocar no hay otra, (z<h para que no se compare con el nivel que no existe que seria el z+1)
s.t. restriccion_colocacion_caja_vacio{i in FILA, j in COL, z in NIVEL, t in PALLET: z < h}:
    sum{k in CAJA} variable_posicion[k,i,j,z,t] >= sum{k in CAJA} variable_posicion[k,i,j,z+1,t];

#coste de cada posicion: suma de las prioridades de las cajas de delante (i2 > i); si la posicion esta vacia le resto M_coste para que su coste quede en 0
s.t. restriccion_coste_objetivo{i in FILA, j in COL, z in NIVEL, t in PALLET}:
    Coste[i,j,z,t] >= sum{i2 in FILA, k in CAJA: i2 > i} p[k]*variable_posicion[k,i2,j,z,t]
                      - M_coste * (1 - sum{k in CAJA} variable_posicion[k,i,j,z,t]);

solve;

/* (CAMBIA) salida con formato fijo, ahora tambien con el pallet: ASIG fila columna nivel pallet caja */
printf {i in FILA, j in COL, z in NIVEL, t in PALLET, k in CAJA: variable_posicion[k,i,j,z,t] > 0.5} "ASIG %d %d %d %d %d\n", i, j, z, t, k;

end;