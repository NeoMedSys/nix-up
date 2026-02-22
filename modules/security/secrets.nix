{ userConfig, ... }:
{
  sops = {
    age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";
    secrets.mullvad-conf = {
      sopsFile = ../../secrets/wireguard.yaml;
      key = "mullvad_conf";
    };
  };
}
