# Prueba los tres accesos sueltos del escritorio como lo haria una persona:
# doble clic. Verifica que el servicio arranca y cuanto tarda, y cuenta las
# consolas nuevas. Si alguno falla, el resumen lo dice.
$desk = [Environment]::GetFolderPath('Desktop')
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
    Get-Process llama-server -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Get-Process open-webui -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Get-Process python -EA SilentlyContinue | Where-Object { $_.Path -like '*ComfyUI*' -or $_.Path -like '*FramePack*' } | Stop-Process -Force -EA SilentlyContinue
    Get-Process Goose -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 4
}

# Los mensajes van con Write-Host a proposito: lo que sale con Write-Output
# dentro de una funcion forma parte de lo que devuelve. Antes $resultados
# guardaba una lista de textos, que PowerShell da siempre por verdadera, y el
# resumen salia OK aunque el acceso ni existiera.
function Probar($nombre, $lnk, $puerto, $maxSeg, $procesoExtra) {
    Write-Host ""
    Write-Host "--- $nombre ---"
    $ruta = Join-Path $desk $lnk
    if (-not (Test-Path $ruta)) { Write-Host "  FALLO: no existe el acceso directo $ruta"; return $false }

    $cmdAntes = (Get-Process cmd -EA SilentlyContinue | Measure-Object).Count
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
        if ($puerto -gt 0) { if (Test-Puerto $puerto) { $ok = $true; break } }
        elseif ($procesoExtra) { if (Get-Process $procesoExtra -EA SilentlyContinue) { $ok = $true; break } }
    }
    $seg = [math]::Round(((Get-Date) - $t0).TotalSeconds, 0)
    $cmdDespues = (Get-Process cmd -EA SilentlyContinue | Measure-Object).Count
    $ventanasNuevas = $cmdDespues - $cmdAntes

    if ($ok) { Write-Host "  OK      arranco en $seg s" }
    else     { Write-Host "  FALLO   no arranco en $seg s" }
    # Solo informativo: cada servidor corre en su consola minimizada, asi que
    # lo normal es una por servicio arrancado. Mira si alguna quedo delante.
    Write-Host "  procesos cmd nuevos: $ventanasNuevas (los servidores van en consolas minimizadas)"
    return $ok
}

Write-Output "========================================="
Write-Output "  PRUEBA DE LOS LANZADORES"
Write-Output "========================================="
Write-Output "Parando todo para partir de cero..."
Parar-Todo

$resultados = @{}
$resultados['IA - Imagenes']         = Probar 'IA - Imagenes (ComfyUI)'      'IA - Imagenes.lnk'          8188 150 $null
Parar-Todo
$resultados['IA - Chat y documentos'] = Probar 'IA - Chat y documentos (Open WebUI)' 'IA - Chat y documentos.lnk' 3000 240 $null
Parar-Todo
$resultados['IA - Todo en uno']      = Probar 'IA - Todo en uno (Goose Desktop)' 'IA - Todo en uno.lnk'   0    180 'Goose'

Write-Output ""
Write-Output "========================================="
Write-Output "  RESUMEN"
Write-Output "========================================="
foreach ($k in $resultados.Keys | Sort-Object) {
    "{0,-26} {1}" -f $k, $(if ($resultados[$k]) { 'OK' } else { 'FALLO' })
}
$fallos = ($resultados.Values | Where-Object { -not $_ } | Measure-Object).Count
Write-Output ""
Write-Output "fallos: $fallos de $($resultados.Count)"
