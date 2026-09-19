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
title Open WebUI
"%USERPROFILE%\.local\bin\open-webui.exe" serve --host 127.0.0.1 --port 3000
pause
