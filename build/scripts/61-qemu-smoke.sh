#!/bin/sh
# 61-qemu-smoke.sh - smoke test HEADLESS do Winux no QEMU
# Boota o kernel + initrd do ISO por serial (sem display).
#   uso: 61-qemu-smoke.sh [segundos]   (default 240)
# SAI: lista os marcos de boot encontrados no log serial.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"

ISO="$ROOT/out/$DISTRO_NAME-$DISTRO_VER.iso"
VMLINUZ="$ROOT/iso/live/vmlinuz-$KVER"
INITRD="$ROOT/iso/live/initrd.img"
LOG=/tmp/winux-smoke.log
SECS="${1:-240}"

[ -f "$VMLINUZ" ] && [ -f "$INITRD" ] || { echo "kernel/initrd ausentes. Rode 45+40 antes."; exit 1; }

rm -f "$LOG"
timeout "$SECS" qemu-system-x86_64 -M q35 -m 2048 -accel tcg -cpu max -smp 2 \
    -kernel "$VMLINUZ" -initrd "$INITRD" \
    -append "boot=live console=ttyS0" \
    -drive file="$ISO",media=cdrom,readonly=on \
    -display none -serial file:"$LOG" >/dev/null 2>&1 || true

echo ">> log serial: $LOG ($(wc -c < "$LOG") bytes)"
echo ">> marcos de boot:"
grep -aoE 'Linux version [^ ]+|Command line: [^"]*|Freeing initrd memory[^"]*|Run /init as init process|systemd\[1\]: (Reached target|Started|Failed) [^ ]+|live-boot: [^ ]+|Reached target Graphical Interface|login:|Kernel panic|Oops' "$LOG" \
    | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | sort | uniq -c | sort -rn | head -25 || true