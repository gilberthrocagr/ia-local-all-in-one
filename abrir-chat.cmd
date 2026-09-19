@echo off
title Abriendo chat...
tasklist /FI "IMAGENAME eq llama-server.exe" 2>NUL | find /I "llama-server.exe" >NUL
if errorlevel 1 (
  echo Arrancando Qwen3.6, espera unos 20 segundos...
  start "Servidor Qwen3.6 - NO CERRAR" cmd /c C:\AI\start-qwen.cmd
  timeout /t 20 /nobreak >NUL
)
start http://127.0.0.1:8080
exit
