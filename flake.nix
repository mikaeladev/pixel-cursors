{
  description = "pixel-cursors nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:

    flake-utils.lib.eachDefaultSystem (
      system:

      let
        pkgs = nixpkgs.legacyPackages.${system};
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in

      {
        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;

        packages = rec {
          pixel-cursors = pkgs.callPackage ./package.nix { themes = [ "default" ]; };
          pixel-cursors-amethyst = pixel-cursors.override { themes = [ "amethyst" ]; };
          pixel-cursors-golden = pixel-cursors.override { themes = [ "golden" ]; };
          default = pixel-cursors;
        };
      }
    );
}
