#!/bin/bash
#
# CoolOS Build Script v1.2.0
# Manual debootstrap + xorriso approach with grub-mkstandalone
# Usage: sudo ./scripts/build.sh
#
set -ex

echo "=========================================="
echo "       CoolOS Build System v1.2.0"
echo "=========================================="

if [[ $EUID -ne 0 ]]; then
    echo "Error: Must run as root (sudo ./scripts/build.sh)"
    exit 1
fi

WORK=/coolos-build
rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

ROOTFS="$WORK/chroot"
IMAGE="$WORK/image"
SQUASH="$WORK/squashfs"
ISO_NAME="CoolOS-1.2.0-amd64.iso"

# --- 1. Debootstrap ---
debootstrap --arch=amd64 bookworm "$ROOTFS" http://deb.debian.org/debian/

# --- 2. Configure the chroot ---
chroot "$ROOTFS" bash -c '
set -e
echo "CoolOS" > /etc/hostname
echo "127.0.0.1 localhost CoolOS" > /etc/hosts

echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

apt-get update
apt-get install -y \
  linux-image-amd64 \
  systemd systemd-sysv dbus udev kmod procps locales sudo \
  openbox tint2 rofi pcmanfm thunar lxterminal \
  lightdm lightdm-gtk-greeter picom dunst nitrogen lxappearance \
  arc-theme papirus-icon-theme \
  fonts-noto fonts-noto-color-emoji fonts-firacode fonts-dejavu fonts-liberation \
  xorg xserver-xorg xinit x11-xserver-utils xterm dbus-x11 \
  firefox-esr libreoffice-writer libreoffice-calc libreoffice-impress \
  vlc mpv gimp inkscape geany evince galculator file-roller \
  network-manager network-manager-gnome \
  gnome-system-monitor baobab ncdu ufw \
  pulseaudio pavucontrol \
  build-essential git python3 curl wget vim-tiny nano \
  htop tmux tree zip unzip p7zip-full \
  live-boot live-config live-config-systemd

useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev coolos || true
echo "coolos:coolors" | chpasswd
echo "root:coolors" | chpasswd
echo "coolos ALL=(ALL) ALL" > /etc/sudoers.d/coolos
chmod 440 /etc/sudoers.d/coolos

systemctl enable NetworkManager 2>/dev/null || true
systemctl enable lightdm 2>/dev/null || true

mkdir -p /etc/xdg/openbox
cat > /etc/xdg/openbox/autostart << '"'"'AUTO'"'"'
#!/bin/sh
nitrogen --restore &
tint2 &
picom --experimental-backends &
dunst &
pcmanfm --daemon &
xset r rate 300 50
xsetroot -cursor_name left_ptr
AUTO
chmod +x /etc/xdg/openbox/autostart

mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-coolos.conf << '"'"'LDM'"'"'
[Seat:*]
autologin-user=coolos
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
LDM

mkdir -p /home/coolos/.config/{openbox,tint2}
cp /etc/xdg/openbox/autostart /home/coolos/.config/openbox/
chown -R 1000:1000 /home/coolos
'

# --- 3. Create squashfs ---
mkdir -p "$SQUASH"
mksquashfs "$ROOTFS" "$SQUASH/filesystem.squashfs" -comp xz -e boot

# --- 4. Assemble image directory ---
mkdir -p "$IMAGE/boot/grub/x86_64-efi"
mkdir -p "$IMAGE/boot/grub/i386-pc"
mkdir -p "$IMAGE/boot/isolinux"
mkdir -p "$IMAGE/live"

cp "$SQUASH/filesystem.squashfs" "$IMAGE/live/"

# Find and copy kernel/initrd
KVER=$(ls "$ROOTFS/boot/" | grep -E "^vmlinuz-" | head -1 | sed 's/vmlinuz-//')
echo "Kernel: $KVER"
cp "$ROOTFS/boot/vmlinuz-$KVER" "$IMAGE/boot/vmlinuz"
cp "$ROOTFS/boot/initrd.img-$KVER" "$IMAGE/boot/initrd.img"

# --- 5. GRUB config ---
cat > "$IMAGE/boot/grub/grub.cfg" << 'GRUBCFG'
set default=0
set timeout=5
set gfxpayload=keep

menuentry "CoolOS Live" {
  linux /boot/vmlinuz boot=live quiet splash
  initrd /boot/initrd.img
}

menuentry "CoolOS Live (safe mode)" {
  linux /boot/vmlinuz boot=live quiet splash nomodeset
  initrd /boot/initrd.img
}
GRUBCFG

# --- 6. Isolinux ---
cat > "$IMAGE/boot/isolinux/isolinux.cfg" << 'ISOLINUX'
UI vesamenu.c32
MENU TITLE CoolOS Boot Menu
DEFAULT coolos
TIMEOUT 50

LABEL coolos
  MENU LABEL CoolOS Live
  LINUX /boot/vmlinuz
  INITRD /boot/initrd.img
  APPEND boot=live quiet splash

LABEL coolos-safe
  MENU LABEL CoolOS Live (safe mode)
  LINUX /boot/vmlinuz
  INITRD /boot/initrd.img
  APPEND boot=live quiet splash nomodeset
ISOLINUX

cp /usr/lib/ISOLINUX/isolinux.bin "$IMAGE/boot/isolinux/"
cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$IMAGE/boot/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$IMAGE/boot/isolinux/" 2>/dev/null || true

# --- 7. GRUB EFI standalone (all modules embedded) ---
grub-mkstandalone \
  --format=x86_64-efi \
  --modules="" \
  --locales="" \
  --fonts="" \
  -o "$IMAGE/boot/grub/x86_64-efi/BOOTX64.EFI" \
  "boot/grub/grub.cfg=$IMAGE/boot/grub/grub.cfg"

# --- 8. Create ISO ---
cd "$WORK"

xorriso -as mkisofs \
  -r -J \
  -V 'CoolOS' \
  -o "$ISO_NAME" \
  --grub2-mbr /usr/lib/grub/i386-pc/boot.img \
  --grub2-boot-info \
  -eltorito-boot boot/isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/isolinux/boot.cat \
  -eltorito-alt-boot \
    -e boot/grub/x86_64-efi/BOOTX64.EFI \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
  "$IMAGE"

# --- 9. Verify ---
ls -lh "$ISO_NAME"
sha256sum "$ISO_NAME"

mkdir -p /coolos-build/output
mv "$ISO_NAME" /coolos-build/output/
cd /coolos-build/output
sha256sum *.iso > SHA256SUMS

echo ""
echo "=========================================="
echo "       BUILD COMPLETE!"
echo "=========================================="
ls -lh *.iso
cat SHA256SUMS
