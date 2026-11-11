@echo off
title Abriendo FramePack...
echo.
echo  ATENCION: el video necesita la GPU entera (6 GB).
echo  Se va a cerrar el chat (llama-server) si esta abierto.
echo  ComfyUI NO se cierra solo: si esta abierto, cierra su ventana antes.
echo  (El acceso "IA - Video" si cierra los dos.)
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
