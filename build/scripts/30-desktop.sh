#!/bin/sh
# 30-desktop.sh - XFCE com visual Windows 98 (tema Chicago95) + xorg NVIDIA
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"

# --- tema Chicago95 (icones/GTK/xfwm estilo Win95/98) ---
if [ ! -d "$RFS/usr/share/themes/Chicago95" ]; then
    git clone --depth 1 https://github.com/grassmunk/Chicago95.git /tmp/chicago95
    cp -a /tmp/chicago95/Theme/Chicago95 "$RFS/usr/share/themes/"
    cp -a /tmp/chicago95/Icons/Chicago95 "$RFS/usr/share/icons/"
fi

# --- NVIDIA: o pacote nvidia-driver (instalado na Fase D, via DKMS) ja
# fornece /usr/share/X11/xorg.conf.d/10-nvidia.conf. Nao forcar Driver
# "nvidia" no live (sem modulo o X nao sobe).

# --- lightdm: login com tema padrao ---
sed -i 's/^#autologin-user=.*/autologin-user=winux/; s/^#autologin-session=.*/autologin-session=xfce/' \
    "$RFS/etc/lightdm/lightdm.conf" 2>/dev/null || true

# --- prefs XFCE: painel e temas Win98 (aplicado no primeiro login do usuario) ---
mkdir -p "$RFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
cat > "$RFS/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Chicago95"/>
    <property name="title_font" type="string" value="Tahoma 9"/>
  </property>
</channel>
EOF

echo ">> desktop ok"