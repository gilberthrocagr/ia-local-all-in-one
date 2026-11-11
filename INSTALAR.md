# Instalar en otra máquina

Esta guía monta en otro PC lo que [LEEME.md](LEEME.md) describe en la máquina del autor
(RTX 1000 Ada de 6 GB, 64 GB de RAM DDR5-5600, Windows nativo sin WSL2 ni Docker). El repositorio solo trae
scripts y configuraciones: los programas y los modelos (~110 GB) se descargan aparte y
quedan fuera de git (`.gitignore`).

**Todo cuelga de `C:\AI`.** Los scripts, los `.vbs` y las configuraciones usan esa ruta.
Si instalas en otra, tendrás que cambiarla en todos ellos.

Las rutas, nombres de fichero y puertos de esta guía salen de los propios scripts.
Lo que viene de fuera (enlaces, comandos de instalación) está sacado de la documentación
oficial de cada proyecto; donde algo no se ha podido comprobar, se dice.

---

## 1. Requisitos

| Qué | Versión | Notas |
|---|---|---|
| GPU NVIDIA | probado en sm_89 (Ada) | Con otra arquitectura hay que recompilar llama.cpp para ella (paso 3) |
| Driver NVIDIA | rama R595 o posterior | Las notas de CUDA 13.2 no dan el mínimo para Windows; en Linux piden ≥ 595.45.04 |
| CUDA Toolkit | **13.2**, en su ruta por defecto | `start-qwen.cmd`, `start-qwen-mtp.cmd`, `build-llama.cmd` y `bench-*.ps1` usan `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2`. Con otra versión, cambia `v13.2` en ellos |
| Visual Studio 2022 Build Tools | 17.x, con «Desarrollo para el escritorio con C++» | `build-llama.cmd` carga `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat`. CUDA 13.2 admite VS 2022 17.x. `winget install -e --id Microsoft.VisualStudio.2022.BuildTools` no añade la carga de C++: elígela después en el Visual Studio Installer |
| CMake y Ninja | | Comprueba en una consola donde hayas ejecutado `vcvars64.bat` que `cmake --version` y `ninja --version` responden. Si no: `winget install Kitware.CMake` y `winget install Ninja-build.Ninja` |
| Git | | `winget install --id Git.Git -e` |
| uv | | `winget install --id=astral-sh.uv -e` (así lo instaló el autor) o el instalador oficial de uv |
| 7-Zip | | Para los `.7z` de ComfyUI y FramePack |
| Disco | ~110 GB libres | Modelo de lenguaje 22,4 GB, Z-Image 11,3 GB, FramePack ~30 GB, más las aplicaciones |

Windows PowerShell 5.1, el que trae Windows, basta para todos los `.ps1`.

## 2. Clonar el repositorio en `C:\AI`

```
git clone https://github.com/gilberthrocagr/ia-local-all-in-one.git C:\AI
```

## 3. llama.cpp (el motor)

```
git clone https://github.com/ggml-org/llama.cpp C:\AI\llama.cpp
C:\AI\build-llama.cmd
git -C C:\AI\llama.cpp rev-parse --short HEAD
```

- **Apunta el commit que compilas.** Los flags de llama.cpp cambian entre versiones
  (`--no-mmap --mlock`, por ejemplo, ya no existe). Los scripts usan `--n-cpu-moe`,
  `--load-mode mlock`, `--reasoning-budget`, `--spec-type draft-mtp` y
  `--spec-draft-n-max`. La rama `master` los tenía todos el 11-nov-2026.
- `build-llama.cmd` compila para `sm_89` (`-DCMAKE_CUDA_ARCHITECTURES=89`). Si tu GPU no
  es Ada, pon ahí su *compute capability* (NVIDIA la lista en
  https://developer.nvidia.com/cuda-gpus).
- El servidor queda en `C:\AI\llama.cpp\build\bin\llama-server.exe`, que es donde lo
  busca `start-qwen.cmd`.

## 4. El modelo (GGUF)

Carpeta: `C:\AI\models\llm\`

| Fichero | Para qué |
|---|---|
| `Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf` | El que usa `start-qwen.cmd` (variante con MTP) |
| `Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf` | Opcional: sin MTP. Lo usa `bench-contexto.ps1` y sirve para volver a la configuración sin MTP (ver LEEME) |

**Enlace de descarga: no comprobado.** Busca en Hugging Face cada nombre de fichero
exacto. Una búsqueda web indica que el repositorio `unsloth/Qwen3.6-35B-A3B-MTP-GGUF`
ofrece la cuantización `UD-Q4_K_XL` con MTP, pero esta guía no ha podido comprobar el
nombre exacto del fichero allí. Si el que descargas se llama distinto, renómbralo o
cambia `MODEL` en `start-qwen.cmd`.

Prueba: ejecuta `C:\AI\start-qwen.cmd`, espera a que cargue y abre
http://127.0.0.1:8080. Mientras carga, `http://127.0.0.1:8080/health` contesta 503;
cuando está listo, 200.

## 5. Imágenes: ComfyUI portable + Z-Image

1. Descarga el portable para NVIDIA que enlaza el README de ComfyUI:
   https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z
   (según ese README, ahora trae Python 3.13 y PyTorch con CUDA 13.0, y si no arranca hay
   que actualizar el driver).
2. Descomprímelo y deja como `C:\AI\ComfyUI` la carpeta que contiene `python_embeded\` y
   `ComfyUI\`. `start-comfy.cmd` ejecuta
   `C:\AI\ComfyUI\python_embeded\python.exe -s ComfyUI\main.py`.
3. Copia `C:\AI\configs\comfyui-extra_model_paths.yaml` a
   `C:\AI\ComfyUI\ComfyUI\extra_model_paths.yaml`. Así ComfyUI busca los modelos en
   `C:\AI\models`.
4. Descarga los tres ficheros de Z-Image:

| Fichero | Carpeta |
|---|---|
| [z_image_turbo_int8_convrot.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_int8_convrot.safetensors) | `C:\AI\models\image\diffusion_models\` |
| [qwen_3_4b_fp8_mixed.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b_fp8_mixed.safetensors) | `C:\AI\models\image\text_encoders\` |
| [ae.safetensors](https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors) | `C:\AI\models\image\vae\` |

   Los enlaces vienen de la nota «Model links» de la plantilla Z-Image Turbo de ComfyUI,
   guardada en `test-aider/cat_workflow.json`. Esa carpeta es un resto de las pruebas con
   Goose: la plantilla conserva su prompt de ejemplo (un retrato de moda), no el del gato.
5. Prueba: `C:\AI\start-comfy.cmd` y http://127.0.0.1:8188. Los ajustes que funcionan
   están en el LEEME (sección 4). También puedes mandar el flujo de prueba por la API,
   y la imagen aparece en `C:\AI\ComfyUI\ComfyUI\output\`:

```powershell
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8188/prompt -ContentType 'application/json' -InFile C:\AI\zimage-test.json
```

## 6. Vídeo: FramePack

1. Descarga el paquete de un clic para Windows que enlaza el README de FramePack:
   https://github.com/lllyasviel/FramePack/releases/download/windows/framepack_cu126_torch26.7z
2. Descomprímelo de forma que existan `C:\AI\FramePack\system\python\python.exe` y
   `C:\AI\FramePack\webui\demo_gradio.py`, que es lo que usa `start-framepack.cmd`.
3. Ejecuta su `update.bat` una vez (su README insiste en ello).
4. La primera vez que ejecutes `C:\AI\start-framepack.cmd` se descargan más de 30 GB de
   Hugging Face, a `C:\AI\models\video\hf-cache` (`HF_HOME` en el script).

## 7. Open WebUI, Aider y comfy-mcp (con uv)

```
uv tool install --python 3.12 open-webui
uv tool install --force --python python3.12 --with pip aider-chat@latest
uv tool install comfy-mcp --with "comfy-cli>=1.14.0"
uv tool update-shell
uv tool list
```

- Open WebUI pide Python ≥ 3.11 y < 3.13; su README usa 3.12. El comando de Aider es el
  de su documentación.
- comfy-mcp necesita comfy-cli ≥ 1.14.0 (lo dice su README en PyPI). Con `--with` queda
  dentro del entorno de comfy-mcp, y uv no copia los ejecutables de las dependencias a la
  carpeta de herramientas. Por eso el `config.yaml` de Goose le pasa la ruta de `comfy.exe`
  en `COMFY_BIN`. El README de comfy-mcp también pide que comfy-cli apunte a tu ComfyUI
  (`comfy set-default <ruta>`). Con el portable, la carpeta con `main.py` es
  `C:\AI\ComfyUI\ComfyUI`.
- uv deja los ejecutables en `%USERPROFILE%\.local\bin` (`uv tool dir --bin`), que es
  donde los buscan `start-openwebui.cmd` y `aider-qwen.cmd`. `uv tool update-shell` añade
  esa carpeta al `PATH`.
- `uv tool list` da las versiones instaladas: apúntalas.
- El servidor MCP de FramePack (`framepack-mcp.py`) no se instala: Goose lo lanza con
  `uv run --with mcp --with gradio_client --python 3.12`, y uv baja lo que falte la
  primera vez.

## 8. Goose (CLI y Desktop)

El proyecto está ahora en https://github.com/aaif-goose/goose (antes `block/goose`).

- **CLI:** descarga
  https://github.com/aaif-goose/goose/releases/download/stable/goose-x86_64-pc-windows-msvc.zip
  y descomprímelo en `C:\AI\tools\goose\`. El zip trae una carpeta `goose-package`, así
  que queda `C:\AI\tools\goose\goose-package\goose.exe`, que es lo que llama
  `goose-qwen.cmd`.
- **Desktop:** el ZIP portable,
  https://github.com/aaif-goose/goose/releases/download/stable/Goose-win32-x64.zip,
  descomprimido de forma que exista `C:\AI\GooseDesktop\Goose.exe`. El instalador
  (`Goose-win32-x64-setup.exe`) lo pondría en otra carpeta y los lanzadores no lo
  encontrarían.
- **Configuración:** con Goose cerrado, copia `C:\AI\configs\goose-config.yaml` a
  `%APPDATA%\Block\goose\config\config.yaml` y edita:
  - `comfyui` → `cmd`: la ruta de `comfy-mcp.exe`, en la carpeta que da `uv tool dir --bin`.
  - `comfyui` → `COMFY_BIN`: `comfy.exe`, en la carpeta que da `uv tool dir`, más
    `\comfy-mcp\Scripts\comfy.exe`.
  - `framepack` → `cmd`: la ruta de tu `uv.exe`, que da `(Get-Command uv).Source` en
    PowerShell. La del fichero es la de uv instalado con winget en la máquina del autor.

  Las que llevan `<TU_USUARIO>` son las rutas del autor con el usuario quitado. Guarda el
  fichero como **UTF-8 sin BOM** (en el Bloc de notas, «UTF-8», no «UTF-8 con BOM»):
  con BOM, Goose dice «No provider configured» (ver LEEME).
- **API key:** Goose no lee la clave del proveedor desde `config.yaml`. `goose-qwen.cmd` la
  pasa por `OPENAI_API_KEY` al CLI. Para Goose Desktop, guarda cualquier valor con
  `C:\AI\tools\goose\goose-package\goose.exe configure`: el servidor local no la comprueba.
- La plantilla viene con el **perfil ligero** (solo `developer`). Las imágenes y el vídeo
  están en el perfil completo: `goose-perfil.ps1 -Perfil completo`. El LEEME explica por
  qué el completo es mucho más lento.

## 9. Accesos directos del escritorio

Los accesos llaman a los `.vbs` con `wscript.exe` (sin ventanas de consola). Estos
nombres son los que esperan `probar-lanzadores.ps1` y `probar-todo.ps1`. Pégalo en una
ventana de PowerShell:

```powershell
$ws   = New-Object -ComObject WScript.Shell
$desk = [Environment]::GetFolderPath('Desktop')
New-Item -ItemType Directory -Force -Path (Join-Path $desk 'IA Local') | Out-Null
$accesos = [ordered]@{
    'IA - Todo en uno'                         = 'ia-goose-codigo.vbs'
    'IA - Goose completo (lento)'              = 'ia-goose-completo.vbs'
    'IA - Chat y documentos'                   = 'ia-openwebui.vbs'
    'IA - Imagenes'                            = 'ia-imagenes.vbs'
    'IA - Video'                               = 'ia-video.vbs'
    'IA Local\0 - TODO EN UNO (Goose Desktop)' = 'ia-goose.vbs'
    'IA Local\1 - Chat unificado (Open WebUI)' = 'ia-openwebui.vbs'
    'IA Local\2 - Chat simple (llama.cpp)'     = 'ia-chat.vbs'
    'IA Local\3 - Programar (Aider)'           = 'ia-aider.vbs'
    'IA Local\4 - Agente (Goose)'              = 'ia-goosecli.vbs'
    'IA Local\5 - Imagenes (ComfyUI)'          = 'ia-imagenes.vbs'
    'IA Local\6 - Video (FramePack)'           = 'ia-video.vbs'
}
foreach ($nombre in $accesos.Keys) {
    $l = $ws.CreateShortcut((Join-Path $desk "$nombre.lnk"))
    $l.TargetPath       = "$env:WINDIR\System32\wscript.exe"
    $l.Arguments        = '"C:\AI\' + $accesos[$nombre] + '"'
    $l.WorkingDirectory = 'C:\AI'
    $l.Save()
}
```

| `.vbs` | Qué hace |
|---|---|
| `ia-goose-codigo.vbs` | Pone Goose en el perfil ligero, arranca el modelo y abre Goose Desktop |
| `ia-goose-completo.vbs` | Igual con el perfil completo, y arranca también ComfyUI |
| `ia-goose.vbs` | Abre Goose Desktop con el perfil que tenga el `config.yaml`, con modelo y ComfyUI |
| `ia-openwebui.vbs` | Modelo + ComfyUI + Open WebUI → http://127.0.0.1:3000 |
| `ia-chat.vbs` | Modelo → http://127.0.0.1:8080 |
| `ia-aider.vbs` | Modelo + una consola con las instrucciones para Aider |
| `ia-goosecli.vbs` | Modelo + Goose en una consola |
| `ia-imagenes.vbs` | ComfyUI → http://127.0.0.1:8188 |
| `ia-video.vbs` | Pide confirmación, cierra el modelo y ComfyUI, y abre FramePack → http://127.0.0.1:7860 |

Si cambias algo de los `.vbs`, cámbialo en `generar-vbs.py` y vuelve a generarlos
(`python C:\AI\generar-vbs.py`).

## 10. Comprobar que todo arranca

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\AI\probar-todo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File C:\AI\probar-lanzadores.ps1
```

- **Antes de cada prueba paran todos los servicios** (llama-server, Open WebUI,
  ComfyUI, FramePack y Goose). No los lances con trabajo a medias.
- `probar-todo.ps1` prueba la carpeta «IA Local» salvo «6 - Video», que pide confirmación.
  La consola de Aider que abre se queda abierta: ciérrala a mano.
- `probar-lanzadores.ps1` prueba los tres accesos sueltos («IA - Imagenes», «IA - Chat y
  documentos» e «IA - Todo en uno»). El último deja Goose en el perfil ligero.
- Arrancar no es funcionar: la verificación funcional de cada pieza (que el modelo
  conteste, que ComfyUI guarde un PNG, que Aider edite un fichero...) está descrita en el
  LEEME.
- **Windows Defender** puede bloquear un `.ps1` con el aviso «Este script contiene
  elementos malintencionados». Ya pasó con un script que juntaba peticiones HTTP,
  arranque de procesos y escritura de ficheros (ver LEEME). Si te pasa, mira qué fichero
  es antes de añadir excepciones.

## 11. Seguridad

Todos los servicios escuchan solo en `127.0.0.1`. Open WebUI entra sin contraseña y
llama-server no tiene API key: el README explica qué implica y cómo cerrarlo.
