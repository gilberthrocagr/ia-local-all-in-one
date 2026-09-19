# Observa si un mensaje escrito en Goose Desktop llega realmente al modelo.
# Registra cada 2 s: uso de GPU, conexiones al LLM y peticiones nuevas en el log.
$logs = "$env:APPDATA\Block\goose\data\logs"
$duracion = 180

$peticionesAntes = (Get-ChildItem $logs -Recurse -Filter 'llm_request*.jsonl' -EA SilentlyContinue).Count
Write-Output "Peticiones al modelo registradas antes de empezar: $peticionesAntes"
Write-Output "Observando durante $duracion segundos. ESCRIBE AHORA EN GOOSE."
Write-Output ""
Write-Output "hora      GPU%   conexiones-LLM   peticiones"
Write-Output "--------  -----  ---------------  ----------"

$t0 = Get-Date
$huboActividad = $false
$maxGpu = 0

while (((Get-Date) - $t0).TotalSeconds -lt $duracion) {
    $gpu = [int]((nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits) -split "`n")[0]
    if ($gpu -gt $maxGpu) { $maxGpu = $gpu }
    $conex = (Get-NetTCPConnection -RemotePort 8080 -State Established -EA SilentlyContinue | Measure-Object).Count
    $peticiones = (Get-ChildItem $logs -Recurse -Filter 'llm_request*.jsonl' -EA SilentlyContinue).Count
    if ($gpu -gt 20 -or $conex -gt 0 -or $peticiones -gt $peticionesAntes) { $huboActividad = $true }
    "{0}  {1,5}  {2,15}  {3,10}" -f (Get-Date -Format 'HH:mm:ss'), $gpu, $conex, $peticiones
    Start-Sleep -Seconds 2
}

Write-Output ""
Write-Output "=========================================="
$peticionesDespues = (Get-ChildItem $logs -Recurse -Filter 'llm_request*.jsonl' -EA SilentlyContinue).Count
Write-Output "peticiones nuevas al modelo: $($peticionesDespues - $peticionesAntes)"
Write-Output "pico de GPU: $maxGpu %"
Write-Output ""
if ($huboActividad) {
    Write-Output "VEREDICTO: el mensaje SI llego al modelo (hubo actividad)."
    Write-Output "Si no viste respuesta, es que tardaba, no que se perdiera."
} else {
    Write-Output "VEREDICTO: NO llego nada al modelo."
    Write-Output "Goose no esta enviando la peticion: el problema esta en la app,"
    Write-Output "no en el modelo ni en la GPU."
}

# El ultimo log de sesion, por si registro algo util
$ultimo = Get-ChildItem $logs -Recurse -Filter '*.log' -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ultimo -and $ultimo.Length -gt 0) {
    Write-Output ""
    Write-Output "=== ULTIMAS LINEAS DEL LOG DE GOOSE ==="
    Get-Content $ultimo.FullName -Tail 12
}
