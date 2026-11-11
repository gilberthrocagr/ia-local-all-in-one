@echo off
title Abriendo Open WebUI...
REM Hace lo mismo que el acceso "1 - Chat unificado": lanzador.ps1 arranca lo que haga
REM falta y espera a que el modelo responda (/health) antes de abrir nada.
REM Antes esperaba 20 s a ciegas y a veces abria antes de que el modelo cargara.
REM Tambien arranca ComfyUI, para que funcionen las imagenes dentro de Open WebUI.
echo Arrancando Qwen3.6, ComfyUI y Open WebUI. El navegador se abrira cuando
echo todo responda. La primera vez puede tardar unos minutos...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AI\lanzador.ps1" -App openwebui
exit
