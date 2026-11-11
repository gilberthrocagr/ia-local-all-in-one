"""Genera los lanzadores .vbs con las comillas escapadas como exige VBScript.

Escribe los nueve .vbs en la carpeta de este fichero (C:\\AI en la
instalacion documentada). Dentro de cada .vbs la ruta del script de
PowerShell es C:\\AI\\..., porque los accesos directos los lanzan desde
cualquier sitio.

Uso:  python generar-vbs.py
"""
import os

CARPETA = os.path.dirname(os.path.abspath(__file__))

# nombre del .vbs -> (script de PowerShell en C:\AI, argumentos)
LANZADORES = {
    "ia-chat": ("lanzador.ps1", "-App chat"),
    "ia-openwebui": ("lanzador.ps1", "-App openwebui"),
    "ia-imagenes": ("lanzador.ps1", "-App imagenes"),
    "ia-goose": ("lanzador.ps1", "-App goose"),
    "ia-video": ("lanzador.ps1", "-App video"),
    "ia-aider": ("lanzador.ps1", "-App aider"),
    "ia-goosecli": ("lanzador.ps1", "-App goosecli"),
    "ia-goose-codigo": ("goose-perfil.ps1", "-Perfil codigo -Abrir"),
    "ia-goose-completo": ("goose-perfil.ps1", "-Perfil completo -Abrir"),
}

# En VBScript, una comilla doble dentro de un string se escribe duplicada: ""
# Se rellena con replace() y marcadores que no aparecen en el resto de la
# linea: un reemplazo de palabras sueltas ya rompio estos .vbs una vez
# ('-Perfil' acabo convertido en '-codigo').
PLANTILLA = (
    "' Lanza la IA sin mostrar ninguna ventana de consola.\r\n"
    "' Generado por generar-vbs.py - no editar a mano.\r\n"
    'CreateObject("WScript.Shell").Run '
    '"powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden '
    '-File ""C:\\AI\\@@SCRIPT@@"" @@ARGS@@", 0, False\r\n'
)


def contenido(script, args):
    return PLANTILLA.replace("@@SCRIPT@@", script).replace("@@ARGS@@", args)


for nombre, (script, args) in LANZADORES.items():
    ruta = os.path.join(CARPETA, nombre + ".vbs")
    with open(ruta, "w", encoding="ascii", newline="") as f:
        f.write(contenido(script, args))
    print("generado: {}.vbs  -> {} {}".format(nombre, script, args))

print()
print("=== COMPROBACION DE SINTAXIS ===")
for nombre, (script, args) in LANZADORES.items():
    ruta = os.path.join(CARPETA, nombre + ".vbs")
    with open(ruta, encoding="ascii", newline="") as f:
        linea = [l for l in f if l.startswith("CreateObject")][0]
    # las comillas deben ser pares, las internas dobles, y el script existir
    comillas = linea.count('"')
    ok = (comillas % 2 == 0
          and '""C:\\AI\\' + script + '""' in linea
          and os.path.isfile(os.path.join(CARPETA, script)))
    print("  {}: {}".format(nombre, "OK" if ok else "MAL"))
