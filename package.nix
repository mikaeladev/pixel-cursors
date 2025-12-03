{
  pkgs,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pixel-cursors";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    pkgs.jq
    pkgs.imagemagick
    pkgs.toml-cli
    pkgs.xcursorgen
    (python3Packages.buildPythonApplication {
      pname = "pixels2svg";
      version = "0.2.4";
      format = "pyproject";

      src = fetchFromGitHub {
        owner = "ValentinFrancois";
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

  buildPhase = ''
    runHook preBuild
    sh ./scripts/build.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r ./dist $out/share/icons/${finalAttrs.pname}
    runHook postInstall
  '';
})
