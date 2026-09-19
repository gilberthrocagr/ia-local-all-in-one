@echo off
REM ===== ComfyUI portable  -  RTX 1000 Ada 6GB =====
REM Usa run_nvidia_gpu normal, NO el _fast_fp16_accumulation:
REM el modo "fast" con pesos fp8 produce salidas corruptas (issue #9190).
REM Modelos en C:\AI\models (ver ComfyUI\extra_model_paths.yaml).
REM
REM --vram-headroom 0.5 : obliga a ComfyUI a dejar siempre 0.5 GB de VRAM
REM libre CONTANDO lo que usan otras apps (el LLM del puerto 8080). Sin esto
REM el pico medido llegaba al 94% de la VRAM y Windows podia desbordar a RAM
REM en silencio, con penalizacion de 30-100x invisible en los logs.
pushd C:\AI\ComfyUI
.\python_embeded\python.exe -s ComfyUI\main.py --windows-standalone-build --port 8188 --vram-headroom 0.5
popd
