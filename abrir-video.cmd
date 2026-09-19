@echo off
title Abriendo FramePack...
echo.
echo  ATENCION: el video necesita la GPU entera (6 GB).
echo  Se van a cerrar el chat y ComfyUI si estan abiertos.
echo.
pause
taskkill /IM llama-server.exe /F >NUL 2>&1
netstat -an | find "127.0.0.1:7860" >NUL
if errorlevel 1 (
  echo Arrancando FramePack, la primera vez tarda varios minutos...
  start "FramePack - NO CERRAR" cmd /c C:\AI\start-framepack.cmd
  timeout /t 60 /nobreak >NUL
)
start http://127.0.0.1:7860
exit
