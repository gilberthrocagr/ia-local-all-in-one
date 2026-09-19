# Cambia el perfil de Goose antes de abrirlo.
#
# POR QUE: cada extension mete las definiciones de sus herramientas en el prompt
# del sistema EN CADA MENSAJE. Medido en esta maquina con "hola estas aqui":
#
#   solo developer                      21,7 s
#   + comfyui + framepack              249,4 s   <- 11 veces mas lento
#   + las 9 extensiones de plataforma  314,3 s
#
# comfy-mcp es el caro: sus herramientas traen descripciones larguisimas.
#
# Uso:
#   goose-perfil.ps1 -Perfil codigo    -> rapido, solo editar/ejecutar
#   goose-perfil.ps1 -Perfil completo  -> lento, con imagenes y video
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('codigo','completo')]
    [string]$Perfil,
    [switch]$Abrir
)

$cfg = "$env:APPDATA\Block\goose\config\config.yaml"
if (-not (Test-Path $cfg)) { Write-Error "No existe $cfg"; exit 1 }

# Goose reescribe el fichero al cerrarse; hay que cerrarlo antes de tocarlo
Get-Process Goose -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$activar = ($Perfil -eq 'completo')
$texto = [IO.File]::ReadAllText($cfg)

foreach ($ext in @('comfyui','framepack')) {
    $valor = if ($activar) { 'true' } else { 'false' }
    $texto = $texto -replace "(?ms)(  $ext`:\r?\n    )enabled: (true|false)", "`$1enabled: $valor"
}

# UTF8 SIN BOM: con BOM el parser YAML de Goose falla con
# "No provider configured"
[IO.File]::WriteAllText($cfg, $texto, (New-Object System.Text.UTF8Encoding($false)))

# Comprobacion
$lineas = Get-Content $cfg
$actual = $null; $activas = @(); $enExt = $false
foreach ($l in $lineas) {
    if ($l -match '^extensions:\s*$') { $enExt = $true } elseif ($l -match '^\w') { $enExt = $false }
    if ($enExt -and $l -match '^  (\w+):\s*$') { $actual = $matches[1] }
    if ($enExt -and $actual -and $l -match '^    enabled: true') { $activas += $actual; $actual = $null }
    elseif ($enExt -and $actual -and $l -match '^    enabled: false') { $actual = $null }
}

Write-Output "Perfil: $Perfil"
Write-Output "Extensiones activas: $($activas -join ', ')"
if ($Perfil -eq 'completo') {
    Write-Output "AVISO: con imagenes y video cada mensaje tarda varios minutos."
} else {
    Write-Output "Rapido: ~20 s por mensaje. Sin imagenes ni video."
}

if (-not $Abrir) { return }

# IMPORTANTE: hay que arrancar el modelo ANTES de abrir Goose y ESPERAR a que
# responda. Si no, la ventana abre en 4 segundos pero no hay nadie al otro lado:
# escribes y no contesta, porque el modelo sigue cargando sus 22 GB.
function Puerto-Abierto($p) {
    return (Test-NetConnection -ComputerName '127.0.0.1' -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue)
}

function Asegurar-Servicio($script, $puerto, $segundos) {
    if (Puerto-Abierto $puerto) { return $true }
    Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $script -WindowStyle Minimized
    $fin = (Get-Date).AddSeconds($segundos)
    while ((Get-Date) -lt $fin) {
        Start-Sleep -Seconds 2
        if (Puerto-Abierto $puerto) { return $true }
    }
    return $false
}

$modeloListo = Asegurar-Servicio 'C:\AI\start-qwen.cmd' 8080 150
if (-not $modeloListo) {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show(
        "El modelo no arranco en 2,5 minutos.`n`nAbre C:\AI\start-qwen.cmd a mano para ver el error.",
        'IA - Goose') | Out-Null
    return
}

# El perfil completo necesita ademas ComfyUI para generar imagenes
if ($Perfil -eq 'completo') {
    Asegurar-Servicio 'C:\AI\start-comfy.cmd' 8188 150 | Out-Null
}

Start-Process 'C:\AI\GooseDesktop\Goose.exe'
