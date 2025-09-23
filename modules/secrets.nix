{ ... }:
{
  sops = {
    age.keyFile = "/home/jon/.config/sops/age/keys.txt";
    secrets.mullvad-conf = {
      sopsFile = ../secrets/wireguard.yaml;
      key = "mullvad_conf";
    };
  };
}
