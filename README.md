# Winux

Distro Linux **desktop otimizada para a máquina do Ric** (ASUS, Intel Core
i7-4771 **Haswell**, 24GB RAM, **GTX 1060 6GB**), com **visual Windows 98** e
**dual-boot seguro** com Windows 11.

Objetivos:

- **Alto desempenho real**: kernel `-march=haswell`, governor `performance`,
  preempt de baixa latência, DE leve (XFCE). O maior ganho medido é eliminar
  a paginação do Windows (hoje 54GB de commit em 24GB RAM → swap ativo).
- **Visual Windows 98**: tema **Chicago95** (ícones/GTK/xfwm) no XFCE4.
- **Dual-boot sem risco**: Windows (disco Kingston/UEFI) **nunca é tocado**;
  GRUB só no NVMe dedicado, `default=winux timeout=10`, com entrada pro
  Windows via chainload. Adobe e programas Windows-only continuam no Windows.
- **Userspace**: Debian (debootstrap) + X11 + driver NVIDIA proprietário
  (DKMS) — estável e compatível com a GTX 1060 (Pascal).

## Documentação

| Doc | Assunto |
|-----|---------|
| [`docs/00-VISAO.md`](docs/00-VISAO.md) | Visão geral e decisões |
| [`docs/01-HARDWARE.md`](docs/01-HARDWARE.md) | Hardware da máquina + drivers |
| [`docs/02-BOOT.md`](docs/02-BOOT.md) | Estratégia de boot (dual-boot seguro) |
| [`docs/03-BUILD.md`](docs/03-BUILD.md) | Como compilar (WSL) |
| [`docs/04-INSTALL-dualboot.md`](docs/04-INSTALL-dualboot.md) | Instalação no NVMe |
| [`docs/05-UPGRADE.md`](docs/05-UPGRADE.md) | Atualizações |

## Build rápido (WSL)

```
build/scripts/00-deps.sh      # toolchain
build/scripts/10-kernel.sh    # kernel Haswell (march=haswell)
build/scripts/20-userspace.sh # debootstrap Debian
build/scripts/30-desktop.sh   # XFCE + tema Win98 + NVIDIA
build/scripts/40-initramfs.sh # initramfs
build/scripts/45-bootfiles.sh # kernel/initrd no rootfs
build/scripts/50-iso.sh       # ISO UEFI bootável
build/scripts/60-qemu-test.sh # teste no QEMU
```

Ou: `build/scripts/build-all.sh`. Resultado: `out/winux-<ver>.iso`.

## Instalação (dual-boot)

```
build/scripts/70-dualboot.sh /dev/nvmeXnY          # dry-run
build/scripts/70-dualboot.sh /dev/nvmeXnY --yes    # executa
```

> Mover o D: (BANCO) para E:/F: é **pré-condição** e só acontece com
> **comando explícito** do usuário — nunca automático.

## Estrutura

```
docs/            documentação
build/config/    build.conf + fragmento do kernel (haswell-desktop)
build/scripts/   pipeline de build + instalador dual-boot
overlay/         arquivos do sistema versionados
overlay-initrd/  (reservado) init custom
src/ out/ iso/ artifacts/   (gerados no build)
```