# Anexa o NVMe ao WSL e DEIXA ANEXADO (para depurar o instalador sem repetir UAC).
$ErrorActionPreference = 'Continue'
$disk = '\\.\PHYSICALDRIVE3'
$LOG = '\\wsl$\Ubuntu-24.04\root\winux\out\mount.log'
function Say($m){ Write-Host $m; try { Add-Content -Path $LOG -Value $m } catch {} }

Say "=== mount $(Get-Date -Format 'HH:mm:ss') ==="
try { Set-Disk -Number 3 -IsOffline $true; Say "disco 3 offline OK" } catch { Say "Set-Disk offline: $_" }
$m = (wsl --mount $disk --bare 2>&1 | Out-String)
Say ("wsl --mount: " + $m.Trim())
Start-Sleep -Seconds 4
$d = (wsl -d Ubuntu-24.04 -e bash -c 'lsblk -dno NAME,SIZE 2>/dev/null' 2>&1 | Out-String)
Say ("dispositivos: " + $d.Replace("`n"," | "))
Say "disco anexado e mantido. Feche esta janela (Read-Host)."
Read-Host | Out-Null