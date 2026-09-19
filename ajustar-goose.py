"""Apaga las extensiones de Goose que no se usan.

Cada extension activa mete las definiciones de sus herramientas en el prompt
del sistema EN CADA MENSAJE. Con 12 activas, el prompt era tan grande que
responder 'hola' tardaba 314 segundos en esta maquina.

Se dejan solo:
  developer  -> editar ficheros y ejecutar comandos (el nucleo del agente)
  comfyui    -> generar imagenes con Z-Image
  framepack  -> generar video
"""
import io
import re

CFG = r"C:\Users\gilbe\AppData\Roaming\Block\goose\config\config.yaml"

MANTENER = {"developer", "comfyui", "framepack"}

with io.open(CFG, encoding="utf-8") as f:
    lineas = f.readlines()

salida = []
extension_actual = None
cambiadas = []

for linea in lineas:
    m = re.match(r"^  (\w+):\s*$", linea)
    if m:
        extension_actual = m.group(1)

    if extension_actual and re.match(r"^    enabled: true\s*$", linea):
        if extension_actual not in MANTENER:
            linea = "    enabled: false\n"
            cambiadas.append(extension_actual)
        extension_actual = None
    elif extension_actual and re.match(r"^    enabled: false\s*$", linea):
        extension_actual = None

    salida.append(linea)

with io.open(CFG, "w", encoding="utf-8", newline="") as f:
    f.writelines(salida)

print("apagadas ({}): {}".format(len(cambiadas), ", ".join(cambiadas)))
print()

# Comprobacion
with io.open(CFG, encoding="utf-8") as f:
    lineas = f.readlines()
actual = None
activas = []
for l in lineas:
    m = re.match(r"^  (\w+):\s*$", l)
    if m:
        actual = m.group(1)
    if actual and re.match(r"^    enabled: true", l):
        activas.append(actual)
        actual = None
    elif actual and re.match(r"^    enabled: false", l):
        actual = None

print("ACTIVAS AHORA ({}): {}".format(len(activas), ", ".join(activas)))
