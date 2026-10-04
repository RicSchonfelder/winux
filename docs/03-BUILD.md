# 03 — Como compilar (WSL Ubuntu 24.04)

O build roda no WSL (mesma máquina, mas ambiente Linux). Kernel e ISO são
x86_64 nativos — sem cross-compile.

## Passos

```bash
cd /mnt/c/Users/ricar/winux

# 1. toolchain
build/scripts/00-deps.sh

# 2. pipeline completo
build/scripts/build-all.sh
```

O pipeline executa: `00-deps → 10-kernel → 20-userspace → 30-desktop →
40-initramfs → 45-bootfiles → 50-iso`.

## Artefatos

```
src/                    fontes (kernel baixado)
out/bzImage-<ver>       kernel compilado
out/modules/            módulos instalados (p/ DKMS)
out/rootfs/             rootfs Debian completo
out/winux-<ver>.iso     ISO UEFI bootável (live, squashfs)
```

## Teste no QEMU

```bash
build/scripts/60-qemu-test.sh
```

> No WSL2 normalmente não há `/dev/kvm` → QEMU roda em TCG (lento, mas serve
> como smoke-test de boot). O ISO é UEFI (OVMF).

## Otimizações ativas

- `KCFLAGS="-march=haswell -mtune=haswell -O2"` (AVX2).
- Fragmento `haswell-desktop.fragment`: governor `performance`, preempt de
  baixa latência, `HZ=1000`, io_uring, NVMe, BTRFS/XFS, `nouveau` off.