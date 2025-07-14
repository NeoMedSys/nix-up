#### **🎯 Super Easy Deployment with Helper Script**

Use the included deployment script for the easiest experience:

```bash
# Download and run the deployment helper
curl -sSL https://raw.githubusercontent.com/yourusername/perseus/main/deploy-perseus.sh | bash -s -- yourusername/perseus root@target

# Or clone and use locally
git clone https://github.com/yourusername/perseus.git
cd perseus
chmod +x deploy-perseus.sh

# Examples:
./deploy-perseus.sh yourusername/perseus root@192.168.1.100  # Default settings
./deploy-perseus.sh -u alice -d python,rust,nextjs yourusername/perseus root@target  # Dev setup
./deploy-perseus.sh -d python,go,rust,nextjs -b firefox,brave yourusername/perseus root@workstation  # Full dev
./deploy-perseus.sh -c perseus-server -d python,go yourusername/perseus root@server  # Server deployment
./deploy-perseus.sh --help  # Show all options
```

### Example: Custom User Configuration

```nix
# Example customization in flake.nix for user "alice"
perseus-alice = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs;
    isLaptop = true;
    hasGPU = false;  # No NVIDIA GPU
    user = "alice";
    userSpecifiedBrowsers = [ "firefox" "chromium" ];
  };
  modules = [
    ./system/configuration.nix
    nixvim.nixosModules.nixvim
    disko.nixosModules.disko
  ];
};
```

Then deploy with: `sudo nixos-rebuild switch --flake .#perseus-alice`├── polybar-config/ # Polybar configuration
│ ├── config.ini # Polybar main configuration
│ └── launch.sh # Polybar launch script# Perseus v0.1.0 - NixOS Laptop Configuration

A complete NixOS configuration for development and gaming laptops with flakes, i3 window manager, and NVIDIA support.

## Structure

```
.
├── flake.nix                    # Main flake configuration
├── README.md                    # This file
├── initial-configuration.nix    # Bootstrap config for minimal ISO
├── test-setup.sh                # Testing script for configuration
├── deploy-perseus.sh            # Easy deployment helper script
├── modules/                     # Modular configurations
│   ├── environment.nix          # Base system settings & Brave browser
│   ├── dev-tools.nix            # Development tools (Python, Go, Rust, Next.js)
│   ├── i3.nix                   # i3 window manager configuration
│   ├── polybar.nix              # Status bar configuration
│   ├── zsh.nix                  # Zsh shell configuration
│   ├── nixvim.nix               # Neovim configuration
│   ├── system-packages.nix      # Core system packages
│   ├── ssh-config.nix           # SSH daemon configuration
│   ├── ssh-keys.nix             # SSH public keys
│   ├── steam.nix                # Gaming platform
│   ├── nvidia.nix               # NVIDIA drivers
│   └── expressvpn.nix           # VPN configuration
├── polybar-config/              # Polybar configuration
│   ├── config.ini               # Polybar main configuration
│   └── launch.sh                # Polybar launch script
└── system/                      # System-level configurations
    ├── disko-config.nix         # Disk partitioning
    ├── hardware-configuration.nix # Hardware-specific settings
    └── configuration.nix        # Main system configuration
```

## Installation

### 1. Boot from NixOS Minimal ISO

Download the latest NixOS minimal ISO (25.05) and boot from it.

### 2. Initial Setup with Minimal Configuration

```bash
# Enable flakes temporarily
export NIX_CONFIG="experimental-features = nix-command flakes"

# Setup networking if needed
sudo systemctl start wpa_supplicant # for WiFi

# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Clone this repository
git clone <your-repo-url> /tmp/nixos-config

# Copy initial configuration
sudo cp /tmp/nixos-config/initial-configuration.nix /mnt/etc/nixos/configuration.nix

# OPTIONAL: Edit the username in the copied file (default is "algol")
# sudo nano /mnt/etc/nixos/configuration.nix  # Change "algol" to your preferred username

# Install NixOS with basic setup
sudo nixos-install

# Set password for your user (default: "algol", or whatever you changed it to)
sudo nixos-enter --root /mnt -c 'passwd algol'

# Reboot
reboot
```

### 3. Deploy Full Configuration

After rebooting and logging in with the username:

```bash
# Clone the config
git clone <your-repo-url> ~/nixos-config
cd ~/nixos-config

# IMPORTANT: Customize for your setup
# 1. Edit flake.nix - update user and userSpecifiedBrowsers in specialArgs
# 2. Update SSH keys in modules/ssh-keys.nix with your actual keys
# 3. Update hardware-configuration.nix with your actual hardware UUIDs

# Deploy the full configuration
sudo nixos-rebuild switch --flake .#perseus
```

### 4. Post-Installation

```bash
# Set up ExpressVPN (manual)
sudo /etc/expressvpn-install.sh

# Configure i3 (copy sample config to ~/.config/i3/config)
# Configure polybar (already configured system-wide)

# Reboot to ensure all services start correctly
sudo reboot
```

## Features

- **Operating System**: NixOS 25.05 (latest) with Flakes
- **Window Manager**: i3 with custom configuration
- **Status Bar**: Polybar with system monitoring
- **Shell**: Zsh with powerlevel10k theme and useful aliases
- **Editor**: Neovim with extensive plugin setup via nixvim
- **Browser**: Configurable browsers (Brave, Firefox, Chromium)
- **Development**: Configurable language support (Python, Go, Rust, Next.js)
- **Gaming**: Steam with NVIDIA support and GameMode optimization
- **Graphics**: NVIDIA drivers with container toolkit support
- **VPN**: ExpressVPN support (manual installation) + OpenVPN
- **Streaming**: Stremio for media consumption
- **Security**: SSH with key-based authentication, firewall configured
- **Power Management**: TLP for battery optimization, thermal management
- **Auto-Updates**: Automatic system updates and garbage collection
- **CLI Configuration**: No code editing required - configure via environment variables

## Customization

Edit the modules in `modules/` to customize specific aspects:

- `environment.nix` - Base system settings
- `zsh.nix` - Shell configuration and aliases
- `nixvim.nix` - Editor configuration
- `i3.nix` - Window manager settings
- `polybar.nix` - Status bar configuration

## Updates

```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#perseus
```

## nixos-anywhere Deployment

This configuration is designed to work with nixos-anywhere for remote deployments using GitHub releases. **No code editing required** - configure via environment variables:

### **🚀 Easy CLI Configuration**

```bash
# Deploy with default settings (user: algol, browser: brave, no dev tools)
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus root@target-machine

# Customize via environment variables - no code editing needed!
PERSEUS_USER=alice \
PERSEUS_BROWSERS=firefox,chromium \
PERSEUS_DEV_TOOLS=python,rust,nextjs \
PERSEUS_LAPTOP=false \
PERSEUS_GPU=true \
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus root@target-machine

# Full development setup
PERSEUS_DEV_TOOLS=python,go,rust,nextjs \
PERSEUS_BROWSERS=brave,firefox \
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus root@dev-machine

# Server deployment (backend development only)
PERSEUS_USER=admin \
PERSEUS_DEV_TOOLS=python,go \
PERSEUS_BROWSERS= \
PERSEUS_LAPTOP=false \
PERSEUS_GPU=false \
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus root@server

# Use pre-configured variants (include common dev tools)
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus-desktop root@desktop
nixos-anywhere --flake github:yourusername/perseus/v0.1.0#perseus-server root@server
```

### **📋 Environment Variables**

| Variable            | Default | Description                                           |
| ------------------- | ------- | ----------------------------------------------------- |
| `PERSEUS_USER`      | `algol` | Username for the system                               |
| `PERSEUS_BROWSERS`  | `brave` | Comma-separated browser list (firefox,chromium,brave) |
| `PERSEUS_DEV_TOOLS` | ``      | Comma-separated dev tools (python,go,rust,nextjs)     |
| `PERSEUS_LAPTOP`    | `true`  | Enable laptop optimizations (true/false)              |
| `PERSEUS_GPU`       | `true`  | Enable NVIDIA support (true/false)                    |

### Release Workflow

1. **Test locally** first using the provided test script:

```bash
# Make test script executable and run it
chmod +x test-setup.sh
./test-setup.sh
```

2. **Create GitHub release** with version tag (e.g., v0.1.0)
3. **Deploy remotely** using nixos-anywhere with the release tag

**Manual testing commands:**

```bash
# Local testing
nix flake check                    # Check flake syntax
nix build .#nixosConfigurations.perseus.config.system.build.toplevel  # Test build
nixos-rebuild build-vm --flake .#perseus  # Test in VM
```

## Important Notes

### Before First Use

1. **SSH Keys**: Replace the placeholder keys in `modules/ssh-keys.nix` with your actual public keys
2. **Hardware Configuration**: After installation, copy the generated `/etc/nixos/hardware-configuration.nix` to `system/hardware-configuration.nix`
3. **Disk Configuration**: Adjust the disk device in `system/disko-config.nix` based on your hardware (e.g., `/dev/sda` vs `/dev/nvme0n1`)
4. **CPU Type**: Update `hardware-configuration.nix` to use `kvm-amd` instead of `kvm-intel` if using AMD processor
5. **NVIDIA**: The configuration assumes NVIDIA GPU; disable via `PERSEUS_GPU=false` or use `#perseus-server` for non-GPU systems

### Default Settings

- **Username**: `algol` (the famous variable star in Perseus)
- **Browser**: `brave`
- **Development Tools**: None (add via `PERSEUS_DEV_TOOLS=python,go,rust,nextjs`)
- **Laptop optimizations**: Enabled
- **NVIDIA support**: Enabled
- **All easily configurable via CLI!**

### Available Development Tools

- **Python**: Python 3.11 + pip
- **Go**: Go compiler
- **Rust**: rustc + cargo
- **Next.js**: Node.js 20 LTS + TypeScript

### ExpressVPN Setup

ExpressVPN requires manual installation as it's not available in nixpkgs:

1. Download the Linux package from ExpressVPN website
2. Follow the installation script instructions at `/etc/expressvpn-install.sh`
3. Alternatively, use OpenVPN with ExpressVPN's .ovpn configuration files

### Customization Tips

- Edit `modules/zsh.nix` to add more aliases or change shell behavior
- Modify `modules/polybar.nix` to customize the status bar appearance
- Update `modules/i3.nix` to add window manager keybindings and rules
- Adjust `modules/system-packages.nix` to add or remove system-wide packages

## Version

Current version: **v0.1.0**

This configuration targets NixOS 25.05 (latest stable release) with kernel 6.12 LTS for optimal NVIDIA compatibility.

**Perseus** - Named after the constellation, with **Algol** as the default username (the famous "demon star" in Perseus). Perfect for a laptop that connects to remote systems via nixos-anywhere. perseus
