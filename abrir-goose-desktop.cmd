@echo off
title Abriendo Goose Desktop...
REM ===== Goose Desktop: chat + agente de codigo + imagenes en una ventana =====
REM Arranca el LLM si no esta corriendo, y ComfyUI para que funcionen las imagenes.
tasklist /FI "IMAGENAME eq llama-server.exe" 2>NUL | find /I "llama-server.exe" >NUL
if errorlevel 1 (
  echo Arrancando Qwen3.6, espera unos 20 segundos...
  start "Servidor Qwen3.6 - NO CERRAR" cmd /c C:\AI\start-qwen.cmd
  timeout /t 20 /nobreak >NUL
)
netstat -an | find "127.0.0.1:8188" >NUL
if errorlevel 1 (
  echo Arrancando ComfyUI para las imagenes...
  start "ComfyUI - NO CERRAR" cmd /c C:\AI\start-comfy.cmd
  timeout /t 15 /nobreak >NUL
)
start "" "C:\AI\GooseDesktop\Goose.exe"
exit
