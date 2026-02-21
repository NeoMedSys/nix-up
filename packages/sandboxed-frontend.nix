{ pkgs, ... }:

pkgs.writeShellScriptBin "jail-dev" ''
  ISOLATION_DIR="$(pwd)/.sandbox"
  mkdir -p "$ISOLATION_DIR"
  USER_ID=$(id -u)

  # 1. Grab the "Reference Book" (Public Root CAs) from Nix
  #    This is NOT your domain cert, it is the list of all trusted public authorities.
  NIX_CERT_PATH="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

  # --- DYNAMIC .ENV PARSING ---
  ENV_ARGS=()
  if [ -f ".env" ]; then
    while IFS='=' read -r key value; do
      if [[ -n "$key" && -n "$value" ]]; then
        clean_val=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        ENV_ARGS+=(--setenv "$key" "$clean_val")
      fi
    done < <(grep -v '^#' .env | grep -v '^\s*$')
  fi

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
    --ro-bind /bin /bin \
    --ro-bind /usr/bin /usr/bin \
    --ro-bind /etc/fonts /etc/fonts \
    --ro-bind /etc/resolv.conf /etc/resolv.conf \
    --ro-bind /etc/machine-id /etc/machine-id \
    --ro-bind /etc/passwd /etc/passwd \
    --ro-bind /etc/group /etc/group \
    \
    --dir /etc/ssl/certs \
    --ro-bind "$NIX_CERT_PATH" /etc/ssl/certs/ca-certificates.crt \
    \
    --dir /run/user/$USER_ID \
    --bind "$ISOLATION_DIR" "$HOME" \
    --bind "$(pwd)" "$(pwd)" \
    --chdir "$(pwd)" \
    --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
    --ro-bind-try "$HOME/.ssh/known_hosts" "$HOME/.ssh/known_hosts" \
    --ro-bind-try "$HOME/.ssh/config" "$HOME/.ssh/config" \
    --ro-bind-try "$HOME/.config/git" "$HOME/.config/git" \
    --ro-bind-try "$HOME/.zshrc" "$HOME/.zshrc" \
    --ro-bind-try "$HOME/.p10k.zsh" "$HOME/.p10k.zsh" \
    --setenv HOME "$HOME" \
    --setenv PATH "$PATH" \
    --setenv XDG_RUNTIME_DIR "/run/user/$USER_ID" \
    --setenv SHELL "/run/current-system/sw/bin/zsh" \
    --setenv ZSH "${pkgs.oh-my-zsh}/share/oh-my-zsh" \
    --setenv IN_JAIL "JAILED" \
    --setenv SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
    --setenv NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt \
    --unsetenv SSH_AUTH_SOCK \
    "''${ENV_ARGS[@]}" \
    /run/current-system/sw/bin/zsh
''
