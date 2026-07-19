# CoolOS Configuration

## Project Structure

```
CoolOS/
├── config/                     # Build configuration
│   ├── package-lists/          # Package lists for different components
│   │   ├── base.list.chroot   # Base system packages
│   │   ├── desktop.list.chroot # Desktop environment packages
│   │   ├── apps.list.chroot   # Pre-installed applications
│   │   ├── dev.list.chroot    # Development tools
│   │   └── multimedia.list.chroot # Multimedia packages
│   ├── hooks/                  # Build hooks
│   │   ├── apt/               # APT configuration hooks
│   │   └── live/              # Live system hooks
│   ├── includes.chroot/       # Files to include in chroot
│   └── bootloaders/          # Boot loader configurations
├── scripts/                    # Build and utility scripts
│   ├── build.sh               # Main build script
│   ├── create-iso.sh          # ISO creation script
│   ├── create-vm.sh           # VM creation script
│   └── test-qemu.sh           # QEMU testing script
├── docs/                       # Documentation
├── iso/                        # ISO build directory
└── output/                     # Built ISOs and VMs
```

## Default Credentials

- **Username:** coolos
- **Password:** coolors

## Build Requirements

### System Requirements

- Debian/Ubuntu-based host system
- At least 8GB RAM
- At least 20GB free disk space
- Root access

### Required Packages

```bash
sudo apt install \
    debootstrap \
    squashfs-tools \
    xorriso \
    mtools \
    dosfstools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mbr \
    binutils \
    qemu-system-x86
```

## Build Instructions

### Quick Build

```bash
# Clone the repository
git clone https://github.com/itriedcoding/CoolOS.git
cd CoolOS

# Make scripts executable
chmod +x scripts/*.sh

# Build the ISO
sudo ./scripts/build.sh
```

### Manual Build

```bash
# 1. Create build directories
sudo mkdir -p build cache iso output

# 2. Bootstrap base system
sudo debootstrap --arch=amd64 --variant=minbase bookworm build http://deb.debian.org/debian/

# 3. Install packages
sudo chroot build apt-get update
sudo chroot build apt-get install -y $(cat config/package-lists/*.list.chroot | grep -v '^#' | tr '\n' ' ')

# 4. Apply configurations
sudo chroot build bash config/hooks/apt/7000-coolos-settings.chroot
sudo chroot build bash config/hooks/live/5000-coolos-desktop.chroot

# 5. Create SquashFS
sudo mksquashfs build iso/live/filesystem.squashfs -comp xz

# 6. Create ISO
sudo xorriso -as mkisofs -o output/CoolOS.iso iso/
```

## Testing the ISO

### Test with QEMU

```bash
# Test in BIOS mode
sudo ./scripts/test-qemu.sh -m bios

# Test in UEFI mode
sudo ./scripts/test-qemu.sh -m uefi

# Clean up test files
sudo ./scripts/test-qemu.sh -c
```

### Test with VirtualBox

1. Create a new VM
2. Set type to Linux, version to Debian (64-bit)
3. Allocate at least 2GB RAM
4. Create a 20GB virtual hard disk
5. Attach the ISO to the optical drive
6. Start the VM

### Test with VMware

1. Create a new VM
2. Select "Installer disc image file (iso)"
3. Browse to the ISO file
4. Follow the wizard
5. Start the VM

## Creating Virtual Machine Images

### QEMU/KVM

```bash
sudo ./scripts/create-vm.sh -k myvm
```

### VirtualBox

```bash
sudo ./scripts/create-vm.sh -v myvm
```

### VMware

```bash
sudo ./scripts/create-vm.sh -w myvm
```

### Proxmox

```bash
sudo ./scripts/create-vm.sh -p myvm
```

### All Formats

```bash
sudo ./scripts/create-vm.sh -a
```

## Customization

### Adding Packages

Edit the package lists in `config/package-lists/`:

- `base.list.chroot` - Core system packages
- `desktop.list.chroot` - Desktop environment packages
- `apps.list.chroot` - Pre-installed applications
- `dev.list.chroot` - Development tools
- `multimedia.list.chroot` - Multimedia packages

### Adding Custom Files

Place files in `config/includes.chroot/` with the desired directory structure. For example:

```
config/includes.chroot/etc/skel/.bashrc
```

will be installed as:

```
/root/.bashrc
/home/coolos/.bashrc
```

### Adding Build Hooks

Create executable scripts in `config/hooks/apt/` or `config/hooks/live/`:

```bash
#!/bin/sh
set -e
# Your customization script
```

## Features

### Included Software

- **Desktop Environment:** Openbox with Tint2 panel
- **File Manager:** PCManFM and Thunar
- **Web Browser:** Firefox ESR and Chromium
- **Terminal:** LXTerminal and Terminator
- **Text Editor:** Geany and Mousepad
- **Office Suite:** LibreOffice
- **Media Players:** VLC and MPV
- **Image Editor:** GIMP and Inkscape
- **Development Tools:** Git, VS Code, Docker

### System Features

- Lightweight and fast boot
- UEFI and BIOS support
- Auto-login for live session
- Network Manager for easy networking
- Bluetooth support
- Print support
- Firewall enabled by default

## Troubleshooting

### Build Fails

1. Ensure you have enough disk space (at least 20GB)
2. Check that all dependencies are installed
3. Run with `sudo` privileges
4. Check network connectivity

### ISO Won't Boot

1. Verify the ISO is not corrupted (check SHA256 hash)
2. Ensure virtualization is enabled in BIOS
3. Try booting in BIOS mode first
4. Check VM settings (memory, CPU, disk)

### Network Not Working

1. Check NetworkManager status: `systemctl status NetworkManager`
2. Restart NetworkManager: `sudo systemctl restart NetworkManager`
3. Check network interfaces: `ip a`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the GPL License - see the LICENSE file for details.

## Support

- **GitHub Issues:** https://github.com/itriedcoding/CoolOS/issues
- **Documentation:** See the docs/ directory

## Credits

- Debian Linux
- Openbox Window Manager
- All open-source contributors
