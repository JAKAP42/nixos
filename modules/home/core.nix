# Baseline Home Manager settings shared by the user. The per-app modules
# (waybar, rofi, ...) are separate files, assembled in modules/user.nix.
{
  flake.homeModules.core =
    { userconf, ... }:
    {
      home.username = userconf.username;
      home.homeDirectory = "/home/${userconf.username}";
      # Keep this in sync with the system's stateVersion; do NOT bump it casually.
      home.stateVersion = userconf.stateVersion;

      programs.home-manager.enable = true;
      # Terminal (kitty) now lives in its own module: modules/home/kitty.nix.
    };
}
