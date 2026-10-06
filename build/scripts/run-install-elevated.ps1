# Executa a instalacao do Winux no NVMe via WSL. Precisa rodar ELEVADO.
$ErrorActionPreference = 'Continue'
$disk = '\\.\PHYSICALDRIVE3'

Write-Host "[1/3] anexando $disk ao WSL..."
wsl --mount $disk --bare
Start-Sleep -Seconds 3

Write-Host "[2/3] rodando o instalador dentro do WSL..."
wsl -d Ubuntu-24.04 -e bash /root/winux/build/scripts/71-install-from-wsl.sh
$rc = $LASTEXITCODE
Write-Host "instalador retornou: $rc"

Write-Host "[3/3] liberando o disco do WSL..."
wsl --unmount $disk

Write-Host "FIM. Verifique o log: \\wsl$\Ubuntu-24.04\root\winux\out\install-nvme.log"
