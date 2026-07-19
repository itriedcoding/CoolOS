# CoolOS Changelog

All notable changes to CoolOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-19

### Added

#### Core System
- Debian Bookworm base system
- Linux kernel with hardware support
- systemd init system
- UFW firewall (enabled by default)
- NetworkManager for network management

#### Desktop Environment
- Openbox window manager
- Tint2 panel
- Plank dock
- Rofi application launcher
- Picom compositor
- Dunst notification daemon

#### File Managers
- PCManFM
- Thunar

#### Terminals
- LXTerminal
- Terminator
- Alacritty

#### Applications
- Firefox ESR web browser
- Chromium web browser
- LibreOffice suite (Writer, Calc, Impress)
- VLC media player
- MPV media player
- GIMP image editor
- Inkscape vector graphics
- Geany code editor
- VS Code IDE
- Audacity audio editor
- Kdenlive video editor
- OBS Studio screen recording
- Blender 3D modeling

#### Development Tools
- Build essentials (GCC, Make)
- Git version control
- Python 3 with pip
- Node.js with npm
- Docker and Docker Compose
- VS Code IDE

#### System Tools
- GNOME System Monitor
- BaTop system monitor
- NCdu disk usage analyzer
- GNOME Disk Utility
- GParted partition manager

#### Theming
- Arc-Dark GTK theme
- Papirus Dark icon theme
- Noto Sans font family
- Fira Code monospace font
- Custom Openbox themes

#### Boot Support
- UEFI boot
- BIOS/Legacy boot
- GRUB bootloader
- Isolinux bootloader
- Live session support

#### Virtual Machine Support
- QEMU/KVM integration
- VirtualBox compatibility
- VMware support
- Proxmox templates

### Build System
- Automated build scripts
- Package list configuration
- Build hooks system
- ISO creation tool
- VM creation tool
- QEMU testing script

### Documentation
- Complete README
- Configuration guide
- Build instructions
- Troubleshooting guide
- Contributing guidelines
- License (GPLv3)

---

## [0.9.0] - 2026-07-18 (Beta)

### Added
- Initial project structure
- Basic build system
- Package lists
- Boot configuration

### Changed
- Optimized package selection
- Improved build scripts

### Fixed
- Boot loader configuration
- Package dependencies

---

## [0.8.0] - 2026-07-17 (Alpha)

### Added
- Project initialization
- Basic directory structure
- Initial documentation

### Changed
- Refined project goals
- Updated requirements

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2026-07-19 | First stable release |
| 0.9.0 | 2026-07-18 | Beta release |
| 0.8.0 | 2026-07-17 | Alpha release |

---

## Upcoming Features

### Version 1.1.0
- [ ] Installer (Calamares)
- [ ] Encryption support
- [ ] Btrfs snapshots
- [ ] More desktop themes
- [ ] Accessibility features

### Version 1.2.0
- [ ] ARM support
- [ ] Raspberry Pi images
- [ ] Container optimization
- [ ] Cloud images

### Version 2.0.0
- [ ] Custom package manager
- [ ] Atomic updates
- [ ] Flatpak integration
- [ ] Snap support

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to CoolOS.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
