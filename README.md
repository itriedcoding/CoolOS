<div align="center">

# CoolOS

### A Lightweight Linux Distribution

[![GitHub stars](https://img.shields.io/github/stars/itriedcoding/CoolOS?style=social)](https://github.com/itriedcoding/CoolOS/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/itriedcoding/CoolOS?style=social)](https://github.com/itriedcoding/CoolOS/network/members)
[![GitHub issues](https://img.shields.io/github/issues/itriedcoding/CoolOS)](https://github.com/itriedcoding/CoolOS/issues)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

</div>

---

CoolOS is a lightweight Linux distribution designed for speed, simplicity, and modern computing needs. Built on Debian, it provides a complete desktop experience with pre-installed applications, development tools, and multimedia software.

## Features

### Lightweight & Fast
- Optimized for speed and low resource usage
- Fast boot times
- Minimal memory footprint
- Efficient window management with Openbox

### Complete Desktop Experience
- Modern desktop environment
- Pre-installed web browsers (Firefox ESR, Chromium)
- Office suite (LibreOffice)
- Media players (VLC, MPV)
- Image editing (GIMP, Inkscape)

### Development Ready
- Full development tools (GCC, Git, VS Code)
- Docker support
- Python and Node.js environments
- Version control integration

### Multimedia Capable
- Audio production (Audacity, Ardour)
- Video editing (Kdenlive, Shotcut)
- Screen recording (OBS Studio)
- Codecs for all media formats

### Virtualization Support
- QEMU/KVM integration
- VirtualBox compatibility
- VMware support
- Proxmox templates

## Quick Start

### Prerequisites

- Debian/Ubuntu-based host system
- 8GB RAM minimum
- 20GB free disk space
- Root access

### Installation

```bash
# Clone the repository
git clone https://github.com/itriedcoding/CoolOS.git
cd CoolOS

# Make scripts executable
chmod +x scripts/*.sh

# Build the ISO
sudo ./scripts/build.sh
```

### Testing

```bash
# Test with QEMU
sudo ./scripts/test-qemu.sh

# Test in UEFI mode
sudo ./scripts/test-qemu.sh -m uefi
```

### Creating Virtual Machines

```bash
# Create QEMU/KVM VM
sudo ./scripts/create-vm.sh -k myvm

# Create all VM formats
sudo ./scripts/create-vm.sh -a
```

## Default Credentials

| Username | Password |
|----------|----------|
| coolos   | coolors  |

## Included Software

### Desktop Environment
- **Window Manager:** Openbox
- **Panel:** Tint2
- **File Manager:** PCManFM, Thunar
- **Terminal:** LXTerminal, Terminator
- **Text Editor:** Geany, Mousepad

### Applications
- **Web Browser:** Firefox ESR, Chromium
- **Office:** LibreOffice (Writer, Calc, Impress)
- **Media:** VLC, MPV, Rhythmbox
- **Graphics:** GIMP, Inkscape
- **Development:** Git, VS Code, Docker

### System Tools
- **Network:** NetworkManager, Bluetooth
- **Security:** UFW Firewall
- **Printing:** CUPS
- **System Monitor:** GNOME System Monitor

## Project Structure

```
CoolOS/
├── config/                     # Build configuration
│   ├── package-lists/         # Package lists
│   ├── hooks/                 # Build hooks
│   ├── includes.chroot/       # System files
│   └── bootloaders/          # Boot loader configs
├── scripts/                   # Build scripts
│   ├── build.sh              # Main build script
│   ├── create-iso.sh         # ISO creation
│   ├── create-vm.sh          # VM creation
│   └── test-qemu.sh          # Testing script
├── docs/                      # Documentation
├── iso/                       # ISO build directory
└── output/                    # Built ISOs
```

## Documentation

- [Configuration Guide](docs/CONFIGURATION.md)
- [Build Instructions](docs/CONFIGURATION.md#build-instructions)
- [Troubleshooting](docs/CONFIGURATION.md#troubleshooting)

## Customization

### Adding Packages

Edit package lists in `config/package-lists/`:

```bash
# Add package to desktop list
echo "package-name" >> config/package-lists/desktop.list.chroot
```

### Adding Custom Files

Place files in `config/includes.chroot/` with the desired path:

```bash
# Add custom wallpaper
cp wallpaper.png config/includes.chroot/usr/share/backgrounds/
```

### Adding Build Hooks

Create scripts in `config/hooks/apt/` or `config/hooks/live/`:

```bash
#!/bin/sh
set -e
# Your customization
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Debian](https://www.debian.org/) - The base distribution
- [Openbox](http://openbox.org/) - Window manager
- All open-source contributors

## Support

- **Issues:** [GitHub Issues](https://github.com/itriedcoding/CoolOS/issues)
- **Discussions:** [GitHub Discussions](https://github.com/itriedcoding/CoolOS/discussions)

---

<div align="center">

**Made with ❤️ by itriedcoding**

</div>
