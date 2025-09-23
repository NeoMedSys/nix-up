![CI/CD](https://github.com/NeoMedSys/perseus/actions/workflows/perseus.yaml/badge.svg)
![Version](https://img.shields.io/github/v/tag/NeoMedSys/perseus)
[![FlakeHub](https://img.shields.io/badge/flakehub-NeoMedSys/perseus-blue)](https://flakehub.com/flake/NeoMedSys/perseus)

# Perseus 🛡️

> A privacy-first, developer-optimized NixOS configuration that protects you from the tech overlords while maximizing productivity.

## TL;DR

Perseus is a fully declarative NixOS setup that combines **uncompromising privacy**, **developer ergonomics**, and **gaming readiness** into one reproducible system. Deploy anywhere with a single command and get the exact same environment every time.

**Designed for open collaboration** - your personal data stays local, GitHub gets sanitized configs for easy teamwork.

### What you get:

1.  **Desktop**: **Sway** compositor + **Waybar** + **Alacritty** terminal + **Rofi** launcher (fully Wayland-native)
2.  **Login**: **Tuigreet** (minimalist text-based greeter) with **Fingerprint** (`fprintd`) support
3.  **Privacy**: **OpenSnitch** firewall + encrypted DNS with **dnscrypt-proxy2** + **Mullvad VPN** integration
4.  **Development**: **Neovim** (via nixvim) + Python/Go/Rust environments + Docker + Git integration
5.  **Daily Apps**: LibreWolf browser + Sandboxed Slack/Spotify/Steam
6.  **Gaming**: Steam + NVIDIA drivers (if enabled) + GameMode + controller support

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/8ec48a37-a0c3-4c76-8d18-b9ead35a5087" />

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ba326466-74ce-45eb-a042-8f52fd5f1d5e" />

## 🚀 Quick Start

### Prerequisites

1.  NixOS 25.05 or later installed on bare metal
2.  Git installed
3.  20GB+ free disk space

### 1. Perseus Setup Script

**⚠️ CRITICAL: You MUST run `./perseus.sh` before installation!**

This script is not optional. It generates your private `user-config.nix` file and sets up Git filters to protect your personal data from being committed.

```bash
# From the root of the cloned repository
./perseus.sh
```

1.  **Personal Configuration**: Collects your username, hostname, git details, location, and preferences.
2.  **Hardware Detection**: Auto-detects NVIDIA GPU, laptop status, and PCI bus IDs.
3.  **Git Filtering Setup**: Protects your privacy while enabling collaboration.

This generated file is **private**, listed in `.gitignore`, and ensures your personal data is **never committed to the repository**.

### 2. Installation

With your base NixOS system running, follow these steps to deploy Perseus.

```bash
# 2.1 Clone the repository
git clone [https://github.com/yourusername/perseus](https://github.com/yourusername/perseus)
cd perseus

# 2.2 Run the mandatory setup script
# This creates your personalized user-config.nix
./perseus.sh

# 2.3 Copy your machine's hardware configuration
# This file was generated during the bare metal NixOS install
sudo cp /etc/nixos/hardware-configuration.nix system/

# 2.4 (OPTIONAL) Set up VPN secrets if you plan to use the VPN
# See the detailed "VPN Setup with Sops" section below before proceeding.

# 2.5 Install your personalized Perseus system
sudo nixos-install --flake .#<your-hostname>
# Replace <your-hostname> with the hostname you set in ./perseus.sh

# 2.6 Reboot and enjoy your freedom
sudo reboot
```

> **⚠️ IMPORTANT FIRST-TIME INSTALL ADVICE**
> For the initial installation, it is strongly recommended to set `hasGPU` and `vpn` to `false` in your `user-config.nix`. You can easily enable them later by changing the flags and running `sudo nixos-rebuild switch --flake .#<hostname>`. This ensures a smoother first boot.

### 3. VPN Setup with Sops (Optional)

Perseus uses **sops-nix** to manage the Mullvad WireGuard configuration securely. If you set `vpn = true;` in your `user-config.nix`, you must complete these steps.

#### Step 1: Generate an `age` key

`age` is a simple and secure encryption tool. We'll use it to encrypt your VPN configuration.

```bash
# Install age if you don't have it
nix-shell -p age

# Create the sops directory and generate your key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# The file keys.txt now contains your private and public keys.
# The public key starts with "age1...".
```

#### Step 2: Create a `.sops.yaml` configuration file

This file tells `sops` how to encrypt your secrets. Create a file named `.sops.yaml` in the root of the Perseus repository.

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    encrypted_regex: '^(data|stringData|mullvad_conf)$'
    age: >-
      # PASTE YOUR PUBLIC KEY FROM keys.txt HERE
      age1...
```

#### Step 3: Create the secret file

Create a new file at `secrets/wireguard.yaml` and paste your Mullvad WireGuard configuration into it.

```yaml
# secrets/wireguard.yaml
mullvad_conf: |
  [Interface]
  PrivateKey = ...
  Address = ...
  DNS = ...
  [Peer]
  PublicKey = ...
  AllowedIPs = 0.0.0.0/0,::0/0
  Endpoint = ...
```
**Note:** The `|` is important for multi-line strings in YAML.

#### Step 4: Encrypt the file

Now, use `sops` to encrypt the file in-place.

```bash
# Install sops if you don't have it
nix-shell -p sops

# Encrypt the file
sops -e -i secrets/wireguard.yaml
```

Your secret is now securely encrypted! You can enable the VPN (`vpn = true;` in `user-config.nix`) and rebuild your system.

## 🎯 Philosophy

**"Your machine, your rules"** - Perseus embodies the principle that you should have complete control over your computing environment:

-   **Privacy by Default**: Every connection monitored, every tracker blocked, every telemetry disabled.
-   **Reproducible Everywhere**: One config file → identical system on any machine.
-   **Zero Manual Configuration**: Everything from keybindings to themes defined in code.
-   **Modular Architecture**: Enable only what you need, when you need it.
-   **Community First**: Built on open standards, contributing back to the ecosystem.

## 🛡️ Privacy & Security Arsenal

### The Tech Overlord Defense System

Perseus includes **NastyTechLords** - an automated security daemon that runs comprehensive audits every 6 hours using tools like `lynis` and `chkrootkit`.

```bash
ntl status         # Check daemon status
ntl run            # Manual security audit
ntl report         # View latest findings
ntl run --full-check # Deep system verification
```

### Multi-Layer Protection

1.  **DNS Level**: `dnscrypt-proxy2` for encrypted, anonymous DNS with ad/tracker/malware blocking.
2.  **Network Level**: **OpenSnitch** application firewall, MAC address randomization, and hardened `nftables` rules.
3.  **System Level**: **AppArmor** mandatory access control, kernel hardening, and disabled swap to prevent memory dumps.
4.  **Application Level**: **Sandboxed Slack, Spotify, and Steam** with restricted permissions, memory limits, and disabled telemetry.
5.  **VPN Level**: **Mullvad WireGuard** integration with a kill switch, managed securely via sops.

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

Perseus uses `direnv` to automatically manage isolated Python environments on a per-project basis. This is faster and more flexible than wrapper scripts.

To create an environment, simply add a `.envrc` file to your project directory:

```sh
# In your project's .envrc file
use nix -p python312 poetry
```

Run direnv allow once. Now, your shell is automatically configured with python and poetry every time you cd into that directory.

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

| Keybinding    | Action               |
| ------------- | -------------------- |
| `Mod+Enter`   | Terminal             |
| `Mod+b`       | Brave browser        |
| `Mod+c`       | Slack                |
| `Mod+d`       | Application launcher |
| `Mod+h/j/k/l` | Navigate windows     |
| `Mod+1-9`     | Switch workspace     |

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
modules/          # Individual system components
configs/          # Application configuration files
pkgs/             # Custom package definitions
system/           # Core NixOS configuration
```

### Why Modular?

- **Selective Features**: Enable only Python, skip Rust, add gaming - your choice
- **Easy Maintenance**: Update i3 config without touching VPN settings
- **Better Collaboration**: Contributors can focus on specific components
- **Privacy Separation**: Personal configs isolated from system modules

### Key Components

- **`user-config.nix`**: (Private) Generated by the setup script. Contains your username, preferences, and hardware flags. This file is in `.gitignore`.
- **`system/hardware-configuration.nix`**: (Private) Your personal machine settings This file is in `.gitignore`
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

_"In a world of tech overlords, be the rebel with root access"_ - Perseus Project
