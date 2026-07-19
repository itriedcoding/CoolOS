<div align="center">

# CoolOS

### A Lightweight Linux Distribution

[![GitHub stars](https://img.shields.io/github/stars/itriedcoding/CoolOS?style=social)](https://github.com/itriedcoding/CoolOS/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/itriedcoding/CoolOS?style=social)](https://github.com/itriedcoding/CoolOS/network/members)
[![GitHub issues](https://img.shields.io/github/issues/itriedcoding/CoolOS)](https://github.com/itriedcoding/CoolOS/issues)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Build ISO](https://github.com/itriedcoding/CoolOS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/itriedcoding/CoolOS/actions/workflows/build-iso.yml)

</div>

---

CoolOS is a lightweight Linux distribution designed for speed, simplicity, and modern computing needs. Built on Debian, it provides a complete desktop experience with pre-installed applications, development tools, and multimedia software.

## Download

**Latest Release:** [CoolOS v1.1.0](https://github.com/itriedcoding/CoolOS/releases/tag/v1.1.0)

- **ISO:** `CoolOS-1.1.0-amd64.iso` (~1.4GB)
- **Boot:** UEFI + BIOS (works with Hyper-V, VMware, VirtualBox, QEMU)
- **Installer:** Calamares graphical installer included

## Quick Start

1. Download the ISO from [Releases](https://github.com/itriedcoding/CoolOS/releases)
2. Create a new VM or boot from USB
3. Login: `coolos` / `coolors`
4. Run the installer from the desktop

## Default Credentials

| Username | Password |
|----------|----------|
| coolos   | coolors  |

## Virtual Machine Setup

### Hyper-V
1. Create a new Generation 2 VM
2. Set RAM to 2048MB+
3. Attach the ISO to the DVD drive
4. Disable Secure Boot (in Settings > Security)
5. Boot from DVD

### VMware
1. Create a new VM > Linux > Debian 12.x 64-bit
2. Set RAM to 2048MB+
3. Attach the ISO
4. Power on

### VirtualBox
1. Create a new VM > Linux > Debian (64-bit)
2. Set RAM to 2048MB+
3. Attach the ISO to the optical drive
4. Start the VM

### QEMU/KVM
```bash
qemu-system-x86_64 -m 2048 -enable-kvm -cdrom CoolOS-1.1.0-amd64.iso -boot d
```

## Features

### Desktop
- **Window Manager:** Openbox (lightweight, fast)
- **Panel:** Tint2
- **File Manager:** PCManFM, Thunar
- **Terminal:** LXTerminal
- **Theme:** Arc-Dark + Papirus icons

### Pre-installed Applications
- **Web:** Firefox ESR
- **Office:** LibreOffice (Writer, Calc, Impress)
- **Media:** VLC, MPV
- **Graphics:** GIMP, Inkscape
- **Code:** Geany text editor
- **System:** GNOME System Monitor, Baobab, NCdu

### System
- **Base:** Debian Bookworm
- **Kernel:** Linux 6.1
- **Network:** NetworkManager
- **Audio:** PulseAudio
- **Firewall:** UFW (enabled)

### Installer
- **Calamares** graphical installer for easy installation to disk
- Partition editor
- User setup
- Bootloader configuration

## Included Software

| Category | Applications |
|----------|-------------|
| Browser | Firefox ESR |
| Office | LibreOffice Writer, Calc, Impress |
| Media | VLC, MPV |
| Graphics | GIMP, Inkscape |
| Editor | Geany |
| System | GNOME System Monitor, Baobab, NCdu |
| Network | NetworkManager, Bluetooth (Blueman) |
| Dev | Git, Python3, Build tools |

## Build from Source

```bash
git clone https://github.com/itriedcoding/CoolOS.git
cd CoolOS
sudo ./scripts/build.sh
```

## Project Structure

```
CoolOS/
├── .github/workflows/    # GitHub Actions CI/CD
├── config/               # Build configuration
│   ├── package-lists/   # Package lists
│   ├── hooks/           # Build hooks
│   └── includes.chroot/ # System files
├── scripts/              # Build scripts
│   └── build.sh         # Main build script
└── docs/                 # Documentation
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues:** [GitHub Issues](https://github.com/itriedcoding/CoolOS/issues)

---

**Made with ❤️ by [itriedcoding](https://github.com/itriedcoding)**
