{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,

  jq,
  imagemagick,
  toml-cli,
  xcursorgen,

  theme,
}:

let
  inherit (lib) escapeShellArg fileset;
  inherit (fileset) toSource unions;

  pixel-to-svg = rustPlatform.buildRustPackage {
    pname = "pixel-to-svg";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "mikaeladev";
      repo = "pixel-to-svg";
      rev = "07b3070c2d0f284704a00fd1be3176dedf9d7aa1";
      hash = "sha256-acZoCwe2rFeZ5W2nTJSBAUKjmkcwm3NQ3UNHgb6BFAo=";
    };

    cargoHash = "sha256-SOZtDO2IPLo6pOVojfh+cmbOFX4JNU7FCmtSPx6UnJ0=";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "pixel-cursors";
  version = "0.1.0";

  src = toSource {
    root = ./.;
    fileset = unions [
      ./assets
      ./scripts
      ./config.toml
    ];
  };

  nativeBuildInputs = [
    jq
    imagemagick
    pixel-to-svg
    toml-cli
    xcursorgen
  ];

  postPatch = ''
    patchShebangs scripts/
  '';

  buildPhase = ''
    runHook preBuild

    scripts/build.sh ${escapeShellArg theme}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    THEME=${escapeShellArg theme}
    PKG_NAME='pixel-cursors'

    if [[ $THEME != 'default' ]]; then
      PKG_NAME+="-$THEME"
    fi

    mkdir -p $out/share/icons
    cp -r dist $out/share/icons/$PKG_NAME

    unset THEME PKG_NAME

    runHook postInstall
  '';
})
