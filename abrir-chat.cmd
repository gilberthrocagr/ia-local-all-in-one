@echo off
title Abriendo chat...
REM Hace lo mismo que el acceso "2 - Chat simple": lanzador.ps1 arranca lo que haga
REM falta y espera a que el modelo responda (/health) antes de abrir nada.
REM Antes esperaba 20 s a ciegas y a veces abria antes de que el modelo cargara.
echo Arrancando Qwen3.6. El navegador se abrira cuando el modelo responda.
echo La primera carga puede tardar hasta 3 minutos...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AI\lanzador.ps1" -App chat
exit
