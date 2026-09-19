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

if ($Abrir) { Start-Process 'C:\AI\GooseDesktop\Goose.exe' }
