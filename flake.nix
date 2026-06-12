{
  description = "pixel-cursors nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt,
      ...
    }:

    let
      forAllSystems =
        fn:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: fn nixpkgs.legacyPackages.${system}
        );
    in

    {
      formatter = forAllSystems (
        pkgs: (treefmt.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper
      );

      packages = forAllSystems (pkgs: rec {
        default = pixel-cursors;
        pixel-cursors = pkgs.callPackage ./package.nix { theme = "default"; };
        pixel-cursors-amethyst = pixel-cursors.override { theme = "amethyst"; };
        pixel-cursors-golden = pixel-cursors.override { theme = "golden"; };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ (self.packages.${pkgs.stdenv.hostPlatform.system}.default) ];

          shellHook = ''
            export HISTFILE="$(pwd)/.bash_history"
          '';
        };
      });
    };
}
