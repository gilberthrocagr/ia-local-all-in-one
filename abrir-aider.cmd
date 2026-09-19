@echo off
title Aider - programar con Qwen3.6
tasklist /FI "IMAGENAME eq llama-server.exe" 2>NUL | find /I "llama-server.exe" >NUL
if errorlevel 1 (
  echo Arrancando Qwen3.6, espera unos 20 segundos...
  start "Servidor Qwen3.6 - NO CERRAR" cmd /c C:\AI\start-qwen.cmd
  timeout /t 20 /nobreak >NUL
)
echo.
echo  Estas en Aider. Primero ve a tu proyecto, por ejemplo:
echo     cd C:\ruta\de\tu\proyecto
echo  y luego ejecuta:  C:\AI\aider-qwen.cmd
echo.
cmd /k
