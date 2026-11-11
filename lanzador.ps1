# Lanzador unico para todas las IA.
# Arranca lo que haga falta MINIMIZADO, espera a que el servicio responda
# de verdad (no un timeout a ciegas) y abre el navegador.
#
# El modelo (llama-server, puerto 8080) abre el puerto ANTES de cargar sus
# 22 GB y mientras carga contesta 503 "Loading model". Con el no basta con
# que el puerto acepte conexiones: se espera a que /health devuelva 200.
# Para ComfyUI, Open WebUI y FramePack basta con el puerto.
#
# OJO con Windows Defender: bloquea los .ps1 que juntan peticiones HTTP,
# arranque de procesos y escritura de ficheros. Este script hace las dos
# primeras; que no escriba ficheros.
param([Parameter(Mandatory=$true)][string]$App)

$ProgressPreference = 'SilentlyContinue'
$SALUD_LLM  = 'http://127.0.0.1:8080/health'
$ESPERA_LLM = 180   # segundos: la primera carga del modelo puede tardar

function Test-Puerto($puerto) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $r = $c.BeginConnect('127.0.0.1', $puerto, $null, $null)
        $ok = $r.AsyncWaitHandle.WaitOne(700, $false)
        if ($ok) { $c.EndConnect($r) }
        $c.Close()
        return $ok
    } catch { return $false }
}

function Test-Salud($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}

# Listo = /health en 200 si se da $url; si no, el puerto acepta conexiones
function Test-Listo($puerto, $url) {
    if ($url) { return (Test-Salud $url) }
    return (Test-Puerto $puerto)
}

function Iniciar-Servicio($script, $puerto, $segundosMax, $url) {
    if (Test-Listo $puerto $url) { return $true }
    # Puerto abierto pero aun sin responder: ya esta arrancando, no lanzar otro
    if (-not (Test-Puerto $puerto)) {
        Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $script -WindowStyle Minimized
    }
    $fin = (Get-Date).AddSeconds($segundosMax)
    while ((Get-Date) -lt $fin) {
        Start-Sleep -Milliseconds 800
        if (Test-Listo $puerto $url) { return $true }
    }
    return $false
}

function Iniciar-Modelo {
    return (Iniciar-Servicio 'C:\AI\start-qwen.cmd' 8080 $ESPERA_LLM $SALUD_LLM)
}

function Aviso($texto, $titulo) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($texto, $titulo) | Out-Null
}

$noArranco = "El modelo no arranco en 3 minutos.`n`nAbre C:\AI\start-qwen.cmd a mano para ver el error."

switch ($App) {

    'chat' {
        if (Iniciar-Modelo) { Start-Process 'http://127.0.0.1:8080' }
        else { Aviso $noArranco 'IA - Chat' }
    }

    'openwebui' {
        if (-not (Iniciar-Modelo)) { Aviso $noArranco 'IA - Chat y documentos'; break }
        # ComfyUI hace falta para que funcionen las imagenes dentro de Open WebUI
        Iniciar-Servicio 'C:\AI\start-comfy.cmd' 8188 90 | Out-Null
        if (Iniciar-Servicio 'C:\AI\start-openwebui.cmd' 3000 120) { Start-Process 'http://127.0.0.1:3000' }
        else { Aviso "Open WebUI no arranco en 2 minutos." 'IA - Chat y documentos' }
    }

    'imagenes' {
        if (Iniciar-Servicio 'C:\AI\start-comfy.cmd' 8188 120) { Start-Process 'http://127.0.0.1:8188' }
        else { Aviso "ComfyUI no arranco en 2 minutos.`n`nAbre C:\AI\start-comfy.cmd a mano para ver el error." 'IA - Imagenes' }
    }

    # Goose Desktop. 'goose' (ia-goose.vbs) abre con el perfil que tenga el
    # config.yaml; goose-perfil.ps1 llama con 'goose-codigo' o 'goose-completo'
    # despues de cambiarlo. ComfyUI solo hace falta si hay imagenes.
    { $_ -in 'goose', 'goose-codigo', 'goose-completo' } {
        if (-not (Iniciar-Modelo)) { Aviso $noArranco 'IA - Goose'; break }
        if ($App -ne 'goose-codigo') { Iniciar-Servicio 'C:\AI\start-comfy.cmd' 8188 90 | Out-Null }
        Start-Process 'C:\AI\GooseDesktop\Goose.exe'
    }

    'video' {
        Add-Type -AssemblyName PresentationFramework
        $r = [System.Windows.MessageBox]::Show(
            "El video necesita la GPU entera.`n`nSe van a cerrar el chat y ComfyUI si estan abiertos.`n`nRecuerda: unos 10 minutos por CADA SEGUNDO de video.`n`nContinuar?",
            'IA - Video', 'YesNo', 'Warning')
        if ($r -ne 'Yes') { break }
        Get-Process llama-server -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
        Get-Process python -EA SilentlyContinue | Where-Object { $_.Path -like '*ComfyUI*' } | Stop-Process -Force -EA SilentlyContinue
        Start-Sleep -Seconds 3
        if (Iniciar-Servicio 'C:\AI\start-framepack.cmd' 7860 300) { Start-Process 'http://127.0.0.1:7860' }
        else { Aviso "FramePack no arranco en 5 minutos.`n`nLa primera vez puede tardar mas. Abre C:\AI\start-framepack.cmd a mano." 'IA - Video' }
    }

    'aider' {
        Iniciar-Modelo | Out-Null
        Start-Process 'cmd.exe' -ArgumentList '/k', 'echo Estas listo para usar Aider. Ve a tu proyecto con: cd C:\ruta\del\proyecto  y ejecuta: C:\AI\aider-qwen.cmd'
    }

    'goosecli' {
        # Goose en terminal. Necesita ventana: es una consola interactiva.
        if (-not (Iniciar-Modelo)) { Aviso $noArranco 'IA - Agente (terminal)'; break }
        Start-Process 'cmd.exe' -ArgumentList '/c', 'C:\AI\goose-qwen.cmd session'
    }

    default { Aviso "Aplicacion desconocida: $App" 'Lanzador IA' }
}
