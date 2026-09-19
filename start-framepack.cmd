@echo off
REM ===== FramePack  -  video en 6 GB de VRAM  -  RTX 1000 Ada =====
REM LTX-2 NO cabe en esta maquina: necesita ~24 GB (Gemma 3 12B + difusor 22B).
REM FramePack declara 6 GB minimo y esta pensado para portatiles.
REM OJO: parar llama-server y ComfyUI antes, no caben los tres en 6 GB.
REM Modelos en C:\AI\models\video\hf-cache (no en el perfil de usuario).
setlocal

set "HF_HOME=C:\AI\models\video\hf-cache"
set "HUGGINGFACE_HUB_CACHE=C:\AI\models\video\hf-cache"
set "SKIP_VENV=1"
set "DIR=C:\AI\FramePack\system"
set "PATH=%DIR%\python;%DIR%\python\Scripts;%DIR%\git\bin;%PATH%"

cd /d C:\AI\FramePack\webui
"%DIR%\python\python.exe" demo_gradio.py --server 127.0.0.1 --port 7860
pause
