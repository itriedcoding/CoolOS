#!/bin/bash
#
# CoolOS VM Builder
# Creates pre-configured VM images
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

# VM Configuration
VM_MEMORY="2048"
VM_SMP="2"
VM_DISK_SIZE="20G"

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

check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("qemu-img" "virt-install" "virsh")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "Missing dependency: $dep"
            print_info "Install with: sudo apt install virt-manager qemu-system-x86"
            exit 1
        fi
    done
    
    print_status "Dependencies satisfied"
}

check_iso() {
    if [ ! -f "$OUTPUT_DIR/$ISO_NAME" ]; then
        print_error "ISO not found: $OUTPUT_DIR/$ISO_NAME"
        print_info "Build the ISO first with: ./scripts/build.sh"
        exit 1
    fi
}

create_vm() {
    local vm_name="$1"
    local vm_memory="$2"
    local vm_cpus="$3"
    local vm_disk="$4"
    
    print_status "Creating VM: $vm_name"
    
    # Create disk image
    qemu-img create -f qcow2 "$OUTPUT_DIR/$vm_name.qcow2" "$vm_disk"
    
    # Create VM with virt-install
    virt-install \
        --name "$vm_name" \
        --memory "$vm_memory" \
        --vcpus "$vm_cpus" \
        --disk "$OUTPUT_DIR/$vm_name.qcow2,format=qcow2" \
        --cdrom "$OUTPUT_DIR/$ISO_NAME" \
        --os-variant debian11 \
        --network bridge=virbr0 \
        --graphics vnc,listen=0.0.0.0 \
        --noautoconsole \
        --import
    
    print_status "VM created: $vm_name"
    print_info "Connect with: virsh console $vm_name"
}

create_vm_virtualbox() {
    local vm_name="$1"
    local vm_memory="$2"
    local vm_cpus="$3"
    
    print_status "Creating VirtualBox VM: $vm_name"
    
    # Check for VirtualBox
    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox is not installed"
        return 1
    fi
    
    # Create VM
    VBoxManage createvm --name "$vm_name" --register
    VBoxManage modifyvm "$vm_name" \
        --memory "$vm_memory" \
        --cpus "$vm_cpus" \
        --os-type Linux \
        --os-variant Debian_64 \
        --graphicscontroller vboxsvga \
        --vram 128 \
        --nic1 nat \
        --natpf1 "ssh,tcp,,2222,,22" \
        --natpf1 "http,tcp,,8080,,80" \
        --natpf1 "https,tcp,,8443,,443"
    
    # Create disk
    VBoxManage createmedium disk --filename "$OUTPUT_DIR/$vm_name.vdi" --size 20480 --format VDI
    
    # Add storage
    VBoxManage storagectl "$vm_name" --name "IDE" --add ide
    VBoxManage storageattach "$vm_name" --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "$OUTPUT_DIR/$ISO_NAME"
    
    VBoxManage storagectl "$vm_name" --name "SATA" --add sata --hostiocache on
    VBoxManage storageattach "$vm_name" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$OUTPUT_DIR/$vm_name.vdi"
    
    print_status "VirtualBox VM created: $vm_name"
    print_info "Start with: VBoxManage startvm $vm_name"
}

create_vm_vmware() {
    local vm_name="$1"
    local vm_memory="$2"
    local vm_cpus="$3"
    
    print_status "Creating VMware VM: $vm_name"
    
    # Check for vmrun
    if ! command -v vmrun &> /dev/null; then
        print_error "VMware is not installed"
        return 1
    fi
    
    # Create VM directory
    mkdir -p "$OUTPUT_DIR/$vm_name"
    
    # Create VMX file
    cat > "$OUTPUT_DIR/$vm_name/$vm_name.vmx" << EOF
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "19"
displayName = "$vm_name"
guestOS = "debian11-64"
memory = "$vm_memory"
numvcpus = "$vm_cpus"
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.fileName = "$vm_name.vmdk"
scsi0:0.present = "TRUE"
ide1:0.fileName = "$ISO_NAME"
ide1:0.deviceType = "cdrom-image"
ide1:0.present = "TRUE"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
ethernet0.autoNegotiate = "TRUE"
usb.present = "TRUE"
sound.present = "TRUE"
sound.autoDetect = "TRUE"
EOF
    
    # Create VMDK file
    qemu-img convert -f qcow2 -O vmdk "$OUTPUT_DIR/$vm_name.qcow2" "$OUTPUT_DIR/$vm_name/$vm_name.vmdk"
    
    print_status "VMware VM created: $vm_name"
    print_info "Open $vm_name.vmx in VMware Workstation"
}

create_vm_proxmox() {
    local vm_name="$1"
    local vm_memory="$2"
    local vm_cpus="$3"
    
    print_status "Creating Proxmox VM template: $vm_name"
    
    # Create Proxmox template directory
    mkdir -p "$OUTPUT_DIR/proxmox"
    
    # Create template configuration
    cat > "$OUTPUT_DIR/proxmox/$vm_name.conf" << EOF
# CoolOS Proxmox Template
# Import with: qm importovf <vmid> $vm_name.ovf

boot: order=scsi0;ide2;net0
cores: $vm_cpus
cpu: host
memory: $vm_memory
name: $vm_name
net0: virtio,bridge=vmbr0
ostype: l26
scsi0: local-lvm:1,iothread=1
scsihw: virtio-scsi-pci
sockets: 1
template: 1
EFI disk: efidisk0,efitype=4m,pre-enrolled-keys=1
ide2: none,media=cdrom
EOF
    
    print_status "Proxmox template created"
    print_info "Import with: qm importovf <vmid> $vm_name.ovf"
}

create_all_vms() {
    print_status "Creating all VM variants..."
    
    # QEMU/KVM
    create_vm "CoolOS-Test" "$VM_MEMORY" "$VM_SMP" "$VM_DISK_SIZE"
    
    # VirtualBox
    create_vm_virtualbox "CoolOS-Test" "$VM_MEMORY" "$VM_SMP"
    
    # VMware
    create_vm_vmware "CoolOS-Test" "$VM_MEMORY" "$VM_SMP"
    
    # Proxmox
    create_vm_proxm "CoolOS-Test" "$VM_MEMORY" "$VM_SMP"
    
    print_status "All VMs created"
}

show_help() {
    echo "CoolOS VM Builder"
    echo ""
    echo "Usage: $0 [option] [vm_name]"
    echo ""
    echo "Options:"
    echo "  -k, --kvm        Create QEMU/KVM VM"
    echo "  -v, --virtualbox Create VirtualBox VM"
    echo "  -w, --vmware     Create VMware VM"
    echo "  -p, --proxmox    Create Proxmox template"
    echo "  -a, --all        Create all VM variants"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -k myvm       # Create QEMU/KVM VM"
    echo "  $0 -v myvm       # Create VirtualBox VM"
    echo "  $0 -a            # Create all variants"
    echo ""
}

# Main function
main() {
    local mode="kvm"
    local vm_name="CoolOS-Test"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--kvm)
                mode="kvm"
                shift
                ;;
            -v|--virtualbox)
                mode="virtualbox"
                shift
                ;;
            -w|--vmware)
                mode="vmware"
                shift
                ;;
            -p|--proxmox)
                mode="proxmox"
                shift
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                vm_name="$1"
                shift
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # Check ISO
    check_iso
    
    # Create VM
    case $mode in
        kvm)
            create_vm "$vm_name" "$VM_MEMORY" "$VM_SMP" "$VM_DISK_SIZE"
            ;;
        virtualbox)
            create_vm_virtualbox "$vm_name" "$VM_MEMORY" "$VM_SMP"
            ;;
        vmware)
            create_vm_vmware "$vm_name" "$VM_MEMORY" "$VM_SMP"
            ;;
        proxmox)
            create_vm_proxm "$vm_name" "$VM_MEMORY" "$VM_SMP"
            ;;
        all)
            create_all_vms
            ;;
        *)
            print_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
    
    print_status "VM creation complete"
}

# Run main function
main
