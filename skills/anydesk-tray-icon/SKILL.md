---
name: anydesk-tray-icon
description: >
  Troca o ícone do AnyDesk junto ao relógio (bandeja do sistema) por uma versão
  minimalista: só o desenho branco, sem o retângulo vermelho, mantendo a
  proporção. Use quando o usuário pedir "tirar o retângulo vermelho do AnyDesk",
  "ícone minimalista do AnyDesk", "mudar o ícone do anydesk no canto do relógio",
  "tray icon do AnyDesk", ou quando o ícone da bandeja do AnyDesk estiver a
  incomodar visualmente. Vale para qualquer máquina com XFCE/X11 (winux, lab).
  Inclui o diagnóstico de por que trocar /usr/share/icons NÃO funciona.
---

# AnyDesk — ícone minimalista da bandeja

Deixa o ícone da bandeja (canto do relógio) como **só o desenho branco**
(losango + seta), sem o retângulo vermelho, mantendo a proporção.

Solução completa versionada em **`winux` → `overlay/opt/anydesk-tray-icon/`**.

## O que NÃO funciona (não perca tempo)

| Tentativa | Resultado |
|-----------|-----------|
| Trocar `/usr/share/icons/hicolor/*/apps/anydesk.png` + `/usr/share/pixmaps/anydesk.{png,xpm}` + `gtk-update-icon-cache` | **não muda nada** |
| Trocar os PNGs embutidos no binário `/usr/bin/anydesk` (16/32/48/96 px no `.rodata`) | **não muda nada** |
| Trocar o tema de ícones (`Adwaita`, `Papirus-Dark`, …) | **não muda nada** |
| `strace` no `anydesk --tray` | **não abre nenhum ficheiro de imagem** |

Motivo: o AnyDesk **desenha o ícone em runtime** e entrega ao GTK por
`gtk_status_icon_new_from_pixbuf()`. Nem tema, nem ficheiro, nem recurso.

## Solução: interceptar a chamada ao GTK (LD_PRELOAD)

`anydesk-tray-icon.so` substitui o pixbuf entregue ao GTK pelo nosso desenho.
**Nada em `/usr` é alterado** — o binário e os ícones do sistema ficam intactos.

- `gtk_status_icon_new_from_pixbuf()` e `gtk_status_icon_set_from_pixbuf()`
  são substituídos.
- O interceptador só age quando `/proc/self/exe` é `anydesk` — é seguro mesmo
  com `LD_PRELOAD` global.
- Desenho: o próprio logo da AnyDesk, rasterizado do vetor original com
  supersampling 16×, em branco puro (`#fff`), sobre transparente.

## Aplicar numa máquina

```bash
# 1. copiar a pasta (do repo winux ou de outra máquina já instalada)
#    overlay/opt/anydesk-tray-icon/  ->  ~/Projetos/Programas/anydesk/icone-tray/
scp -r winux:~/Projetos/Programas/anydesk/icone-tray lab:~/Projetos/Programas/anydesk/

# 2. instalar (compila o .so, escreve o autostart e reinicia a bandeja)
ssh lab 'export DISPLAY=:0.0; cd ~/Projetos/Programas/anydesk/icone-tray && ./instalar.sh'

# 3. opcional: escolher outro tamanho (o painel do XFCE aqui é 16px)
./instalar.sh icons/tray-24.png
```

Requisitos: `gcc` (para compilar) — se não houver, o script usa o `.so`
pré-compilado que vem no repositório.

### Teste rápido, sem instalar nada

```bash
LD_PRELOAD=$HOME/Projetos/Programas/anydesk/icone-tray/anydesk-tray-icon.so \
  /usr/bin/anydesk --tray
```

## Como verificar

```bash
export DISPLAY=:0            # :0.0 no lab
xwininfo -root -tree | grep '"AnyDesk"'      # janela da bandeja (ex.: 16x16+X+Y)
scrot -o /tmp/antes.png                      # ou: import -window root /tmp/antes.png
# reinicia a bandeja e compara
```

No XFCE o ícone é uma janela XEmbed de 16×16; use `scrot` (lab) ou
`import -window root` (winux).

## Desinstalar

```bash
./desinstalar.sh      # remove autostart+menu e reinicia a bandeja original
```

## Armadilhas (aprendidas na prática)

- **`ETXTBSY` / "Text file busy"**: não dá para escrever em `/usr/bin/anydesk`
  enquanto ele corre. Se algum dia quiser patchá-lo, gere uma cópia e substitua
  com `os.replace()` (rename atómico) — mas aqui **nem é preciso tocar nele**.
- **`pkill -f "anydesk --tray"` mata a própria shell** (o padrão casa com a
  linha de comando do bash). Use sempre `pkill -f '^/usr/bin/anydesk --tray'`.
- **Reiniciar a bandeja não derruba sessão remota**: o `--service` (root) é que
  mantém as sessões. O `--tray` é só a UI do utilizador. Confirme com
  `wmctrl -lx | grep -i anydesk` que não há **janela principal** aberta antes
  de matar o processo (matá-lo fecha a janela).
- **Se o painel for maior** (HiDPI), use `icons/tray-22|24|32.png` — o
  padrão `tray-16.png` é o que fica sem reamostragem no painel de 16px.
- O **ícone do menu/launcher continua vermelho** de propósito; o
  `~/.local/share/applications/anydesk.desktop` só serve para o LD_PRELOAD
  valer quando o AnyDesk é aberto pelo menu.

## Máquinas onde já está aplicado

| Máquina | SO / DE | AnyDesk | Ícone | Notas |
|---------|---------|---------|-------|-------|
| `winux` (192.168.100.94) | Debian + XFCE, X11 | 8.1.x | `tray-16.png` | origem do desenvolvimento |
| `lab` (192.168.100.102, user `schon`) | Ubuntu 22.04 + XFCE | 8.0.4 | `tray-16.png` | painel 1366×768, bandeja 16×16 |

`DISPLAY` no lab é `:0.0`; na winux é `:0`.

## Ficheiros

```
overlay/opt/anydesk-tray-icon/
├── anydesk-tray-icon.c     # interceptador (GtkStatusIcon)
├── anydesk-tray-icon.so    # pré-compilado (x86_64), fallback sem gcc
├── instalar.sh             # instala autostart + menu e reinicia a bandeja
├── desinstalar.sh          # reverte tudo
├── icons/tray-{16,22,24,32,48}.png
└── README.md
skills/anydesk-tray-icon/SKILL.md   # esta skill
```
