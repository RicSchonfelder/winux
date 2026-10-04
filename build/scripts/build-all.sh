#!/bin/sh
# build-all.sh - pipeline completo do Winux
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for s in 00-deps 10-kernel 20-userspace 30-desktop 40-initramfs 45-bootfiles 50-iso; do
    echo "==================== $s ===================="
    "$ROOT/build/scripts/$s.sh"
done

echo ">> build concluido. Artefatos em $ROOT/artifacts/ e $ROOT/out/"
echo ">> Instalacao no disco alvo: build/scripts/70-dualboot.sh /dev/nvmeXnY --yes"