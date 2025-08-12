{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Enable Powerlevel10k Theme
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "z"
        "vi-mode"
        "fzf"
      ];
    };
    # add extras to .zshrc
    shellInit = ''
      # This part is for syntax highlighting
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

      # This function creates a custom Powerlevel10k prompt segment.
      # It checks for the '$IN_NIX_SHELL' variable, which is set by nix-shell.
      prompt_nix_shell() {
        if [[ -n "$IN_NIX_SHELL" ]]; then
          p10k segment -f cyan -t '(pyenv)'
        fi
      }
      # Add the custom function to the right-side of your prompt.
      typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS
      POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS+=(custom_prompt_nix_shell)
      eval "$(direnv hook zsh)"
      if ! ssh-add -l &>/dev/null; then
          eval "$(ssh-agent -s)" > /dev/null
          # Auto-load private keys
          for key in ~/.ssh/*; do
              if [[ -f "$key" && ! "$key" =~ \.(pub|old)$ && "$key" != *known_hosts* && "$key" != *authorized_keys* && "$key" != *config* ]]; then
                  ssh-add -q "$key" 2>/dev/null || true
              fi
          done
      fi
    '';
    loginShellInit = ''
      fastfetch
    '';
    syntaxHighlighting.enable = true;
    # Zsh Aliases
    shellAliases = {
      l = "ls -la";
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake";
      g = "git";
      gs = "git status";
      ga = "git add --all";
      gcm = "git commit -m";
      gch = "git checkout";
      gp = "git push";
      dotdot = "cd ..";
      n = "nvim";
      d = "docker";
      SS = "sudo systemctl";
    };
  };
}
