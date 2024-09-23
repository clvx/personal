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
   shellHook = ''
    if [ -d .git/modules ]; then
      echo 'Running post shell hook...'
      git submodule add -f git@github.com:lukeorth/poison.git  themes/poison
      git submodule update --init --recursive --remote 
      cd themes/poison && git checkout 07485e85f0247518bc64ed0cc6fd6b39abe3d90d && cd -
      hugo
    fi
  '';
}
