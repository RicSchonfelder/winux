# 01 — Hardware da máquina

Medições reais (2026-10-04, Windows 11 Pro build 26200):

| Componente | Detalhe |
|-----------|---------|
| CPU | Intel Core i7-4771 @ 3.50GHz (Haswell, 4C/8T) |
| RAM | 24 GB (25636093952 bytes) |
| GPU | NVIDIA GeForce GTX 1060 6GB (Pascal) + Intel HD 4600 |
| Placa-mãe | ASUS "All Series" (série H81/B85/H87 provável) |
| Boot | UEFI (Windows 11 GPT no Kingston) |

## Discos

| Disco | Tipo | Tamanho | Papel atual | Papel no Winux |
|-------|------|---------|-------------|----------------|
| Kingston SA400S37480G | SATA SSD | 447GB | **Windows C:** (GPT/UEFI, ESP+Recovery) | **INTOCÁVEL** |
| WDC WDS480G2G0C | **NVMe** | 447GB | **D: "BANCO"** (MBR, ~108GB usados) | **disco do Winux** (após mover D:) |
| ST1000DM003 | HDD | 931GB | E: "Schon1 3.5" (NTFS, 426GB livres) | recebe dados do D: |
| ST2000DM005 | HDD | 1863GB | F: "JOB" (exFAT, 792GB livres) | recebe dados do D: |
| JMicron | USB | 931GB | G: "SCHON II" (exFAT) | backup |

## Drivers cobertos pelo fragmento do kernel

- **Rede**: Realtek RTL8111/8169 (`r8169`) e Intel I217V (`e1000e`) — presentes em ASUS desta geração.
- **SATA**: `sata_ahci` (Kingston + HDDs).
- **NVMe**: `nvme` (disco do Winux).
- **Áudio**: `snd_hda_intel` (Realtek ALC + HDMI da GTX).
- **USB**: xHCI + EHCI + storage + HID.
- **GPU**: NVIDIA proprietária via **DKMS** (`drm/nouveau` desligado no fragmento).