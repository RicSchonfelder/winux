#!/bin/sh
# winux-install - instala o Winux no disco alvo a partir do SISTEMA LIVE.
# Uso:  winux-install /dev/nvmeXnY [--yes]
#
# Seguro por padrao: sem --yes apenas mostra o plano (dry-run).
# NUNCA toca no disco do Windows: apenas LE o ESP do Windows para
# montar o menu (chainload). GRUB vai so no ESP do alvo.
set -e

KVER="$(uname -r)"
TARGET="$1"
YES=0
[ "$2" = "--yes" ] && YES=1

LOGF=/tmp/win-install.log
die() { echo "ERRO: $*"; echo "ERRO: $*" >> "$LOGF" 2>/dev/null; exit 1; }
log() { echo ">> $*"; echo ">> $*" >> "$LOGF" 2>/dev/null; }

[ -n "$TARGET" ] || die "uso: $0 /dev/nvmeXnY [--yes]"
[ -b "$TARGET" ] || die "$TARGET nao e um block device"
echo "$TARGET" | grep -q '^/dev/nvme' || die "o alvo deve ser um NVMe (disco dedicado do Winux)"
[ -d /sys/firmware/efi ] || die "o live nao esta em modo UEFI"

# nao pode ser o disco de boot do live
ROOTSRC="$(findmnt -no SOURCE / || true)"
if [ -n "$ROOTSRC" ]; then
    PK="$(lsblk -no PKNAME "$ROOTSRC" 2>/dev/null | head -1)"
    [ -n "$PK" ] && [ "$TARGET" = "/dev/$PK" ] && die "alvo e o disco de boot do live"
fi
# nenhuma particao do alvo pode estar montada
lsblk -no MOUNTPOINT "$TARGET" 2>/dev/null | grep -q . && die "alvo tem particao montada"
# sanidade de tamanho (evita escolher o disco errado). WINUX_MIN_GB permite
# lowering em testes (ex.: disco virtual); padrao 200 (o NVMe alvo tem 480GB).
MIN_GB="${WINUX_MIN_GB:-200}"
SIZE_GB=$(( $(blockdev --getsize64 "$TARGET") / 1000000000 ))
[ "$SIZE_GB" -ge "$MIN_GB" ] || die "alvo pequeno demais ($SIZE_GB GB, min $MIN_GB)"

echo "== Plano de instalacao do Winux =="
echo "   Disco alvo:  $TARGET ($SIZE_GB GB)"
echo "   Kernel:      $KVER"
echo "   Particoes:   GPT | ESP 512M | root BTRFS (subvol @)"
echo "   Bootloader:  GRUB no ESP do alvo | default=winux | timeout=10"
echo "   Windows:     chainload (somente leitura; disco original intocado)"
[ "$YES" = 1 ] || { echo ">> dry-run. Use --yes para executar."; exit 0; }

log "reparticionando (DESTRUTIVO)"
wipefs -a "$TARGET" 2>/dev/null || true
# sfdisk pode sair !=0 ao falhar o re-read da tabela (device busy); a tabela
# ja foi gravada. Ignoramos o exit e re-lendo via partprobe abaixo.
sfdisk "$TARGET" <<'SFDISK' || true
label: gpt
start=1MiB, size=512MiB, type=U
type=L
SFDISK
partprobe "$TARGET" 2>/dev/null || true
sleep 2

ESP="${TARGET}p1"; ROOTP="${TARGET}p2"
# espera os nos das particoes aparecerem (devtmpfs)
i=0
while [ "$i" -lt 30 ]; do
    [ -b "$ESP" ] && [ -b "$ROOTP" ] && break
    partprobe "$TARGET" 2>/dev/null || true
    sleep 1; i=$((i+1))
done
[ -b "$ESP" ]   || die "particao ESP ($ESP) nao apareceu"
[ -b "$ROOTP" ] || die "particao root ($ROOTP) nao apareceu"

mkfs.vfat -F32 -n WINUX-ESP "$ESP" || die "mkfs.vfat falhou"
# monta o ESP cedo para poder registrar o log da instalacao no disco alvo
mkdir -p /mnt-esp
mount "$ESP" /mnt-esp || die "nao montou o ESP"
LOGF=/mnt-esp/win-install.log
cp /tmp/win-install.log "$LOGF" 2>/dev/null || true
mkfs.btrfs -f -L WINUX "$ROOTP" || die "mkfs.btrfs falhou"

log "criando subvol @ e montando"
mount -t btrfs "$ROOTP" /mnt || die "nao montou o root btrfs"
btrfs subvolume create /mnt/@ || die "nao criou o subvol @"
umount /mnt
mount -t btrfs -o subvol=@,compress=zstd:1,noatime "$ROOTP" /mnt || die "nao montou o subvol @"
mkdir -p /mnt/boot/efi
umount /mnt-esp 2>/dev/null || true
mount "$ESP" /mnt/boot/efi || die "nao montou o ESP em /boot/efi"

log "localizando a midia live"
MEDIUM=""
for m in /run/live/medium /cdrom /media/sr0 /media/cdrom; do
    if [ -f "$m/live/filesystem.squashfs" ]; then MEDIUM="$m"; break; fi
done

SRC=""
if [ -n "$MEDIUM" ]; then
    mkdir -p /mnt-src
    if mount -o loop,ro "$MEDIUM/live/filesystem.squashfs" /mnt-src 2>/dev/null; then
        SRC=/mnt-src
        log "origem = squashfs limpo (em /mnt-src)"
    fi
fi

log "copiando o sistema (pode demorar alguns minutos)"
FROM="${SRC:-/}"
set +e
rsync -aHAX --numeric-ids \
    --exclude '/proc' --exclude '/sys' --exclude '/dev' --exclude '/run' \
    --exclude '/tmp' --exclude '/mnt' --exclude '/mnt-src' --exclude '/media' \
    --exclude '/lost+found' --exclude '/boot/efi' --exclude '/live' \
    "$FROM/" /mnt/
RSYNC_RC=$?
set -e
[ "$RSYNC_RC" -le 24 ] || die "rsync falhou (codigo $RSYNC_RC)"
if [ -n "$SRC" ]; then umount /mnt-src 2>/dev/null || true; rmdir /mnt-src 2>/dev/null || true; fi

ROOT_UUID="$(blkid -s UUID -o value "$ROOTP")"
ESP_UUID="$(blkid -s UUID -o value "$ESP")"
cat > /mnt/etc/fstab <<EOF
UUID=$ROOT_UUID  /          btrfs  subvol=@,compress=zstd:1,noatime  0 1
UUID=$ESP_UUID   /boot/efi  vfat   umask=0077                         0 1
EOF
echo winux > /mnt/etc/hostname

for d in proc sys dev run; do mount --bind "/$d" "/mnt/$d"; done
[ -f /etc/resolv.conf ] && cp /etc/resolv.conf /mnt/etc/resolv.conf

log "gerando initramfs e tentando o driver NVIDIA"
chroot /mnt bash -c "
    export DEBIAN_FRONTEND=noninteractive
    KVER=$KVER
    mkinitramfs -o /boot/initrd.img-\$KVER \$KVER >/dev/null 2>&1
    if [ -e /lib/modules/\$KVER/build ] && getent hosts deb.debian.org >/dev/null 2>&1; then
        apt-get update -qq 2>/dev/null || true
        apt-get install -y --no-install-recommends nvidia-driver nvidia-kernel-dkms 2>/dev/null || true
        dkms autoinstall 2>/dev/null || true
        mkinitramfs -o /boot/initrd.img-\$KVER \$KVER >/dev/null 2>&1
    else
        echo '   (NVIDIA sera instalado depois: apt install nvidia-driver)'
    fi
"

log "instalando o GRUB no ESP do alvo"
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi \
    --bootloader-id=WINUX --no-nvram --recheck >/dev/null 2>&1 \
    || chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi \
        --bootloader-id=WINUX --no-nvram --removable >/dev/null 2>&1
mkdir -p /mnt/boot/efi/EFI/BOOT
cp /mnt/boot/efi/EFI/WINUX/grubx64.efi /mnt/boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true

# localiza o ESP do Windows (somente leitura)
WIN_UUID=""
for name in $(lsblk -rno NAME,TYPE | awk '$2=="part"{print $1}'); do
    dev="/dev/$name"
    [ "$dev" = "$ESP" ] && continue
    T="$(mktemp -d)"
    if mount -r "$dev" "$T" 2>/dev/null; then
        if [ -f "$T/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
            WIN_UUID="$(blkid -s UUID -o value "$dev")"
        fi
        umount "$T"
    fi
    rmdir "$T" 2>/dev/null || true
    [ -n "$WIN_UUID" ] && break
done

cat > /mnt/boot/grub/grub.cfg <<EOF
set timeout=10
set default=0
menuentry "Winux (alto desempenho)" {
    load_video
    search --no-floppy --fs-uuid $ROOT_UUID
    linux /boot/vmlinuz-$KVER root=UUID=$ROOT_UUID rw quiet
    initrd /boot/initrd.img-$KVER
}
EOF
if [ -n "$WIN_UUID" ]; then
    cat >> /mnt/boot/grub/grub.cfg <<EOF
menuentry "Windows 11" {
    search --no-floppy --fs-uuid $WIN_UUID
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
    log "Windows encontrado (chainload adicionado)"
else
    log "Windows nao localizado (use F8 na BIOS para escolher)"
fi

for d in proc sys dev run; do umount "/mnt/$d" 2>/dev/null || true; done
umount /mnt/boot/efi 2>/dev/null || true
umount /mnt 2>/dev/null || true

# entrada de boot do Winux + prioridade
efibootmgr --create --disk "$TARGET" --part 1 --label "Winux" \
    --loader '\EFI\WINUX\grubx64.efi' >/dev/null 2>&1 || true

echo ">> INSTALACAO CONCLUIDA em $TARGET. Reinicie e escolha Winux (ou F8)."