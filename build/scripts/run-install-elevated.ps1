# Executa a instalacao do Winux no NVMe via WSL. Precisa rodar ELEVADO.
$ErrorActionPreference = 'Continue'
$disk = '\\.\PHYSICALDRIVE3'
$LOG = '\\wsl$\Ubuntu-24.04\root\winux\out\elevated.log'
function Say($m){ Write-Host $m; try { Add-Content -Path $LOG -Value $m } catch {} }

Say "=== Winux install (elevated) $(Get-Date -Format 'HH:mm:ss') ==="

# 0) garante que o NVMe (Disk 3) esta OFFLINE para o wsl --mount poder anexa-lo
Say "[0/3] colocando o disco 3 offline..."
try { Set-Disk -Number 3 -IsOffline $true; Say "  disco 3 offline OK" } catch { Say "  aviso: Set-Disk falhou: $_" }

Say "[1/3] anexando $disk ao WSL..."
$mountOut = (wsl --mount $disk --bare 2>&1 | Out-String)
Say ("  wsl --mount said: " + $mountOut.Trim())
Start-Sleep -Seconds 4
$devs = (wsl -d Ubuntu-24.04 -e bash -c 'lsblk -dno NAME,SIZE 2>/dev/null | tr "\n" ";"' 2>&1 | Out-String)
Say ("  dispositivos no WSL: " + $devs.Trim())

Say "[2/3] rodando o instalador dentro do WSL..."
# captura toda a saida num arquivo legivel (o console elevado nao e acessivel aqui)
$wslLog = '\\wsl$\Ubuntu-24.04\root\winux\out\installer-stdout.log'
wsl -d Ubuntu-24.04 -e bash /root/winux/build/scripts/71-install-from-wsl.sh *>&1 | Tee-Object -FilePath $wslLog
Say "instalador retornou codigo: $LASTEXITCODE"

Say "[3/3] liberando o disco do WSL..."
wsl --unmount $disk 2>&1 | Out-String | ForEach-Object { if($_.Trim()){Say "  unmount: $_"} }
Start-Sleep -Seconds 2
try { Set-Disk -Number 3 -IsOnline $true; Say "  disco 3 online de volta" } catch { Say "  aviso: Set-Disk online falhou: $_" }

Say "=== FIM. Logs: install-nvme.log + installer-stdout.log (em /root/winux/out) ==="
Write-Host ""
Write-Host "PRESSIONE ENTER PARA FECHAR ESTA JANELA..."
Read-Host | Out-Null
