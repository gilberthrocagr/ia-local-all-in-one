@echo off
REM ===== Goose contra Qwen3.6-35B-A3B local (llama.cpp en 127.0.0.1:8080) =====
REM Uso: C:\AI\goose-qwen.cmd session      (chat interactivo)
REM      C:\AI\goose-qwen.cmd run -t "tarea"
REM El servidor debe estar corriendo (C:\AI\start-qwen.cmd).
setlocal
set "OPENAI_API_KEY=local-no-auth"
"C:\AI\tools\goose\goose-package\goose.exe" %*
