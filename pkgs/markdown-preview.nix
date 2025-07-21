packages.x86_64-linux.markdownPreviewServer = pkgs.stdenv.mkDerivation rec {
    pname = "markdown-preview-server";
    version = "1.7.0";  # match the plugin’s version

    src = pkgs.fetchFromGitHub {
      owner  = "iamcco";
      repo   = "markdown-preview.nvim";
      rev    = "v${version}";
      sha256 = "<calculate-with-nix-prefetch-git>";
    };

    nativeBuildInputs = [ pkgs.nodejs pkgs.yarn ];

    buildPhase = ''
      cd app
      yarn install --production --frozen‑lockfile
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib/markdown-preview
      cp -r app/* $out/lib/markdown-preview/
      cat > $out/bin/markdown-preview-server <<EOF
      #!${pkgs.runtimeShell}/bin/sh
      exec ${pkgs.nodejs}/bin/node $out/lib/markdown-preview/app
      EOF
      chmod +x $out/bin/markdown-preview-server
    '';
  };

