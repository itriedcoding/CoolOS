#!/bin/bash
#
# CoolOS Build Script
# Lightweight Linux Distribution
#
# Usage: sudo ./build.sh [options]
#

set -e

# Configuration
COOLOS_VERSION="1.0.0"
COOLOS_CODENAME="Frostbite"
COOLOS_ARCH="amd64"
COOLOS_DEBIAN="bookworm"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")/build"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
ISO_DIR="$(dirname "$SCRIPT_DIR")/iso"
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    CoolOS Build System                     ║"
    echo "║              Lightweight Linux Distribution                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_info "Use: sudo ./scripts/build.sh"
        exit 1
    fi
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("debootstrap" "squashfs-tools" "xorriso" "mtools" "dosfstools" "grub-pc-bin" "grub-efi-amd64-bin" "mbr" "binutils")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -l "$dep" &> /dev/null 2>&1; then
            print_warning "Installing missing dependency: $dep"
            apt-get update
            apt-get install -y "$dep"
        fi
    done
    
    print_status "Dependencies satisfied"
}

setup_directories() {
    print_status "Setting up build directories..."
    
    mkdir -p "$BUILD_DIR" "$ISO_DIR/live" "$OUTPUT_DIR"
    
    # Clean previous build
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        mkdir -p "$BUILD_DIR"
    fi
    
    print_status "Directories ready"
}

debootstrap_base() {
    print_status "Installing base system with debootstrap..."
    
    debootstrap \
        --arch="$COOLOS_ARCH" \
        --variant=minbase \
        --include=apt-transport-https,ca-certificates,curl,wget,gnupg,systemd,systemd-sysv,dbus,udev,kmod,procps,locales \
        "$COOLOS_DEBIAN" \
        "$BUILD_DIR" \
        http://deb.debian.org/debian/
    
    print_status "Base system installed"
}

configure_apt() {
    print_status "Configuring APT sources..."
    
    cat > "$BUILD_DIR/etc/apt/sources.list" << EOF
# CoolOS Repository Sources
deb http://deb.debian.org/debian/ $COOLOS_DEBIAN main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $COOLOS_DEBIAN-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $COOLOS_DEBIAN-security main contrib non-free non-free-firmware
EOF

    # Mount necessary filesystems
    mount --bind /dev "$BUILD_DIR/dev" 2>/dev/null || true
    mount --bind /dev/pts "$BUILD_DIR/dev/pts" 2>/dev/null || true
    mount -t proc proc "$BUILD_DIR/proc" 2>/dev/null || true
    mount -t sysfs sysfs "$BUILD_DIR/sys" 2>/dev/null || true
    
    # Copy DNS configuration
    cp /etc/resolv.conf "$BUILD_DIR/etc/resolv.conf" 2>/dev/null || true
    
    # Update package lists inside chroot
    chroot "$BUILD_DIR" apt-get update
    
    print_status "APT configured"
}

install_packages() {
    print_status "Installing CoolOS packages..."
    
    chroot "$BUILD_DIR" /bin/bash -c '
        set -e
        export DEBIAN_FRONTEND=noninteractive
        
        # Update package lists
        apt-get update
        
        # Install base packages
        apt-get install -y \
            linux-image-amd64 \
            linux-headers-amd64 \
            systemd \
            systemd-sysv \
            dbus \
            udev \
            kmod \
            procps \
            locales
        
        # Install desktop environment
        apt-get install -y \
            openbox \
            tint2 \
            plank \
            rofi \
            dmenu \
            pcmanfm \
            thunar \
            lxterminal \
            terminator \
            lightdm \
            lightdm-gtk-greeter \
            picom \
            dunst \
            nitrogen \
            lxappearance \
            arc-theme \
            papirus-icon-theme \
            fonts-noto \
            fonts-noto-color-emoji \
            fonts-firacode \
            fonts-dejavu \
            fonts-liberation
        
        # Install applications
        apt-get install -y \
            firefox-esr \
            chromium \
            libreoffice-writer \
            libreoffice-calc \
            libreoffice-impress \
            vlc \
            mpv \
            gimp \
            inkscape \
            geany \
            evince \
            galculator \
            file-roller \
            network-manager \
            network-manager-gnome \
            blueman \
            cups \
            system-config-printer \
            gnome-system-monitor \
            baobab \
            ncdu \
            ufw
        
        # Install development tools
        apt-get install -y \
            build-essential \
            gcc \
            g++ \
            make \
            git \
            python3 \
            python3-pip \
            curl \
            wget \
            vim-tiny \
            nano \
            sudo \
            htop \
            tmux \
            tree \
            lsof \
            rsync \
            zip \
            unzip \
            p7zip-full
        
        # Install live system packages
        apt-get install -y \
            live-boot \
            live-config \
            live-config-systemd
        
        # Install boot loader
        apt-get install -y \
            grub-efi-amd64-bin \
            grub-pc-bin \
            grub2-common \
            grub-common \
            syslinux \
            syslinux-common \
            isolinux \
            xorriso \
            mtools
        
        # Clean up
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    '
    
    print_status "Packages installed"
}

configure_system() {
    print_status "Configuring system..."
    
    # Set hostname
    echo "CoolOS" > "$BUILD_DIR/etc/hostname"
    echo "127.0.0.1 localhost CoolOS" > "$BUILD_DIR/etc/hosts"
    
    # Set locale
    chroot "$BUILD_DIR" /bin/bash -c '
        echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
        locale-gen
        update-locale LANG=en_US.UTF-8
    '
    
    # Set timezone
    chroot "$BUILD_DIR" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    
    # Create default user
    chroot "$BUILD_DIR" /bin/bash -c '
        useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth coolos 2>/dev/null || true
        echo "coolos:coolors" | chpasswd
        echo "root:coolors" | chpasswd
        echo "coolos ALL=(ALL) ALL" > /etc/sudoers.d/coolos
        chmod 440 /etc/sudoers.d/coolos
    '
    
    # Enable services
    chroot "$BUILD_DIR" systemctl enable NetworkManager 2>/dev/null || true
    chroot "$BUILD_DIR" systemctl enable lightdm 2>/dev/null || true
    
    # Configure fstab for live system
    cat > "$BUILD_DIR/etc/fstab" << 'EOF'
# CoolOS Live System fstab
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
tmpfs           /tmp            tmpfs   defaults,noatime 0       0
EOF
    
    print_status "System configured"
}

apply_hooks() {
    print_status "Applying CoolOS customizations..."
    
    # Copy desktop configuration
    mkdir -p "$BUILD_DIR/etc/xdg/openbox"
    mkdir -p "$BUILD_DIR/etc/skel/.config/tint2"
    mkdir -p "$BUILD_DIR/etc/skel/.config/openbox"
    mkdir -p "$BUILD_DIR/etc/lightdm/lightdm.conf.d"
    mkdir -p "$BUILD_DIR/usr/share/applications"
    
    # Copy Openbox configuration
    cp "$CONFIG_DIR/includes.chroot/etc/xdg/openbox/menu.xml" "$BUILD_DIR/etc/xdg/openbox/menu.xml" 2>/dev/null || true
    cp "$CONFIG_DIR/includes.chroot/etc/xdg/openbox/rc.xml" "$BUILD_DIR/etc/xdg/openbox/rc.xml" 2>/dev/null || true
    cp "$CONFIG_DIR/includes.chroot/etc/xdg/openbox/autostart" "$BUILD_DIR/etc/xdg/openbox/autostart" 2>/dev/null || true
    chmod +x "$BUILD_DIR/etc/xdg/openbox/autostart" 2>/dev/null || true
    
    # Copy user configurations
    cp "$CONFIG_DIR/includes.chroot/etc/skel/.config/tint2/tint2rc" "$BUILD_DIR/etc/skel/.config/tint2/tint2rc" 2>/dev/null || true
    cp "$CONFIG_DIR/includes.chroot/etc/skel/.bashrc" "$BUILD_DIR/etc/skel/.bashrc" 2>/dev/null || true
    cp "$CONFIG_DIR/includes.chroot/etc/skel/.vimrc" "$BUILD_DIR/etc/skel/.vimrc" 2>/dev/null || true
    
    # Copy desktop files
    cp "$CONFIG_DIR/includes.chroot/usr/share/applications/"*.desktop "$BUILD_DIR/usr/share/applications/" 2>/dev/null || true
    
    # Configure LightDM
    cat > "$BUILD_DIR/etc/lightdm/lightdm.conf.d/50-coolos.conf" << 'EOF'
[Seat:*]
autologin-user=coolos
autologin-user-timeout=0
user-session=openbox
EOF
    
    # Copy configurations to user
    mkdir -p "$BUILD_DIR/home/coolos/.config/openbox"
    mkdir -p "$BUILD_DIR/home/coolos/.config/tint2"
    mkdir -p "$BUILD_DIR/home/coolos/.config/gtk-3.0"
    mkdir -p "$BUILD_DIR/home/coolos/.icons/default"
    
    cp "$BUILD_DIR/etc/xdg/openbox/autostart" "$BUILD_DIR/home/coolos/.config/openbox/autostart" 2>/dev/null || true
    cp "$BUILD_DIR/etc/xdg/openbox/menu.xml" "$BUILD_DIR/home/coolos/.config/openbox/menu.xml" 2>/dev/null || true
    cp "$BUILD_DIR/etc/xdg/openbox/rc.xml" "$BUILD_DIR/home/coolos/.config/openbox/rc.xml" 2>/dev/null || true
    cp "$BUILD_DIR/etc/skel/.config/tint2/tint2rc" "$BUILD_DIR/home/coolos/.config/tint2/tint2rc" 2>/dev/null || true
    
    # Set GTK theme
    cat > "$BUILD_DIR/home/coolos/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=Noto Sans 10
EOF
    
    # Set cursor theme
    cat > "$BUILD_DIR/home/coolos/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=Adwaita
EOF
    
    # Fix permissions
    chown -R 1000:1000 "$BUILD_DIR/home/coolos" 2>/dev/null || true
    
    print_status "Customizations applied"
}

configure_bootloader() {
    print_status "Configuring boot loader..."
    
    # Find kernel and initrd
    KERNEL=$(ls "$BUILD_DIR"/boot/vmlinuz-* 2>/dev/null | head -n1)
    INITRD=$(ls "$BUILD_DIR"/boot/initrd.img-* 2>/dev/null | head -n1)
    
    if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
        print_error "Kernel or initrd not found"
        ls -la "$BUILD_DIR/boot/"
        exit 1
    fi
    
    cp "$KERNEL" "$ISO_DIR/live/vmlinuz"
    cp "$INITRD" "$ISO_DIR/live/initrd"
    
    # Create GRUB configuration
    mkdir -p "$ISO_DIR/boot/grub"
    
    cat > "$ISO_DIR/boot/grub/grub.cfg" << 'EOF'
# CoolOS GRUB Configuration

set timeout=10
set default=0

set color_normal=light-gray/black
set color_highlight=white/blue

menuentry "CoolOS Live" {
    linux /live/vmlinuz boot=live quiet splash
    initrd /live/initrd
}

menuentry "CoolOS Live (Safe Mode)" {
    linux /live/vmlinuz boot=live quiet splash nomodeset
    initrd /live/initrd
}

menuentry "CoolOS Live (Verbose)" {
    linux /live/vmlinuz boot=live verbose
    initrd /live/initrd
}

menuentry "CoolOS Install" {
    linux /live/vmlinuz boot=live quiet splash components
    initrd /live/initrd
}
EOF
    
    # Create Isolinux configuration
    mkdir -p "$ISO_DIR/isolinux"
    
    cat > "$ISO_DIR/isolinux/isolinux.cfg" << 'EOF'
UI menu.c32

MENU TITLE CoolOS Boot Menu
MENU TIMEOUT 100
MENU COLOR TITLE 1;36;44
MENU COLOR SEL 7;37;40

LABEL coolos
    MENU LABEL CoolOS Live
    MENU DEFAULT
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash

LABEL safe
    MENU LABEL CoolOS Live (Safe Mode)
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash nomodeset

LABEL verbose
    MENU LABEL CoolOS Live (Verbose)
    KERNEL /live/vmlinuz
    APPEND boot=live verbose

LABEL install
    MENU LABEL CoolOS Install
    KERNEL /live/vmlinuz
    APPEND boot=live quiet splash components
EOF
    
    # Copy isolinux files
    cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/" 2>/dev/null || \
        cp /usr/share/syslinux/isolinux.bin "$ISO_DIR/isolinux/" 2>/dev/null || true
    
    cp /usr/lib/ISOLINUX/isohdpfx.bin "$ISO_DIR/isolinux/" 2>/dev/null || \
        cp /usr/share/syslinux/isohdpfx.bin "$ISO_DIR/isolinux/" 2>/dev/null || true
    
    cp /usr/share/syslinux/menu.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/libutil.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/libcom32.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/ldlinux.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
    
    # Create GRUB EFI image
    mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
    mkdir -p "$ISO_DIR/boot/grub/i386-pc"
    
    grub-mkimage \
        --directory=/usr/lib/grub/x86_64-efi \
        --output="$ISO_DIR/boot/grub/x86_64-efi/core.efi" \
        --format=x86_64-efi \
        --prefix="(cd)/boot/grub" \
        fat iso9660 normal boot linux configfile 2>/dev/null || echo "EFI image creation skipped"
    
    print_status "Boot loader configured"
}

create_squashfs() {
    print_status "Creating SquashFS image..."
    
    # Unmount chroot filesystems
    umount "$BUILD_DIR/dev/pts" 2>/dev/null || true
    umount "$BUILD_DIR/dev" 2>/dev/null || true
    umount "$BUILD_DIR/proc" 2>/dev/null || true
    umount "$BUILD_DIR/sys" 2>/dev/null || true
    
    # Create squashfs
    mksquashfs \
        "$BUILD_DIR" \
        "$ISO_DIR/live/filesystem.squashfs" \
        -comp xz \
        -b 1M \
        -Xbcj x86 \
        -noappend \
        -e boot
    
    # Create filesystem.size
    BLOCK_COUNT=$(du -s "$BUILD_DIR" | cut -f1)
    echo $(( (BLOCK_COUNT * 4096 / 4096) + 1 )) > "$ISO_DIR/live/filesystem.size"
    
    print_status "SquashFS image created"
}

create_iso() {
    print_status "Creating ISO image..."
    
    local ISO_NAME="CoolOS-${COOLOS_VERSION}-${COOLOS_ARCH}.iso"
    
    # Create ISO with xorriso
    xorriso -as mkisofs \
        -o "$OUTPUT_DIR/$ISO_NAME" \
        -isohybrid-mbr "$ISO_DIR/isolinux/isohdpfx.bin" \
        -c isolinux/boot.cat \
        -b isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/x86_64-efi/core.efi \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -V "CoolOS" \
        -R -J \
        "$ISO_DIR"
    
    print_status "ISO image created: $OUTPUT_DIR/$ISO_NAME"
}

cleanup() {
    print_status "Cleaning up..."
    
    # Unmount chroot filesystems
    umount "$BUILD_DIR/dev/pts" 2>/dev/null || true
    umount "$BUILD_DIR/dev" 2>/dev/null || true
    umount "$BUILD_DIR/proc" 2>/dev/null || true
    umount "$BUILD_DIR/sys" 2>/dev/null || true
    
    # Remove build directory
    rm -rf "$BUILD_DIR"
    
    # Remove ISO working directory
    rm -rf "$ISO_DIR"
    
    print_status "Cleanup complete"
}

show_info() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗"
    echo -e "║                    Build Complete!                         ║"
    echo -e "╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}ISO Location:${NC} $OUTPUT_DIR/CoolOS-${COOLOS_VERSION}-${COOLOS_ARCH}.iso"
    echo ""
    echo -e "${YELLOW}Default Credentials:${NC}"
    echo "  Username: coolos"
    echo "  Password: coolors"
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  1. Create a new VM"
    echo "  2. Attach the ISO image"
    echo "  3. Boot from ISO"
    echo "  4. Follow the installation wizard"
    echo ""
}

# Main function
main() {
    print_header
    
    # Check if running as root
    check_root
    
    # Check dependencies
    check_dependencies
    
    # Setup directories
    setup_directories
    
    # Build process
    debootstrap_base
    configure_apt
    install_packages
    configure_system
    apply_hooks
    configure_bootloader
    create_squashfs
    create_iso
    
    # Cleanup
    cleanup
    
    # Show information
    show_info
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            echo "CoolOS Build Script v${COOLOS_VERSION}"
            exit 0
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -v, --version    Show version"
            echo "  -h, --help       Show this help"
            echo ""
            echo "This script builds CoolOS ISO image."
            echo "It must be run as root."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main
