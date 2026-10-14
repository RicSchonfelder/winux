#!/usr/bin/env bash
# Instala o icone minimalista da bandeja do AnyDesk.
#
# Nao altera o binario do AnyDesk nem nada em /usr: tudo fica na pasta do
# utilizador (autostart + entrada de menu), com o .so carregado via LD_PRELOAD.
set -euo pipefail

D="$(cd "$(dirname "$0")" && pwd)"
SO="$D/anydesk-tray-icon.so"
ICON="${1:-$D/icons/tray-16.png}"

echo "==> a preparar o interceptador"
if command -v gcc >/dev/null 2>&1; then
    gcc -O2 -fPIC -shared -Wall -o "$SO" "$D/anydesk-tray-icon.c" -ldl
elif [ -f "$SO" ]; then
    echo "    (sem gcc: a usar o .so pre-compilado que veio no repositorio)"
else
    echo "ERRO: sem gcc e sem anydesk-tray-icon.so" >&2
    exit 1
fi

echo "==> a instalar autostart (bandeja)"
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/anydesk_global_tray.desktop" <<EOF
[Desktop Entry]
Name=AnyDesk Tray
GenericName=AnyDeskTray
X-GNOME-FullName=AnyDesk
Exec=env LD_PRELOAD=$SO /usr/bin/anydesk --tray
Icon=anydesk
Terminal=false
Type=Application
EOF

echo "==> a instalar entrada de menu"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/anydesk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=AnyDesk
GenericName=AnyDesk
X-GNOME-FullName=AnyDesk
Exec=env LD_PRELOAD=$SO /usr/bin/anydesk %u
Icon=anydesk
Terminal=false
TryExec=anydesk
Categories=Network;GTK;
MimeType=x-scheme-handler/anydesk;
Name[de_DE]=AnyDesk
EOF
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "==> a reiniciar a bandeja (icone: $(basename "$ICON"))"
pkill -f '^/usr/bin/anydesk --tray' 2>/dev/null || true
sleep 2
LD_PRELOAD="$SO" ANYDESK_TRAY_ICON="$ICON" \
  setsid /usr/bin/anydesk --tray >/dev/null 2>&1 < /dev/null &

echo "Pronto. O icone muda ja nesta sessao e em todos os logins seguintes."
