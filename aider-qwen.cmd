@echo off
REM ===== Aider contra Qwen3.6-35B-A3B local (llama.cpp en 127.0.0.1:8080) =====
REM Uso: abre una terminal en tu proyecto y ejecuta  C:\AI\aider-qwen.cmd
REM El servidor debe estar corriendo (C:\AI\start-qwen.cmd).
setlocal

set "PATH=%USERPROFILE%\.local\bin;%PATH%"
set "OPENAI_API_BASE=http://127.0.0.1:8080/v1"
set "OPENAI_API_KEY=local-no-auth"
set "AIDER_MODEL=openai/qwen3.6"
set "AIDER_MODEL_METADATA_FILE=C:\AI\.aider.model.metadata.json"
set "AIDER_EDIT_FORMAT=diff"
set "AIDER_AUTO_COMMITS=false"
set "AIDER_SHOW_MODEL_WARNINGS=false"

aider %*
