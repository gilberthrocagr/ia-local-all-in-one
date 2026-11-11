@echo off
title Abriendo Goose Desktop...
REM ===== Goose Desktop: chat + agente de codigo + imagenes en una ventana =====
REM Hace lo mismo que el acceso "0 - TODO EN UNO": lanzador.ps1 arranca lo que haga
REM falta y espera a que el modelo responda (/health) antes de abrir nada.
REM Antes esperaba 20 s a ciegas y a veces abria antes de que el modelo cargara.
REM Arranca tambien ComfyUI. Abre Goose con el perfil que tenga su config.yaml.
echo Arrancando Qwen3.6 y ComfyUI. Goose Desktop se abrira cuando el modelo
echo responda. La primera carga puede tardar hasta 3 minutos...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AI\lanzador.ps1" -App goose
exit
