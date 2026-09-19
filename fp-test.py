from gradio_client import Client, handle_file
import time, sys

c = Client("http://127.0.0.1:7860")
print("=== ENDPOINTS DISPONIBLES ===")
try:
    c.view_api(print_info=True, return_format=None)
except Exception as e:
    print("view_api fallo:", e)
