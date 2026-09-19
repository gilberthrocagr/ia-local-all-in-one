@echo off
REM ===== PRUEBA: Qwen3.6-35B-A3B con MTP / speculative decoding =====
REM Identico a start-qwen.cmd salvo el modelo (variante MTP) y los flags
REM --spec-type draft-mtp --spec-draft-n-max 2
REM Baseline a batir: 28.20 tok/s
setlocal

set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin\x64;%PATH%"
set "MODEL=C:\AI\models\llm\Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf"
set "BIN=C:\AI\llama.cpp\build\bin\llama-server.exe"

"%BIN%" -m "%MODEL%" ^
  --n-cpu-moe 99 --n-gpu-layers 99 ^
  --flash-attn on -ctk q8_0 -ctv q8_0 ^
  -c 65536 -b 512 -ub 128 ^
  --load-mode mlock --jinja -a qwen3.6 ^
  --reasoning-budget 1500 ^
  --spec-type draft-mtp --spec-draft-n-max 2 ^
  --temp 0.6 --top-p 0.95 --top-k 20 ^
  --host 127.0.0.1 --port 8080
