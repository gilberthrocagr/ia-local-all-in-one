# Mide si la ganancia de MTP aguanta con contexto largo (el caso real de Aider)
$ErrorActionPreference = 'Continue'
$env:PATH = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin\x64;' + $env:PATH
$BIN = 'C:\AI\llama.cpp\build\bin\llama-server.exe'
$MODEL_MTP = 'C:\AI\models\llm\Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf'
$MODEL_STD = 'C:\AI\models\llm\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf'

# Contexto de codigo real (lo que Aider cargaria)
$src = @()
Get-ChildItem 'C:\AI\llama.cpp\src','C:\AI\llama.cpp\common' -Filter '*.cpp' -EA SilentlyContinue |
    Sort-Object Length -Descending | Select-Object -First 6 | ForEach-Object {
        $src += (Get-Content $_.FullName -Raw -EA SilentlyContinue)
    }
$big = $src -join "`n`n"

function Get-Ctx($approxTokens) {
    $chars = $approxTokens * 4
    if ($big.Length -lt $chars) { return $big }
    return $big.Substring(0, $chars)
}

function Measure-Config($label, $model, $useMtp) {
    Write-Output "=== $label ==="
    Get-Process llama-server -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 4
    $a = @('-m',$model,'--n-cpu-moe','99','--n-gpu-layers','99','--flash-attn','on',
           '-ctk','q8_0','-ctv','q8_0','-c','65536','-b','512','-ub','128',
           '--load-mode','mlock','--jinja','-a','qwen3.6','--reasoning-budget','1500',
           '--temp','0.6','--top-p','0.95','--top-k','20','--host','127.0.0.1','--port','8080')
    if ($useMtp) { $a += @('--spec-type','draft-mtp','--spec-draft-n-max','2') }
    Start-Process -FilePath $BIN -ArgumentList $a -WindowStyle Hidden
    $ready=$false
    for ($i=0; $i -lt 50; $i++) { Start-Sleep -Seconds 3
        try { $null=Invoke-RestMethod 'http://127.0.0.1:8080/v1/models' -TimeoutSec 3 -EA Stop; $ready=$true; break } catch {} }
    if (-not $ready) { Write-Output "  no arranco"; return }

    foreach ($depth in 0, 8000, 16000, 32000) {
        $ctx = if ($depth -eq 0) { "" } else { Get-Ctx $depth }
        $q = if ($depth -eq 0) { "Escribe una funcion Python que valide un numero de cedula venezolana." }
             else { "Aqui tienes codigo fuente:`n`n$ctx`n`nResume en 3 lineas que hace este codigo." }
        $runs=@(); $ptok=0
        for ($k=1; $k -le 2; $k++) {
            $b = @{ messages=@(@{role='user';content=$q}); max_tokens=200; chat_template_kwargs=@{enable_thinking=$false} } | ConvertTo-Json -Depth 5 -Compress
            try {
                $r = Invoke-RestMethod 'http://127.0.0.1:8080/v1/chat/completions' -Method Post -Body $b -ContentType 'application/json' -TimeoutSec 600
                $runs += [math]::Round($r.timings.predicted_per_second,2)
                $ptok = $r.usage.prompt_tokens
            } catch { Write-Output "    fallo: $($_.Exception.Message)" }
        }
        if ($runs.Count -gt 0) {
            $avg = [math]::Round((($runs | Measure-Object -Average).Average),2)
            Write-Output ("  contexto {0,6} tokens reales -> {1,6} tok/s   (runs: {2})" -f $ptok, $avg, ($runs -join ', '))
        }
    }
}

Measure-Config 'CON MTP (n-max 2)' $MODEL_MTP $true
Measure-Config 'SIN MTP' $MODEL_STD $false
Write-Output ''
Write-Output 'FIN'
