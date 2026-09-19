@echo off
REM ===== Compilacion de llama.cpp con CUDA para RTX 1000 Ada (sm_89) =====
REM Para ThinkPad P16v Gen 2 (RTX 1000 Ada, 6 GB VRAM)
setlocal

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 ( echo ERROR: no se pudo cargar el entorno de MSVC & exit /b 1 )

set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2"
set "PATH=%CUDA_PATH%\bin;%PATH%"

cd /d C:\AI\llama.cpp

cmake -B build -S . -G Ninja ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DGGML_CUDA=ON ^
  -DCMAKE_CUDA_ARCHITECTURES=89 ^
  -DGGML_CUDA_NCCL=OFF ^
  -DGGML_CUDA_GRAPHS=ON ^
  -DLLAMA_BUILD_TESTS=OFF ^
  -DLLAMA_BUILD_EXAMPLES=OFF ^
  -DLLAMA_BUILD_TOOLS=ON ^
  -DLLAMA_BUILD_SERVER=ON
if errorlevel 1 ( echo ERROR en la configuracion de cmake & exit /b 1 )

cmake --build build --config Release
if errorlevel 1 ( echo ERROR en la compilacion & exit /b 1 )

echo.
echo ===== COMPILACION TERMINADA =====
dir /b build\bin\llama-server.exe build\bin\llama-bench.exe build\bin\llama-fit-params.exe
