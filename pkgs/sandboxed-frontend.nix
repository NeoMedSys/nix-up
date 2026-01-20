{ pkgs, ... }:

pkgs.writeShellScriptBin "jail-dev" ''
  ISOLATION_DIR="$(pwd)/.sandbox"
  mkdir -p "$ISOLATION_DIR"

  USER_ID=$(id -u)
  
  echo "🛡️ Entering Frontend Jail..."
  echo "📍 Project Home: $ISOLATION_DIR"

  exec ${pkgs.bubblewrap}/bin/bwrap \
    --unshare-all \
    --share-net \
    --die-with-parent \
    --new-session \
    --hostname "frontend-prison" \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --tmpfs /dev/shm \
    --ro-bind /nix /nix \
    --ro-bind /run/current-system /run/current-system \
    --ro-bind /etc/fonts /etc/fonts \
    --ro-bind /etc/ssl /etc/ssl \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/machine-id /etc/machine-id \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind /etc/group /etc/group \
    --dir /run/user/$USER_ID \
    --bind "$ISOLATION_DIR" "$HOME" \
    --bind "$(pwd)" "$(pwd)" \
    --chdir "$(pwd)" \
    --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
    --ro-bind-try "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts" \
    --ro-bind-try "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519" \
    --ro-bind-try "$HOME/.ssh/config" "$HOME/.ssh/config" \
    --ro-bind-try "$HOME/.config" "$HOME/.config" \
    --ro-bind-try "$HOME/.local/share" "$HOME/.local/share" \
    --ro-bind-try "$HOME/.zshrc" "$HOME/.zshrc" \
    --ro-bind-try "$HOME/.p10k.zsh" "$HOME/.p10k.zsh" \
    --setenv HOME "$HOME" \
    --setenv PATH "$PATH" \
    --setenv XDG_RUNTIME_DIR "/run/user/$USER_ID" \
    --setenv SHELL "/run/current-system/sw/bin/zsh" \
    --setenv ZSH "${pkgs.oh-my-zsh}/share/oh-my-zsh" \
    --setenv IN_JAIL "JAILED" \
    --unsetenv SSH_AUTH_SOCK \
    /run/current-system/sw/bin/zsh
''
