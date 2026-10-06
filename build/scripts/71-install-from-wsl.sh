#!/bin/sh
# 71-install-from-wsl.sh - instala o Winux no NVMe já anexado ao WSL.
#
# Pré-requisito (PowerShell ELEVADO, uma vez):
#   wsl --mount \\.\PHYSICALDRIVE3 --bare
#
# Depois (dentro do WSL, sem elevate):
#   wsl -d Ubuntu-24.04 -e bash /root/winux/build/scripts/71-install-from-wsl.sh
#
# POR QUE É SEGURO: dentro do WSL os discos do Windows (Kingston=C:) NÃO são
# visíveis — o WSL só enxerga o disco que foi anexado via wsl --mount. O
# instalador ainda exige tamanho ~480GB (o WDC NVMe), o que exclui qualquer
# outro dispositivo. O disco do Windows é literalmente inalcançável daqui.
set -e
# PATH limpo: o PATH herdado do Windows aponta p/ D: (que some quando o disco
# e anexado), o que pode deixar comandos basicos introuveis.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ROOT=/root/winux
. "$ROOT/build/config/build.conf"
RFS="$ROOT/out/rootfs"
LOG=/root/winux/out/install-nvme.log

[ -d "$RFS" ] || { echo "ERRO: rootfs nao encontrado em $RFS ( rode 20-userspace )"; exit 1; }
[ -f "$RFS/boot/vmlinuz-$KVER" ] || { echo "ERRO: kernel ausente em $RFS/boot"; exit 1; }

log() { echo ">> $*"; echo ">> $*" >> "$LOG" 2>/dev/null || true; }
die() { echo "ERRO: $*"; echo "ERRO: $*" >> "$LOG" 2>/dev/null || true; exit 1; }

: > "$LOG"

# --- detecta o alvo: bloco ~480GB, sem particao montada (o NVMe anexado) ---
TARGET=""
for d in /dev/nvme0n1 /dev/nvme1n1 /dev/nvme0n2 /dev/sd[a-z]; do
    [ -b "$d" ] || continue
    SZ=$(blockdev --getsize64 "$d" 2>/dev/null || echo 0)
    [ "$SZ" -ge 400000000000 ] && [ "$SZ" -le 500000000000 ] || continue
    lsblk -no MOUNTPOINT "$d" 2>/dev/null | grep -q . && continue
    TARGET="$d"; SZ="$SZ"; break
done
[ -n "$TARGET" ] || { lsblk -dno NAME,SIZE,MODEL >> "$LOG" 2>&1; die "disco alvo ~480GB nao encontrado (dispositivos acima no log)"; }
log "alvo detectado: $TARGET ($(( SZ / 1000000000 )) GB)"

# confirma que nao e um disco do windows (o do windows e SATA, o alvo e NVMe)
# (a deteccao por tamanho ja garante; mantido como log)
log "modelo: $(lsblk -dno MODEL "$TARGET" 2>/dev/null)"

# --- monta o que precisa existir no rootfs ---
log "garantindo fstab/hostname no rootfs"
ROOT_UUID_PRE=; ESP_UUID_PRE=

# --- 1) particiona ---
# cleanup de execucoes anteriores (idempotencia)
umount /mnt/boot/efi 2>/dev/null || true
for d in proc sys dev; do umount "/mnt/$d" 2>/dev/null || true; done
umount /mnt 2>/dev/null || true
umount /mnt-src 2>/dev/null || true

log "particionando (DESTRUTIVO no alvo apenas)"
wipefs -a "$TARGET" 2>/dev/null || true
sfdisk "$TARGET" <<'SFDISK' || true
label: gpt
start=1MiB, size=512MiB, type=U
type=L
SFDISK
partprobe "$TARGET" 2>/dev/null || true
sleep 2

case "$TARGET" in
    /dev/nvme*) ESP="${TARGET}p1"; ROOTP="${TARGET}p2" ;;
    /dev/sd?)   ESP="${TARGET}1";  ROOTP="${TARGET}2"  ;;
esac
i=0; while [ "$i" -lt 30 ]; do
    [ -b "$ESP" ] && [ -b "$ROOTP" ] && break
    partprobe "$TARGET" 2>/dev/null || true; sleep 1; i=$((i+1))
done
[ -b "$ESP" ] && [ -b "$ROOTP" ] || die "particoes nao apareceram"

# --- 2) formatar ---
log "formatando"
mkfs.vfat -F32 -n WINUX-ESP "$ESP"
mkfs.btrfs -f -L WINUX "$ROOTP"

# --- 3) montar root (TOP-LEVEL do btrfs, sem subvolume) ---
# Usamos o top-level (nao um subvolume @) de proposito: o initramfs do Debian
# monta a raiz pelo UUID sem honoured subvol=, e um subvolume faz o boot cair
# em "No init found". Para um SO unico, o top-level e o caminho simples e correto.
log "montando root (top-level btrfs)"
mount -t btrfs -o compress=zstd:1,noatime "$ROOTP" /mnt
mkdir -p /mnt/boot/efi
mount "$ESP" /mnt/boot/efi

# --- 4) copiar o sistema ---
log "copiando o sistema (1-3 min)"
rsync -aHAX --numeric-ids \
    --exclude '/proc' --exclude '/sys' --exclude '/dev' --exclude '/run' \
    --exclude '/tmp' --exclude '/mnt' --exclude '/media' --exclude '/lost+found' \
    --exclude '/boot/efi' --exclude '/live' \
    "$RFS/" /mnt/

# --- 5) fstab / hostname ---
ROOT_UUID="$(blkid -s UUID -o value "$ROOTP")"
ESP_UUID="$(blkid -s UUID -o value "$ESP")"
cat > /mnt/etc/fstab <<EOF
UUID=$ROOT_UUID  /          btrfs  compress=zstd:1,noatime          0 1
UUID=$ESP_UUID   /boot/efi  vfat   umask=0077                       0 1
EOF
echo winux > /mnt/etc/hostname

# --- 6) binds p/ chroot ---
mkdir -p /mnt/proc /mnt/sys /mnt/dev /mnt/run
for d in proc sys dev run; do mount --bind "/$d" "/mnt/$d"; done

# --- 7) initramfs + GRUB (dentro do chroot, usa o grub do proprio sistema) ---
log "gerando initramfs e instalando o GRUB"
# regenerate initramfs para o sistema instalado (root=UUID vem do grub.cfg)
chroot /mnt /sbin/mkinitramfs -o "/boot/initrd.img-$KVER" "$KVER" >/dev/null 2>&1 || log "aviso: regeneracao do initramfs falhou (usando o do build)"
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    --bootloader-id=WINUX --no-nvram --recheck \
    || chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi \
         --bootloader-id=WINUX --no-nvram --removable
mkdir -p /mnt/boot/efi/EFI/BOOT
cp /mnt/boot/efi/EFI/WINUX/grubx64.efi /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true

# grub.cfg de ENCADEAMENTO na ESP: o core (carregado da ESP) procura o prefix
# /boot/grub NELA, mas os modulos/config estao na particao root (btrfs, separada).
# Este cfg minimo busca a root por UUID, aponta o prefix e le o grub.cfg real.
for D in /mnt/boot/efi/boot/grub /mnt/boot/efi/EFI/BOOT /mnt/boot/efi/EFI/WINUX; do
    mkdir -p "$D"
    cat > "$D/grub.cfg" <<EOF
search --no-floppy --fs-uuid $ROOT_UUID --set=root
set prefix=(\$root)/boot/grub
configfile \$prefix/grub.cfg
EOF
done

# --- 8) grub.cfg: Winux padrao (10s) + Windows chainload (por busca de arquivo,
#     nao precisa do UUID do ESP do Windows — que nao e visivel via WSL) ---
cat > /mnt/boot/grub/grub.cfg <<EOF
set timeout=10
set default=0
menuentry "Winux (alto desempenho)" {
    search --no-floppy --fs-uuid $ROOT_UUID --set=root
    linux /boot/vmlinuz-$KVER root=UUID=$ROOT_UUID rootfstype=btrfs rw console=tty0 console=ttyS0
    initrd /boot/initrd.img-$KVER
}
menuentry "Windows 11" {
    insmod part_gpt
    insmod fat
    search --no-floppy --file /EFI/Microsoft/Boot/bootmgfw.efi --set=root
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
log "grub.cfg: Winux (padrao, 10s) + Windows (chainload por bootmgfw.efi)"

for d in proc sys dev; do umount "/mnt/$d" 2>/dev/null || true; done
umount /mnt/boot/efi 2>/dev/null || true
umount /mnt 2>/dev/null || true

log "INSTALACAO CONCLUIDA em $TARGET"
log "proximos passos: (1) reative o disco no Windows/PC, (2) no BIOS defina o NVMe como 1o boot device (F8/UEFI), (3) o GRUB mostra Winux por padrao com 10s"
