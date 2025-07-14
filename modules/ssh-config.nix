{ config, lib, inputs, user ? "algol", ... }:
{
	# Enable the OpenSSH daemon
	services.openssh = {
		enable = true;
		settings = {
			PermitRootLogin = "no";
			PasswordAuthentication = false;
			PubkeyAuthentication = true;
			Port = 7889;
		};
	};
	
	# SSH keys for the user
	users.users.${user}.openssh.authorizedKeys.keys =
		let keys = import ./ssh-keys.nix;
		in [
			keys.jon
		];
}
