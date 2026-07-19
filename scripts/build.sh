#!/bin/bash
#
# CoolOS Build Script
# Lightweight Linux Distribution
#
# Usage: ./build.sh [options]
#

set -e

# Configuration
COOLOS_VERSION="1.0.0"
COOLOS_CODENAME="Frostbite"
COOLOS_ARCH="amd64"
COOLOS_DEBIAN="bookworm"

# Directories
BUILD_DIR="$(pwd)/build"
CACHE_DIR="$(pwd)/cache"
CONFIG_DIR="$(pwd)/config"
ISO_DIR="$(pwd)/iso"
OUTPUT_DIR="$(pwd)/output"

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
        print_info "Use: sudo ./build.sh"
        exit 1
    fi
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("debootstrap" "squashfs-tools" "xorriso" "mtools" "dosfstools" "grub-pc-bin" "grub-efi-amd64-bin" "mbr" "binutils")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -l "$dep" &> /dev/null; then
            print_warning "Installing missing dependency: $dep"
            apt-get update
            apt-get install -y "$dep"
        fi
    done
    
    print_status "Dependencies satisfied"
}

setup_directories() {
    print_status "Setting up build directories..."
    
    mkdir -p "$BUILD_DIR" "$CACHE_DIR" "$ISO_DIR" "$OUTPUT_DIR"
    
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
        --include=apt-transport-https,ca-certificates,curl,wget,gnupg \
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

# CoolOS Custom Repository
# deb http://repo.coolors.org/ $COOLOS_CODENAME main
EOF

    # Mount necessary filesystems
    mount --bind /dev "$BUILD_DIR/dev"
    mount --bind /dev/pts "$BUILD_DIR/dev/pts"
    mount -t proc proc "$BUILD_DIR/proc"
    mount -t sysfs sysfs "$BUILD_DIR/sys"
    
    # Copy DNS configuration
    cp /etc/resolv.conf "$BUILD_DIR/etc/resolv.conf"
    
    # Update package lists inside chroot
    chroot "$BUILD_DIR" apt-get update
    
    print_status "APT configured"
}

install_packages() {
    print_status "Installing CoolOS packages..."
    
    # Copy package lists
    cp -r "$CONFIG_DIR/package-lists" "$BUILD_DIR/tmp/"
    
    chroot "$BUILD_DIR" << 'CHROOT'
        set -e
        
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
            procps
        
        # Install all package lists
        for list in /tmp/package-lists/*.list.chroot; do
            if [ -f "$list" ]; then
                echo "Installing packages from $list..."
                xargs -a "$list" apt-get install -y || true
            fi
        done
        
        # Clean up
        apt-get clean
        rm -rf /var/lib/apt/lists/*
CHROOT
    
    print_status "Packages installed"
}

configure_system() {
    print_status "Configuring system..."
    
    # Set hostname
    echo "CoolOS" > "$BUILD_DIR/etc/hostname"
    echo "127.0.0.1 localhost CoolOS" > "$BUILD_DIR/etc/hosts"
    
    # Set locale
    chroot "$BUILD_DIR" << 'CHROOT'
        echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
        locale-gen
        update-locale LANG=en_US.UTF-8
CHROOT
    
    # Set timezone
    chroot "$BUILD_DIR" ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    
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
    
    # Copy hooks to build directory
    cp -r "$CONFIG_DIR/hooks" "$BUILD_DIR/tmp/"
    
    chroot "$BUILD_DIR" << 'CHROOT'
        set -e
        
        # Run APT hooks
        for hook in /tmp/hooks/apt/*.chroot; do
            if [ -f "$hook" ] && [ -x "$hook" ]; then
                echo "Running hook: $hook"
                "$hook"
            fi
        done
        
        # Run live hooks
        for hook in /tmp/hooks/live/*.chroot; do
            if [ -f "$hook" ] && [ -x "$hook" ]; then
                echo "Running hook: $hook"
                "$hook"
            fi
        done
        
        # Clean up
        rm -rf /tmp/hooks
CHROOT
    
    print_status "Customizations applied"
}

configure_bootloader() {
    print_status "Configuring boot loader..."
    
    # Copy kernel and initrd
    mkdir -p "$ISO_DIR/live"
    
    # Find kernel and initrd
    KERNEL=$(ls "$BUILD_DIR"/boot/vmlinuz-* 2>/dev/null | head -n1)
    INITRD=$(ls "$BUILD_DIR"/boot/initrd.img-* 2>/dev/null | head -n1)
    
    if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
        print_error "Kernel or initrd not found"
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
    
    # Create BIOS boot image
    mkdir -p "$ISO_DIR/boot/grub/i386-pc"
    grub-mkimage \
        --directory="$BUILD_DIR/usr/lib/grub/i386-pc" \
        --output="$ISO_DIR/boot/grub/i386-pc/core.img" \
        --format=i386-pc \
        --prefix="(cd)/boot/grub" \
        biosdisk iso9660 part_msdos fat normal boot linux
    
    # Create EFI boot image
    mkdir -p "$ISO_DIR/boot/grub/x86_64-efi"
    grub-mkimage \
        --directory="$BUILD_DIR/usr/lib/grub/x86_64-efi" \
        --output="$ISO_DIR/boot/grub/x86_64-efi/core.efi" \
        --format=x86_64-efi \
        --prefix="(cd)/boot/grub" \
        fat iso9660 normal boot linux
    
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
    BLOCK_SIZE=$(stat -f -c %S "$ISO_DIR/live/filesystem.squashfs")
    BLOCK_COUNT=$(du -s "$BUILD_DIR" | cut -f1)
    echo $(( (BLOCK_COUNT * 4096 / BLOCK_SIZE) + 1 )) > "$ISO_DIR/live/filesystem.size"
    
    print_status "SquashFS image created"
}

create_iso() {
    print_status "Creating ISO image..."
    
    local ISO_NAME="CoolOS-${COOLOS_VERSION}-${COOLOS_ARCH}.iso"
    
    # Create BIOS boot image
    dd if=/usr/lib/ISOLINUX/isohdpfx.bin of=/tmp/isohdpfx.bin bs=4096 count=1 2>/dev/null || true
    
    # Create ISO with xorriso
    xorriso -as mkisofs \
        -o "$OUTPUT_DIR/$ISO_NAME" \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
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
