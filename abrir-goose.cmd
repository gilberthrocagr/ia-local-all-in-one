@echo off
title Goose - agente con Qwen3.6
REM Hace lo mismo que el acceso "4 - Agente (Goose)": lanzador.ps1 arranca lo que haga
REM falta y espera a que el modelo responda (/health) antes de abrir nada.
REM Antes esperaba 20 s a ciegas y a veces abria antes de que el modelo cargara.
echo Arrancando Qwen3.6. Goose se abrira en otra ventana cuando el modelo
echo responda. La primera carga puede tardar hasta 3 minutos...
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\AI\lanzador.ps1" -App goosecli
exit
