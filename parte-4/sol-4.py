#!/usr/bin/env python3
#sol-4.py Miguel Merino 100522156 , Pablo García 100522190
import os, re, subprocess, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))# para tener la ruta de sol-4.py
MODEL_FILE = os.path.join(SCRIPT_DIR, "parte-4.mod")#para unir con la otra ruta 


def resolver_ruta(ruta):
    #creo una funcion por si tiene ruta absoluta si no tiene le pongo la ruta del sol-4.py 
    if os.path.isabs(ruta) or os.path.dirname(ruta):
        return ruta
    return os.path.join(SCRIPT_DIR, ruta)


def leer_entrada(ruta_entrada):
    with open(ruta_entrada, encoding="utf-8") as f:
        lineas = []    
        for linea in f:      
            if linea.strip():    
                lineas.append(linea.strip())  # se guarda sin espacios ni saltos de linea

    # la primera linea ahora trae tres valores: lado, numero maximo de niveles y coste de montar un pallet
    primera = lineas[0].split()
    l = int(primera[0])
    h = int(primera[1])
    P = float(primera[2])  # float porque el enunciado no dice que el coste tenga que ser entero
    prioridades = list(map(int, lineas[1].split()))
    pesos = list(map(int, lineas[2].split()))
    capacidades = list(map(int, lineas[3].split()))
    n = len(prioridades) # el numero de cajas no es fijo: es cuantas prioridades hay
    # las tres lineas deben tener el mismo numero de valores porque cada caja necesita su prioridad, peso y capacidad
    if len(pesos) != n:
        raise ValueError(f"Se esperaban: {n} pesos, hay {len(pesos)}")
    if len(capacidades) != n:
        raise ValueError(f"Se esperaban: {n} capacidades, hay {len(capacidades)}")
    # ya no hay limite superior de cajas porque hay pallets ilimitados; solo tiene que haber al menos una
    if n < 1:
        raise ValueError("Tiene que haber al menos una caja")
    return l, h, P, prioridades, pesos, capacidades


def generar_dat(ruta_dat, l, h, P, prioridades, pesos, capacidades):
    filas = " ".join(str(i) for i in range(1, l + 1))
    niveles = " ".join(str(z) for z in range(1, h + 1))   
    cajas = " ".join(str(k) for k in range(1, len(prioridades) + 1))
    # tantos pallets como cajas: en el peor caso cada caja va sola en su pallet, asi que siempre basta
    pallets = " ".join(str(t) for t in range(1, len(prioridades) + 1))
    with open(ruta_dat, "w", encoding="utf-8") as f: #creo el fichero dat y escribo todo
        f.write("data;\n\n")
        f.write(f"param l := {l};\n\n")
        f.write(f"param h := {h};\n\n")
        f.write(f"param P := {P};\n\n")  #coste de montar un pallet
        f.write(f"set FILA := {filas};\n")
        f.write(f"set COL := {filas};\n")
        f.write(f"set NIVEL := {niveles};\n")
        f.write(f"set CAJA := {cajas};\n")
        f.write(f"set PALLET := {pallets};\n\n")  #  pallets disponibles
        f.write("param p :=\n")
        k = 1      
        for p in prioridades:  
            f.write(f"{k} {p}\n")  # escribe el numero de cada caja y prioridad
            k = k + 1       
        f.write(";\n\n")

        f.write("param w :=\n")
        k = 1
        for w in pesos:
            f.write(f"{k} {w}\n")  # escribe el numero de cada caja y su peso
            k = k + 1
        f.write(";\n\n")

        f.write("param y :=\n") 
        k = 1
        for y in capacidades:
            f.write(f"{k} {y}\n") # escribe el numero de cada caja y su capacidad
            k = k + 1
        f.write(";\n\nend;\n")


def llamar_glpsol(ruta_dat):#usamos esto para llamar a glpsol y que nos de una solucion,(.returncode , .stdout, .stderr, recordar)
    ruta_sol = ruta_dat + ".sol.txt"
    r = subprocess.run(
        ["glpsol", "--model", MODEL_FILE, "--data", ruta_dat, "--output", ruta_sol],
        capture_output=True, text=True) #ejecuto glpsol con los parametros que le paso y guardo la salida en r
    if r.returncode != 0:#por si glpsol falla escribo en stderr la salida de glpsol y lanzo un error
        sys.stderr.write(r.stdout + r.stderr)
        raise RuntimeError("glpsol ha fallado") 
    return ruta_sol, r.stdout


def lectura_text_sol(ruta_sol):
    with open(ruta_sol, encoding="utf-8") as f:#abro el fichero solucion del glpsol y busco las filas, columnas y el objetivo con expresiones regulares
        contenido = f.read()
    filas = int(re.search(r"Rows:\s+(\d+)", contenido).group(1))
    columnas = int(re.search(r"Columns:\s+(\d+)", contenido).group(1)) 
    objetivo = float(re.search(r"Objective:\s+\S+\s*=\s*([\-\d.eE]+)", contenido).group(1)) #paso el objetivo a float, para ello busco simplemente que puede estar en notaficacion cientifica o no, por eso pongo [\-\d.eE]+, o tanbien con coma por ser float
    numero_variables = columnas
    numero_restricciones = filas - 1
    return numero_variables, numero_restricciones, objetivo


def lectura_stdout_glpsol(stdout):#ahora para leer el stdout del glpsol y saber donde esta cada caja
    diccionario_posicion_valor = {}  
    for linea in stdout.splitlines():    #recorro el stdout linea linea y busco usando saltos de linea 
        trozos = linea.split()   # divido la linea por saltos de espacio en trozos
        if len(trozos) == 6 and trozos[0] == "ASIG": # ahora son 6 trozos porque el printf incluye tambien el pallet
            i = int(trozos[1]) 
            j = int(trozos[2])  
            z = int(trozos[3])
            t = int(trozos[4])
            k = int(trozos[5]) 
            diccionario_posicion_valor[(i, j, z, t)] = k # la clave lleva el pallet porque cada pallet tiene sus propias posiciones
    return diccionario_posicion_valor


def escribir_fichero_solucion(ruta_visual, l, h, diccionario_posicion_valor, prioridades, pesos, capacidades, objetivo):
    #  solo se dibujan los pallets que tienen alguna caja; los saco de las claves del diccionario (el 4º valor es el pallet)
    pallets_usados = sorted(set(clave[3] for clave in diccionario_posicion_valor))
    with open(ruta_visual, "w", encoding="utf-8") as f:#creo el fichero de la solucion
        f.write("Se puede entrar por fila superior, la pared es la fila 1. Las posiciones vacias aparecen como 'vacia'\n")
        f.write(f"Pallets usados: {len(pallets_usados)}\n")
        # bucle exterior por pallets; los numero 1, 2, 3... al dibujarlos aunque el solver haya usado otros numeros
        numero = 1
        for t in pallets_usados:
            f.write(f"\n========== Pallet {numero} ==========\n")
            for z in range(1, h + 1):
                f.write(f"\nNivel {z}\n")
                for i in range(l, 0, -1):  # empiezo por la fila mas alta como en el parte 1 y bajo 
                    celdas = []
                    for j in range(1, l + 1):
                        k = diccionario_posicion_valor.get((i, j, z, t)) #la caja que hay en cada casilla de este nivel y pallet
                        if k is None:
                            # si la posicion no esta en el diccionario es un hueco; la dejo del mismo ancho para que las columnas queden alineadas
                            celdas.append(f"[{'vacia':^20}]")
                        else:
                            celdas.append(f"[p={prioridades[k-1]:>4} w={pesos[k-1]:>4} y={capacidades[k-1]:>4}]")
                    f.write(f"Fila {i}: " + " ".join(celdas) + "\n") #escribo la celda entera en una fila
            numero = numero + 1
        f.write(f"\nCoste total: {objetivo:.4f}\n")  #ahora es el coste total, no el medio


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("Uso: ./sol-4.py fichero-entrada fichero-salida\n")
        sys.exit(1)

    ruta_entrada = resolver_ruta(sys.argv[1])
    ruta_dat = resolver_ruta(sys.argv[2])

    l, h, P, prioridades, pesos, capacidades = leer_entrada(ruta_entrada)  # ahora tambien devuelve P
    generar_dat(ruta_dat, l, h, P, prioridades, pesos, capacidades)        #  y se lo paso para escribirlo en el .dat

    ruta_sol, stdout = llamar_glpsol(ruta_dat)#llamo a glpsol y me devuelve la ruta del fichero de solucion y el stdout de glpsol
    numero_variables, numero_restricciones, objetivo = lectura_text_sol(ruta_sol)#leo el fichero de solucion y me devuelve las filas, columnas y objetivo
    diccionario_posicion_valor = lectura_stdout_glpsol(stdout)#leo el stdout de glpsol y me devuelve el diccionario

    print(f"{numero_variables} {numero_restricciones} {objetivo:.2f}") 

    ruta_visual = os.path.splitext(ruta_dat)[0] + "_solucion.txt"
    escribir_fichero_solucion(ruta_visual, l, h, diccionario_posicion_valor, prioridades, pesos, capacidades, objetivo)

    os.remove(ruta_sol)  # fichero intermedio de glpsol, no es un entregable


if __name__ == "__main__":
    main()