#!/bin/sh
# analisa o log de boot do Winux instalado
LOG=/root/winux/out/installed-boot.log
tr -d '\r' < "$LOG" > /tmp/bl.txt 2>/dev/null
echo "=== linhas total ==="; wc -l < /tmp/bl.txt
echo "=== fase initramfs/root ==="
grep -aiE 'ALERT|Begin|Mounting root|not found|unable|cannot|switch_root|BusyBox|BTRFS|does not exist|waiting for|Start|Initramfs|Unmount' /tmp/bl.txt | head -30
echo "=== ultimas 20 linhas relevantes ==="
tail -25 /tmp/bl.txt