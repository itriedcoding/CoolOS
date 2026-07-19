#!/bin/bash
#
# CoolOS Build Script
# Usage: sudo ./scripts/build.sh
#
set -ex

BUILD=/coolos-build
ISO=$BUILD/iso
OUTPUT=$BUILD/output
CHROOT=$BUILD/chroot

echo "=========================================="
echo "       CoolOS Build System v1.1.0"
echo "=========================================="

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Must run as root (sudo ./scripts/build.sh)"
    exit 1
fi

# Install dependencies
echo "[*] Installing build dependencies..."
apt-get update
apt-get install -y \
    debootstrap squashfs-tools xorriso mtools dosfstools \
    grub-efi-amd64-bin grub-efi-amd64-signed shim-signed \
    mbr binutils isolinux syslinux-common syslinux \
    live-build ovmf

# Clean
rm -rf $BUILD
mkdir -p $CHROOT $ISO/{live,boot/grub,boot/grub/x86_64-efi,EFI/BOOT,BOOT,isolinux} $OUTPUT

# === Bootstrap ===
echo "[*] Bootstrapping Debian Bookworm..."
debootstrap --arch=amd64 --variant=minbase \
    --include=apt-transport-https,ca-certificates,curl,wget,gnupg,systemd,systemd-sysv,dbus,udev,kmod,procps,locales,sudo \
    bookworm $CHROOT http://deb.debian.org/debian/

# APT sources
cat > $CHROOT/etc/apt/sources.list << 'EOF'
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Mount
mount --bind /dev $CHROOT/dev
mount --bind /dev/pts $CHROOT/dev/pts
mount -t proc proc $CHROOT/proc
mount -t sysfs sysfs $CHROOT/sys
cp /etc/resolv.conf $CHROOT/etc/resolv.conf

# === Install packages ===
echo "[*] Installing packages..."
chroot $CHROOT /bin/bash << 'CHROOTPKG'
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    
    # Kernel and core
    apt-get install -y --no-install-recommends \
        linux-image-amd64 systemd systemd-sysv dbus udev kmod procps locales sudo \
        console-setup keyboard-configuration
    
    # Desktop
    apt-get install -y --no-install-recommends \
        openbox tint2 rofi pcmanfm thunar lxterminal lightdm \
        lightdm-gtk-greeter picom dunst nitrogen lxappearance \
        arc-theme papirus-icon-theme \
        fonts-noto fonts-noto-color-emoji fonts-firacode fonts-dejavu fonts-liberation \
        xorg xserver-xorg xinit x11-xserver-utils xterm \
        dbus-x11
    
    # Apps
    apt-get install -y --no-install-recommends \
        firefox-esr libreoffice-writer libreoffice-calc libreoffice-impress \
        vlc mpv gimp inkscape geany evince galculator file-roller \
        network-manager network-manager-gnome \
        gnome-system-monitor baobab ncdu ufw \
        pulseaudio pavucontrol
    
    # Dev tools
    apt-get install -y --no-install-recommends \
        build-essential git python3 python3-pip curl wget vim-tiny nano \
        htop tmux tree zip unzip p7zip-full
    
    # Live system
    apt-get install -y --no-install-recommends \
        live-boot live-config live-config-systemd
    
    # Installer
    apt-get install -y calamares calamares-settings-debian || true
    
    # Boot loaders
    apt-get install -y --no-install-recommends \
        grub-efi-amd64-bin grub-pc-bin grub2-common grub-common \
        syslinux syslinux-common isolinux xorriso mtools
    
    apt-get clean
    rm -rf /var/lib/apt/lists/*
CHROOTPKG

# === System config ===
echo "[*] Configuring system..."
chroot $CHROOT /bin/bash << 'CHROOTCFG'
    set -e
    echo "CoolOS" > /etc/hostname
    echo "127.0.0.1 localhost CoolOS" > /etc/hosts
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    update-locale LANG=en_US.UTF-8
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev coolos || true
    echo "coolos:coolors" | chpasswd
    echo "root:coolors" | chpasswd
    echo "coolos ALL=(ALL) ALL" > /etc/sudoers.d/coolos
    chmod 440 /etc/sudoers.d/coolos
    systemctl enable NetworkManager 2>/dev/null || true
    systemctl set-default graphical.target 2>/dev/null || true
CHROOTCFG

# === Desktop config ===
echo "[*] Configuring desktop..."
mkdir -p $CHROOT/etc/xdg/openbox
mkdir -p $CHROOT/etc/skel/.config/{openbox,tint2}
mkdir -p $CHROOT/etc/lightdm/lightdm.conf.d

# Autostart
tee $CHROOT/etc/xdg/openbox/autostart > /dev/null << 'AUTOSTART'
#!/bin/sh
nitrogen --restore &
tint2 &
picom --experimental-backends &
dunst &
pcmanfm --daemon &
xset r rate 300 50
xsetroot -cursor_name left_ptr
AUTOSTART
chmod +x $CHROOT/etc/xdg/openbox/autostart

# LightDM
tee $CHROOT/etc/lightdm/lightdm.conf.d/50-coolos.conf > /dev/null << 'LDM'
[Seat:*]
autologin-user=coolos
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
LDM

# Copy configs
cp config/includes.chroot/etc/xdg/openbox/menu.xml $CHROOT/etc/xdg/openbox/ 2>/dev/null || true
cp config/includes.chroot/etc/xdg/openbox/rc.xml $CHROOT/etc/xdg/openbox/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.bashrc $CHROOT/etc/skel/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.vimrc $CHROOT/etc/skel/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.config/tint2/tint2rc $CHROOT/etc/skel/.config/tint2/ 2>/dev/null || true

# Copy to user
mkdir -p $CHROOT/home/coolos/.config/{openbox,tint2}
cp $CHROOT/etc/xdg/openbox/autostart $CHROOT/home/coolos/.config/openbox/
cp $CHROOT/etc/xdg/openbox/menu.xml $CHROOT/home/coolos/.config/openbox/ 2>/dev/null || true
cp $CHROOT/etc/xdg/openbox/rc.xml $CHROOT/home/coolos/.config/openbox/ 2>/dev/null || true
chown -R 1000:1000 $CHROOT/home/coolos

# === Unmount ===
echo "[*] Unmounting..."
umount $CHROOT/dev/pts 2>/dev/null || true
umount $CHROOT/dev 2>/dev/null || true
umount $CHROOT/proc 2>/dev/null || true
umount $CHROOT/sys 2>/dev/null || true

# === SquashFS ===
echo "[*] Creating SquashFS image..."
mksquashfs $CHROOT $ISO/live/filesystem.squashfs -comp xz -b 1M -noappend -e boot

# === Kernel ===
echo "[*] Copying kernel..."
KERNEL=$(ls $CHROOT/boot/vmlinuz-* | head -n1)
INITRD=$(ls $CHROOT/boot/initrd.img-* | head -n1)
cp "$KERNEL" $ISO/live/vmlinuz
cp "$INITRD" $ISO/live/initrd

# === BIOS Boot ===
echo "[*] Setting up BIOS boot..."
cp /usr/lib/ISOLINUX/isolinux.bin $ISO/isolinux/ 2>/dev/null || \
    cp /usr/share/syslinux/isolinux.bin $ISO/isolinux/ 2>/dev/null || true
cp /usr/lib/ISOLINUX/isohdpfx.bin $ISO/isolinux/ 2>/dev/null || \
    cp /usr/share/syslinux/isohdpfx.bin $ISO/isolinux/ 2>/dev/null || true
cp /usr/share/syslinux/menu.c32 $ISO/isolinux/ 2>/dev/null || true
cp /usr/share/syslinux/ldlinux.c32 $ISO/isolinux/ 2>/dev/null || true

tee $ISO/isolinux/isolinux.cfg > /dev/null << 'ISOlinux'
UI menu.c32
MENU TITLE CoolOS Boot Menu
MENU TIMEOUT 50
DEFAULT coolos

LABEL coolos
    MENU LABEL CoolOS Live
    MENU DEFAULT
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live quiet splash

LABEL safe
    MENU LABEL CoolOS Live (Safe Mode)
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live quiet splash nomodeset

LABEL install
    MENU LABEL CoolOS Install
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live quiet splash components
ISOlinux

# === EFI Boot ===
echo "[*] Setting up EFI boot..."
tee $ISO/boot/grub/grub.cfg > /dev/null << 'GRUBCFG'
set timeout=5
set default=0
set color_normal=white/black
set color_highlight=white/blue
insmod all_video

menuentry "CoolOS Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd
}

menuentry "CoolOS Live (Safe Mode)" {
    linux /live/vmlinuz boot=live quiet splash nomodeset
    initrd /live/initrd
}

menuentry "CoolOS Install" {
    linux /live/vmlinuz boot=live quiet splash components
    initrd /live/initrd
}
GRUBCFG

# Create GRUB EFI image
grub-mkimage \
    --directory=/usr/lib/grub/x86_64-efi \
    --output=$ISO/BOOT/GRUBX64.EFI \
    --format=x86_64-efi \
    --prefix='(cd)/boot/grub' \
    fat part_gpt part_msdos iso9660 normal boot linux configfile \
    search search_fs_uuid search_label terminal gfxterm \
    all_video loadenv exfat ext2 ntfs

# Create EFI fallback
mkdir -p $ISO/EFI/BOOT
cp $ISO/BOOT/GRUBX64.EFI $ISO/EFI/BOOT/BOOTX64.EFI

# Copy GRUB modules
mkdir -p $ISO/boot/grub/x86_64-efi
cp /usr/lib/grub/x86_64-efi/*.mod $ISO/boot/grub/x86_64-efi/ 2>/dev/null || true
cp /usr/lib/grub/x86_64-efi/*.lst $ISO/boot/grub/x86_64-efi/ 2>/dev/null || true

# === Build ISO ===
echo "[*] Building ISO..."
xorriso -as mkisofs \
    -o $OUTPUT/CoolOS-1.1.0-amd64.iso \
    -isohybrid-mbr $ISO/isolinux/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/x86_64-efi/core.img \
    --grub2-mbr $ISO/isolinux/isohdpfx.bin \
    --grub2-boot-info \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -V "CoolOS" \
    -R -J \
    --efi-boot \
    --efi-boot-partition \
    --efi-boot-image boot/grub/x86_64-efi/core.img \
    $ISO

# Checksums
cd $OUTPUT
sha256sum *.iso > SHA256SUMS

# Cleanup
rm -rf $BUILD/iso $BUILD/chroot

echo ""
echo "=========================================="
echo "       BUILD COMPLETE!"
echo "=========================================="
echo ""
echo "ISO: $OUTPUT/CoolOS-1.1.0-amd64.iso"
echo ""
ls -lh $OUTPUT/*.iso
echo ""
echo "Checksum:"
cat $OUTPUT/SHA256SUMS
