{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
    ./lock.nix
    ./wallpaper.nix
    ./packages.nix
    ./vscodium.nix
    ./onenote.nix
    ./onedrive.nix
    ./mega.nix
  ];

  home.username = "jakap42";
  home.homeDirectory = "/home/jakap42";
  # Keep this in sync with the system's stateVersion; do NOT bump it casually.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Terminal — enabled via the module (not just the package) so Stylix themes it.
  programs.kitty.enable = true;
}
