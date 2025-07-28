#!/usr/bin/env bash
# Perseus setup - generate user-config.nix
set -e
echo "Welcome to Perseus NixOS Configuration Setup"
echo "==========================================="

if [ -f user-config.nix ]; then
    echo "user-config.nix already exists!"
    read -p "Overwrite? [y/N]: " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

# Detect hardware
GPU_DETECTED=false
LAPTOP_DETECTED=false
if ls /sys/class/drm/card* >/dev/null 2>&1; then
    # Check if any card mentions nvidia ( add support for other cards )
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
echo "Browser selection (space to toggle, enter to confirm):"
echo "1. Brave"
echo "2. Firefox" 
echo "Both selected by default."
read -p "Include Brave? [Y/n]: " BRAVE_INPUT
read -p "Include Firefox? [Y/n]: " FIREFOX_INPUT

BROWSERS="["
[[ ! $BRAVE_INPUT =~ ^[Nn]$ ]] && BROWSERS="$BROWSERS \"brave\""
[[ ! $FIREFOX_INPUT =~ ^[Nn]$ ]] && BROWSERS="$BROWSERS \"firefox\""
BROWSERS="$BROWSERS ]"
BROWSERS=$(echo $BROWSERS | sed 's/\[ /[/g' | sed 's/ \]/]/g' | sed 's/" "/", "/g')

# Generate config file
cat > user-config.nix << EOF
# Perseus User Configuration
{
  username = "$USERNAME";
  hostname = "$HOSTNAME";
  timezone = "$(timedatectl show -p Timezone --value 2>/dev/null || echo "Europe/Amsterdam")";
  isLaptop = $IS_LAPTOP;
  hasGPU = $HAS_GPU;
  browsers = $BROWSERS;
  devTools = [ "python" "go" ];
  gaming = true;
  privacy = true;
  vpn = false;
  gitName = "$GIT_NAME";
  gitEmail = "$GIT_EMAIL";
  latitude = 52.37;
  longitude = 4.89;
}
EOF

# Handle SSH keys
echo ""
echo "SSH Key Setup:"
read -p "Do you want to add an SSH key now? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
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

echo "✓ Created user-config.nix"
echo ""
echo "Next steps:"
echo "1. Edit user-config.nix to customize further"
echo "2. Add SSH keys to modules/ssh-keys.nix (if you didn't above)"
echo "3. Run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
