# Perseus 🛡️

> A privacy-first, developer-optimized NixOS configuration that protects you from the tech overlords while maximizing productivity.

## TL;DR

Perseus is a fully declarative NixOS setup that combines **uncompromising privacy**, **developer ergonomics**, and **gaming readiness** into one reproducible system. Deploy anywhere with a single command and get the exact same environment every time.

```bash
sudo nixos-rebuild switch --flake .#perseus
```

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

### i3 Window Manager

Clean, keyboard-driven workflow with sensible defaults:

| Keybinding | Action | 
|------------|--------|
| `Mod+Enter` | Terminal |
| `Mod+b` | Brave browser |
| `Mod+Shift+r` | Toggle blue light filter |
| `Mod+d` | Application launcher |
| `Mod+h/j/k/l` | Navigate windows |
| `Mod+1-9` | Switch workspace |

### Status Bar

Interactive i3status-rust modules:
- **Blue Light Filter**: Click to adjust screen temperature
- **Network**: Shows SSID, click for network manager
- **Bluetooth**: Connected device, click for manager
- **System Stats**: CPU, RAM, disk usage
- **Battery**: Smart icon based on charge level

### Daily Use Applications

- **Brave**: Privacy-focused browsing
- **Alacritty**: GPU-accelerated terminal
- **Slack**: Sandboxed team communication
- **Spotify**: Music streaming
- **Stremio**: Media streaming

## 🚀 Quick Start

### Prerequisites

1. NixOS 25.05 or later
2. Git installed
3. 20GB+ free disk space

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/perseus
cd perseus

# For laptop without GPU
sudo nixos-rebuild switch --flake .#perseus

# For system with NVIDIA GPU
sudo nixos-rebuild switch --flake .#perseus-gpu
```

### First Boot

1. Security daemon starts automatically
2. Blue light filter activates at 10 PM
3. All privacy protections enabled by default

### Customization

Edit `flake.nix` to:
- Change username (default: "jon")
- Select browsers
- Enable/disable GPU support
- Add development tools

## 📊 System Architecture

```
modules/
├── environment.nix      # System-wide settings
├── privacy.nix          # Security & privacy configs
├── techoverlord_protection.nix  # NastyTechLords daemon
├── nixvim.nix          # Neovim configuration
├── steam.nix           # Gaming setup
├── gpl.nix             # Programming languages
└── redshift.nix        # Blue light filter

configs/
├── i3-config/          # Window manager
├── i3status-rust/      # Status bar
└── alacritty/          # Terminal emulator
```

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
