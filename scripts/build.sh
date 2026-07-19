#!/bin/bash
#
# CoolOS Build Script (using live-build)
# Usage: sudo ./scripts/build.sh
#
set -ex

echo "=========================================="
echo "       CoolOS Build System v1.2.0"
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
    cpio genisoimage live-build ovmf

BUILD=/coolos-build
rm -rf $BUILD
mkdir -p $BUILD && cd $BUILD

# Initialize live-build config
echo "[*] Configuring live-build..."
lb config \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootloaders "grub-efi,syslinux" \
    --binary-images iso-hybrid \
    --debian-installer none \
    --memtest none \
    --iso-application "CoolOS" \
    --iso-publisher "CoolOS" \
    --iso-volume "CoolOS 1.2.0" \
    --bootappend-live "boot=live quiet splash"

# Package lists
mkdir -p config/package-lists

cat > config/package-lists/coolors.list.chroot << 'EOF'
# Kernel
linux-image-amd64

# Core
systemd systemd-sysv dbus udev kmod procps locales sudo

# Desktop
openbox tint2 rofi pcmanfm thunar lxterminal
lightdm lightdm-gtk-greeter
picom dunst nitrogen lxappearance
arc-theme papirus-icon-theme
fonts-noto fonts-noto-color-emoji fonts-firacode fonts-dejavu fonts-liberation
xorg xserver-xorg xinit x11-xserver-utils xterm dbus-x11

# Apps
firefox-esr
libreoffice-writer libreoffice-calc libreoffice-impress
vlc mpv gimp inkscape geany evince galculator file-roller
network-manager network-manager-gnome
gnome-system-monitor baobab ncdu ufw
pulseaudio pavucontrol

# Dev
build-essential git python3 curl wget vim-tiny nano
htop tmux tree zip unzip p7zip-full

# Live system
live-boot live-config live-config-systemd
EOF

# Hooks
mkdir -p config/hooks/live

# User setup hook
cat > config/hooks/live/0100-users.chroot << 'HOOKEOF'
#!/bin/sh
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
HOOKEOF
chmod +x config/hooks/live/0100-users.chroot

# Desktop config hook
cat > config/hooks/live/0200-desktop.chroot << 'HOOKEOF'
#!/bin/sh
set -e

mkdir -p /etc/xdg/openbox
mkdir -p /etc/skel/.config/{openbox,tint2}
mkdir -p /etc/lightdm/lightdm.conf.d

# Autostart
cat > /etc/xdg/openbox/autostart << 'AUTOSTART'
#!/bin/sh
nitrogen --restore &
tint2 &
picom --experimental-backends &
dunst &
pcmanfm --daemon &
xset r rate 300 50
xsetroot -cursor_name left_ptr
AUTOSTART
chmod +x /etc/xdg/openbox/autostart

# LightDM
cat > /etc/lightdm/lightdm.conf.d/50-coolos.conf << 'LDM'
[Seat:*]
autologin-user=coolos
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
LDM

# Copy to user
mkdir -p /home/coolos/.config/{openbox,tint2}
cp /etc/xdg/openbox/autostart /home/coolos/.config/openbox/
chown -R 1000:1000 /home/coolos
HOOKEOF
chmod +x config/hooks/live/0200-desktop.chroot

# Build
echo "[*] Building ISO (this will take a while)..."
lb build 2>&1 | tail -50

# Find the ISO
ISO_FILE=$(ls -1 *.iso 2>/dev/null | head -n1)
if [ -z "$ISO_FILE" ]; then
    echo "ERROR: No ISO found!"
    ls -la
    exit 1
fi

# Move to output
OUTPUT=/coolos-build/output
mkdir -p $OUTPUT
mv "$ISO_FILE" $OUTPUT/
cd $OUTPUT
sha256sum *.iso > SHA256SUMS

echo ""
echo "=========================================="
echo "       BUILD COMPLETE!"
echo "=========================================="
echo ""
ls -lh $OUTPUT/*.iso
echo ""
cat $OUTPUT/SHA256SUMS
