![CI/CD](https://github.com/NeoMedSys/nix-up/actions/workflows/nix-up.yaml/badge.svg)
![Version](https://img.shields.io/github/v/tag/NeoMedSys/nix-up)
[![FlakeHub](https://img.shields.io/badge/flakehub-NeoMedSys/nix--up-blue)](https://flakehub.com/flake/NeoMedSys/nix-up)

# NixUp 🛡️

A declarative, privacy-hardened NixOS configuration. Built for Wayland, aggressive application sandboxing, and local network control.

## System Architecture

Perseus runs on **Niri** (scrollable-tiling Wayland compositor) with **DankMaterialShell (DMS)** providing the shell UI — widgets, app launcher, media controls, notifications, and system toggles.

To handle gaps in the Wayland ecosystem, Perseus ships three custom Rust daemons:

- **`clammy`** — Wayland power and display management daemon. Hooks into D-Bus/logind and the `ext_idle_notify_v1` Wayland protocol to manage: gradual screen dimming before lock (290s → 300s at default config), lock screen activation, DPMS toggling, system suspend, lid switch handling, and external monitor awareness for clamshell mode.

- **`niri-reaper`** — Flatpak zombie process killer. Watches the Niri event stream for window close events. When a Flatpak window is closed, the sandbox and child processes (including Wayland idle inhibitors) keep running — `niri-reaper` runs `flatpak kill` immediately to clean them up. Targets: Slack, Spotify, Steam, Teams, Zoom.

- **`ntl-daemon` (NastyTechLords)** — Security auditing daemon. Runs every 6 hours via systemd timer, inspecting processes, network state, filesystem integrity, privacy leaks, and Nix configuration. Reports logged to `/var/log/nastyTechLords/`.

## Privacy & Network Defense

The network stack is default-deny.

- **OpenSnitch + nftables**: All outbound traffic is queued to OpenSnitch for per-application approval. The nftables output chain explicitly allows only DNS (to local `dnscrypt-proxy`) and WireGuard before queuing everything else to OpenSnitch **without** the `bypass` flag — if OpenSnitch crashes, DNS and VPN keep working but all other traffic is dropped.
- **Encrypted DNS**: `dnscrypt-proxy2` on `127.0.0.1:53` handles all DNS (Cloudflare/Quad9, DNSSEC required). OISD domain blocklist updated daily. Application DoH/DoT endpoints are blackholed to prevent DNS bypass.
- **Telemetry blackhole**: Known analytics, crash reporting, and AI telemetry domains (Google Analytics, Slack metrics, Microsoft Vortex, Copilot, Tabnine, Sentry, Codeium, Cursor) blackholed to `0.0.0.0` in `/etc/hosts`. Corresponding environment variables (`SLACK_DISABLE_TELEMETRY`, `DOTNET_CLI_TELEMETRY_OPTOUT`, etc.) are set system-wide.
- **VPN**: Native WireGuard integration for Mullvad, secrets encrypted via `sops-nix` and `age`.
- **Network hardening**: MAC address randomization (Wi-Fi and Ethernet), disabled IP forwarding, SYN cookies, martian logging, ICMP echo disabled.
- **Fail2ban**: SSH on port 7889, 3 attempts max, 24h ban with incremental escalation.
- **AppArmor**: Enabled with `killUnconfinedConfinables`.
- **No swap**: Both swap devices and zram are force-disabled to prevent memory dumps.

## Application Sandboxing

Daily applications are isolated using two methods:

**Flatpak** (primary): Slack, Spotify, Steam, Teams, and Zoom run as Flatpaks with strict system overrides — forced Wayland sockets, `--nosocket=x11`, `--nofilesystem=home`, `--nofilesystem=host`, and injected telemetry-kill environment variables. Overrides are applied declaratively in `modules/apps/flatpak.nix`.

**Bubblewrap** (supplementary): For binaries not in Flatpak, Perseus uses custom `bwrap` derivations:
- `sandboxed-logseq` — Jailed Logseq with restricted namespace and filesystem access.
- `sandboxed-frontend` — Provides the `jail-dev` command for spinning up temporary containers for untrusted NPM/Node projects with stripped SSH agent access and isolated filesystem.

## Browsers

Both **LibreWolf** and **Firefox** are provisioned with declarative policies.

- **Hardening**: **Betterfox** (`Fastfox.js`, `Peskyfox.js`, `Securefox.js`, `Smoothfox.js`) loaded via flake input into `extraConfig`. On top of that, declarative `settings.nix` locks down telemetry, disables Pocket, blocks fingerprinting (`privacy.resistFingerprinting`), enforces HTTPS-only, disables WebRTC, clears data on shutdown, and blocks DoH/DoT bypass. Firefox Studies and Normandy are disabled.
- **Theming**: **Catppuccin** `userChrome.css` loaded via flake input.
- **Extensions**: Force-installed: uBlock Origin, DarkReader, Firemonkey, ClearURLs. Extensions auto-enabled in private browsing.

## Gaming

- **NVIDIA**: Prime offloading configured (`nvidia-drm.modeset=1`, early KMS).
- **Performance tooling**: `gamemode`, `gamescope`, `mangohud`.
- **Steam**: Flatpak with forced Wayland, full device access, and `xdg-download` filesystem.
- **Controllers**: DualSense and generic gamepad support via `antimicrox` and system uinput access.

## Development Environment

- **Language stacks**: Python, Go, Rust, and Node.js toggled via `user-config.nix`. Paths and environment variables merged dynamically.
- **Per-project isolation**: `direnv` with Nix integration — drop a `.envrc` in any project directory for automatic isolated environments.
- **Editor**: Neovim via `nixvim` — Catppuccin theme, Treesitter, Telescope, `conform.nvim`, and language-specific LSPs.
- **Jailed frontend dev**: `jail-dev` command launches a Bubblewrap container for untrusted Node/NPM work with restricted filesystem and no SSH agent.

## Project Structure

```
hosts/default/          # Machine-specific NixOS and hardware config
modules/
  apps/                 # Flatpak, LibreWolf, Thunderbird
  dev/                  # Language tooling, nixvim
  hardware/             # clammy, NVIDIA, Thunderbolt
  security/             # Privacy, firewall, telemetry deny, VPN, SSH, fail2ban
  system/               # Niri, DMS, greetd, packages, environment
home/                   # Home-manager: Firefox, zsh
programs/               # Custom Rust daemons (clammy, niri-reaper, ntl, perseus-net)
packages/               # Nix derivations for custom programs
configs/                # Dotfiles (Alacritty, GTK, LibreWolf userChrome, Mullvad)
secrets/                # sops-encrypted VPN config
```

## Installation

**Prerequisites:** NixOS 25.11+ on bare metal, Git, 20GB+ free space.

1. Clone the repository:
   ```bash
   git clone https://github.com/NeoMedSys/nix-up
   cd nix-up
   ```

2. Run the setup script **(required)**:
   ```bash
   ./setup.sh
   ```
   Interactive wizard that detects hardware, lets you choose browsers, dev tools, Flatpak apps, and optional modules. Generates `user-config.nix` and sets up Git smudge/clean filters so personal data never reaches the remote. Copies `hardware-configuration.nix` automatically if found.

3. Build and install:
   ```bash
   sudo nixos-install --flake .#<your-hostname>
   sudo reboot
   ```

> **First install**: Set `hasGPU` and `vpn` to `false` in `user-config.nix`. Enable after first successful boot.

### What's configurable

Everything toggleable lives in `user-config.nix`:

| Key | Type | Effect |
|-----|------|--------|
| `isLaptop` | bool | Enables clammy (idle/lock/suspend daemon) |
| `hasGPU` | bool | NVIDIA drivers + Prime offloading |
| `thunderbolt` | bool | Thunderbolt/dock support |
| `vpn` | bool | Mullvad WireGuard + sops-nix secrets |
| `email` | bool | Thunderbird |
| `flatpakApps` | list | Which Flatpak apps to install (empty = no Flatpak) |
| `browsers` | list | `"librewolf"`, `"firefox"`, or both |
| `devTools` | list | `"python"`, `"go"`, `"rust"`, `"node"` |
| `extraHosts` | attrset | Custom `/etc/hosts` entries |

### VPN Setup (Optional)

Requires `vpn = true;` in `user-config.nix`.

1. Generate an `age` key:
   ```bash
   mkdir -p ~/.config/sops/age
   nix-shell -p age -c "age-keygen -o ~/.config/sops/age/keys.txt"
   ```

2. Create `.sops.yaml` in repo root pointing to your public key.

3. Place WireGuard config in `secrets/wireguard.yaml` under `mullvad_conf`.

4. Encrypt: `nix-shell -p sops -c "sops -e -i secrets/wireguard.yaml"`

## Maintenance

```bash
nix flake update                                    # Update inputs
sudo nixos-rebuild switch --flake .#<hostname>         # Rebuild
sudo nixos-rebuild switch --rollback                # Rollback
ntl report                                          # Security audit report
```

## License

GPL-3.0
