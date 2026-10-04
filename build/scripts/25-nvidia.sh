#!/bin/sh
# 25-nvidia.sh - driver NVIDIA proprietario (DKMS) no rootfs
# Roda APOS o kernel estar instalado no rootfs (veja 70-dualboot.sh / install).
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"

# headers do nosso kernel dentro do rootfs (copiados na instalacao)
chroot "$RFS" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends nvidia-driver nvidia-kernel-dkms
    dkms autoinstall || true
'

# nunca deixa o nouveau competir com o modulo NVIDIA
cat > "$RFS/etc/modprobe.d/blacklist-nouveau.conf" <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF

echo ">> nvidia ok"