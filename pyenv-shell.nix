{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "poetry-env";

  # Packages available inside the shell
  buildInputs = with pkgs; [
    python312
    poetry
    nox
    pkg-config
    openssl
    gcc
  ];

  # Tells Poetry to create its .venv inside the project folder
  shellHook = ''
    export POETRY_VIRTUALENVS_IN_PROJECT=true
  '';
}
