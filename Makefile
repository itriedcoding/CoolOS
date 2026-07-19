# CoolOS Makefile
# Build and management commands

.PHONY: all build clean test vm help

# Configuration
VERSION := 1.0.0
ARCH := amd64
ISO_NAME := CoolOS-$(VERSION)-$(ARCH).iso

# Directories
BUILD_DIR := build
OUTPUT_DIR := output
SCRIPTS_DIR := scripts

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m

# Default target
all: help

# Help target
help:
	@echo ""
	@echo -e "$(CYAN)╔════════════════════════════════════════════════════════════╗"
	@echo -e "║                    CoolOS Build System                     ║"
	@echo -e "╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo -e "$(GREEN)Available targets:$(NC)"
	@echo ""
	@echo -e "$(YELLOW)  make build$(NC)      - Build CoolOS ISO"
	@echo -e "$(YELLOW)  make clean$(NC)      - Clean build directory"
	@echo -e "$(YELLOW)  make test$(NC)       - Test ISO with QEMU"
	@echo -e "$(YELLOW)  make test-uefi$(NC)  - Test ISO in UEFI mode"
	@echo -e "$(YELLOW)  make vm$(NC)         - Create virtual machine"
	@echo -e "$(YELLOW)  make vm-all$(NC)     - Create all VM formats"
	@echo -e "$(YELLOW)  make iso$(NC)        - Create ISO only"
	@echo -e "$(YELLOW)  make info$(NC)       - Show project information"
	@echo -e "$(YELLOW)  make help$(NC)       - Show this help"
	@echo ""

# Build CoolOS ISO
build:
	@echo -e "$(CYAN)Building CoolOS ISO...$(NC)"
	@sudo $(SCRIPTS_DIR)/build.sh

# Clean build directory
clean:
	@echo -e "$(CYAN)Cleaning build directory...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(OUTPUT_DIR)/*.iso
	@rm -rf $(OUTPUT_DIR)/*.qcow2
	@rm -rf $(OUTPUT_DIR)/*.vdi
	@rm -rf $(OUTPUT_DIR)/*.vmdk
	@echo -e "$(GREEN)Clean complete$(NC)"

# Test ISO with QEMU
test:
	@echo -e "$(CYAN)Testing ISO with QEMU...$(NC)"
	@sudo $(SCRIPTS_DIR)/test-qemu.sh

# Test ISO in UEFI mode
test-uefi:
	@echo -e "$(CYAN)Testing ISO in UEFI mode...$(NC)"
	@sudo $(SCRIPTS_DIR)/test-qemu.sh -m uefi

# Test ISO in BIOS mode
test-bios:
	@echo -e "$(CYAN)Testing ISO in BIOS mode...$(NC)"
	@sudo $(SCRIPTS_DIR)/test-qemu.sh -m bios

# Create virtual machine
vm:
	@echo -e "$(CYAN)Creating virtual machine...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-vm.sh -k

# Create all VM formats
vm-all:
	@echo -e "$(CYAN)Creating all VM formats...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-vm.sh -a

# Create VirtualBox VM
vm-vbox:
	@echo -e "$(CYAN)Creating VirtualBox VM...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-vm.sh -v

# Create VMware VM
vm-vmware:
	@echo -e "$(CYAN)Creating VMware VM...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-vm.sh -w

# Create Proxmox template
vm-proxmox:
	@echo -e "$(CYAN)Creating Proxmox template...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-vm.sh -p

# Create ISO only
iso:
	@echo -e "$(CYAN)Creating ISO...$(NC)"
	@sudo $(SCRIPTS_DIR)/create-iso.sh

# Show project information
info:
	@echo ""
	@echo -e "$(CYAN)╔════════════════════════════════════════════════════════════╗"
	@echo -e "║                    CoolOS Information                       ║"
	@echo -e "╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo -e "$(GREEN)Version:$(NC) $(VERSION)"
	@echo -e "$(GREEN)Architecture:$(NC) $(ARCH)"
	@echo -e "$(GREEN)ISO Name:$(NC) $(ISO_NAME)"
	@echo ""
	@echo -e "$(YELLOW)Default Credentials:$(NC)"
	@echo "  Username: coolos"
	@echo "  Password: coolors"
	@echo ""
	@echo -e "$(YELLOW)Build Requirements:$(NC)"
	@echo "  - Debian/Ubuntu host"
	@echo "  - 8GB RAM minimum"
	@echo "  - 20GB disk space"
	@echo "  - Root access"
	@echo ""

# Install dependencies
deps:
	@echo -e "$(CYAN)Installing dependencies...$(NC)"
	@sudo apt update
	@sudo apt install -y \
		debootstrap \
		squashfs-tools \
		xorriso \
		mtools \
		dosfstools \
		grub-pc-bin \
		grub-efi-amd64-bin \
		mbr \
		binutils \
		qemu-system-x86 \
		virt-manager
	@echo -e "$(GREEN)Dependencies installed$(NC)"

# Create build directories
dirs:
	@echo -e "$(CYAN)Creating build directories...$(NC)"
	@mkdir -p $(BUILD_DIR) $(OUTPUT_DIR)
	@echo -e "$(GREEN)Directories created$(NC)"

# Check system requirements
check:
	@echo -e "$(CYAN)Checking system requirements...$(NC)"
	@echo -e "$(GREEN)RAM:$(NC) $$(free -h | awk '/^Mem:/{print $$2}')"
	@echo -e "$(GREEN)Disk:$(NC) $$(df -h . | awk 'NR==2{print $$4}')"
	@echo -e "$(GREEN)CPU:$(NC) $$(nproc) cores"
	@echo ""

# Show disk usage
disk:
	@echo -e "$(CYAN)Disk usage:$(NC)"
	@du -sh $(BUILD_DIR) $(OUTPUT_DIR) 2>/dev/null || true
	@echo ""

# Show log
log:
	@echo -e "$(CYAN)Build log:$(NC)"
	@tail -f $(OUTPUT_DIR)/build.log 2>/dev/null || echo "No log file found"

# Test all targets
test-all: test test-uefi test-bios

# Full build and test
full: clean build test

# Quick build (without cleaning)
quick: build

# Development build (with verbose output)
dev:
	@echo -e "$(CYAN)Development build...$(NC)"
	@sudo $(SCRIPTS_DIR)/build.sh -v

# Package list
packages:
	@echo -e "$(CYAN)Package lists:$(NC)"
	@ls -la config/package-lists/

# Show hooks
hooks:
	@echo -e "$(CYAN)Build hooks:$(NC)"
	@find config/hooks -type f -name "*.chroot" | sort

# Validate configuration
validate:
	@echo -e "$(CYAN)Validating configuration...$(NC)"
	@for list in config/package-lists/*.list.chroot; do \
		echo "Checking $$list..."; \
		grep -v '^#' $$list | grep -v '^$$' > /dev/null || true; \
	done
	@echo -e "$(GREEN)Configuration valid$(NC)"
