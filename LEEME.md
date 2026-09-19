# IA local en el ThinkPad P16v — guía de uso

Instalado el 18-sep-2026. Todo en `C:\AI`, versionado en git y publicado en
**https://github.com/gilberthrocagr/ia-local-all-in-one** (MIT). Hardware: RTX 1000 Ada (6 GB), 64 GB RAM DDR5-5600.

---

## Lo más fácil: los accesos del escritorio

Tienes cuatro accesos sueltos en el escritorio, agrupados por nombre:

| Acceso | Para qué | Ojo |
|---|---|---|
| **IA - Todo en uno** | Chat + código + imágenes + vídeo (Goose Desktop) | Tu día a día |
| **IA - Chat y documentos** | Open WebUI: PDFs, RAG, imágenes | Convive con lo demás |
| **IA - Imagenes** | ComfyUI, control nodo a nodo | 14 s por imagen |
| **IA - Video** | FramePack | **Cierra lo demás solo** |

Para vídeo hay dos caminos: **IA - Video** va al doble de velocidad (10,5 min por
segundo) pero cierra el chat; pedirlo desde **IA - Todo en uno** no cierra nada pero
tarda 21,7 min por segundo. Para un clip de 4 s: 42 min contra 87.

## Y la carpeta "IA Local" del escritorio

Tienes accesos directos numerados. **Cada uno arranca solo lo que necesita** y abre el
navegador cuando está listo. No tienes que acordarte de nada:

| Acceso directo | Para qué |
|---|---|
| **0 - TODO EN UNO (Goose Desktop)** | **Chat + código + imágenes + vídeo en una ventana** |
| **1 - Chat unificado (Open WebUI)** | Chat + imágenes + documentos. Mejor para PDFs y RAG |
| **2 - Chat simple (llama.cpp)** | Chat directo, más ligero |
| **3 - Programar (Aider)** | Terminal lista para programar |
| **4 - Agente (Goose)** | El mismo Goose, pero en terminal |
| **5 - Imágenes (ComfyUI)** | Z-Image, control total del flujo |
| **6 - Vídeo (FramePack)** | Su propia ventana. El doble de rápido que por Goose |

**Para el día a día usa el 0.** Los demás son para cuando quieras control fino
(ComfyUI), documentos y RAG (Open WebUI) o vídeo a máxima velocidad (FramePack).

## O a mano, si prefieres

| Quiero... | Arranco | Y uso |
|---|---|---|
| **Todo en uno** | `C:\AI\abrir-openwebui.cmd` | http://127.0.0.1:3000 |
| **Programar** (prioridad 1) | `C:\AI\start-qwen.cmd` | `C:\AI\aider-qwen.cmd` en tu proyecto |
| **Un agente** (prioridad 2) | `C:\AI\start-qwen.cmd` | `C:\AI\goose-qwen.cmd session` |
| **Chatear** (prioridad 3) | `C:\AI\start-qwen.cmd` | Navegador → http://127.0.0.1:8080 |
| **Imágenes** (prioridad 4) | `C:\AI\start-comfy.cmd` | Navegador → http://127.0.0.1:8188 |
| **Vídeo** | `C:\AI\start-framepack.cmd` | Navegador → http://127.0.0.1:7860 |

**`start-qwen.cmd` es la base de casi todo.** Déjalo corriendo en una ventana y olvídate.

---

## REGLA DE ORO: la VRAM no da para todo a la vez

Solo tienes 6 GB. Medido en esta máquina:

| Combinación | ¿Funciona? |
|---|---|
| llama-server solo | ✅ 3481 MiB |
| llama-server + ComfyUI | ✅ pico 5762 MiB (94%, va justo) |
| **FramePack** | ❌ **necesita la GPU para él solo** |

Antes de usar FramePack, cierra las ventanas de llama-server y ComfyUI.

---

## 1. Programar con Aider

```
cd C:\ruta\de\tu\proyecto
C:\AI\aider-qwen.cmd
```

Dentro de Aider:
- `/add fichero.py` — mete un fichero en el contexto
- `/drop fichero.py` — lo saca
- `/undo` — deshace el último cambio
- `/diff` — ve qué cambió
- `/help` — el resto

**`auto-commits` está desactivado a propósito.** Aider modifica los ficheros pero NO hace commit: revisas con `git diff` y commiteas tú. Lo dejé así porque esta máquina toca producción.

Tarea simple medida: **51 s**, 2,7k tokens enviados.

---

## 2. Agente con Goose

```
C:\AI\goose-qwen.cmd session          (chat interactivo)
C:\AI\goose-qwen.cmd run -t "tarea"   (una sola tarea)
```

**Está en modo `approve`**: te pide permiso antes de ejecutar cualquier comando. Deliberado, por lo mismo de arriba. Si algún día quieres que vaya solo, cambia `GOOSE_MODE` a `auto` en:
`%APPDATA%\Block\goose\config\config.yaml`

---

## 3. Chat diario

Con `start-qwen.cmd` corriendo, abre **http://127.0.0.1:8080** — llama.cpp trae su propia interfaz web.

También es una API compatible con OpenAI, así que sirve para cualquier cliente que acepte una URL base:
- URL: `http://127.0.0.1:8080/v1`
- Modelo: `qwen3.6`
- API key: cualquier cosa (no hay autenticación)

---

## 4. Imágenes con ComfyUI

```
C:\AI\start-comfy.cmd
```
→ http://127.0.0.1:8188

Modelos a elegir en los nodos:
- Difusión: `z_image_turbo_int8_convrot.safetensors`
- Text encoder: `qwen_3_4b_fp8_mixed.safetensors`
- VAE: `ae.safetensors`

Ajustes que funcionan: **8 pasos, CFG 1.0, sampler euler, scheduler simple, 1024x1024**.
Medido: **14,3 s por imagen**.

**NO uses** `fp8_e4m3fn_fast` en el `weight_dtype` del UNETLoader, ni el arranque
`run_nvidia_gpu_fast_fp16_accumulation.bat`: producen imágenes corruptas (issue #9190).
Deja `weight_dtype` en `default`.

---

## 5. Vídeo con FramePack

```
C:\AI\start-framepack.cmd
```
→ http://127.0.0.1:7860

**Cierra antes llama-server y ComfyUI.**

**MEDIDO: 10,5 minutos por CADA SEGUNDO de vídeo** (768x526). Un clip de 4 s son ~42 min;
los 5 s que trae por defecto, casi una hora. Funciona, pero en esta máquina el vídeo es
una curiosidad, no una herramienta de trabajo.

Vas viendo los fotogramas conforme se generan, así que sabes pronto si va bien sin esperar al final.

---

## 6. Open WebUI — todo en una sola web

```
C:\AI\abrir-openwebui.cmd
```
→ http://127.0.0.1:3000

Arranca solo el LLM si hace falta. Te da en una interfaz tipo ChatGPT:
- **Chat** con Qwen3.6
- **Imágenes**: pide una imagen en el chat y la genera con tu Z-Image por detrás
  (ya configurado: 1024x1024, 8 pasos. **Medido: 23 s por imagen**)
- **Documentos**: sube PDFs y pregunta sobre ellos
- **Búsqueda web**

Para que las imágenes funcionen, **ComfyUI tiene que estar corriendo** (arráncalo con el
acceso directo 5 o `start-comfy.cmd`).

Notas:
- Entra sin pedir contraseña (`WEBUI_AUTH=False`) y solo escucha en `127.0.0.1`.
  Si prefieres que pida login, quita esa línea de `start-openwebui.cmd`.
- Su licencia **no es open source estándar**: prohíbe alterar su branding, salvo en
  despliegues de ≤50 usuarios. Siendo tú solo, estás cubierto.
- Lo que **no** integra: el vídeo. FramePack sigue aparte en su 7860.

---

## 7. Goose Desktop — chat + código + imágenes en una ventana

```
C:\AI\abrir-goose-desktop.cmd
```
(o el acceso directo **"0 - TODO EN UNO"** del escritorio)

Arranca por su cuenta el LLM y ComfyUI, y abre la GUI. Es lo más parecido a Claude Code
en local: le hablas normal y él edita ficheros, ejecuta comandos y genera imágenes.

Va en modo **`approve`**: pide permiso antes de ejecutar nada. No lo cambies a `auto`
sin pensarlo — lee el aviso de abajo.

**Las imágenes van por MCP** (`comfy-mcp` → tu ComfyUI). Está configurado para que
`generate_image` use la plantilla `image_z_image_turbo_int8`, que ya apunta a tus tres
modelos. Sin las variables `COMFY_T2I_*` del `config.yaml`, el agente acaba lanzando
plantillas con su **prompt de ejemplo** en vez del tuyo — pasó en la primera prueba y
salió un retrato de moda en blanco y negro en lugar del gato que se pidió.

**El vídeo también va por MCP** (`C:\AI\framepack-mcp.py`, escrito a medida porque FramePack
no trae uno). Herramientas: `framepack_status` y `generate_video`.

Medido pidiéndolo desde Goose con el LLM cargado a la vez: **21,7 minutos por 1 segundo**
de vídeo. Con la GPU libre son 10,5 min, o sea que **compartirla cuesta el doble**. Funciona
sin cerrar nada, pero si tienes prisa cierra el LLM y úsalo desde su propia ventana (:7860).

En esperas tan largas puede aparecer un `Network error: Stream decode error`: es la conexión
con el LLM cortándose, no el vídeo fallando. Goose se recupera solo.

Config en: `%APPDATA%\Block\goose\config\config.yaml`

### CRÍTICO: cada extensión de Goose cuesta MINUTOS por mensaje

Cada extensión activa mete las definiciones de sus herramientas en el prompt del
sistema **en cada mensaje**. Tu GPU procesa prompt a ~180 tok/s, así que un prompt
grande se paga en tiempo antes de que el modelo escriba una sola palabra.

Medido con la frase "hola estas aqui":

| Extensiones activas | Tiempo en responder |
|---|---|
| Solo `developer` | **21,7 s** |
| + `comfyui` + `framepack` | **249,4 s** |
| + las 9 de plataforma | **314,3 s** |

**`comfy-mcp` es el caro**: sus herramientas traen descripciones larguísimas.
Tener imágenes y vídeo enchufados a Goose lo hace **11 veces más lento**.

Por eso hay dos perfiles:

```
IA - Todo en uno              -> solo developer. Rapido (~20 s). Para programar.
IA - Goose completo (lento)   -> + imagenes y video. Varios minutos por mensaje.
```

Se cambia con `goose-perfil.ps1 -Perfil codigo|completo`, que cierra Goose, ajusta el
`config.yaml` y lo reabre.

**Dos trampas del fichero de configuración**, las dos descubiertas rompiéndolo:

1. `providers.openai.enabled` **no es una extensión**. Si se apaga por error, Goose
   dice "No provider configured" y no conecta con nada.
2. **El `config.yaml` no admite BOM.** `Set-Content -Encoding UTF8` de PowerShell 5.1
   lo añade y Goose falla con el mismo mensaje confuso. Hay que escribirlo con
   `UTF8Encoding($false)`.

### Si pides algo que el perfil no puede hacer, el modelo improvisa

Pasó de verdad: con el perfil **código** activo (sin la extensión de imágenes), se le
pidió "un arcoíris sobre un río". El modelo no tiene herramienta para generar imágenes,
así que **no avisó de que no podía**: se puso a escribir un programa en Python con PIL
para dibujarlo a mano, píxel a píxel. Tardó minutos y el resultado no era una imagen
generada por IA.

**Cómo saber si está trabajando o colgado:** `monitor-goose.ps1` observa durante 3
minutos si hay actividad de GPU, conexiones al puerto 8080 y peticiones nuevas en el
log. Si hay actividad, el mensaje llegó y solo tarda; si no hay nada, el problema está
en la aplicación.

**Regla práctica: para imágenes no uses Goose.** Usa "IA - Imagenes" (ComfyUI, 14 s) o
"IA - Chat y documentos" (Open WebUI, 23 s). El perfil completo de Goose puede generar
imágenes de verdad, pero cobra 249 s en *cada* mensaje, también en los que no tienen
nada que ver con imágenes.

### AVISO IMPORTANTE: el modelo se inventa verificaciones

En esa primera prueba fallida, Qwen3.6 dijo *"¡Listo! La imagen fue generada
exitosamente"*, describió el gato con detalle, y afirmó haber ejecutado `read_image`
sobre el fichero. **Tenía la imagen delante y reportó lo que esperaba ver, no lo que
había.** Es el mismo patrón que cuando dijo que un fichero tenía 16 líneas y tenía 11.

**Qué significa en la práctica:** cuando Goose te diga que ha hecho algo, compruébalo.
Mira el fichero, abre la imagen, ejecuta el test. Este modelo es rápido y competente
escribiendo código, pero **no es de fiar cuando afirma haber verificado algo**.

Por eso `GOOSE_MODE` está en `approve` y `auto-commits` de Aider en `false`.

---

## Cómo arrancan las cosas (lanzadores)

Los accesos directos **no** ejecutan los `.cmd` directamente: llaman a un `.vbs` que
lanza `lanzador.ps1` **sin mostrar ninguna ventana de consola**.

```
acceso directo  ->  wscript  ->  ia-XXX.vbs  ->  lanzador.ps1 -App XXX
```

Eso resuelve dos problemas de la primera versión:

1. Antes se veía **una ventana negra bloqueada 25 segundos** (`timeout /t 25`) y luego
   quedaban ventanas abiertas. Ahora no se ve nada: los servidores arrancan minimizados.
2. Antes se esperaba un tiempo fijo a ciegas. Ahora **se comprueba el puerto cada 0,8 s**
   y el navegador se abre en cuanto el servicio responde de verdad, ni antes ni después.

Si un servicio no arranca, sale un aviso diciendo qué `.cmd` ejecutar a mano para ver el error.

**Los `.vbs` se generan con `generar-vbs.py`, no los edites a mano.** VBScript exige que
las comillas dentro de un string vayan duplicadas (`""`), y escribirlas mal rompe el
fichero sin avisar: el lanzador simplemente no hace nada.

Para comprobar que todo sigue funcionando: `probar-lanzadores.ps1` prueba cada acceso
parando antes los servicios, y verifica que arrancan y que no aparecen ventanas.

---

## Verificación: comprobar que todo funciona

`probar-todo.ps1` prueba que los accesos **arrancan** (para los servicios antes de
cada uno, para comprobar que lo hacen desde cero).

Pero arrancar no es funcionar. La verificación **funcional** —que cada cosa haga su
trabajo— se hizo con comandos sueltos, no con un script, por una razón:

**Windows Defender bloquea los scripts .ps1 que combinan peticiones HTTP, arranque de
procesos y escritura de ficheros.** Da el error "Este script contiene elementos
malintencionados". Es un falso positivo, pero el antivirus está haciendo su trabajo:
ese perfil se parece al de un script dañino. La solución fue ejecutar las pruebas
como comandos independientes.

Resultado de la última verificación funcional (6 de 6):

| Componente | Qué demostró | Tiempo |
|---|---|---|
| Modelo (llama.cpp) | Respondió a una pregunta | 1,3 s |
| ComfyUI | Generó un PNG de 1270 KB en disco | 24,2 s |
| Open WebUI | Sirvió su interfaz (HTTP 200) | — |
| Goose | Respondió como agente | 23,5 s |
| Aider | **Editó un fichero**, comprobado leyéndolo | 42,2 s |
| FramePack | Arrancó y su endpoint /process responde | 20 s |

La prueba de Aider es la que más vale: no se fía de lo que diga el agente, **abre el
fichero y comprueba que el cambio está**. Es la defensa contra que el modelo se
invente verificaciones.

---

## Dónde está cada cosa

```
C:\AI\
├─ start-qwen.cmd          Servidor LLM (la base de todo)
├─ aider-qwen.cmd          Aider apuntado al modelo local
├─ goose-qwen.cmd          Goose apuntado al modelo local
├─ start-comfy.cmd         ComfyUI
├─ start-framepack.cmd     FramePack
├─ build-llama.cmd         Recompilar llama.cpp si actualizas el código
├─ llama.cpp\              Código y binarios compilados
├─ ComfyUI\                ComfyUI portable
├─ FramePack\              FramePack
└─ models\
   ├─ llm\                 Qwen3.6-35B-A3B (22,4 GB)
   ├─ image\               Z-Image (11,3 GB)
   └─ video\hf-cache\      FramePack (~30 GB)
```

Los modelos están **fuera** de las carpetas de las apps a propósito: puedes reinstalar o
actualizar ComfyUI sin perder 11 GB de descargas. ComfyUI los encuentra por
`ComfyUI\ComfyUI\extra_model_paths.yaml`.

---

## Rendimiento medido en esta máquina

| Qué | Resultado |
|---|---|
| **Generación con MTP (configuración actual)** | **35-37 tok/s** |
| Generación sin MTP | 28,20 tok/s |
| Generación, 16K de contexto (sin MTP) | 24,44 tok/s |
| Procesado de prompt | 155 tok/s |
| Imagen 1024x1024, 8 pasos | 14,3 s |
| Vídeo | 10,5 min por segundo |

El contexto cuesta ~20% de velocidad. Es normal: cada token nuevo atiende a todo lo anterior.

### El barrido de MTP (speculative decoding)

| Configuración | tok/s | VRAM |
|---|---|---|
| Sin MTP | 28,20 | 3554 MiB |
| **MTP `--spec-draft-n-max 2`** | **36,59** | 4500 MiB |
| MTP n-max 3 | 35,32 | 4784 MiB |
| MTP n-max 4 | 30,28 | 5036 MiB |
| MTP n-max 5 | 27,78 (peor que sin MTP) | 5286 MiB |

**Subir el `n-max` empeora y gasta más VRAM.** El 2 es el óptimo en esta máquina.
La calidad no cambia: el speculative decoding verifica cada token contra el modelo real,
así que la salida es idéntica; solo cambia la velocidad.

### IMPORTANTE: la ventaja de MTP desaparece con contexto largo

| Contexto | Con MTP | Sin MTP | Diferencia |
|---|---|---|---|
| Vacío | 33,39 | 27,52 | **+21%** |
| ~8K | 28,92 | 26,26 | +10% |
| ~16K | 24,70 | 25,74 | −4% |
| ~32K | 25,34 | 23,68 | +7% |

**A partir de 16K empatan.** Las diferencias de −4% y +7% están dentro del ruido de
medición (solo 2 muestras y mucha dispersión). O sea: **programando con Aider, donde el
contexto va lleno, MTP no te aporta nada.** El +21% solo se nota en respuestas cortas:
chat diario, preguntas sueltas.

Se deja activado porque en el peor caso empata y en el mejor gana, y los 950 MB extra de
VRAM no dan problemas de convivencia con ComfyUI. **Si alguna vez necesitas esos 950 MB**,
quítalo sin dudarlo: cambia el `MODEL` en `start-qwen.cmd` al fichero sin MTP y borra las
dos líneas `--spec-*`.

Nota: con MTP la velocidad varía más entre peticiones (dispersión del 9%); sin MTP era
clavada (1%). Es normal, depende de cuántos tokens propuestos acierta el predictor.

---

## Cosas que se descubrieron montando esto

- **`--n-cpu-moe 99` es el óptimo.** Bajarlo empeora un 12%. No lo toques.
- **`--no-mmap --mlock` ya no existe** en llama.cpp; ahora es `--load-mode mlock`.
- **En CUDA 13.x las DLLs están en `bin\x64`**, no en `bin`. Por eso los scripts lo añaden al PATH.
- **El modelo razona por defecto** y se le iban 600 tokens en tareas triviales. Limitado a
  1500 con `--reasoning-budget`. Para desactivarlo del todo en una petición concreta:
  `chat_template_kwargs: {"enable_thinking": false}`.
- **El modelo se inventa números.** En una prueba dijo que un fichero tenía 16 líneas cuando
  tenía 11. Si necesitas un dato exacto, oblígalo a ejecutar el comando que lo calcula.
- **LTX-2 no cabe aquí.** Necesita ~24 GB (text encoder Gemma 3 12B + difusor 22B). Por eso
  FramePack, que declara 6 GB.
- **MTP sí funciona aquí (+29,8%).** Hay tests publicados donde el speculative decoding sale
  peor que el baseline; en esta máquina gana claramente. Por eso había que medirlo.
  Usa el modelo `Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf` (753 tensores, 20 más que el normal).
  El modelo sin MTP se conserva en `models\llm` por si alguna vez necesitas los 950 MB de VRAM.

---

## Qué tal programa de verdad: 4 pruebas medidas

Banco de pruebas real, con tests que se ejecutan. Los proyectos están en
`C:\AI\bench-codigo`, `bench-codigo2`, `bench-codigo3` y `bench-codigo4` por si
quieres repetirlas o hacer las tuyas.

| Prueba | Qué medía | Resultado | Tiempo | Tokens |
|---|---|---|---|---|
| 1 | Encontrar un bug off-by-one sin pistas | ✅ 3/3 | 112 s | 3,0k → 1,9k |
| 2 | Implementar reglas de negocio con casos borde | ⚠️ 7/8 | 83 s | 3,5k → 1,3k |
| 3 | Refactorizar sin romper tests que ya pasaban | ✅ 5/5 | 113 s | 3,5k → 2,1k |
| 4 | Feature nueva tocando 4 ficheros coordinados | ✅ **17/17** | 202 s | 6,2k → 3,5k |

**Total: 32 de 33 tests (97%).**

### Lo que hizo bien

- Corrigió **las dos mitades** del off-by-one (rango del bucle e índices del slice).
- El refactor fue idiomático: extrajo la función común con `_` de privado y mantuvo
  la API pública intacta.
- En la prueba multi-fichero hizo el parámetro nuevo **opcional**
  (`cupones: Optional[RepositorioCupones] = None`) para no romper el constructor
  antiguo. Nadie se lo dijo: lo dedujo leyendo los tests existentes. Coordinó
  cambios en cuatro capas manteniendo compatibilidad hacia atrás.

### El único fallo, y por qué importa

En la prueba 2 usó `round()` para redondear dinero. Python hace **redondeo bancario**:
`round(5.625, 2)` devuelve `5.62`, no `5.63`. Para dinero hay que usar
`Decimal` con `ROUND_HALF_UP`.

Acertó **todas** las reglas de negocio con trampa (km hacia arriba, 5 kg exactos sin
recargo, mínimo aplicado tras hora pico, ValueError en negativos). Falló solo en ese
detalle de especialista. **En cualquier código que facture, eso es dinero mal cobrado**, así
que revisa el redondeo siempre que el código toque importes.

### Comparado con Claude Code

**Donde pierde:**
- **5-10x más lento.** 8,5 min las cuatro pruebas; Claude Code, uno o dos.
- **Conocimiento de especialista** (el caso del `Decimal`).
- **Se inventa verificaciones.** Cuando dice "ya lo comprobé", puede no ser verdad.
- **Contexto de 64K.** Aquí usó 6,2k; un repo grande lo desborda.

**Donde empata:**
- **En la calidad del código de estas tareas, prácticamente no hay diferencia.**
  97%, código idiomático, decisiones de diseño correctas.

**Sin medir:** un repo de decenas de miles de líneas, donde hay que *encontrar* qué
tocar antes de tocarlo. Ahí es donde se espera que el contexto limitado pese, pero
no está comprobado.

### Cómo usarlo, en resumen

Herramienta principal para el día a día: bugs, features, refactors, tests. Funciona
y sale gratis. Reserva un modelo de pago para dos cosas: **cambios que toquen medio
repo** y **código que mueva dinero**.

---

## Seguridad

El servidor arranca **sin API key y con CORS abierto**. Solo escucha en `127.0.0.1`, así que
desde la red no se llega — pero cualquier web que abras en el navegador podría hacerle
peticiones. Si quieres cerrarlo, añade `--api-key TU_CLAVE` en `start-qwen.cmd` y la misma
clave en `aider-qwen.cmd` y `goose-qwen.cmd`.

## Sobre el Sysmem Fallback (decidido: no hace falta)

Con el LLM y ComfyUI a la vez, el pico de VRAM llega al **94%** (5780 de 6141 MiB). Eso
asustaba, pero se midió y **no hay desbordamiento**:

| Escenario | Pico VRAM | Tiempo de imagen |
|---|---|---|
| Solo ComfyUI | 5762 MiB (94%) | 14,3 s |
| ComfyUI + LLM cargado | 5780 MiB (94%) | **13,7 s** |

**Esos 13,7 segundos son la prueba.** Si Windows estuviera volcando VRAM a RAM, la imagen
tardaría *minutos*: la penalización es de 30-100x, no se puede esconder. Tarda lo mismo con
la GPU llena que vacía.

La razón es el **DynamicVRAM de ComfyUI** (confirmado activo en el log de arranque): ve
cuánta memoria queda libre y trabaja dentro de ese margen en vez de pedir de más. Es
exactamente la función que se habría perdido usando WSL2 o Docker.

`start-comfy.cmd` lleva además `--vram-headroom 0.5` como red de seguridad. No penaliza
nada y ayuda si encolas varias imágenes seguidas.

**Si alguna vez notas lentitud rarísima** (imágenes que pasan de 14 s a varios minutos sin
motivo), entonces sí configúralo: Panel de Control NVIDIA → Administrar configuración 3D →
**Configuración de programa** → añadir `C:\AI\llama.cpp\build\bin\llama-server.exe` →
*CUDA - Sysmem Fallback Policy* → **Prefer No Sysmem Fallback**. Por aplicación, nunca global.
