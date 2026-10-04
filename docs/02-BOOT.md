# 02 — Estratégia de boot (dual-boot seguro)

## Princípio

**Um SO por disco físico.** Windows mora no Kingston (GPT/UEFI); Winux mora
no NVMe dedicado. Nenhum bootloader é gravado no disco do Windows.

## Fluxo

1. **BIOS/UEFI** inicializa com prioridade no NVMe → GRUB do Winux.
2. GRUB: `default=winux`, `timeout=10`:
   - **Winux** (padrão) — kernel + initramfs do NVMe.
   - **Windows 11** — `chainloader` do `bootmgfw.efi` original (ESP do
     Kingston, lido apenas). Windows boota intacto.
3. Fallback: tecla de boot da ASUS (**F8**) sempre permite escolher qualquer
   disco, mesmo se algo der errado no GRUB.

## Garantias

- O disco do Windows **nunca é particionado/redimensionado/gravado**.
- Recuperação: com F8 é possível voltar ao Windows a qualquer momento.
- Backup do C: e D: recomendado (Clonezilla) **antes** de qualquer passo.

## Endpoint gráfico

- X11 + `xorg.conf.d/20-nvidia.conf` (`Driver "nvidia"`).
- NVIDIA DKMS compilado contra o kernel custom (6.18.x).