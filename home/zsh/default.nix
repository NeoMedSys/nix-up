{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # 1. This is the corrected option
    syntaxHighlighting.enable = true; 

    # This runs 'fastfetch' on login (this option was correct)
    profileExtra = ''
      fastfetch
    '';

    "oh-my-zsh" = {
      enable = true;
      plugins = [
        "git"
        "z"
        "vi-mode"
        "fzf"
        "ssh-agent"
      ];
    };

    # 2. This is the corrected option: initContent
    initContent = ''
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

      # This sources the powerlevel10k theme
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';

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
