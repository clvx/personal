{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "hugo-shell";
  buildInputs = [
    (pkgs.hugo.overrideAttrs (_: {
      version = "0.126.1";
    }))
    pkgs.go_1_21
    pkgs.git
  ];
   postShellHook = ''
    if [ -d .git/modules ]; then
      echo 'Running post shell hook...'
      git submodule update --init --recursive --remote
    fi
  '';
}
