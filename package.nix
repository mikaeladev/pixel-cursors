{
  lib,
  pkgs,
  python3Packages,
  stdenv,
  themes,
  ...
}:

let
  inherit (lib) escapeShellArgs;
  inherit (stdenv) mkDerivation;
in

mkDerivation (finalAttrs: {
  pname = "pixel-cursors";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    jq
    imagemagick
    toml-cli
    xcursorgen

    (python3Packages.buildPythonApplication {
      pname = "pixels2svg";
      version = "0.2.4";
      format = "pyproject";

      src = fetchFromGitHub {
        owner = "mikaeladev";
        repo = "pixels2svg";
        rev = "d9e1de61563965eb41c94226d1127af668ee838c";
        hash = "sha256-jNJDVa0sNd5QsuhLb/TkDl8p7V7S7JbHx8htqdAzrNk=";
      };

      dependencies = with python3Packages; [
        connected-components-3d
        pillow
        scipy
        setuptools
        svgwrite
      ];
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
