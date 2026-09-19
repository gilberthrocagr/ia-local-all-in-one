# Barrido de --spec-draft-n-max para MTP. Baseline sin MTP: 28.20 tok/s. n-max 2: 36.59 tok/s
$ErrorActionPreference = 'Continue'
$env:PATH = 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.2\bin\x64;' + $env:PATH
$BIN   = 'C:\AI\llama.cpp\build\bin\llama-server.exe'
$MODEL = 'C:\AI\models\llm\Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf'
$PROMPT = 'Escribe una funcion Python que valide un numero de cedula venezolana. Incluye docstring y manejo de errores.'

$out = @()
foreach ($n in 3,4,5) {
    Write-Output "=== probando --spec-draft-n-max $n ==="
    Get-Process llama-server -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    Start-Sleep -Seconds 4

    $args = @('-m', $MODEL, '--n-cpu-moe','99','--n-gpu-layers','99','--flash-attn','on',
              '-ctk','q8_0','-ctv','q8_0','-c','65536','-b','512','-ub','128',
              '--load-mode','mlock','--jinja','-a','qwen3.6','--reasoning-budget','1500',
              '--spec-type','draft-mtp','--spec-draft-n-max',"$n",
              '--temp','0.6','--top-p','0.95','--top-k','20',
              '--host','127.0.0.1','--port','8080')
    Start-Process -FilePath $BIN -ArgumentList $args -WindowStyle Hidden

    $ready = $false
    for ($i=0; $i -lt 50; $i++) {
        Start-Sleep -Seconds 3
        try { $null = Invoke-RestMethod 'http://127.0.0.1:8080/v1/models' -TimeoutSec 3 -EA Stop; $ready=$true; break } catch {}
    }
    if (-not $ready) { Write-Output "  no arranco con n-max $n"; continue }

    $runs = @()
    for ($k=1; $k -le 3; $k++) {
        $b = @{ messages=@(@{role='user';content=$PROMPT}); max_tokens=250; chat_template_kwargs=@{enable_thinking=$false} } | ConvertTo-Json -Depth 5
        try {
            $r = Invoke-RestMethod 'http://127.0.0.1:8080/v1/chat/completions' -Method Post -Body $b -ContentType 'application/json' -TimeoutSec 300
            $runs += [math]::Round($r.timings.predicted_per_second, 2)
        } catch { Write-Output "  fallo run $k" }
    }
    if ($runs.Count -gt 0) {
        $avg = [math]::Round((($runs | Measure-Object -Average).Average), 2)
        $vram = [int]((nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits) -split "`n")[0]
        Write-Output "  runs: $($runs -join ', ')  ->  PROMEDIO $avg tok/s  (VRAM $vram MiB)"
        $out += [PSCustomObject]@{ n_max=$n; avg=$avg; runs=($runs -join ' '); vram=$vram }
    }
}

Write-Output ''
Write-Output '=== RESUMEN ==='
Write-Output 'sin MTP      : 28.20 tok/s'
Write-Output 'MTP n-max 2  : 36.59 tok/s'
$out | ForEach-Object { "MTP n-max $($_.n_max)  : $($_.avg) tok/s   (VRAM $($_.vram) MiB)" }
