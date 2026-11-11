"""Genera 1 segundo de video con FramePack y mide cuanto tarda.

Uso:  python fp-gen.py [imagen.png]
Sin argumento usa la ultima imagen que guardo zimage-test.json en ComfyUI
(el colibri, prefijo zimage_test).
"""
from gradio_client import Client, handle_file
import time, shutil, os, sys, glob

SALIDA = r"C:\AI\ComfyUI\ComfyUI\output"
if len(sys.argv) > 1:
    IMG = sys.argv[1]
else:
    hechas = sorted(glob.glob(os.path.join(SALIDA, "zimage_test*.png")), key=os.path.getmtime)
    IMG = hechas[-1] if hechas else os.path.join(SALIDA, "zimage_test_00001_.png")
if not os.path.isfile(IMG):
    sys.exit("No existe la imagen de partida: {}".format(IMG))
c = Client("http://127.0.0.1:7860")

t0 = time.time()
print("Lanzando generacion de 1 segundo de video...", flush=True)

res = c.predict(
    input_image=handle_file(IMG),
    prompt="The hummingbird flaps its wings rapidly while hovering next to the red flower",
    n_prompt="",
    seed=31337,
    total_second_length=1,
    latent_window_size=9,
    steps=25,
    cfg=1.0,
    gs=10.0,
    rs=0.0,
    gpu_memory_preservation=6,
    use_teacache=True,
    mp4_crf=16,
    api_name="/process",
)
el = time.time() - t0
print(f"\n=== TERMINADO en {el:.1f}s ({el/60:.1f} min) ===", flush=True)

vid = res[0]
if isinstance(vid, dict):
    vid = vid.get("video")
print("Video:", vid)
if vid and os.path.exists(vid):
    dest = r"C:\AI\framepack-test.mp4"
    shutil.copy(vid, dest)
    print(f"Copiado a {dest} ({os.path.getsize(dest)/1048576:.2f} MB)")
else:
    print("No se obtuvo fichero de video. Resultado completo:", res)
