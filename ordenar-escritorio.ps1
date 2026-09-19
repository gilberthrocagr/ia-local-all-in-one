# Ordena el escritorio agrupando accesos directos en carpetas.
# NO borra nada: solo mueve. Guarda un registro para poder revertir.
$desk = [Environment]::GetFolderPath('Desktop')
$registro = Join-Path $desk 'IA Local\_escritorio-antes-de-ordenar.txt'

# Registro del estado original, por si hay que revertir
"Estado del escritorio antes de ordenar - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File $registro -Encoding UTF8
"Para revertir: arrastra los ficheros de vuelta al escritorio." | Out-File $registro -Append -Encoding UTF8
"" | Out-File $registro -Append -Encoding UTF8
Get-ChildItem $desk | ForEach-Object { $_.Name } | Out-File $registro -Append -Encoding UTF8

$grupos = @{
    'Deliservy' = @(
        'Deliservy.lnk',
        'Deliservy - BlueStacks App Player 15.lnk',
        'Deliservy - BlueStacks App Player 16.lnk',
        'Deliservy - BlueStacks App Player 17.lnk',
        'HP Deliservy1.lnk',
        'HP Deliservy2.lnk',
        'a2AdminFL - Acceso directo.lnk',
        'DirectoriosA2.exe',
        'F04.pdf'
    )
    'Comunicacion' = @(
        'WhatsApp.lnk',
        'WhatsApp - BlueStacks App Player 15.lnk',
        'WhatsApp - BlueStacks App Player 16.lnk',
        'Gmail - BlueStacks App Player 15.lnk',
        'Gmail - BlueStacks App Player 16.lnk',
        'Gmail - BlueStacks App Player 17.lnk'
    )
    'Navegadores' = @(
        'Firefox.exe',
        'Gilberth - Chrome.lnk',
        'Microsoft Edge.lnk'
    )
    'Herramientas' = @(
        'Visual Studio Code.lnk',
        'PowerToys (Preview).lnk',
        'Remote Desktop Connection.lnk',
        'ZeroTier.lnk',
        'Macbook Gilberth.lnk'
    )
}

foreach ($grupo in $grupos.Keys | Sort-Object) {
    $destino = Join-Path $desk $grupo
    New-Item -ItemType Directory -Force -Path $destino | Out-Null
    Write-Output "--- $grupo ---"
    foreach ($fichero in $grupos[$grupo]) {
        $origen = Join-Path $desk $fichero
        if (Test-Path $origen) {
            try {
                Move-Item -Path $origen -Destination $destino -Force -ErrorAction Stop
                Write-Output "  movido: $fichero"
            } catch {
                Write-Output "  NO se pudo mover $fichero : $($_.Exception.Message)"
            }
        } else {
            Write-Output "  (no estaba: $fichero)"
        }
    }
}

Write-Output ""
Write-Output "=== ESCRITORIO DESPUES ==="
Get-ChildItem $desk | Sort-Object { -not $_.PSIsContainer }, Name | ForEach-Object {
    $t = if ($_.PSIsContainer) { '[carpeta]' } else { '          ' }
    "  $t $($_.Name)"
}
Write-Output ""
Write-Output "Registro guardado en: $registro"
