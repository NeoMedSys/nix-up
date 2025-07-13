# modules/zsh.nix
{ config, pkgs, ... }:
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
			source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
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
