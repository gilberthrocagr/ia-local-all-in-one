# Prueba TODOS los accesos de la carpeta "IA Local" como si se hiciera doble clic.
# Para los servicios antes de cada prueba para comprobar que arrancan de cero.
$desk = [Environment]::GetFolderPath('Desktop')
$carpeta = Join-Path $desk 'IA Local'
$ws = New-Object -ComObject WScript.Shell

function Test-Puerto($p) {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $r = $c.BeginConnect('127.0.0.1', $p, $null, $null)
        $ok = $r.AsyncWaitHandle.WaitOne(700, $false)
        if ($ok) { $c.EndConnect($r) }
        $c.Close(); return $ok
    } catch { return $false }
}

function Parar-Todo {
    Get-Process llama-server, open-webui, Goose, goose -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Get-Process python -EA SilentlyContinue | Where-Object { $_.Path -like '*ComfyUI*' -or $_.Path -like '*FramePack*' } | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 4
}

$resultados = @()

function Probar($lnk, $puerto, $proceso, $maxSeg, $esperaVentanaCmd) {
    $nombre = [IO.Path]::GetFileNameWithoutExtension($lnk)
    Write-Output ""
    Write-Output "--- $nombre ---"
    $ruta = Join-Path $carpeta $lnk
    if (-not (Test-Path $ruta)) {
        Write-Output "  FALLO: no existe"
        $script:resultados += [PSCustomObject]@{ Acceso=$nombre; Resultado='NO EXISTE' }
        return
    }
    $cmdAntes = (Get-Process cmd -EA SilentlyContinue | Measure-Object).Count
    $l = $ws.CreateShortcut($ruta)
    Start-Process -FilePath $l.TargetPath -ArgumentList $l.Arguments -WorkingDirectory $l.WorkingDirectory

    $t0 = Get-Date
    $ok = $false
    for ($i = 0; $i -lt ($maxSeg / 2); $i++) {
        Start-Sleep -Seconds 2
        if ($puerto -gt 0 -and (Test-Puerto $puerto)) { $ok = $true; break }
        if ($proceso -and (Get-Process $proceso -EA SilentlyContinue)) { $ok = $true; break }
        if ($esperaVentanaCmd) {
            $ahora = (Get-Process cmd -EA SilentlyContinue | Measure-Object).Count
            if ($ahora -gt $cmdAntes) { $ok = $true; break }
        }
    }
    $seg = [math]::Round(((Get-Date) - $t0).TotalSeconds, 0)
    if ($ok) { Write-Output "  OK      arranco en $seg s" } else { Write-Output "  FALLO   no arranco en $seg s" }
    $script:resultados += [PSCustomObject]@{ Acceso=$nombre; Resultado=$(if ($ok) { "OK ($seg s)" } else { "FALLO" }) }
}

Write-Output "================================================"
Write-Output "  PRUEBA DE TODOS LOS ACCESOS DE 'IA Local'"
Write-Output "================================================"

Parar-Todo
Probar '2 - Chat simple (llama.cpp).lnk'      8080 $null 120 $false
Parar-Todo
Probar '5 - Imagenes (ComfyUI).lnk'           8188 $null 150 $false
Parar-Todo
Probar '1 - Chat unificado (Open WebUI).lnk'  3000 $null 240 $false
Parar-Todo
Probar '0 - TODO EN UNO (Goose Desktop).lnk'  0 'Goose' 180 $false
Parar-Todo
Probar '4 - Agente (Goose).lnk'               0 $null 150 $true
Parar-Todo
Probar '3 - Programar (Aider).lnk'            0 $null 150 $true

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
