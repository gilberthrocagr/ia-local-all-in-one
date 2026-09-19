@echo off
title Abriendo Open WebUI...
tasklist /FI "IMAGENAME eq llama-server.exe" 2>NUL | find /I "llama-server.exe" >NUL
if errorlevel 1 (
  echo Arrancando Qwen3.6, espera unos 20 segundos...
  start "Servidor Qwen3.6 - NO CERRAR" cmd /c C:\AI\start-qwen.cmd
  timeout /t 20 /nobreak >NUL
)
tasklist /FI "IMAGENAME eq open-webui.exe" 2>NUL | find /I "open-webui.exe" >NUL
if errorlevel 1 (
  echo Arrancando Open WebUI, espera unos 30 segundos...
  start "Open WebUI - NO CERRAR" cmd /c C:\AI\start-openwebui.cmd
  timeout /t 30 /nobreak >NUL
)
start http://127.0.0.1:3000
exit
