# Ícone minimalista da bandeja do AnyDesk

Troca o ícone junto ao relógio (bandeja do sistema) do AnyDesk por uma versão
**minimalista: só o desenho branco, sem o retângulo vermelho**, mantendo a
proporção original.

![antes/depois](icons/tray-16.png)

## O que foi descoberto

- O AnyDesk **não** usa os PNGs de `/usr/share/icons` nem `/usr/share/pixmaps`
  para a bandeja (substituí-los não muda nada).
- Também **não** vem dos recursos embutidos no binário `/usr/bin/anydesk`
  (testei os ícones embutidos de 16, 32, 48 e 96 px — nenhum altera a bandeja).
- A bandeja desenha o ícone em tempo de execução via GTK:
  `gtk_status_icon_new_from_pixbuf()`.

## Como funciona a solução

Um pequeno interceptador (`LD_PRELOAD`) que substitui o pixbuf entregue ao GTK
pelo nosso desenho branco. **Nada no sistema é alterado** — não se toca no
binário nem em `/usr`; tudo vive na pasta do utilizador.

```
anydesk-tray-icon.c       -> intercepta gtk_status_icon_new_from_pixbuf/_set_from_pixbuf
anydesk-tray-icon.so      -> biblioteca compilada (pré-compilada no repo, fallback sem gcc)
icons/tray-{16,22,24,32,48}.png -> desenho branco em vários tamanhos
instalar.sh / desinstalar.sh
```

O interceptador só age quando o processo é o `anydesk` (verifica
`/proc/self/exe`), por isso é seguro mesmo com `LD_PRELOAD` global.

## Instalar

```bash
./instalar.sh                       # usa icons/tray-16.png
./instalar.sh icons/tray-24.png     # outro tamanho
```

Ou para testes pontuais, sem instalar nada:

```bash
LD_PRELOAD=$PWD/anydesk-tray-icon.so /usr/bin/anydesk --tray
```

## Desinstalar

```bash
./desinstalar.sh
```

## Detalhes úteis

- O tamanho do ícone da bandeja do XFCE aqui é 16×16, por isso o padrão é o
  `tray-16.png` (sem reamostragem = mais nítido). Para painéis maiores use
  `tray-22/24/32`.
- O desenho é o próprio logo da AnyDesk (losango + seta), rasterizado do vetor
  original com supersampling 16×, em branco puro.
- O ícone do **menu/launcher** continua o original (vermelho), de propósito.
  Se quiser mudar também, basta trocar `Icon=anydesk` por `Icon=<caminho do png>`
  em `~/.local/share/applications/anydesk.desktop`.

## Notas

- Atualizações do pacote do AnyDesk **não** afetam isto (não dependemos do
  binário nem de ficheiros de `/usr`).
- Se algum dia a bandeja voltar a ficar vermelha, corra `./instalar.sh` — o
  autostart do utilizador é que manda.
