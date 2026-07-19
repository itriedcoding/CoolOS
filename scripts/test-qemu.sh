#!/bin/bash
#
# CoolOS QEMU Test Script
# Tests the ISO in QEMU virtual machine
#

set -e

# Configuration
COOLOS_VERSION="1.0.0"
COOLOS_ARCH="amd64"
ISO_NAME="CoolOS-${COOLOS_VERSION}-${COOLOS_ARCH}.iso"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$ROOT_DIR/output"

# QEMU Configuration
QEMU_MEMORY="2048"
QEMU_SMP="2"
QEMU_DISK_SIZE="20G"

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

check_qemu() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        print_error "QEMU is not installed"
        print_info "Install with: sudo apt install qemu-system-x86"
        exit 1
    fi
}

check_iso() {
    if [ ! -f "$OUTPUT_DIR/$ISO_NAME" ]; then
        print_error "ISO not found: $OUTPUT_DIR/$ISO_NAME"
        print_info "Build the ISO first with: ./scripts/build.sh"
        exit 1
    fi
}

test_iso() {
    print_status "Testing ISO in QEMU..."
    
    # Create disk image
    qemu-img create -f qcow2 "$OUTPUT_DIR/coolos-disk.qcow2" "$QEMU_DISK_SIZE"
    
    # Start QEMU
    qemu-system-x86_64 \
        -m "$QEMU_MEMORY" \
        -smp "$QEMU_SMP" \
        -cpu host \
        -enable-kvm \
        -cdrom "$OUTPUT_DIR/$ISO_NAME" \
        -hda "$OUTPUT_DIR/coolos-disk.qcow2" \
        -boot d \
        -vga virtio \
        -display sdl,gl=on \
        -usb \
        -device usb-tablet \
        -net nic,model=virtio \
        -net user \
        -name "CoolOS Test"
}

test_iso_bios() {
    print_status "Testing ISO in QEMU (BIOS mode)..."
    
    # Create disk image
    qemu-img create -f qcow2 "$OUTPUT_DIR/coolos-disk-bios.qcow2" "$QEMU_DISK_SIZE"
    
    # Start QEMU
    qemu-system-x86_64 \
        -m "$QEMU_MEMORY" \
        -smp "$QEMU_SMP" \
        -cpu qemu64 \
        -cdrom "$OUTPUT_DIR/$ISO_NAME" \
        -hda "$OUTPUT_DIR/coolos-disk-bios.qcow2" \
        -boot d \
        -vga virtio \
        -display sdl \
        -usb \
        -device usb-tablet \
        -net nic,model=virtio \
        -net user \
        -name "CoolOS Test (BIOS)"
}

test_iso_uefi() {
    print_status "Testing ISO in QEMU (UEFI mode)..."
    
    # Create disk image
    qemu-img create -f qcow2 "$OUTPUT_DIR/coolos-disk-uefi.qcow2" "$QEMU_DISK_SIZE"
    
    # Find OVMF firmware
    OVMF_PATH="/usr/share/OVMF/OVMF_CODE.fd"
    if [ ! -f "$OVMF_PATH" ]; then
        OVMF_PATH="/usr/share/edk2/ovmf/OVMF_CODE.fd"
    fi
    
    if [ -f "$OVMF_PATH" ]; then
        # Start QEMU with UEFI
        qemu-system-x86_64 \
            -m "$QEMU_MEMORY" \
            -smp "$QEMU_SMP" \
            -cpu host \
            -enable-kvm \
            -bios "$OVMF_PATH" \
            -cdrom "$OUTPUT_DIR/$ISO_NAME" \
            -hda "$OUTPUT_DIR/coolos-disk-uefi.qcow2" \
            -boot d \
            -vga virtio \
            -display sdl,gl=on \
            -usb \
            -device usb-tablet \
            -net nic,model=virtio \
            -net user \
            -name "CoolOS Test (UEFI)"
    else
        print_warning "OVMF firmware not found, using default BIOS"
        test_iso
    fi
}

cleanup() {
    print_status "Cleaning up test files..."
    rm -f "$OUTPUT_DIR/coolos-disk.qcow2"
    rm -f "$OUTPUT_DIR/coolos-disk-bios.qcow2"
    rm -f "$OUTPUT_DIR/coolos-disk-uefi.qcow2"
    print_status "Cleanup complete"
}

show_help() {
    echo "CoolOS QEMU Test Script"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -m, --mode     Test mode (bios, uefi, default)"
    echo "  -c, --cleanup  Clean up test files"
    echo "  -h, --help     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0              # Test with default settings"
    echo "  $0 -m bios      # Test in BIOS mode"
    echo "  $0 -m uefi      # Test in UEFI mode"
    echo "  $0 -c           # Clean up test files"
    echo ""
}

# Main function
main() {
    local mode="default"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                mode="$2"
                shift 2
                ;;
            -c|--cleanup)
                cleanup
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check QEMU
    check_qemu
    
    # Check ISO
    check_iso
    
    # Test ISO
    case $mode in
        bios)
            test_iso_bios
            ;;
        uefi)
            test_iso_uefi
            ;;
        default)
            test_iso
            ;;
        *)
            print_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

# Run main function
main
