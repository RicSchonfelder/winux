#!/usr/bin/env bash
# Desfaz tudo: volta o icone vermelho original do AnyDesk.
set -euo pipefail

echo "==> a remover overrides do utilizador"
rm -f "$HOME/.config/autostart/anydesk_global_tray.desktop"
rm -f "$HOME/.local/share/applications/anydesk.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "==> a reiniciar a bandeja sem o interceptador"
pkill -f '^/usr/bin/anydesk --tray' 2>/dev/null || true
sleep 2
setsid /usr/bin/anydesk --tray >/dev/null 2>&1 < /dev/null &

echo "Pronto: icone original de volta."
