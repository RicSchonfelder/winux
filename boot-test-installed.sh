#!/bin/sh
# boot-test-installed.sh - boota o Winux INSTALADO (disco real) no QEMU,
# em modo somente-leitura (snapshot), p/ confirmar que da para bootar.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "desmontando montagens temporarias..."
umount /tmp/v 2>/dev/null || true
umount /tmp/r 2>/dev/null || true

cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/bvars.fd
echo "disco alvo:"; lsblk -no NAME,SIZE,MODEL /dev/sdg

timeout 550 qemu-system-x86_64 -M q35 -m 4096 -accel tcg -cpu max -smp 4 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=/tmp/bvars.fd \
    -drive file=/dev/sdg,format=raw,if=none,id=d0,snapshot=on \
    -device nvme,drive=d0,serial=WINUXREAL \
    -boot c -display none -serial file:/root/winux/out/installed-boot.log \
    >/dev/null 2>&1 || true

echo "=== marcos do boot ==="
grep -aoE 'GNU GRUB|Winux \(alto desempenho\)|Windows 11|Linux version [^ ]+|systemd\[1\]: Reached target [^ ]+|login:|Debian GNU/Linux [0-9]+|panic|error' \
    /root/winux/out/installed-boot.log 2>/dev/null | head -30
echo "=== ultimas linhas ==="
tail -c 400 /root/winux/out/installed-boot.log 2>/dev/null | tr -d '\r'