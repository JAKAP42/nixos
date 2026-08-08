{ pkgs, ... }:
{
  # VSCodium = Visual Studio Code with Microsoft's telemetry/branding stripped
  # out. Fully open source, so no allowUnfree needed (unlike real VS Code).
  #
  # The Vim extension gives you vim MOTIONS inside a normal GUI editor: you get
  # hjkl / dw / ciw / etc., but the mouse, menus and file tree are all still
  # there as a safety net while you learn. The motions transfer 1:1 to Neovim
  # later if you decide to switch.
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

    # Declare extensions in Nix so they're reproducible (installed from nixpkgs,
    # not the in-app marketplace). Add more here as you find them.
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
      ];

      # Editor settings. Stylix handles the color theme + fonts, so those are
      # intentionally left out here.
      userSettings = {
        # Relative line numbers make vim's count motions (e.g. 5j, d3w) easy to
        # aim: each line shows its distance from the cursor.
        "editor.lineNumbers" = "relative";

        # Vim extension behaviour.
        "vim.useSystemClipboard" = true;  # y/p share the normal OS clipboard
        "vim.incsearch" = true;           # jump to matches as you type /search
        "vim.hlsearch" = true;            # highlight all search matches
        "vim.easymotion" = true;          # <leader><leader> quick-jump motions
        "vim.leader" = "<space>";         # space as the leader key (comfy)

        # Let a few essential VS Code shortcuts win over Vim so you're never
        # stuck — save, copy, paste, cut, undo, all, find.
        "vim.handleKeys" = {
          "<C-s>" = false;
          "<C-c>" = false;
          "<C-v>" = false;
          "<C-x>" = false;
          "<C-z>" = false;
          "<C-a>" = false;
          "<C-f>" = false;
        };

        # Quality-of-life defaults.
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;
        "files.autoSave" = "onFocusChange";
        "workbench.startupEditor" = "none";
      };
    };
  };
}
