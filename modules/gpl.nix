{ config, pkgs, lib, devTools ? [], user ? "algol", ... }:

let
  # Helper function to check if a tool is enabled
  hasDevTool = tool: builtins.elem tool devTools;

  # This creates the pyenv command
  pyenv = pkgs.writeShellScriptBin "pyenv" ''
    #!${pkgs.stdenv.shell}
    nix-shell --pure pyenv-shell.nix
  '';

  # Language-specific package sets
  goPackages = with pkgs; [ go ];
  rustPackages = with pkgs; [ rustc cargo ];
  nextjsPackages = with pkgs; [ nodejs_20 typescript ];

in
{
  # Conditionally install packages based on devTools list
  environment.systemPackages =
    (lib.optionals (hasDevTool "python") [ pyenv ]) ++
    (lib.optionals (hasDevTool "go") goPackages) ++
    (lib.optionals (hasDevTool "rust") rustPackages) ++
    (lib.optionals (hasDevTool "nextjs") nextjsPackages);

  # Programming-specific environment variables
  environment.variables = lib.mkMerge [
    # Go
    (lib.mkIf (hasDevTool "go") {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
    })
    # Rust
    (lib.mkIf (hasDevTool "rust") {
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
    })
    # Node.js/Next.js
    (lib.mkIf (hasDevTool "nextjs") {
      NODE_OPTIONS = "--max-old-space-size=8192";
    })
  ];

  # Development user groups
  users.users.${user} = lib.mkIf (devTools != []) {
    extraGroups = [ "docker" ];
  };
}
