#!/bin/sh
# finalize-installed.sh - limpa artefatos de teste do Winux instalado
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /tmp/rc
mountpoint -q /tmp/rc || mount -o compress=zstd:1 /dev/sdg2 /tmp/rc
echo "removendo residuos do autoinstall de teste..."
rm -f /tmp/rc/etc/systemd/system/winux-autoinstall.service
rm -f /tmp/rc/etc/systemd/system/multi-user.target.wants/winux-autoinstall.service
rm -f /tmp/rc/usr/local/bin/winux-install
rm -f /tmp/rc/usr/local/bin/winux-autoinstall.sh
rmdir /tmp/rc/usr/local/bin 2>/dev/null || true
echo "feito. Residuos restantes:"
ls /tmp/rc/etc/systemd/system/ 2>/dev/null | grep -i winux || echo "  (nenhum)"
umount /tmp/rc
echo "OK"