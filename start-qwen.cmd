@echo off
REM ===== Servidor Qwen3.6-35B-A3B  -  llama.cpp CUDA  -  RTX 1000 Ada 6GB =====
REM
REM MEDIDO en esta maquina (18-19 sep 2026), peticiones reales:
REM   sin MTP      : 28.20 tok/s
REM   MTP n-max 2  : 36.59 tok/s   <-- ESTA CONFIGURACION (+29.8%)
REM   MTP n-max 3  : 35.32 tok/s
REM   MTP n-max 4  : 30.28 tok/s
REM   MTP n-max 5  : 27.78 tok/s   (peor que sin MTP)
REM Subir --spec-draft-n-max empeora y gasta mas VRAM. No lo toques.
REM
REM --n-cpu-moe 99 es el OPTIMO: bajarlo a 40 empeora un 12%.
REM --no-mmap --mlock ya no existen; su equivalente es --load-mode mlock.
REM En CUDA 13.x las DLLs de runtime estan en bin\x64, no en bin.
REM
REM Si quieres volver al modelo sin MTP (950 MB menos de VRAM), cambia
REM MODEL por Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf y quita las dos lineas --spec-*
setlocal

set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin\x64;%PATH%"
set "MODEL=C:\AI\models\llm\Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf"
set "BIN=C:\AI\llama.cpp\build\bin\llama-server.exe"

if not exist "%BIN%"   ( echo ERROR: falta llama-server.exe, compila primero & exit /b 1 )
if not exist "%MODEL%" ( echo ERROR: falta el modelo GGUF & exit /b 1 )

"%BIN%" -m "%MODEL%" ^
  --n-cpu-moe 99 --n-gpu-layers 99 ^
  --flash-attn on -ctk q8_0 -ctv q8_0 ^
  -c 65536 -b 512 -ub 128 ^
  --load-mode mlock --jinja -a qwen3.6 ^
  --reasoning-budget 1500 ^
  --spec-type draft-mtp --spec-draft-n-max 2 ^
  --temp 0.6 --top-p 0.95 --top-k 20 ^
  --host 127.0.0.1 --port 8080
