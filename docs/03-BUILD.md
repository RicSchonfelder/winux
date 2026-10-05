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
build/scripts/61-qemu-smoke.sh 300   # headless: boota kernel+initrd por serial
build/scripts/60-qemu-test.sh        # interativo (janela)
```

> O `61-qemu-smoke.sh` é o teste confiável: verifica se o ISO chega ao
> `login:` no serial. No WSL2 normalmente não há `/dev/kvm` → QEMU roda em
> TCG (lento, mas válido como smoke-test). UEFI via OVMF (carregado como
> `pflash`, não `-bios`).

## Otimizações ativas

- `KCFLAGS="-march=haswell -mtune=haswell -O2"` (AVX2).
- Config do kernel: `make defconfig` (base sanada p/ desktop — `tinyconfig`
  não serve para Debian/systemd/XFCE, faltaria PRINTK/SYSFS/ELF/CGROUPS) +
  merge do fragmento `haswell-desktop.fragment` + `olddefconfig`.
- Fragmento: governor `performance`, preempt de baixa latência, `HZ=1000`,
  io_uring, NVMe builtin, BTRFS/XFS, squashfs/overlay (live), `nouveau` off.