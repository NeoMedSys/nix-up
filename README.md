![CI/CD](https://github.com/NeoMedSys/perseus/actions/workflows/perseus.yaml/badge.svg)
![Version](https://img.shields.io/github/v/tag/NeoMedSys/perseus)
[![FlakeHub](https://img.shields.io/badge/flakehub-NeoMedSys/perseus-blue)](https://flakehub.com/flake/NeoMedSys/perseus)
# Perseus 🛡️

> A privacy-first, developer-optimized NixOS configuration that protects you from the tech overlords while maximizing productivity.

## TL;DR

Perseus is a fully declarative NixOS setup that combines **uncompromising privacy**, **developer ergonomics**, and **gaming readiness** into one reproducible system. Deploy anywhere with a single command and get the exact same environment every time.

**Designed for open collaboration** - your personal data stays local, GitHub gets sanitized configs for easy teamwork.

What you get:

1. **Desktop**: Sway compositor + Waybar + Alacritty terminal + Rofi launcher (Wayland-native) 
3. **Privacy**: OpenSnitch firewall + encrypted DNS + Mullvad VPN + tracking protection
4. **Development**: Neovim + Python/Go/Rust environments + Docker + Git integration
5. **Daily Apps**: Brave browser + Slack/Teams (sandboxed) + Spotify + Signal
6. **Gaming**: Steam + NVIDIA drivers (if GPU) + GameMode + controller support

###### i3/X11 included but being phased out


<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/8ec48a37-a0c3-4c76-8d18-b9ead35a5087" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ba326466-74ce-45eb-a042-8f52fd5f1d5e" />


## 🚀 Quick Start


### Prerequisites

1. NixOS 25.05 or later
2. Git installed
3. 20GB+ free disk space

### Perseus Setup Script

**⚠️ CRITICAL: You MUST run `./perseus.sh` before installation!**

The Perseus setup script is not optional - it configures your personal settings and sets up collaboration-safe git filtering.

#### What the Script Does

```bash
./perseus.sh
```

1. **Personal Configuration**: Collects your username, hostname, git details, location, and preferences
2. **Hardware Detection**: Auto-detects NVIDIA GPU, laptop status, and PCI bus IDs  
3. **Git Filtering Setup**: Protects your privacy while enabling collaboration
4. **File Protection**: Prevents `git pull` from overwriting your personal configs

#### Why This Matters

Perseus uses a **privacy-first collaboration model**:

- **Your Local Machine**: Contains real usernames, SSH keys, hardware configs, VPN settings
- **GitHub Repository**: Contains only sanitized placeholder configs for CI/collaboration
- **Git Filtering**: Automatically strips personal data when you push commits

#### The Magic Behind the Scenes

When you `git push`, the script's filters automatically transform:

```diff
# Your local user-config.nix
- username = "alice";
- gitEmail = "alice@company.com";
- latitude = 40.7128;

# What gets pushed to GitHub  
+ username = "user";
+ gitEmail = "user@user.com";
+ latitude = 52.4;
```

#### Collaboration Benefits

✅ **Privacy**: No personal data ever reaches GitHub  
✅ **Security**: SSH keys and hardware details stay local  
✅ **Teamwork**: Others can contribute without seeing your setup  
✅ **CI/CD**: Automated testing works with placeholder configs  
✅ **Pull Safety**: `git pull` won't overwrite your personal settings

#### Script Output Example

```
Welcome to Perseus NixOS Configuration Setup
===========================================
Username [alice]: alice
Hostname [perseus]: alice-laptop
Full name for git: Alice Developer
Email for git: alice@company.com
Has NVIDIA GPU? [false]: true
Detecting GPU bus IDs...
Intel bus ID: PCI:0:2:0
NVIDIA bus ID: PCI:1:0:0
```

**After running the script once, your configs are protected forever.**

### Installation

First step is to run the bare metal installation from ISO and then run the Perseus installation.

#### 1 Bare Metal Installation

```bash
# 1.1 Partition your disk (replace /dev/sda with your disk)
sudo fdisk /dev/sda
# Create: 512MB EFI partition (type EF00), rest for root (type 8300)

# 1.2 Format partitions
sudo mkfs.fat -F 32 /dev/sda1  # EFI
sudo mkfs.ext4 /dev/sda2       # Root

# 1.3 Mount the file systems
sudo mount /dev/sda2 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/sda1 /mnt/boot

# 1.4 Generate hardware configuration
sudo nixos-generate-config --root /mnt
```

#### 2. Perseus Installation
```bash
# 2.1 Clone the repository and setup the args for your system
git clone https://github.com/yourusername/perseus
cd perseus

# 2.2
# NB! this step is mandatory for reasons explained in the previous section
sh perseus.sh

# 2.3 Copy the generated hardware config
sudo cp /mnt/etc/nixos/hardware-configuration.nix system/

# 2.4 For system with VPN (Only Mullvad support for now)
cp your-mullvad-config.conf configs/mullvad-config/

# 2.5 Install your personalized system
sudo nixos-install --flake .#<your-hostname>

# 2.6 Reboot and enjoy your freedom
sudo reboot
```

### First Boot

1. Security daemon starts automatically
2. Blue light filter activates at 10 PM
3. All privacy protections enabled by default

##### NOTE: Add mullvad config to the setup before running install if you want the VPN




## 🎯 Philosophy

**"Your machine, your rules"** - Perseus embodies the principle that you should have complete control over your computing environment:

- **Privacy by Default**: Every connection monitored, every tracker blocked, every telemetry disabled
- **Reproducible Everywhere**: One config file → identical system on any machine
- **Zero Manual Configuration**: Everything from keybindings to themes defined in code
- **Modular Architecture**: Enable only what you need, when you need it
- **Community First**: Built on open standards, contributing back to the ecosystem

## 🛡️ Privacy & Security Arsenal

### The Tech Overlord Defense System

Perseus includes **NastyTechLords** - an automated security daemon that runs comprehensive audits every 6 hours:

```bash
ntl status          # Check daemon status
ntl run             # Manual security audit
ntl report          # View latest findings
ntl run --full-check # Deep system verification
```

### Multi-Layer Protection

1. **DNS Level** (First Line of Defense)
   - `dnscrypt-proxy2` with encrypted DNS
   - Automatic ad/tracker/malware blocking
   - Anonymous DNS routing

2. **Network Level**
   - OpenSnitch application firewall (per-app rules)
   - MAC address randomization
   - Custom firewall rules blocking known trackers
   - Fail2ban intrusion prevention

3. **System Level**
   - AppArmor mandatory access control
   - Kernel hardening (sysctl tweaks)
   - No swap (prevents memory dumps)
   - Disabled telemetry for all development tools

4. **Application Level**
   - Sandboxed Teams (via bubblewrap)
   - Brave browser with fingerprint protection
   - Signal & Element for encrypted communication

5. **VPN Level**
   - Mullvad WireGuard integration (auto-configured)
   - On-demand activation via status bar
   - Local network access preserved
   - Kill switch protection when active

## 💻 Developer Paradise

### Language Support

Perseus uses a modular approach - enable only the languages you need:

```nix
# In flake.nix
perseus = mkSystem {
  hasGPU = false;
  devTools = [ "python" "go" "rust" "nextjs" ];
};
```

### Python Development

Integrated `pyenv` command for isolated Python environments:

```bash
pyenv               # Enter Python dev shell
poetry new myapp    # Create new project
poetry add pandas   # Manage dependencies
```

### Editor Features

Neovim (via nixvim) comes preconfigured with:
- **LSP Support**: Auto-completion, go-to-definition, inline diagnostics
- **Telescope**: Fuzzy file/content search (`<leader>t`)
- **Treesitter**: Advanced syntax highlighting
- **Markdown Preview**: Live preview in Brave (`<leader>mp`)
- **Git Integration**: Fugitive and Gitsigns
- **File Explorer**: NvimTree (`<leader>e`)

### Container Development

- Docker with NVIDIA GPU support (when enabled)
- Rootless Podman option
- Pre-configured for development containers

## 🎮 Gaming Ready

### Steam Integration

```nix
# Enable with GPU support
perseus-gpu = mkSystem {
  hasGPU = true;
  devTools = [ "python" ];
};
```

Features:
- Native Steam with Proton
- GameMode for performance optimization
- MangoHud for FPS/performance overlay
- 32-bit libraries for compatibility
- Controller support out of the box

### Performance Tweaks

- NVIDIA drivers with optimal settings
- TLP for power management
- Custom kernel parameters
- Gamemode integration

## 🖥️ Desktop Environment

### Sway Compositor Window Manager

Clean, keyboard-driven workflow with sensible defaults:

| Keybinding | Action | 
|------------|--------|
| `Mod+Enter` | Terminal |
| `Mod+b` | Brave browser |
| `Mod+c` | Slack |
| `Mod+d` | Application launcher |
| `Mod+h/j/k/l` | Navigate windows |
| `Mod+1-9` | Switch workspace |

### Status Bar

Interactive i3status-rust modules:
- **Music Player**: ahows music that is playing
- **Blue Light Filter**: Click to adjust screen temperature
- **VPN**: click to toggle on or off
- **Network**: Shows SSID, click for network manager
- **Bluetooth**: Connected device, click for manager
- **System Stats**: CPU, RAM, disk usage
- **Battery**: Smart icon based on charge level

### Daily Use Applications via Waybar

- **Brave**: Privacy-focused browsing
- **Alacritty**: GPU-accelerated terminal
- **Slack**: Sandboxed team communication
- **Spotify**: Music streaming
- **Stremio**: Media streaming


## 📊 System Architecture

Perseus uses a **modular architecture** for flexibility and maintainability:

```
modules/          # Individual system components
configs/          # Application configuration files  
pkgs/             # Custom package definitions
system/           # Core NixOS configuration
```

### Why Modular?

- **Selective Features**: Enable only Python, skip Rust, add gaming - your choice
- **Easy Maintenance**: Update i3 config without touching VPN settings
- **Better Collaboration**: Contributors can focus on specific components
- **Privacy Separation**: Personal configs isolated from system modules

### Key Components

- **`user-config.nix`**: Your personal settings (username, preferences, hardware)
- **`system/hardware-configuration.nix`**: Your personal machine settings
- **`modules/`**: System features (privacy, gaming, development languages)
- **`configs/`**: Application dotfiles (i3, terminal, status bar)
- **`perseus.sh`**: Setup script with git filtering magic

**Privacy Model**: Personal files stay local, GitHub gets sanitized placeholders.

## 🔧 Maintenance

### System Updates

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#perseus

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

### Security Monitoring

```bash
# Check security status
ntl report

# View audit history
ntl history

# Watch live logs
ntl logs
```

## 🤝 Contributing

Perseus is open source and welcomes contributions:

1. Fork the repository
2. Create a feature branch
3. Follow the existing code style (tabs, not spaces)
4. Test on a VM first
5. Submit a pull request

## 📜 License

MIT - Use Perseus to build your own privacy fortress!

---

*"In a world of tech overlords, be the rebel with root access"* - Perseus Project
