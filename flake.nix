{
  # inspired by: https://serokell.io/blog/practical-nix-flakes#packaging-existing-applications
  description = "nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlay = (final: prev: {
          wasp = prev.stdenv.mkDerivation {
            pname = "wasp";
            version = "0.10.2";
            # NOTE TEMP FIXME: https://github.com/NixOS/nix/issues/4785
            # NOTE TEMP FIXME: https://discourse.nixos.org/t/fetchtarball-with-multiple-top-level-directories-fails/20556
            # src = builtins.fetchTarball {
            src = builtins.fetchurl {
              url =
                "https://github.com/wasp-lang/wasp/releases/download/v0.10.2/wasp-macos-x86_64.tar.gz";
              # "https://github.com/wasp-lang/wasp/releases/download/v0.10.2/wasp-linux-x86_64.tar.gz";
              sha256 = "1hyjvyxd4paixfmr6fd9n7n8nm5x5yi1fvbw8hjq1jkcrnr1wask";
            };
            nativeBuildInputs = [ prev.makeWrapper ];
            # NOTE: https://github.com/wasp-lang/get-wasp/blob/master/installer.sh
            unpackPhase = ''
              tar xzf $src
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp wasp-bin $out/bin/wasp
              cp -r data $out/data
              runHook postInstall
            '';
            postInstall = ''
              wrapProgram $out/bin/wasp \
                --set waspc_datadir $out/data
            '';
          };

        });
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in {
        inherit overlay;
        packages = with pkgs; { inherit wasp; };
        checks = self.packages;
        devShell = with pkgs; mkShell { buildInputs = [ wasp nodejs ]; };
      });
}
