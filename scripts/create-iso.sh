#!/bin/bash
#
# CoolOS ISO Creator
# Creates bootable ISO from pre-built filesystem
#

set -e

# Configuration
COOLOS_VERSION="1.0.0"
COOLOS_ARCH="amd64"
ISO_NAME="CoolOS-${COOLOS_VERSION}-${COOLOS_ARCH}.iso"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"
OUTPUT_DIR="$ROOT_DIR/output"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
        exit 1
    fi
}

create_iso_structure() {
    print_status "Creating ISO directory structure..."
    
    # Create ISO directories
    mkdir -p "$BUILD_DIR/isolinux"
    mkdir -p "$BUILD_DIR/boot/grub"
    mkdir -p "$BUILD_DIR/boot/grub/i386-pc"
    mkdir -p "$BUILD_DIR/boot/grub/x86_64-efi"
    mkdir -p "$BUILD_DIR/live"
    
    print_status "ISO structure created"
}

install_isolinux() {
    print_status "Installing isolinux..."
    
    # Install isolinux
    apt-get update
    apt-get install -y isolinux syslinux-common
    
    # Copy isolinux files
    cp /usr/lib/ISOLINUX/isolinux.bin "$BUILD_DIR/isolinux/"
    cp /usr/lib/ISOLINUX/isohdpfx.bin "$BUILD_DIR/isolinux/"
    cp /usr/share/syslinux/menu.c32 "$BUILD_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/libutil.c32 "$BUILD_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/libcom32.c32 "$BUILD_DIR/isolinux/" 2>/dev/null || true
    cp /usr/share/syslinux/ldlinux.c32 "$BUILD_DIR/isolinux/" 2>/dev/null || true
    
    # Create isolinux configuration
    cat > "$BUILD_DIR/isolinux/isolinux.cfg" << 'EOF'
# CoolOS Isolinux Configuration

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
    
    print_status "Isolinux installed"
}

install_grub_efi() {
    print_status "Installing GRUB EFI..."
    
    # Install GRUB EFI
    apt-get install -y grub-efi-amd64-bin grub2-common grub-common
    
    # Create GRUB modules
    cd "$BUILD_DIR"
    
    # Create BIOS boot image
    grub-mkimage \
        --directory=/usr/lib/grub/i386-pc \
        --output="$BUILD_DIR/boot/grub/i386-pc/core.img" \
        --format=i386-pc \
        --prefix="(cd)/boot/grub" \
        biosdisk iso9660 part_msdos fat normal boot linux
    
    # Create EFI boot image
    grub-mkimage \
        --directory=/usr/lib/grub/x86_64-efi \
        --output="$BUILD_DIR/boot/grub/x86_64-efi/core.efi" \
        --format=x86_64-efi \
        --prefix="(cd)/boot/grub" \
        fat iso9660 normal boot linux
    
    print_status "GRUB EFI installed"
}

create_grub_config() {
    print_status "Creating GRUB configuration..."
    
    cat > "$BUILD_DIR/boot/grub/grub.cfg" << 'EOF'
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
    
    print_status "GRUB configuration created"
}

create_iso() {
    print_status "Creating ISO image..."
    
    # Create ISO
    xorriso -as mkisofs \
        -o "$OUTPUT_DIR/$ISO_NAME" \
        -isohybrid-mbr "$BUILD_DIR/isolinux/isohdpfx.bin" \
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
        "$BUILD_DIR"
    
    print_status "ISO created: $OUTPUT_DIR/$ISO_NAME"
}

cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf "$BUILD_DIR"
    print_status "Cleanup complete"
}

show_info() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗"
    echo -e "║                    ISO Created Successfully!               ║"
    echo -e "╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}ISO Location:${NC} $OUTPUT_DIR/$ISO_NAME"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  1. Create a new virtual machine"
    echo "  2. Attach the ISO image"
    echo "  3. Boot from ISO"
    echo "  4. Follow the installation wizard"
    echo ""
}

# Main function
main() {
    echo -e "${CYAN}CoolOS ISO Creator${NC}"
    echo ""
    
    # Check if running as root
    check_root
    
    # Create ISO structure
    create_iso_structure
    
    # Install boot loaders
    install_isolinux
    install_grub_efi
    
    # Create configurations
    create_grub_config
    
    # Create ISO
    create_iso
    
    # Cleanup
    cleanup
    
    # Show information
    show_info
}

# Run main function
main
