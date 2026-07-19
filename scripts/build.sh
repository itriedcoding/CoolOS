#!/bin/bash
#
# CoolOS Build Script - Simplified
# Usage: sudo ./scripts/build.sh
#
set -ex

COOLOS_VERSION="1.0.0"
BUILD=/coolos-build
ISO=$BUILD/iso
OUTPUT=$BUILD/output

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗"
echo -e "║                    CoolOS Build System                     ║"
echo -e "╚════════════════════════════════════════════════════════════╝${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Must run as root (sudo ./scripts/build.sh)${NC}"
    exit 1
fi

# Check dependencies
echo -e "${GREEN}[*] Checking dependencies...${NC}"
apt-get update
apt-get install -y debootstrap squashfs-tools xorriso mtools dosfstools \
    grub-pc-bin grub-efi-amd64-bin mbr binutils isolinux syslinux-common syslinux

# Clean and create directories
echo -e "${GREEN}[*] Setting up directories...${NC}"
rm -rf $BUILD
mkdir -p $BUILD/chroot $ISO/live $ISO/isolinux $ISO/boot/grub $OUTPUT

# Bootstrap base system
echo -e "${GREEN}[*] Installing base system...${NC}"
debootstrap --arch=amd64 --variant=minbase \
    --include=apt-transport-https,ca-certificates,curl,wget,gnupg,systemd,systemd-sysv,dbus,udev,kmod,procps,locales \
    bookworm $BUILD/chroot http://deb.debian.org/debian/

# Configure APT
echo -e "${GREEN}[*] Configuring APT...${NC}"
cat > $BUILD/chroot/etc/apt/sources.list << 'EOF'
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Mount filesystems
echo -e "${GREEN}[*] Mounting filesystems...${NC}"
mount --bind /dev $BUILD/chroot/dev
mount --bind /dev/pts $BUILD/chroot/dev/pts
mount -t proc proc $BUILD/chroot/proc
mount -t sysfs sysfs $BUILD/chroot/sys
cp /etc/resolv.conf $BUILD/chroot/etc/resolv.conf

# Install packages
echo -e "${GREEN}[*] Installing packages...${NC}"
chroot $BUILD/chroot /bin/bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    
    # Kernel
    apt-get install -y linux-image-amd64 systemd systemd-sysv dbus udev kmod procps locales sudo
    
    # Desktop
    apt-get install -y openbox tint2 rofi pcmanfm thunar lxterminal lightdm \
        lightdm-gtk-greeter picom dunst nitrogen lxappearance arc-theme papirus-icon-theme \
        fonts-noto fonts-noto-color-emoji fonts-firacode fonts-dejavu fonts-liberation
    
    # Apps
    apt-get install -y firefox-esr libreoffice-writer libreoffice-calc libreoffice-impress \
        vlc mpv gimp inkscape geany evince galculator file-roller network-manager network-manager-gnome \
        gnome-system-monitor baobab ncdu ufw
    
    # Dev
    apt-get install -y build-essential git python3 python3-pip curl wget vim-tiny nano htop tmux tree zip unzip p7zip-full
    
    # Live system
    apt-get install -y live-boot live-config live-config-systemd
    
    # Boot
    apt-get install -y syslinux syslinux-common isolinux xorriso mtools
    
    apt-get clean
    rm -rf /var/lib/apt/lists/*
'

# Configure system
echo -e "${GREEN}[*] Configuring system...${NC}"
chroot $BUILD/chroot /bin/bash -c '
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
    systemctl enable NetworkManager || true
    systemctl enable lightdm || true
'

# Desktop configuration
echo -e "${GREEN}[*] Configuring desktop...${NC}"
mkdir -p $BUILD/chroot/etc/xdg/openbox
mkdir -p $BUILD/chroot/etc/skel/.config/tint2
mkdir -p $BUILD/chroot/etc/lightdm/lightdm.conf.d

# Autostart
cat > $BUILD/chroot/etc/xdg/openbox/autostart << 'EOF'
#!/bin/sh
nitrogen --restore &
tint2 &
picom --experimental-backends &
dunst &
xscreensaver -nosplash &
pcmanfm --daemon &
xset r rate 300 50
xsetroot -cursor_name left_ptr
EOF
chmod +x $BUILD/chroot/etc/xdg/openbox/autostart

# LightDM
cat > $BUILD/chroot/etc/lightdm/lightdm.conf.d/50-coolos.conf << 'EOF'
[Seat:*]
autologin-user=coolos
autologin-user-timeout=0
user-session=openbox
EOF

# Copy configs
cp config/includes.chroot/etc/xdg/openbox/menu.xml $BUILD/chroot/etc/xdg/openbox/ 2>/dev/null || true
cp config/includes.chroot/etc/xdg/openbox/rc.xml $BUILD/chroot/etc/xdg/openbox/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.bashrc $BUILD/chroot/etc/skel/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.vimrc $BUILD/chroot/etc/skel/ 2>/dev/null || true
cp config/includes.chroot/etc/skel/.config/tint2/tint2rc $BUILD/chroot/etc/skel/.config/tint2/ 2>/dev/null || true

# Copy to user home
mkdir -p $BUILD/chroot/home/coolos/.config/openbox
mkdir -p $BUILD/chroot/home/coolos/.config/tint2
cp $BUILD/chroot/etc/xdg/openbox/autostart $BUILD/chroot/home/coolos/.config/openbox/
chown -R 1000:1000 $BUILD/chroot/home/coolos

# Unmount
echo -e "${GREEN}[*] Unmounting filesystems...${NC}"
umount $BUILD/chroot/dev/pts 2>/dev/null || true
umount $BUILD/chroot/dev 2>/dev/null || true
umount $BUILD/chroot/proc 2>/dev/null || true
umount $BUILD/chroot/sys 2>/dev/null || true

# Create SquashFS
echo -e "${GREEN}[*] Creating SquashFS image...${NC}"
mksquashfs $BUILD/chroot $ISO/live/filesystem.squashfs -comp xz -b 1M -noappend -e boot

# Copy kernel
echo -e "${GREEN}[*] Setting up boot files...${NC}"
KERNEL=$(ls $BUILD/chroot/boot/vmlinuz-* | head -n1)
INITRD=$(ls $BUILD/chroot/initrd.img-* 2>/dev/null || ls $BUILD/chroot/boot/initrd.img-* 2>/dev/null | head -n1)
cp "$KERNEL" $ISO/live/vmlinuz
cp "$INITRD" $ISO/live/initrd

# Isolinux
cp /usr/lib/ISOLINUX/isolinux.bin $ISO/isolinux/ 2>/dev/null || cp /usr/share/syslinux/isolinux.bin $ISO/isolinux/
cp /usr/lib/ISOLINUX/isohdpfx.bin $ISO/isolinux/ 2>/dev/null || cp /usr/share/syslinux/isohdpfx.bin $ISO/isolinux/
cp /usr/share/syslinux/menu.c32 $ISO/isolinux/ 2>/dev/null || true

cat > $ISO/isolinux/isolinux.cfg << 'EOF'
UI menu.c32
MENU TITLE CoolOS Boot Menu
MENU TIMEOUT 100

LABEL coolos
    MENU LABEL CoolOS Live
    MENU DEFAULT
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash

LABEL safe
    MENU LABEL CoolOS Live (Safe Mode)
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash nomodeset

LABEL install
    MENU LABEL CoolOS Install
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash components
EOF

# GRUB
cat > $ISO/boot/grub/grub.cfg << 'EOF'
set timeout=10
set default=0

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
EOF

# GRUB EFI
mkdir -p $ISO/boot/grub/x86_64-efi
grub-mkimage --directory=/usr/lib/grub/x86_64-efi \
    --output=$ISO/boot/grub/x86_64-efi/core.efi \
    --format=x86_64-efi --prefix="(cd)/boot/grub" \
    fat iso9660 normal boot linux configfile 2>/dev/null || true

# Build ISO
echo -e "${GREEN}[*] Creating ISO image...${NC}"
xorriso -as mkisofs \
    -o $OUTPUT/CoolOS-${COOLOS_VERSION}-amd64.iso \
    -isohybrid-mbr $ISO/isolinux/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/x86_64-efi/core.efi -no-emul-boot \
    -isohybrid-gpt-basdat -V "CoolOS" -R -J $ISO

# Checksums
cd $OUTPUT
sha256sum *.iso > SHA256SUMS

# Cleanup
rm -rf $BUILD/iso $BUILD/chroot

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗"
echo -e "║                    Build Complete!                         ║"
echo -e "╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}ISO:${NC} $OUTPUT/CoolOS-${COOLOS_VERSION}-amd64.iso"
echo ""
ls -lh $OUTPUT/*.iso
echo ""
echo -e "${GREEN}Checksum:${NC}"
cat $OUTPUT/SHA256SUMS
