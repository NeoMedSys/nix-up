{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "expressvpn";
  version = "3.83.0.2"; # Or your downloaded version

  src = ./../vendor/expressvpn_3.83.0.2-1_amd64.deb;
  sha256 = "b0ee2882da2122934b752f4b5651e563e3d1ecf5b8c53895b5cc2d2dd4fdebd6";

  nativeBuildInputs = [ pkgs.dpkg ];
  buildInputs = [ pkgs.autoPatchelfHook pkgs.systemd ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    dpkg -x $src $out
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "ExpressVPN Client";
    homepage = "https://www.expressvpn.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
