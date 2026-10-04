# 05 — Atualizações

## Kernel

```bash
# no WSL, dentro do repo winux
build/scripts/10-kernel.sh        # baixa + compila novo kernel
build/scripts/45-bootfiles.sh     # instala modulos no rootfs
# reinstalar no disco: re-rodar 70-dualboot.sh (idempotente p/ boot, mas
# vai REPARTICIONAR — usar com cautela / modo sem particionar).
```

Alternativa segura no sistema instalado: compilar via DKMS/dkms e trocar
`/boot/vmlinuz` + `initrd` manualmente.

## Usuáriospace / pacotes

```bash
apt update && apt upgrade   # no Winux instalado
```

## Drivers NVIDIA

Atualizar o driver dentro do sistema instalado:

```bash
sudo apt-get update
sudo apt-get install --reinstall nvidia-kernel-dkms nvidia-driver
sudo dkms autoinstall
sudo update-initramfs -u
```

## Repo

```bash
git -C /mnt/c/Users/ricar/winux pull
```