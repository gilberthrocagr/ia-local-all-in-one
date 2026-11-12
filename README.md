# IA local completa en una GPU de 6 GB

Instalación funcionando de un stack de IA **100% local** y de código abierto (con una
salvedad: la licencia de Open WebUI, ver abajo) en un portátil con una **NVIDIA RTX 1000
Ada de 6 GB de VRAM** (ThinkPad P16v Gen 2, Core Ultra 7 155H, 64 GB de RAM). Windows
nativo, sin WSL2 ni Docker.

> ¿Tienes un **Mac con Apple Silicon**? La versión hermana, solo para programar desde la
> Terminal, está en [ia-local-mac](https://github.com/gilberthrocagr/ia-local-mac).

Este repositorio contiene **los scripts y configuraciones**, no los modelos: son 110 GB
descargables y quedan fuera (ver `.gitignore`).

- **Para instalarlo en otra máquina: [INSTALAR.md](INSTALAR.md).**
- La guía de uso, con todas las medidas, está en **[LEEME.md](LEEME.md)**. Describe la
  instalación del autor.

## Qué incluye

| Capa | Qué se usa | Rendimiento medido |
|---|---|---|
| **Motor** | llama.cpp compilado con CUDA (sm_89) | — |
| **Modelo** | Qwen3.6-35B-A3B (MoE, ~3B activos) GGUF UD-Q4_K_XL, variante MTP | **35-37 tok/s** con contexto corto; ~25 tok/s con 16-32K de contexto |
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
- **MTP (speculative decoding) sí funciona aquí: +29,8%** en el barrido de
  `bench-mtp.ps1` (+21% en la medición por contexto de `bench-contexto.ps1`, con otro
  prompt)... pero solo con contexto corto. **A partir de 16K tokens la ventaja
  desaparece.** Hay tests publicados donde MTP sale peor que el baseline; hay que
  medirlo en cada máquina.
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

Cuatro pruebas de programación con Aider: un bug off-by-one, reglas de negocio con casos
borde, un refactor y una funcionalidad nueva que toca cuatro ficheros.

Las carpetas `bench-codigo*` guardan **el código que dejó Qwen al terminar, junto con los
tests**. Al ejecutar los tests salen los 32 de 33 de la tabla (el que falla es
`test_hora_pico`, por el redondeo; el LEEME lo explica). **No se incluyen el código de
partida ni los prompts** que se le dieron, así que sirven para revisar el resultado, no
para repetir la prueba con otro modelo tal cual.

## Seguridad

- Todos los servicios escuchan **solo en `127.0.0.1`**: llama-server (8080),
  ComfyUI (8188), Open WebUI (3000) y FramePack (7860). Desde la red no se llega a ellos.
- **Open WebUI entra sin contraseña** (`WEBUI_AUTH=False` en `start-openwebui.cmd`). Es
  una decisión para un único usuario en su propio equipo; si alguien más usa el equipo, o
  vas a abrirlo a la red, quita esa línea para que pida login.
- **llama-server no tiene API key y su CORS está abierto.** Cualquier programa del equipo,
  y cualquier web que abras en el navegador, puede mandarle peticiones. Para cerrarlo,
  añade `--api-key TU_CLAVE` en `start-qwen.cmd` y la misma clave en `aider-qwen.cmd`,
  `goose-qwen.cmd`, `start-openwebui.cmd` y en la configuración de Goose Desktop.
- ComfyUI y FramePack tampoco tienen login: igual que los anteriores, solo son
  accesibles desde el propio equipo.

## Requisitos

- Windows con una GPU NVIDIA (probado en sm_89)
- Driver NVIDIA reciente y CUDA Toolkit 13.2 (los scripts usan su ruta por defecto)
- Visual Studio Build Tools 2022 (workload C++), CMake, Ninja, Git y uv
- ~110 GB de disco para los modelos

Los pasos, en [INSTALAR.md](INSTALAR.md).

## Licencia

MIT — ver [LICENSE](LICENSE).

Los componentes que se instalan tienen sus propias licencias (no se redistribuyen aquí):

| Componente | Licencia |
|---|---|
| llama.cpp | MIT |
| Goose, FramePack, Aider | Apache 2.0 |
| Qwen3.6, Z-Image | Apache 2.0 |
| ComfyUI | GPL-3.0 |
| comfy-mcp | AGPL-3.0 o licencia comercial |
| Open WebUI | Licencia propia, que restringe alterar su marca |
