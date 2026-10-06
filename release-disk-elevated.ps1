# Libera o NVMe do WSL e devolve ao sistema (ELEVADO).
$ErrorActionPreference='Continue'
$disk='\\.\PHYSICALDRIVE3'
$LOG='\\wsl$\Ubuntu-24.04\root\winux\out\release.log'
function Say($m){ Write-Host $m; try{Add-Content $LOG $m}catch{} }
Say "=== liberando o NVMe $(Get-Date -Format 'HH:mm:ss') ==="
# desmonta montagens pendentes no WSL
wsl -d Ubuntu-24.04 -e bash -c 'umount /tmp/rc /tmp/v /mnt /mnt-src 2>/dev/null; sync' 2>&1 | Out-String | ForEach-Object { if($_.Trim()){Say $_} }
wsl --unmount $disk 2>&1 | Out-String | ForEach-Object { if($_.Trim()){Say ("unmount: "+$_)} }
Start-Sleep -Seconds 2
try { Set-Disk -Number 3 -IsReadOnly $false; Set-Disk -Number 3 -IsOffline $false; Say "disco 3 online (pronto p/ boot pelo BIOS)" } catch { Say "aviso online: $_" }
Say "=== FIM ==="
Read-Host | Out-Null