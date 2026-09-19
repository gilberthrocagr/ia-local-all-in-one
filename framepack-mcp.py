"""
Servidor MCP para FramePack: permite generar video desde Goose.

FramePack no trae MCP, asi que este puente habla con su API de Gradio (:7860).

AVISO DE VRAM: FramePack necesita practicamente toda la GPU. Si el LLM esta
cargado, la generacion sera mucho mas lenta o fallara. La herramienta avisa
de ello y ofrece liberar memoria.

VELOCIDAD MEDIDA en esta maquina: ~10,5 minutos por CADA SEGUNDO de video.
"""
import os
import shutil
import subprocess
import time

# En mcp 2.x FastMCP se renombro a MCPServer. Si algun dia falla el import,
# probar 'from mcp.server.fastmcp import FastMCP' (API v1) o fijar 'mcp<2'.
from mcp.server.mcpserver import MCPServer

FRAMEPACK_URL = os.environ.get("FRAMEPACK_URL", "http://127.0.0.1:7860")
MIN_PER_SECOND = 10.5  # medido en esta maquina

mcp = MCPServer("framepack")


def _client():
    from gradio_client import Client
    return Client(FRAMEPACK_URL, verbose=False)


@mcp.tool()
def framepack_status() -> str:
    """Comprueba si FramePack esta corriendo y cuanta VRAM hay libre.

    Uselo SIEMPRE antes de generar un video.
    """
    import urllib.request

    running = False
    try:
        urllib.request.urlopen(FRAMEPACK_URL, timeout=4)
        running = True
    except Exception:
        running = False

    vram = "desconocida"
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used,memory.free",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=10,
        ).stdout.strip().splitlines()[0]
        used, free = [int(x.strip()) for x in out.split(",")]
        vram = f"{used} MiB usados, {free} MiB libres de 6141"
    except Exception:
        pass

    if not running:
        return (
            f"FramePack NO esta corriendo. VRAM: {vram}.\n"
            "Para arrancarlo hay que ejecutar C:\\AI\\start-framepack.cmd y esperar "
            "a que cargue (1-2 minutos). Conviene cerrar antes el LLM y ComfyUI, "
            "porque FramePack necesita casi toda la GPU."
        )
    return f"FramePack esta listo en {FRAMEPACK_URL}. VRAM: {vram}."


@mcp.tool()
def generate_video(
    image_path: str,
    prompt: str,
    seconds: float = 1.0,
    seed: int = 31337,
    steps: int = 25,
    out_dir: str = "",
) -> str:
    """Genera un video a partir de UNA IMAGEN de partida y una descripcion del movimiento.

    MUY LENTO: unos 10,5 MINUTOS por cada segundo de video. Con seconds=1 son
    unos 10 minutos; con seconds=5, casi una hora. Avise al usuario del tiempo
    ANTES de lanzarlo y confirme que quiere esperar.

    Necesita una imagen de partida: FramePack es imagen-a-video, no texto-a-video.
    Si el usuario no da una imagen, genere primero una con la herramienta de ComfyUI.

    Args:
        image_path: ruta absoluta de la imagen de partida (png/jpg).
        prompt: descripcion EN INGLES del movimiento deseado.
        seconds: duracion en segundos. Empiece por 1 para probar.
        seed: semilla.
        steps: pasos de difusion (25 por defecto).
        out_dir: carpeta donde copiar el video. Si se omite, junto a la imagen.
    """
    from gradio_client import handle_file

    if not os.path.isfile(image_path):
        return f"ERROR: no existe la imagen {image_path}"

    est = seconds * MIN_PER_SECOND
    t0 = time.time()

    try:
        c = _client()
    except Exception as e:
        return (
            f"ERROR: no se pudo conectar con FramePack en {FRAMEPACK_URL} ({e}).\n"
            "Arranque C:\\AI\\start-framepack.cmd primero."
        )

    try:
        res = c.predict(
            input_image=handle_file(image_path),
            prompt=prompt,
            n_prompt="",
            seed=seed,
            total_second_length=seconds,
            latent_window_size=9,
            steps=steps,
            cfg=1.0,
            gs=10.0,
            rs=0.0,
            gpu_memory_preservation=6,
            use_teacache=True,
            mp4_crf=16,
            api_name="/process",
        )
    except Exception as e:
        return f"ERROR durante la generacion: {e}"

    elapsed = (time.time() - t0) / 60.0

    vid = res[0] if isinstance(res, (list, tuple)) else res
    if isinstance(vid, dict):
        vid = vid.get("video")
    if not vid or not os.path.exists(vid):
        return f"La generacion termino pero no se encontro el fichero de video. Resultado: {res}"

    dest_dir = out_dir or os.path.dirname(os.path.abspath(image_path))
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, f"framepack_{int(time.time())}.mp4")
    shutil.copy(vid, dest)
    size_mb = os.path.getsize(dest) / 1048576

    return (
        f"Video generado: {dest} ({size_mb:.2f} MB)\n"
        f"Duracion: {seconds}s | Tiempo real: {elapsed:.1f} min (estimado {est:.1f})\n"
        f"IMPORTANTE: verifique el video abriendolo; no de por hecho que el contenido "
        f"coincide con lo pedido."
    )


if __name__ == "__main__":
    mcp.run()
