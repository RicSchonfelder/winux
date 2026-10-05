#!/bin/sh
# 90-qemu-install-test.sh - teste END-TO-END do instalador em discos VIRTUAIS.
# Cria ISO com winux.autoinstall, um NVMe virtual, roda a instalacao e
# depois tenta bootar o disco instalado. Nada toca o hardware real.
#   uso: 90-qemu-install-test.sh [fase] [segundos]   fase = install|boot
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
TGT="$ROOT/out/test-target.qcow2"
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/vars.fd

FASE="${1:-install}"
QT="${2:-900}"

if [ "$FASE" = "install" ]; then
    rm -rf "$ROOT/iso-test"; cp -a "$ROOT/iso" "$ROOT/iso-test"
    sed -i "s#boot=live quiet console=ttyS0#boot=live quiet console=ttyS0 winux.autoinstall=/dev/nvme0n1 winux.mingb=5#" \
        "$ROOT/iso-test/boot/grub/grub.cfg"
    grub-mkrescue -o "$ROOT/out/winux-test.iso" "$ROOT/iso-test" >/dev/null 2>&1
    echo ">> ISO de teste: $ROOT/out/winux-test.iso"

    # disco de 20G: suficiente pro sistema e rapido p/ mkfs.btrfs no qcow2 esparso
    rm -f "$TGT"; qemu-img create -f qcow2 "$TGT" 20G >/dev/null
    LOG="$ROOT/out/install-test.log"; rm -f "$LOG"
    timeout "$QT" qemu-system-x86_64 -M q35 -m 3072 -accel tcg -cpu max -smp 4 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file=/tmp/vars.fd \
        -drive file="$ROOT/out/winux-test.iso",media=cdrom,readonly=on \
        -drive file="$TGT",if=none,id=tgt,format=qcow2 \
        -device nvme,drive=tgt,serial=winuxtest \
        -boot d -display none -serial file:"$LOG" >/dev/null 2>&1 || true
    echo ">> marcos da instalacao:"
    grep -aE 'Plano de instalacao|Disco alvo|reparticionando|criando subvol|copiando o sistema|instalando o GRUB|Windows encontrado|INSTALACAO CONCLUIDA|ERRO|rsync falhou' "$LOG" \
        | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tail -25 || true
fi

if [ "$FASE" = "boot" ]; then
    LOG="$ROOT/out/boot-test.log"; rm -f "$LOG"
    timeout "$QT" qemu-system-x86_64 -M q35 -m 3072 -accel tcg -cpu max -smp 4 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file=/tmp/vars.fd \
        -drive file="$TGT",if=none,id=tgt,format=qcow2 \
        -device nvme,drive=tgt,serial=winuxtest \
        -boot c -display none -serial file:"$LOG" >/dev/null 2>&1 || true
    echo ">> boot do disco instalado:"
    grep -aoE 'GNU GRUB|Winux \(alto desempenho\)|Linux version [^ ]+|systemd\[1\]: Reached target [^ ]+|login:|Debian GNU/Linux [0-9]+|panic' "$LOG" \
        | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | tail -25 || true
fi