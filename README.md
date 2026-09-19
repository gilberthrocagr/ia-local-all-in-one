# IA local completa en una GPU de 6 GB

Instalación funcionando de un stack de IA **100% local y open source** en un portátil
con una **NVIDIA RTX 1000 Ada de 6 GB de VRAM** (ThinkPad P16v Gen 2, Core Ultra 7 155H,
64 GB de RAM). Windows nativo, sin WSL2 ni Docker.

Este repositorio contiene **los scripts y configuraciones**, no los modelos: son 110 GB
descargables y quedan fuera (ver `.gitignore`).

La guía de uso completa está en **[LEEME.md](LEEME.md)**.

## Qué incluye

| Capa | Qué se usa | Rendimiento medido |
|---|---|---|
| **Motor** | llama.cpp compilado con CUDA (sm_89) | — |
| **Modelo** | Qwen3.6-35B-A3B (MoE, ~3B activos) GGUF Q4_K_XL | **35-37 tok/s** |
| **Código** | Aider | 32/33 tests en el banco de pruebas |
| **Agente** | Goose (CLI y Desktop) | — |
| **Imágenes** | ComfyUI portable + Z-Image Turbo INT8 | **14,3 s** por imagen 1024² |
| **Vídeo** | FramePack (con servidor MCP propio) | 10,5 min por segundo |
| **Interfaz** | Open WebUI y Goose Desktop | — |

## La idea clave: MoE con expertos en RAM

Con 6 GB de VRAM no cabe un modelo denso decente. La solución es un modelo **MoE**
con pocos parámetros activos y **volcar los expertos a la RAM del sistema**:

```
llama-server --n-cpu-moe 99 --n-gpu-layers 99 --flash-attn on -ctk q8_0 -ctv q8_0
```

Eso deja en la GPU solo la atención y las capas densas. El cuello de botella pasa a ser
el ancho de banda de la RAM (DDR5-5600 en dual channel), no la VRAM.

## Hallazgos medidos que contradicen lo que suele leerse

- **`--n-cpu-moe` no se afina hacia abajo.** Bajarlo de 99 a 40 empeora un **12%**.
  El valor conservador ya es el óptimo en esta máquina.
- **MTP (speculative decoding) sí funciona aquí: +29,8%**... pero solo con contexto
  corto. **A partir de 16K tokens la ventaja desaparece.** Hay tests publicados donde
  MTP sale peor que el baseline; hay que medirlo en cada máquina.
- **`--no-mmap --mlock` ya no existe** en llama.cpp: ahora es `--load-mode mlock`.
- **En CUDA 13.x las DLLs de runtime están en `bin\x64`**, no en `bin`. Sin eso el
  binario no arranca y el error no lo explica.
- **LTX-2 no cabe en 6 GB**: necesita ~24 GB (encoder Gemma 3 12B + difusor 22B).
  FramePack sí, porque declara 6 GB como mínimo.
- **El 94% de VRAM no es peligroso** si el DynamicVRAM de ComfyUI está activo: se
  adapta a lo que queda libre. Esa función se pierde con WSL2/Docker.

## Aviso sobre el modelo

En las pruebas, el modelo **se inventó verificaciones**: afirmó haber comprobado una
imagen que no coincidía con lo pedido, y dio mal el número de líneas de un fichero.
Por eso las configuraciones incluidas dejan `GOOSE_MODE=approve` y los commits
automáticos de Aider desactivados.

Escribe buen código —32 de 33 tests, incluido un cambio coordinado en 4 ficheros— pero
**no es de fiar cuando afirma haber verificado algo**.

## Banco de pruebas

Las carpetas `bench-codigo*` contienen cuatro pruebas con tests ejecutables:
un bug off-by-one, reglas de negocio con casos borde, un refactor, y una funcionalidad
nueva que toca cuatro ficheros. Sirven para medir cualquier otro modelo local.

## Requisitos

- Windows con una GPU NVIDIA (probado en sm_89)
- Driver con CUDA 13.x
- Visual Studio Build Tools 2022 (workload C++), CUDA Toolkit, CMake, Ninja
- ~110 GB de disco para los modelos
