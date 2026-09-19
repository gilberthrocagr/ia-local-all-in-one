@echo off
title Abriendo ComfyUI...
netstat -an | find "127.0.0.1:8188" >NUL
if errorlevel 1 (
  echo Arrancando ComfyUI, espera unos 25 segundos...
  start "ComfyUI - NO CERRAR" cmd /c C:\AI\start-comfy.cmd
  timeout /t 25 /nobreak >NUL
)
start http://127.0.0.1:8188
exit
