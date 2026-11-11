@echo off
REM ===== Open WebUI: interfaz unificada (chat + imagenes + documentos) =====
REM Puerto 3000 porque el 8080 lo usa llama-server.
REM Solo escucha en 127.0.0.1: no accesible desde la red.
setlocal
set "DATA_DIR=C:\AI\openwebui-data"
set "OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1"
set "OPENAI_API_KEY=local-no-auth"
set "ENABLE_OLLAMA_API=False"
set "WEBUI_AUTH=False"
set "HOST=127.0.0.1"
set "PORT=3000"
REM Open WebUI guarda su clave (.webui_secret_key) en la carpeta desde la que
REM arranca. Se arranca desde DATA_DIR para que quede ahi, fuera de git.
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
cd /d "%DATA_DIR%"
title Open WebUI
"%USERPROFILE%\.local\bin\open-webui.exe" serve --host 127.0.0.1 --port 3000
pause
