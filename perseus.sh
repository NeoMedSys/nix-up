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

# Update user-config.nix with personal values
sed -i "s/PLACEHOLDER_USERNAME/$USERNAME/g" user-config.nix
sed -i "s/PLACEHOLDER_HOSTNAME/$HOSTNAME/g" user-config.nix
sed -i "s/PLACEHOLDER_TIMEZONE/$(timedatectl show -p Timezone --value 2>/dev/null || echo "Europe/Amsterdam")/g" user-config.nix
sed -i "s/PLACEHOLDER_IS_LAPTOP/$IS_LAPTOP/g" user-config.nix
sed -i "s/PLACEHOLDER_HAS_GPU/$HAS_GPU/g" user-config.nix
sed -i "s/PLACEHOLDER_BROWSERS/$BROWSERS/g" user-config.nix
sed -i "s/PLACEHOLDER_VPN/$VPN_ENABLED/g" user-config.nix
sed -i "s/PLACEHOLDER_GIT_NAME/$GIT_NAME/g" user-config.nix
sed -i "s/PLACEHOLDER_GIT_EMAIL/$GIT_EMAIL/g" user-config.nix
sed -i "s/PLACEHOLDER_LATITUDE/$LAT/g" user-config.nix
sed -i "s/PLACEHOLDER_LONGITUDE/$LON/g" user-config.nix

# Setup git filter to clean personal data on push
echo "Setting up git filter to clean personal data on push"
echo "user-config.nix filter=userconfig" >> .gitattributes

echo "DEBUG: USERNAME='$USERNAME'"
echo "DEBUG: HOSTNAME='$HOSTNAME'" 
echo "DEBUG: GIT_NAME='$GIT_NAME'"
echo "DEBUG: GIT_EMAIL='$GIT_EMAIL'"
echo "DEBUG: LAT='$LAT'"
echo "DEBUG: LON='$LON'"

git config filter.userconfig.clean "sed 's/testuser/PLACEHOLDER_USERNAME/g; s/testhost/PLACEHOLDER_HOSTNAME/g; s/Test User/PLACEHOLDER_GIT_NAME/g; s/test@example.com/PLACEHOLDER_GIT_EMAIL/g; s/52.4/PLACEHOLDER_LATITUDE/g; s/4.9/PLACEHOLDER_LONGITUDE/g; s/Europe\/Amsterdam/PLACEHOLDER_TIMEZONE/g'"
git config filter.userconfig.smudge cat

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

echo "✓ Created user-config.nix from template"
echo ""
echo "Next steps:"
echo "1. Edit user-config.nix to customize further"
echo "2. Add SSH keys to modules/ssh-keys.nix (if you didn't above)"
echo "3. Run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
