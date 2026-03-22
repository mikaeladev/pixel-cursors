{
  lib,
  pkgs,
  stdenv,
  themes,
  ...
}:

let
  inherit (lib) escapeShellArgs fileset;
  inherit (fileset) toSource unions;
  inherit (stdenv) mkDerivation;
in

mkDerivation (finalAttrs: {
  pname = "pixel-cursors";
  version = "1.0.0";

  src = toSource {
    root = ./.;
    fileset = unions [
      ./assets
      ./scripts
      ./config.toml
    ];
  };

  nativeBuildInputs = with pkgs; [
    jq
    imagemagick
    toml-cli
    xcursorgen

    (rustPlatform.buildRustPackage {
      pname = "pixel-to-svg";
      version = "0.1.0";

      src = fetchFromGitHub {
        owner = "mikaeladev";
        repo = "pixel-to-svg";
        rev = "07b3070c2d0f284704a00fd1be3176dedf9d7aa1";
        hash = "sha256-acZoCwe2rFeZ5W2nTJSBAUKjmkcwm3NQ3UNHgb6BFAo=";
      };

      cargoHash = "sha256-SOZtDO2IPLo6pOVojfh+cmbOFX4JNU7FCmtSPx6UnJ0=";
    })
  ];

  preBuild = ''
    THEMES="${escapeShellArgs themes}"
  '';

  buildPhase = ''
    runHook preBuild

    for THEME in $THEMES; do
      sh ./scripts/build.sh $THEME
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -r ./dist/* $out/share/icons

    runHook postInstall
  '';
})
