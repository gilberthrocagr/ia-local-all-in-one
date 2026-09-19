"""Genera los lanzadores .vbs con las comillas escapadas como exige VBScript."""
import io

APPS = {
    "ia-chat": "chat",
    "ia-openwebui": "openwebui",
    "ia-imagenes": "imagenes",
    "ia-goose": "goose",
    "ia-video": "video",
    "ia-aider": "aider",
}

# En VBScript, una comilla doble dentro de un string se escribe duplicada: ""
PLANTILLA = (
    "' Lanza la IA sin mostrar ninguna ventana de consola.\r\n"
    "' Generado por generar-vbs.py - no editar a mano.\r\n"
    'CreateObject("WScript.Shell").Run '
    '"powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden '
    '-File ""C:\\AI\\lanzador.ps1"" -App {app}", 0, False\r\n'
)

for nombre, app in APPS.items():
    ruta = r"C:\AI\{}.vbs".format(nombre)
    with io.open(ruta, "w", encoding="ascii", newline="") as f:
        f.write(PLANTILLA.format(app=app))
    print("generado: {}.vbs  -> -App {}".format(nombre, app))

print()
print("=== COMPROBACION DE SINTAXIS ===")
for nombre in APPS:
    ruta = r"C:\AI\{}.vbs".format(nombre)
    with io.open(ruta, encoding="ascii") as f:
        linea = [l for l in f if l.startswith("CreateObject")][0]
    # las comillas deben ser pares y las internas dobles
    comillas = linea.count('"')
    ok = comillas % 2 == 0 and '""C:\\AI\\lanzador.ps1""' in linea
    print("  {}: {}".format(nombre, "OK" if ok else "MAL"))
