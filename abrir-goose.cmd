@echo off
title Goose - agente con Qwen3.6
tasklist /FI "IMAGENAME eq llama-server.exe" 2>NUL | find /I "llama-server.exe" >NUL
if errorlevel 1 (
  echo Arrancando Qwen3.6, espera unos 20 segundos...
  start "Servidor Qwen3.6 - NO CERRAR" cmd /c C:\AI\start-qwen.cmd
  timeout /t 20 /nobreak >NUL
)
C:\AI\goose-qwen.cmd session
pause
