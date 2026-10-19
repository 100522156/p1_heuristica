#!/usr/bin/env python3
#sol-1.py Miguel Merino 100522156 , Pablo García 100522190
import os, re, subprocess, sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))# para tener la ruta de sol-1.py
MODEL_FILE = os.path.join(SCRIPT_DIR, "parte-1.mod")#para unir con la otra ruta 


def resolver_ruta(ruta):
    #creo una funcion por si tiene ruta absoluta si no tiene le pongo la ruta del sol-1.py 
    if os.path.isabs(ruta) or os.path.dirname(ruta):
        return ruta
    return os.path.join(SCRIPT_DIR, ruta)


def leer_entrada(ruta_entrada):
    with open(ruta_entrada, encoding="utf-8") as f:
        lineas = []    
        for linea in f:      
            if linea.strip():    
                lineas.append(linea.strip())  # se guarda sin espacios ni saltos de linea

    l = int(lineas[0])
    prioridades = list(map(int, lineas[1].split())) #divido en unsa lista de enteros cambiandolos con el map a int
    if len(prioridades) != l * l: #compruebo que la cantidad de cajas sea la correcta 
        raise ValueError(f"Se esperaban {l*l} prioridades, hay {len(prioridades)}")
    return l, prioridades 


def generar_dat(ruta_dat, l, prioridades):
    filas = " ".join(str(i) for i in range(1, l + 1))   
    cajas = " ".join(str(k) for k in range(1, l * l + 1))
    with open(ruta_dat, "w", encoding="utf-8") as f: #creo el fichero dat y escribo todo
        f.write("data;\n\n")
        f.write(f"param l := {l};\n\n")
        f.write(f"set FILA := {filas};\n")
        f.write(f"set COL := {filas};\n")
        f.write(f"set CAJA := {cajas};\n\n")
        f.write("param p :=\n")
        k = 1      
        for p in prioridades:  
            f.write(f"{k} {p}\n")   # escribe el numero de cada caja y prioridad
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
    return numero_variables, numero_restricciones, objetivo#deuelvo las filas, columnas y objetivo


def lectura_stdout_glpsol(stdout):#ahora para leer el stdout del glpsol y saber donde esta cada caja
    diccionario_posicion_valor = {}  
    for linea in stdout.splitlines():    #recorro el stdout linea linea y busco usando saltos de linea 
        trozos = linea.split()   # divido la linea por saltos de espacio en trozos
        if len(trozos) == 4 and trozos[0] == "ASIG": #busco el asig y los tres valores de despues
            i = int(trozos[1]) 
            j = int(trozos[2])  
            k = int(trozos[3]) 
            diccionario_posicion_valor[(i, j)] = k #y lo guardo en el diccionario con clave la posicion y valor la caja
    return diccionario_posicion_valor


def escribir_fichero_solucion(ruta_visual, l, diccionario_posicion_valor, prioridades, objetivo):
    with open(ruta_visual, "w", encoding="utf-8") as f:#creo el fichero de la solucion
        f.write("Se puede entrar por fila superior, la pared es la fila 1\n\n")
        for i in range(l, 0, -1):
            celdas = []
            for j in range(1, l + 1):
                k = diccionario_posicion_valor.get((i, j)) #la caja que hay en cada casilla 
                p = prioridades[k - 1] 
                celdas.append(f"[p={p:>4}]") #imprimo y dejo 4 espacios 
            f.write(f"Fila {i}: " + " ".join(celdas) + "\n") #escribo la celda entera en una fila
        f.write(f"\nCoste medio: {objetivo:.4f}\n")


def main():
    if len(sys.argv) != 3:
        sys.stderr.write("Uso: ./sol-1.py fichero-entrada fichero-salida\n")
        sys.exit(1)

    ruta_entrada = resolver_ruta(sys.argv[1])
    ruta_dat = resolver_ruta(sys.argv[2])

    l, prioridades = leer_entrada(ruta_entrada)#leo la entrada y me devuelve el tamaño y las prioridades de las cajas
    generar_dat(ruta_dat, l, prioridades)

    ruta_sol, stdout = llamar_glpsol(ruta_dat)#llamo a glpsol y me devuelve la ruta del fichero de solucion y el stdout de glpsol
    numero_variables, numero_restricciones, objetivo = lectura_text_sol(ruta_sol)#leo el fichero de solucion y me devuelve las filas, columnas y objetivo
    diccionario_posicion_valor = lectura_stdout_glpsol(stdout)#leo el stdout de glpsol y me devuelve el diccionario

    print(f"{numero_variables} {numero_restricciones} {objetivo:.2f}") 

    ruta_visual = os.path.splitext(ruta_dat)[0] + "_solucion.txt"
    escribir_fichero_solucion(ruta_visual, l, diccionario_posicion_valor, prioridades, objetivo)

    os.remove(ruta_sol)  # fichero intermedio de glpsol, no es un entregable


if __name__ == "__main__":
    main()