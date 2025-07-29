#!/usr/bin/env bash
# Perseus setup - generate user-config.nix
set -e
echo "Welcome to Perseus NixOS Configuration Setup"
echo "==========================================="

if [ -f user-config.nix ]; then
    echo "user-config.nix already exists!"
    read -p "Overwrite? [y/N]: " OVERWRITE_RESPONSE
    [[ ! $OVERWRITE_RESPONSE =~ ^[Yy]$ ]] && exit 0
fi

# Detect hardware
GPU_DETECTED=false
LAPTOP_DETECTED=false

# Check for GPU via DRM subsystem
if ls /sys/class/drm/card* >/dev/null 2>&1; then
    # Check if any card mentions nvidia
    if grep -qi nvidia /sys/class/drm/card*/device/uevent 2>/dev/null; then
        GPU_DETECTED=true
    fi
fi

[ -e /sys/class/power_supply/BAT0 ] && LAPTOP_DETECTED=true

# Get user input
read -p "Username [$USER]: " USERNAME
USERNAME=${USERNAME:-$USER}

read -p "Hostname [perseus]: " HOSTNAME
HOSTNAME=${HOSTNAME:-perseus}

read -p "Full name for git: " GIT_NAME
read -p "Email for git: " GIT_EMAIL

read -p "Has NVIDIA GPU? [$GPU_DETECTED]: " GPU_INPUT
HAS_GPU=${GPU_INPUT:-$GPU_DETECTED}

read -p "Is laptop? [$LAPTOP_DETECTED]: " LAPTOP_INPUT
IS_LAPTOP=${LAPTOP_INPUT:-$LAPTOP_DETECTED}

# Browser selection
echo ""
echo "Browser selection:"
read -p "Include Brave? [Y/n]: " BRAVE_INPUT
read -p "Include Firefox? [Y/n]: " FIREFOX_INPUT

BROWSERS="["
[[ ! $BRAVE_INPUT =~ ^[Nn]$ ]] && BROWSERS="$BROWSERS \"brave\""
[[ ! $FIREFOX_INPUT =~ ^[Nn]$ ]] && BROWSERS="$BROWSERS \"firefox\""
BROWSERS="$BROWSERS ]"
BROWSERS=$(echo $BROWSERS | sed 's/\[ /[/g' | sed 's/ \]/]/g')

# Development tools selection
echo ""
echo "Development tools selection:"
read -p "Include Python? [Y/n]: " PYTHON_INPUT
read -p "Include Go? [Y/n]: " GO_INPUT
read -p "Include Rust? [y/N]: " RUST_INPUT
read -p "Include Node.js? [y/N]: " NODE_INPUT

DEVTOOLS="["
[[ ! $PYTHON_INPUT =~ ^[Nn]$ ]] && DEVTOOLS="$DEVTOOLS \"python\""
[[ ! $GO_INPUT =~ ^[Nn]$ ]] && DEVTOOLS="$DEVTOOLS \"go\""
[[ $RUST_INPUT =~ ^[Yy]$ ]] && DEVTOOLS="$DEVTOOLS \"rust\""
[[ $NODE_INPUT =~ ^[Yy]$ ]] && DEVTOOLS="$DEVTOOLS \"nodejs\""
DEVTOOLS="$DEVTOOLS ]"
DEVTOOLS=$(echo $DEVTOOLS | sed 's/\[ /[/g' | sed 's/ \]/]/g')

# VPN question
read -p "Enable VPN support? [y/N]: " VPN_INPUT
VPN_ENABLED=false
[[ $VPN_INPUT =~ ^[Yy]$ ]] && VPN_ENABLED=true

# Location selection
echo ""
echo "Select your location (for blue light filter):"
echo "1. US East Coast (New York)"
echo "2. US West Coast (Los Angeles)"
echo "3. Europe (Amsterdam)"
echo "4. Asia (Tokyo)"
echo "5. UK (London)"
echo "6. Custom coordinates"
read -p "Choose [1-6]: " LOCATION_CHOICE

case $LOCATION_CHOICE in
    1) LAT=40.7; LON=-74.0 ;;
    2) LAT=34.0; LON=-118.2 ;;
    3) LAT=52.4; LON=4.9 ;;
    4) LAT=35.7; LON=139.7 ;;
    5) LAT=51.5; LON=-0.1 ;;
    6)
        read -p "Enter latitude: " LAT
        read -p "Enter longitude: " LON
        ;;
    *) LAT=52.4; LON=4.9 ;; # Default to Amsterdam
esac

# Detect GPU bus IDs if GPU is enabled
if [[ $HAS_GPU == "true" ]]; then
    echo "Detecting GPU bus IDs..."
    INTEL_BUS_ID=$(lspci | grep -i "vga.*intel" | head -1 | cut -d' ' -f1 | sed 's/:/.:/g' | sed 's/^/PCI:/')
    NVIDIA_BUS_ID=$(lspci | grep -i "vga.*nvidia\|3d.*nvidia" | head -1 | cut -d' ' -f1 | sed 's/:/.:/g' | sed 's/^/PCI:/')
    
    if [[ -z "$INTEL_BUS_ID" || -z "$NVIDIA_BUS_ID" ]]; then
        echo "Warning: Could not auto-detect GPU bus IDs"
        echo "Run 'lspci | grep -i vga' to find your bus IDs"
        read -p "Enter Intel bus ID (format PCI:X:Y:Z): " INTEL_BUS_ID
        read -p "Enter NVIDIA bus ID (format PCI:X:Y:Z): " NVIDIA_BUS_ID
    fi
    echo "Intel bus ID: $INTEL_BUS_ID"
    echo "NVIDIA bus ID: $NVIDIA_BUS_ID"
fi

# Create user-config.nix with actual values
cat > user-config.nix << EOF
# Perseus User Configuration
{
  username = "$USERNAME";
  hostname = "$HOSTNAME";
  timezone = "$(timedatectl show -p Timezone --value 2>/dev/null || echo "Europe/Amsterdam")";
  isLaptop = $IS_LAPTOP;
  hasGPU = $HAS_GPU;
  browsers = $BROWSERS;
  devTools = $DEVTOOLS;
  vpn = $VPN_ENABLED;
  gitName = "$GIT_NAME";
  gitEmail = "$GIT_EMAIL";
  latitude = $LAT;
  longitude = $LON;$(if [[ $HAS_GPU == "true" ]]; then echo "
  intelBusId = \"$INTEL_BUS_ID\";
  nvidiaBusId = \"$NVIDIA_BUS_ID\";"; fi)
  wallpaperPath = "assets/wallpaper.png";
  avatarPath = "assets/king.png";
}
EOF

# Setup git filter to clean personal data on push
echo "Setting up git filters..."

# Check and add gitattributes entries only if they don't exist
grep -q "user-config.nix filter=userconfig" .gitattributes 2>/dev/null || echo "user-config.nix filter=userconfig" >> .gitattributes
grep -q "modules/ssh-keys.nix filter=sshkeys" .gitattributes 2>/dev/null || echo "modules/ssh-keys.nix filter=sshkeys" >> .gitattributes  
grep -q "system/hardware-configuration.nix filter=hardware" .gitattributes 2>/dev/null || echo "system/hardware-configuration.nix filter=hardware" >> .gitattributes

git config filter.userconfig.clean 'cat << "EOF"
# Perseus User Configuration
{
  username = "user";
  hostname = "perseus";
  timezone = "Europe/Amsterdam";
  isLaptop = false;
  hasGPU = false;
  browsers = ["brave" "firefox"];
  devTools = ["python" "go"];
  vpn = true;
  gitName = "user";
  gitEmail = "user@user.com";
  latitude = 52.4;
  longitude = 4.9;
  wallpaperPath = "assets/wallpaper.png";
  avatarPath = "assets/king.png";
}
EOF'
git config filter.userconfig.smudge 'if [ -f user-config.nix ] && [ -s user-config.nix ] && ! grep -q "username = \"user\"" user-config.nix; then cat; else cat; fi'

git config filter.sshkeys.clean 'cat << "EOF"
{
  # SSH public keys - add your keys here
  # Example:
  # user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com";
}
EOF'
git config filter.sshkeys.smudge cat

git config filter.hardware.clean 'cat << "EOF"
# Generic hardware configuration for CI evaluation
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };
  
  swapDevices = [ ];
  
  networking.useDHCP = lib.mkDefault true;
  
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.vmware.guest.enable = lib.mkDefault true;
}
EOF'
git config filter.hardware.smudge cat

# Handle SSH keys
echo ""
echo "SSH Key Setup:"
read -p "Do you want to add an SSH key now? [y/N]: " SSH_RESPONSE
echo
if [[ $SSH_RESPONSE =~ ^[Yy]$ ]]; then
    echo "Paste your SSH public key:"
    read -r SSH_KEY
    cat > modules/ssh-keys.nix << EOF
{
  # SSH public keys
  $USERNAME = "$SSH_KEY";
}
EOF
    echo "✓ Created modules/ssh-keys.nix with your key"
else
    # Create empty ssh-keys.nix so the import doesn't fail
    cat > modules/ssh-keys.nix << EOF
{
  # SSH public keys - add your keys here
  # Example:
  # $USERNAME = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com";
}
EOF
    echo "✓ Created empty modules/ssh-keys.nix"
fi

echo "✓ Created user-config.nix from template"
echo ""

# Protect local configs from being overwritten by git pulls
echo "Protecting local configs from git pull overwrites..."
git update-index --skip-worktree user-config.nix 2>/dev/null || echo "Note: user-config.nix protection will apply after first commit"
git update-index --skip-worktree modules/ssh-keys.nix 2>/dev/null || echo "Note: ssh-keys.nix protection will apply after first commit"
git update-index --skip-worktree system/hardware-configuration.nix 2>/dev/null || echo "Note: hardware-configuration.nix protection will apply after first commit"

echo "Next steps:"
echo "1. Edit user-config.nix to customize further"
echo "2. Add SSH keys to modules/ssh-keys.nix (if you didn't above)"
echo "3. Run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
echo ""
echo "Note: Your personal configs are now protected from git pull overwrites"
