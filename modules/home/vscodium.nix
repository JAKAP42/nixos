{
  flake.homeModules.vscodium =
    { pkgs, config, ... }:
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

      # BUG WORKAROUND: this home-manager version's `programs.vscode` writes the
      # settings to ~/.config/Code/User/ even when the package is VSCodium, which
      # reads ~/.config/VSCodium/User/ — so none of the above (or Stylix's theme)
      # ever reached the editor. Mirror the generated file into VSCodium's real
      # path. Same store source, so Stylix's merged settings come along too.
      home.file."${config.home.homeDirectory}/.config/VSCodium/User/settings.json".source =
        config.home.file."${config.home.homeDirectory}/.config/Code/User/settings.json".source;
    };
}
