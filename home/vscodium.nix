{ pkgs, ... }:
{
  # VSCodium = Visual Studio Code with Microsoft's telemetry/branding stripped
  # out. Fully open source, so no allowUnfree needed (unlike real VS Code).
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
}
