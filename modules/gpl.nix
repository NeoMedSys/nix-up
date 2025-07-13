{ config, pkgs, lib, devTools ? [], user ? "algol", ... }:

let
  # Helper function to check if a tool is enabled
  hasDevTool = tool: builtins.elem tool devTools;
  
  # Language-specific package sets - MINIMAL only
  pythonPackages = with pkgs; [
    python3
    python311Packages.pip
  ];
  
  goPackages = with pkgs; [
    go
  ];
  
  rustPackages = with pkgs; [
    rustc
    cargo
  ];
  
  nextjsPackages = with pkgs; [
    nodejs_20   # Node.js LTS
    typescript
  ];

in
{
  # Only install dev tools if any are specified
  environment.systemPackages = lib.optionals (devTools != []) (
    # Language-specific packages - ONLY what was requested
    (lib.optionals (hasDevTool "python") pythonPackages) ++
    (lib.optionals (hasDevTool "go") goPackages) ++
    (lib.optionals (hasDevTool "rust") rustPackages) ++
    (lib.optionals (hasDevTool "nextjs") nextjsPackages)
  );
}
  
  # Programming-specific environment variables
  environment.variables = lib.mkMerge [
    # Python
    (lib.mkIf (hasDevTool "python") {
      PYTHONDONTWRITEBYTECODE = "1";
      PIP_DISABLE_PIP_VERSION_CHECK = "1";
    })
    
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
  
  # Development-specific services
  services = {
    # Enable Docker if any dev tools are specified
    docker.enable = lib.mkDefault (devTools != []);
  };
  
  # Development user groups
  users.users.${user} = lib.mkIf (devTools != []) {
    extraGroups = [ "docker" ];
  };
}
