let
  indentSize = 2;
  lineWidth = 80;
in

{
  projectRootFile = "flake.nix";

  programs.mdformat = {
    enable = true;
    settings.wrap = lineWidth;
    plugins = ps: [
      ps.mdformat-gfm
      ps.mdformat-gfm-alerts
    ];
  };

  programs.nixfmt = {
    enable = true;
    strict = true;
    indent = indentSize;
    width = lineWidth;
  };

  programs.shfmt = {
    enable = true;
    simplify = true;
    indent_size = indentSize;
  };
}
