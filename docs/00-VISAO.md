# 00 — Visão geral

## O que é

Winux é a evolução desktop do projeto `linux` (distro from-scratch da TV box
Intel Cherry Trail). Mesmo sistema de build, novo alvo: **desktop ASUS
i7-4771 Haswell** com foco em **alto desempenho** e **visual Windows 98**.

## Decisões (confirmadas pelo usuário em 2026-10-04)

| Tema | Decisão |
|------|---------|
| Base | **Híbrida**: kernel custom (build do repo) + userspace **Debian** (debootstrap) |
| Desktop | **XFCE4** + tema **Chicago95** (Win98) — leve, estável, fiel |
| Gráfico | **X11** + **driver NVIDIA proprietário** (DKMS) p/ GTX 1060 |
| Instalação | **NVMe dedicado** (após mover D: para E:/F:) |
| Boot | **Winux = padrão**, **timeout 10s**, GRUB só no NVMe, Windows via chainload |
| Windows | **Nunca tocado** (disco Kingston/UEFI intacto). Adobe e apps Windows-only continuam lá |
| D: | Mover **só com comando explícito** do usuário |

## Por que desempenho

Medições no Windows (2026-10-04): 24GB RAM, commit 54GB, pagefile C: com
**7.3GB em uso (pico 13GB)** → **paginação ativa**. O ganho nº 1 do Winux é
liberar RAM (XFCE ~1GB vs Win11 ~5GB) e eliminar o swap. Kernel com
`-march=haswell` + governor `performance` + preempt baixa latência dá
+5–15% em tarefas de IA/vídeo (Whisper, FFmpeg, builds, n8n).

## O que NÃO se espera

- +50% de CPU "mágico" — o gargalo é RAM/paginação, não o kernel.
- Jogos com anti-cheat/Windows-only.
- Cliente nativo do iCloud (web).