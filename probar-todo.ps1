# Prueba TODOS los accesos de la carpeta "IA Local" como si se hiciera doble clic.
# Para los servicios antes de cada prueba para comprobar que arrancan de cero.
$desk = [Environment]::GetFolderPath('Desktop')
$carpeta = Join-Path $desk 'IA Local'
$ws = New-Object -ComObject WScript.Shell
$ProgressPreference = 'SilentlyContinue'

function Test-Puerto($p) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $r = $c.BeginConnect('127.0.0.1', $p, $null, $null)
        $ok = $r.AsyncWaitHandle.WaitOne(700, $false)
        if ($ok) { $c.EndConnect($r) }
        $c.Close(); return $ok
    } catch { return $false }
}

# Como en lanzador.ps1: el modelo esta listo cuando /health devuelve 200
function Test-Salud($url) {
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        return ($r.StatusCode -eq 200)
    } catch { return $false }
}

function Parar-Todo {
    Get-Process llama-server, open-webui, Goose, goose -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Get-Process python -EA SilentlyContinue | Where-Object { $_.Path -like '*ComfyUI*' -or $_.Path -like '*FramePack*' } | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 4
}

# Detectores: cuentan lo que tiene que abrir cada acceso. No vale contar
# procesos cmd: el lanzador abre antes start-qwen.cmd en una consola
# minimizada, y eso daba OK aunque Goose o Aider no llegaran a abrir.
function Contar-GooseDesktop {
    return @(Get-Process goose -EA SilentlyContinue | Where-Object { $_.Path -like '*\GooseDesktop\*' }).Count
}
function Contar-GooseCli {
    # El goose.exe del CLI, no el Goose.exe de Goose Desktop
    return @(Get-Process goose -EA SilentlyContinue | Where-Object { $_.Path -like '*\goose-package\*' }).Count
}
function Contar-ConsolaAider {
    # La consola que abre 'lanzador.ps1 -App aider' lleva aider-qwen.cmd en su linea de comandos
    return @(Get-CimInstance Win32_Process -Filter "Name = 'cmd.exe'" -EA SilentlyContinue |
        Where-Object { $_.CommandLine -like '*aider-qwen.cmd*' }).Count
}

$resultados = @()

# $puerto > 0: basta con que el puerto acepte conexiones.
# $url: OK solo cuando esa URL devuelve 200 (manda sobre $puerto). Para el
#   modelo no basta el puerto: llama-server abre el 8080 antes de cargar.
# $detector: bloque que cuenta lo abierto; OK cuando hay mas que al empezar.
function Probar($lnk, $puerto, $maxSeg, $detector, $url) {
    $nombre = [IO.Path]::GetFileNameWithoutExtension($lnk)
    Write-Output ""
    Write-Output "--- $nombre ---"
    $ruta = Join-Path $carpeta $lnk
    if (-not (Test-Path $ruta)) {
        Write-Output "  FALLO: no existe"
        $script:resultados += [PSCustomObject]@{ Acceso=$nombre; Resultado='NO EXISTE' }
        return
    }
    $antes = 0
    if ($detector) { $antes = & $detector }
    $l = $ws.CreateShortcut($ruta)
    # Un acceso que apunta directamente al .vbs no tiene argumentos, y
    # Start-Process no acepta -ArgumentList vacio
    $sp = @{ FilePath = $l.TargetPath }
    if ($l.Arguments) { $sp.ArgumentList = $l.Arguments }
    if ($l.WorkingDirectory) { $sp.WorkingDirectory = $l.WorkingDirectory }
    Start-Process @sp

    $t0 = Get-Date
    $ok = $false
    for ($i = 0; $i -lt ($maxSeg / 2); $i++) {
        Start-Sleep -Seconds 2
        if ($url) { if (Test-Salud $url) { $ok = $true; break } }
        elseif ($puerto -gt 0 -and (Test-Puerto $puerto)) { $ok = $true; break }
        if ($detector -and ((& $detector) -gt $antes)) { $ok = $true; break }
    }
    $seg = [math]::Round(((Get-Date) - $t0).TotalSeconds, 0)
    if ($ok) { Write-Output "  OK      arranco en $seg s" } else { Write-Output "  FALLO   no arranco en $seg s" }
    $script:resultados += [PSCustomObject]@{ Acceso=$nombre; Resultado=$(if ($ok) { "OK ($seg s)" } else { "FALLO" }) }
}

Write-Output "================================================"
Write-Output "  PRUEBA DE TODOS LOS ACCESOS DE 'IA Local'"
Write-Output "================================================"

Parar-Todo
Probar '2 - Chat simple (llama.cpp).lnk'      8080 200 $null 'http://127.0.0.1:8080/health'
Parar-Todo
Probar '5 - Imagenes (ComfyUI).lnk'           8188 150 $null
Parar-Todo
Probar '1 - Chat unificado (Open WebUI).lnk'  3000 240 $null
Parar-Todo
Probar '0 - TODO EN UNO (Goose Desktop).lnk'  0    240 { Contar-GooseDesktop }
Parar-Todo
Probar '4 - Agente (Goose).lnk'               0    240 { Contar-GooseCli }
Parar-Todo
Probar '3 - Programar (Aider).lnk'            0    240 { Contar-ConsolaAider }

Write-Output ""
Write-Output "================================================"
Write-Output "  RESUMEN"
Write-Output "================================================"
$resultados | Format-Table -AutoSize
$fallos = ($resultados | Where-Object { $_.Resultado -notlike 'OK*' } | Measure-Object).Count
Write-Output "fallos: $fallos de $($resultados.Count)"
Write-Output ""
Write-Output "NOTA: '6 - Video' no se prueba automaticamente porque muestra un"
Write-Output "dialogo de confirmacion (cierra el resto de servicios) que hay que"
Write-Output "aceptar a mano. Su lanzador tiene la misma estructura que los demas."
Write-Output "La consola de Aider que abre la prueba se queda abierta: cierrala a mano."
