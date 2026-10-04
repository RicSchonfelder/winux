# 04 — Instalação dual-boot (NVMe)

> **Pré-condição obrigatória**: mover D:\ (BANCO, ~108GB) para E:/F: com
> `robocopy` + verificação. **Só quando o usuário mandar.** Nada automático.

## Ordem recomendada (com comando explícito do usuário)

1. **Backup** do C: e D: (Clonezilla) — o usuário não pode perder nada.
2. **Mover D:** → E:/F: (robocopy, verificar). Reinstalar/reapontar
   `Programas` (15GB) e `SteamLibrary` (5GB) se preciso. `iCloud` (100GB)
   vira dados em HDD (mais lento que NVMe — tradeoff aceito).
3. **Liberar o NVMe** (WDC): o disco pode continuar MBR; o instalador apaga.
4. Bootar a ISO Winux (live) e rodar:

```bash
build/scripts/70-dualboot.sh /dev/nvme0n1          # dry-run
build/scripts/70-dualboot.sh /dev/nvme0n1 --yes    # executa
```

## O que o instalador faz

| Passo | Ação |
|-------|------|
| Guardas | recusa se não for NVMe / se for o disco de boot atual / se tiver partição montada |
| Partições | GPT: ESP 512M fat32 + root BTRFS (subvol `@`) |
| Fstab | root por UUID (`subvol=@,compress=zstd:1,noatime`), ESP em `/boot/efi` |
| Sistema | rsync do rootfs → chroot → initramfs + **nvidia-dkms** + efibootmgr |
| GRUB | só no ESP do NVMe; `default=winux`, `timeout=10` |
| Windows | localiza o ESP original (leitura) → menuentry `chainloader bootmgfw.efi` |
| Boot order | `efibootmgr` cria "Winux" e seta como primeiro |

## Após instalar

- Ligar → GRUB: **Winux** (padrão) ou **Windows 11** em 10s.
- Fallback sempre disponível: **F8** na BIOS da ASUS.