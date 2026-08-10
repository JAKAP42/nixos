{
  flake.homeModules.vscodium =
    { pkgs, ... }:
    {
      # VSCodium = Visual Studio Code with Microsoft's telemetry/branding stripped
      # out. Fully open source, so no allowUnfree needed (unlike real VS Code).

      # VSCodium's launcher is called `codium`, not `code`. Add a tiny `code`
      # command that just forwards its arguments to codium, so habits like
      # `code .` (open the current directory) work.
      home.packages = [
        (pkgs.writeShellScriptBin "code" ''exec ${pkgs.vscodium}/bin/codium "$@"'')
      ];

      programs.vscode = {
        enable = true;
        package = pkgs.vscodium;

        profiles.default = {
          # Editor settings. Stylix handles the color theme + fonts, so those are
          # intentionally left out here.
          userSettings = {
            "editor.fontLigatures" = true;
            "editor.minimap.enabled" = false;
            "files.autoSave" = "onFocusChange";
            "workbench.startupEditor" = "none";
          };
        };
      };
    };
}
