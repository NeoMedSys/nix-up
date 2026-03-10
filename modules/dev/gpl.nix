{ pkgs, lib, userConfig, ... }:
let
  devTools = userConfig.devTools;
  hasDevTool = tool: builtins.elem tool devTools;

  goPackages = with pkgs; [ go gopls ];
  rustPackages = with pkgs; [ rustc cargo rust-analyzer clippy ];
  nodePkgs = with pkgs; [ 
    nodejs_22 
    nodePackages.pnpm 
    typescript
    nodePackages.typescript-language-server
    vscode-langservers-extracted 
    tailwindcss-language-server
  ];
in
{
  environment.systemPackages =
    (lib.optionals (hasDevTool "go") goPackages) ++
    (lib.optionals (hasDevTool "rust") rustPackages) ++
    (lib.optionals (hasDevTool "node") nodePkgs);

  environment.variables = lib.mkMerge [
    (lib.mkIf (hasDevTool "go") {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
    })
    (lib.mkIf (hasDevTool "rust") {
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
    })
    (lib.mkIf (hasDevTool "node") {
      NODE_OPTIONS = "--max-old-space-size=8192";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    })
  ];

  environment.sessionVariables = lib.mkIf (hasDevTool "node") {
    PATH = [ "$HOME/.local/share/pnpm" ];
  };
}
